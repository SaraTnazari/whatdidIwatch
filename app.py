"""
What Did I Watch? - AI-Powered Show/Movie Finder
Describe a movie, TV show, cartoon, or anime in your own words and AI will find it for you.

Usage:
    1. Set your API keys as environment variables:
       export ANTHROPIC_API_KEY="your-key-here"
       export TMDB_API_KEY="your-key-here"  (get free at https://www.themoviedb.org/settings/api)

    2. Install dependencies:
       pip install flask anthropic requests python-dotenv

    3. Run the app:
       python app.py

    4. Open http://localhost:5000 in your browser
"""

import os
import re
import json
import traceback
from typing import Optional
import anthropic
import requests
from flask import Flask, request, jsonify, send_from_directory
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
app = Flask(__name__, static_folder=os.path.join(BASE_DIR, "static"))

# ── Claude API client ──────────────────────────────────────────────────────────
client = anthropic.Anthropic()  # Uses ANTHROPIC_API_KEY env var

TMDB_API_KEY = os.environ.get("TMDB_API_KEY", "")
TMDB_BASE = "https://api.themoviedb.org/3"
TMDB_IMG = "https://image.tmdb.org/t/p"

# Use the full model identifier for reliability
CLAUDE_MODEL = "claude-sonnet-4-5-20250929"


def extract_json_array(text: str) -> list:
    """Robustly extract a JSON array from Claude's response text."""
    text = text.strip()

    # Strip markdown code blocks (```json ... ``` or ``` ... ```)
    if text.startswith("```"):
        # Remove opening ``` line (with optional language tag)
        text = re.sub(r"^```(?:json)?\s*\n?", "", text)
        # Remove closing ```
        text = re.sub(r"\n?```\s*$", "", text)
        text = text.strip()

    # Try parsing directly first
    try:
        result = json.loads(text)
        if isinstance(result, list):
            return result
    except json.JSONDecodeError:
        pass

    # Try to find a JSON array in the text (Claude sometimes adds text around it)
    match = re.search(r"\[.*\]", text, re.DOTALL)
    if match:
        try:
            result = json.loads(match.group())
            if isinstance(result, list):
                return result
        except json.JSONDecodeError:
            pass

    # If all else fails, raise an error
    raise json.JSONDecodeError("Could not find valid JSON array", text, 0)


def identify_with_claude(description: str, language: str = "en") -> list:
    """Use Claude to identify shows/movies from a vague description."""

    # Language names for the prompt
    lang_names = {
        "en": "English", "es": "Spanish", "fr": "French", "de": "German",
        "pt": "Portuguese", "it": "Italian", "ru": "Russian", "ar": "Arabic",
        "fa": "Persian/Farsi", "hi": "Hindi", "zh": "Chinese", "ja": "Japanese",
        "ko": "Korean", "tr": "Turkish", "id": "Indonesian", "th": "Thai",
        "vi": "Vietnamese", "pl": "Polish", "nl": "Dutch", "sv": "Swedish",
    }
    lang_name = lang_names.get(language, "the same language as the user's input")

    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=2048,
        system=f"""You are an expert at identifying movies, TV shows, cartoons, and anime from vague descriptions.
Users will describe something they watched in their own words — in ANY language — possibly misremembering details, using informal language, slang, or only recalling fragments.

Your job is to figure out what they're describing. You understand ALL languages. The user may write in {lang_name} or any other language.

Return your answer as a JSON array of up to 5 matches, ordered by confidence (best match first).

Each match MUST have these exact fields:
- "title": The official title (in its original/most well-known form, plus a translation in {lang_name} if different)
- "year": Release year or start year (integer or null)
- "type": One of "movie", "tv", "cartoon", "anime"
- "confidence": "high", "medium", or "low"
- "explanation": A brief explanation IN {lang_name} of why this matches their description (1-2 sentences)
- "search_query": A clean English title to search on TMDB (just the title, no extra words)

IMPORTANT: Write the "explanation" field in {lang_name} so the user can understand it in their language.

Return ONLY a valid JSON array. No markdown, no explanation, no other text — just the JSON array starting with [ and ending with ].""",
        messages=[{"role": "user", "content": description}],
    )

    text = response.content[0].text.strip()
    print(f"[Claude raw response]: {text[:200]}...")

    return extract_json_array(text)


