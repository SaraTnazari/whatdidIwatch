"""
What Did I Watch? — Backend Proxy Server
Handles Claude AI + TMDB requests so users don't need their own API keys.
Deploy this to Render, Railway, or any hosting service.

Usage:
    1. Set environment variables:
       ANTHROPIC_API_KEY=sk-ant-...
       TMDB_API_KEY=your-tmdb-key
       API_SECRET=a-random-secret-for-your-ios-app

    2. pip install -r requirements.txt
    3. python app.py
"""

import os
import re
import json
import time
import hashlib
import traceback
from typing import Optional
from functools import wraps
from collections import defaultdict

import anthropic
import requests
from flask import Flask, request, jsonify
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# ── Config ────────────────────────────────────────────────────────────────────
client = anthropic.Anthropic()
TMDB_API_KEY = os.environ.get("TMDB_API_KEY", "")
TMDB_BASE = "https://api.themoviedb.org/3"
TMDB_IMG = "https://image.tmdb.org/t/p"
CLAUDE_MODEL = "claude-sonnet-4-5-20250929"

# Secret that the iOS app sends to prove it's legit (not a random person hitting your API)
API_SECRET = os.environ.get("API_SECRET", "change-me-to-something-random")

# ── Rate Limiting ─────────────────────────────────────────────────────────────
# Simple in-memory rate limiter. For production, use Redis.
FREE_DAILY_LIMIT = 3
PAID_DAILY_LIMIT = 100

# { device_id: { "count": int, "date": "YYYY-MM-DD", "is_paid": bool } }
usage_tracker = defaultdict(lambda: {"count": 0, "date": "", "is_paid": False})


def check_rate_limit(device_id: str, is_paid: bool) -> tuple[bool, int]:
    """Check if a device has remaining searches. Returns (allowed, remaining)."""
    today = time.strftime("%Y-%m-%d")
    tracker = usage_tracker[device_id]

    # Reset counter on new day
    if tracker["date"] != today:
        tracker["count"] = 0
        tracker["date"] = today

    tracker["is_paid"] = is_paid
    limit = PAID_DAILY_LIMIT if is_paid else FREE_DAILY_LIMIT
    remaining = max(0, limit - tracker["count"])

    if tracker["count"] >= limit:
        return False, 0

    tracker["count"] += 1
    return True, remaining - 1


