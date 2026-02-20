# 🎬 What Did I Watch?

**Describe any movie, TV show, cartoon, or anime in your own words — and AI will find it for you.**

Ever tried to explain a show you watched years ago but couldn't remember the name? Just describe what you remember, no matter how vague, and AI will figure it out.

## ✨ Features

- **AI-Powered Detection** — Uses Claude AI to understand vague, messy, or incomplete descriptions and match them to real titles
- **20 Languages** — Works in English, Spanish, French, German, Arabic, Persian, Hindi, Chinese, Japanese, Korean, and 10 more
- **Voice Input** — Speak your description instead of typing
- **Movie Posters & Ratings** — Pulls posters, ratings, and overviews from TMDB
- **Beautiful Dark UI** — Clean, modern interface that works on desktop and mobile

## 🚀 Try It

Describe something like:
- *"kids with spinning battle tops"* → Beyblade
- *"blue hedgehog collecting rings"* → Sonic
- *"guy stuck in the same day over and over"* → Groundhog Day
- *"teenagers with notebooks that kill people"* → Death Note
- *"fish looking for his son"* → Finding Nemo

## 🛠 Run It Yourself

1. **Clone the repo**
   ```bash
   git clone https://github.com/SaraTnazari/whatdidIwatch.git
   cd whatdidIwatch
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up your API keys**

   Create a `.env` file:
   ```
   ANTHROPIC_API_KEY=sk-ant-your-key-here
   TMDB_API_KEY=your-tmdb-key-here
   ```
   - Get your Anthropic key at [console.anthropic.com](https://console.anthropic.com)
   - Get a free TMDB key at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api)

4. **Run**
   ```bash
   python app.py
   ```
   Open `http://localhost:8080` in your browser.

## 🧠 How It Works

1. You describe what you remember in any language
2. Claude AI analyzes your description and identifies up to 5 possible matches
3. Each match is enriched with posters, ratings, and overviews from TMDB
4. Results are shown with confidence levels so you know how sure the AI is

## 🌍 Supported Languages

English, Spanish, French, German, Portuguese, Italian, Russian, Arabic, Persian, Hindi, Chinese, Japanese, Korean, Turkish, Indonesian, Thai, Vietnamese, Polish, Dutch, Swedish

## 📦 Tech Stack

- **Backend:** Python + Flask
- **AI:** Claude API (Anthropic)
- **Movie Data:** TMDB API
- **Frontend:** Vanilla HTML/CSS/JS
- **Voice:** Web Speech API

## 📄 License

MIT — use it, remix it, build on it.

---

Built with ❤️ and Claude AI