def search_tmdb(query: str, media_type: str = None) -> Optional[dict]:
    """Search TMDB for a movie/show and return poster + details."""
    if not TMDB_API_KEY:
        return None

    try:
        # Use multi-search to find any type
        resp = requests.get(f"{TMDB_BASE}/search/multi", params={
            "api_key": TMDB_API_KEY,
            "query": query,
            "include_adult": "false",
        }, timeout=10)

        if resp.status_code != 200:
            print(f"TMDB API error: status {resp.status_code}")
            return None

        results = resp.json().get("results", [])

        # Filter out person results - we only want movies and TV shows
        results = [r for r in results if r.get("media_type") in ("movie", "tv")]

        if not results:
            return None

        # Prefer the media type Claude suggested
        type_map = {"movie": "movie", "tv": "tv", "cartoon": "tv", "anime": "tv"}
        preferred = type_map.get(media_type, "movie")

        # Try to find a match of the right type first
        result = None
        for r in results:
            if r.get("media_type") == preferred:
                result = r
                break
        if not result:
            result = results[0]

        # Build response
        title = result.get("title") or result.get("name", "Unknown")
        date = result.get("release_date") or result.get("first_air_date", "")
        poster = result.get("poster_path")
        backdrop = result.get("backdrop_path")

        return {
            "tmdb_id": result.get("id"),
            "title": title,
            "year": date[:4] if date else None,
            "overview": result.get("overview", ""),
            "rating": result.get("vote_average", 0),
            "poster_url": f"{TMDB_IMG}/w500{poster}" if poster else None,
            "backdrop_url": f"{TMDB_IMG}/w1280{backdrop}" if backdrop else None,
            "media_type": result.get("media_type", "unknown"),
        }
    except Exception as e:
        print(f"TMDB error: {e}")
        return None


# ── API Routes ─────────────────────────────────────────────────────────────────

@app.route("/api/search", methods=["POST"])
def search():
    """Main search endpoint - takes a description, returns matches."""
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid request body"}), 400

    description = data.get("description", "").strip()
    language = data.get("language", "en")

    if not description:
        return jsonify({"error": "Please provide a description"}), 400

    if len(description) < 10:
        return jsonify({"error": "Please provide a more detailed description (at least 10 characters)"}), 400

    try:
        # Step 1: Ask Claude to identify the show/movie (in user's language)
        print(f"\n[Search] Description: '{description[:100]}...' Language: {language}")
        matches = identify_with_claude(description, language)
        print(f"[Search] Claude returned {len(matches)} matches")

        # Step 2: Enrich with TMDB data (posters, ratings, etc.)
        enriched = []
        for match in matches:
            search_query = match.get("search_query") or match.get("title", "")
            tmdb_data = search_tmdb(search_query, match.get("type"))

            if tmdb_data:
                print(f"[TMDB] Found: '{tmdb_data['title']}' for query '{search_query}'")
            else:
                print(f"[TMDB] No result for query '{search_query}'")

            enriched.append({
                "title": match.get("title", "Unknown"),
                "year": match.get("year"),
                "type": match.get("type", "unknown"),
                "confidence": match.get("confidence", "medium"),
                "explanation": match.get("explanation", ""),
                "poster_url": tmdb_data["poster_url"] if tmdb_data else None,
                "backdrop_url": tmdb_data["backdrop_url"] if tmdb_data else None,
                "overview": tmdb_data["overview"] if tmdb_data else "",
                "rating": tmdb_data["rating"] if tmdb_data else None,
                "tmdb_title": tmdb_data["title"] if tmdb_data else None,
            })

        return jsonify({"matches": enriched})

    except anthropic.AuthenticationError:
        print("[Error] Anthropic authentication failed")
        return jsonify({"error": "Invalid Anthropic API key. Please check your ANTHROPIC_API_KEY in the .env file."}), 401
    except anthropic.RateLimitError:
        print("[Error] Anthropic rate limited")
        return jsonify({"error": "Rate limited by Claude API. Please wait a moment and try again."}), 429
    except anthropic.APIConnectionError as e:
        print(f"[Error] Anthropic connection error: {e}")
        return jsonify({"error": "Could not connect to Claude API. Check your internet connection."}), 503
    except anthropic.NotFoundError:
        print("[Error] Anthropic model not found")
        return jsonify({"error": "Claude model not available. The app may need updating."}), 500
    except json.JSONDecodeError as e:
        print(f"[Error] JSON decode error: {e}")
        return jsonify({"error": "AI returned an unexpected format. Please try again with a different description."}), 500
    except Exception as e:
        print(f"[Error] Unexpected: {e}")
        traceback.print_exc()
        return jsonify({"error": f"Something went wrong: {str(e)}"}), 500


# ── Serve Frontend ─────────────────────────────────────────────────────────────

@app.route("/")
def index():
    return send_from_directory("static", "index.html")


@app.route("/<path:path>")
def static_files(path):
    return send_from_directory("static", path)


if __name__ == "__main__":
    # Validate API keys
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key or api_key == "your-anthropic-key-here":
        print("\n" + "=" * 60)
        print("  WARNING: ANTHROPIC_API_KEY not set!")
        print("  The app needs a valid Anthropic API key to work.")
        print("  1. Get your key at: https://console.anthropic.com")
        print("  2. Add it to the .env file:")
        print('     ANTHROPIC_API_KEY=sk-ant-...')
        print("=" * 60 + "\n")

    if not TMDB_API_KEY:
        print("\n  INFO: TMDB_API_KEY not set (optional but recommended for posters)")
        print("  Get a free key at: https://www.themoviedb.org/settings/api")
        print('  Add to .env: TMDB_API_KEY=your-key-here\n')

    print(f"\n  Using Claude model: {CLAUDE_MODEL}")
    print("  TMDB API: " + ("Enabled" if TMDB_API_KEY else "Disabled (no posters)"))
    print("\n  What Did I Watch? is running at http://localhost:8080\n")
    port = int(os.environ.get("PORT", 8080))
    app.run(debug=True, host="0.0.0.0", port=port)