# ── Auth Middleware ────────────────────────────────────────────────────────────
def require_api_secret(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get("X-API-Secret", "")
        if auth != API_SECRET:
            return jsonify({"error": "Unauthorized"}), 401
        return f(*args, **kwargs)
    return decorated


# ── Claude ────────────────────────────────────────────────────────────────────
def extract_json_array(text: str) -> list:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*\n?", "", text)
        text = re.sub(r"\n?```\s*$", "", text)
        text = text.strip()

    try:
        result = json.loads(text)
        if isinstance(result, list):
            return result
    except json.JSONDecodeError:
        pass

    match = re.search(r"\[.*\]", text, re.DOTALL)
    if match:
        try:
            result = json.loads(match.group())
            if isinstance(result, list):
                return result
        except json.JSONDecodeError:
            pass

    raise json.JSONDecodeError("Could not find valid JSON array", text, 0)


def identify_with_claude(description: str, language: str = "en") -> list:
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
    return extract_json_array(text)


# ── TMDB ──────────────────────────────────────────────────────────────────────
def search_tmdb(query: str, media_type: str = None) -> Optional[dict]:
    if not TMDB_API_KEY:
        return None

    try:
        resp = requests.get(f"{TMDB_BASE}/search/multi", params={
            "api_key": TMDB_API_KEY,
            "query": query,
            "include_adult": "false",
        }, timeout=10)

        if resp.status_code != 200:
            return None

        results = resp.json().get("results", [])
        results = [r for r in results if r.get("media_type") in ("movie", "tv")]

        if not results:
            return None

        type_map = {"movie": "movie", "tv": "tv", "cartoon": "tv", "anime": "tv"}
        preferred = type_map.get(media_type, "movie")

        result = None
        for r in results:
            if r.get("media_type") == preferred:
                result = r
                break
        if not result:
            result = results[0]

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


def build_watch_links(title, year=None, media_type="movie"):
    from urllib.parse import quote_plus
    q = quote_plus(title)
    q_year = quote_plus(f"{title} {year}") if year else q
    return {
        "justwatch": f"https://www.justwatch.com/us/search?q={q}",
        "amazon": f"https://www.amazon.com/s?k={q_year}&i=instant-video",
        "apple_tv": f"https://tv.apple.com/search?term={q}",
        "youtube": f"https://www.youtube.com/results?search_query={q_year}+full+{media_type}",
        "google": f"https://www.google.com/search?q=watch+{q_year}+online",
    }


# ── API Routes ────────────────────────────────────────────────────────────────

@app.route("/api/search", methods=["POST"])
@require_api_secret
def search():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid request body"}), 400

    description = data.get("description", "").strip()
    language = data.get("language", "en")
    device_id = data.get("device_id", "unknown")
    is_paid = data.get("is_paid", False)

    if not description:
        return jsonify({"error": "Please provide a description"}), 400
    if len(description) < 10:
        return jsonify({"error": "Please provide a more detailed description (at least 10 characters)"}), 400

    # Rate limiting
    allowed, remaining = check_rate_limit(device_id, is_paid)
    if not allowed:
        limit = PAID_DAILY_LIMIT if is_paid else FREE_DAILY_LIMIT
        return jsonify({
            "error": f"Daily limit reached ({limit} searches). " +
                     ("Please try again tomorrow." if is_paid else "Upgrade to Pro for more searches!"),
            "limit_reached": True,
            "is_paid": is_paid,
        }), 429

    try:
        matches = identify_with_claude(description, language)

        enriched = []
        for match in matches:
            search_query = match.get("search_query") or match.get("title", "")
            tmdb_data = search_tmdb(search_query, match.get("type"))

            link_title = tmdb_data["title"] if tmdb_data else match.get("title", "")
            link_year = match.get("year")
            watch_links = build_watch_links(link_title, link_year, match.get("type", "movie"))

            enriched.append({
                "title": match.get("title", "Unknown"),
                "year": match.get("year"),
                "type": match.get("type", "unknown"),
                "confidence": match.get("confidence", "medium"),
                "explanation": match.get("explanation", ""),
                "search_query": match.get("search_query", ""),
                "poster_url": tmdb_data["poster_url"] if tmdb_data else None,
                "backdrop_url": tmdb_data["backdrop_url"] if tmdb_data else None,
                "overview": tmdb_data["overview"] if tmdb_data else "",
                "rating": tmdb_data["rating"] if tmdb_data else None,
                "tmdb_title": tmdb_data["title"] if tmdb_data else None,
                "watch_links": watch_links,
            })

        return jsonify({
            "matches": enriched,
            "remaining_searches": remaining,
        })

    except anthropic.AuthenticationError:
        return jsonify({"error": "Server configuration error. Please try again later."}), 500
    except anthropic.RateLimitError:
        return jsonify({"error": "Service is busy. Please wait a moment and try again."}), 429
    except json.JSONDecodeError:
        return jsonify({"error": "AI returned an unexpected format. Please try again."}), 500
    except Exception as e:
        print(f"[Error] {e}")
        traceback.print_exc()
        return jsonify({"error": "Something went wrong. Please try again."}), 500


@app.route("/api/verify-receipt", methods=["POST"])
@require_api_secret
def verify_receipt():
    """Verify an Apple App Store receipt (for validating in-app purchases).
    In production, you'd verify with Apple's servers. For now, trust the client."""
    data = request.get_json()
    device_id = data.get("device_id", "")
    # Mark device as paid
    if device_id:
        usage_tracker[device_id]["is_paid"] = True
    return jsonify({"status": "ok", "is_paid": True})


@app.route("/api/status", methods=["GET"])
def status():
    """Health check endpoint."""
    return jsonify({
        "status": "ok",
        "tmdb_enabled": bool(TMDB_API_KEY),
    })


if __name__ == "__main__":
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        print("\n  WARNING: ANTHROPIC_API_KEY not set!\n")
    if not TMDB_API_KEY:
        print("  INFO: TMDB_API_KEY not set (no posters)\n")
    if API_SECRET == "change-me-to-something-random":
        print("  WARNING: Using default API_SECRET. Set a real one in production!\n")

    print(f"  Model: {CLAUDE_MODEL}")
    print(f"  Free limit: {FREE_DAILY_LIMIT}/day | Paid limit: {PAID_DAILY_LIMIT}/day")
    print(f"\n  Backend running at http://localhost:8080\n")

    port = int(os.environ.get("PORT", 8080))
    app.run(debug=True, host="0.0.0.0", port=port)
