# What Did I Watch? - iOS App Launch Guide

## Overview
What Did I Watch? is an iOS application that helps users find movies and TV shows based on natural language descriptions. Users can describe a movie or show they remember and the app will search for it using Claude AI analysis and TMDB database integration.

## Architecture

### Frontend (iOS App)
- **Framework**: SwiftUI
- **iOS Target**: iOS 15.0 and later
- **Theme**: Dark mode preferred

### Backend (Python Flask)
- **Deployment**: Render.com
- **Database**: SQLite (local) or PostgreSQL (production)
- **API Keys Required**: Claude API, TMDB API

## Project Structure

```
WhatDidIWatch/
├── WhatDidIWatchApp.swift          # App entry point
├── ContentView.swift                # Root view container
├── Models/
│   ├── MatchResult.swift           # Search result model
│   └── AppLanguage.swift           # Supported languages enum
├── ViewModels/
│   └── SearchViewModel.swift       # Main search logic and state
├── Views/
│   ├── SearchView.swift            # Main search interface
│   ├── ResultsSection.swift        # Search results display
│   ├── SettingsView.swift          # App settings
│   └── PaywallView.swift           # Premium subscription interface
├── Services/
│   ├── ClaudeService.swift         # Claude AI integration
│   ├── TMDBService.swift           # TMDB database integration
│   ├── SpeechService.swift         # Voice recognition
│   ├── BackendService.swift        # Backend API communication
│   └── StoreService.swift          # In-app purchases
├── Assets.xcassets/
├── Info.plist                      # App configuration
└── Localizable.strings             # Internationalization

backend/
├── app.py                          # Flask application
├── requirements.txt                # Python dependencies
├── Procfile                        # Render deployment config
├── render.yaml                     # Render deployment manifest
└── .env.example                    # Environment variables template
```

## Setup Instructions

### Prerequisites
- Xcode 14.0 or later
- iOS 15.0+ device or simulator
- Python 3.9+ (for backend)
- API Keys:
  - Claude API key (from Anthropic)
  - TMDB API key (from themoviedb.org)

### 1. Backend Setup (Render.com)

#### Create Render Service
1. Go to render.com and sign up/log in
2. Create a new Web Service
3. Connect your repository or use the provided backend folder
4. Configure environment variables:
   ```
   CLAUDE_API_KEY=<your-claude-api-key>
   TMDB_API_KEY=<your-tmdb-api-key>
   BACKEND_API_SECRET=<generate-a-random-secret>
   ```

#### Local Testing
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
export CLAUDE_API_KEY=<your-key>
export TMDB_API_KEY=<your-key>
export BACKEND_API_SECRET=<your-secret>
python app.py
```

### 2. iOS App Setup

#### Configure Backend URL
1. Open `WhatDidIWatch/Services/BackendService.swift`
2. Update `baseURL` to your deployed Render URL:
   ```swift
   static var baseURL = "https://your-app-name.onrender.com"
   ```
3. Update `apiSecret` to match your backend:
   ```swift
   static var apiSecret = "your-api-secret-here"
   ```

#### Configure TMDB (if using direct API)
1. Get API key from themoviedb.org
2. Update in `TMDBService.swift`:
   ```swift
   private let apiKey = "YOUR_TMDB_API_KEY"
   ```

#### Configure Speech Recognition
1. Open `Info.plist`
2. Ensure these keys are present:
   - `NSMicrophoneUsageDescription`
   - `NSSpeechRecognitionUsageDescription`

#### Build and Run
1. Open `WhatDidIWatch.xcodeproj` in Xcode
2. Select your target (simulator or device)
3. Press Cmd+R to build and run

### 3. App Store Submission

#### Create App Store Connect Entry
1. Create new app in App Store Connect
2. Configure:
   - App ID
   - App Name
   - Bundle ID (matching Xcode)
   - Category: Entertainment or Reference
   - Privacy Policy URL
   - Support Email

#### In-App Purchases
1. Create subscription product:
   - Product ID: `com.saranazari.WhatDidIWatch.proLifetime`
   - Type: Non-consumable
   - Price: $4.99
   - Duration: Lifetime

2. Update `StoreService.swift` with your product ID

#### Prepare for Submission
1. Test on physical device
2. Set appropriate app rating
3. Configure app screenshots
4. Add app description and keywords
5. Set up app icons (1024x1024 minimum)

## Features

### Search Functionality
- **Text Search**: Describe a movie/show in your own words
- **Voice Search**: Use speech recognition for hands-free searching
- **Smart Analysis**: Claude AI understands vague descriptions
- **Multi-language Support**: English, Spanish, French, German, Italian, Portuguese, Japanese, Korean, Chinese, Russian

### Results Display
- Movie/TV show titles with posters
- Release dates and ratings
- Plot summaries
- Confidence scores
- Watch links (via JustWatch integration)

### User Features
- Search history tracking
- Preference language selection
- Premium subscription option
- In-app purchase support

### Premium Features
- Unlimited searches (vs 3/day free)
- Priority processing
- Priority customer support

## API Endpoints

### Backend API

#### POST /api/search
Analyze a description and find matching media.

**Request:**
```json
{
  "description": "A movie about a group of thieves",
  "language": "en",
  "device_id": "uuid-string",
  "is_paid": false
}
```

**Response:**
```json
{
  "matches": [
    {
      "title": "Ocean's Eleven",
      "year": 2001,
      "type": "movie",
      "confidence": "high",
      "explanation": "Classic heist film with ensemble cast",
      "poster_url": "https://...",
      "backdrop_url": "https://...",
      "overview": "...",
      "rating": 7.9,
      "watch_links": {
        "amazon": "https://...",
        "apple_tv": "https://..."
      }
    }
  ],
  "remaining_searches": 2
}
```

## Environment Variables

### Backend (.env)
```
CLAUDE_API_KEY=<your-claude-api-key>
TMDB_API_KEY=<your-tmdb-api-key>
BACKEND_API_SECRET=<random-secret>
FLASK_ENV=production
DATABASE_URL=<postgresql-url-for-production>
```

## Troubleshooting

### Speech Recognition Not Working
- Check microphone permissions in Settings > WhatDidIWatch
- Ensure `NSSpeechRecognitionUsageDescription` in Info.plist
- Test on iOS 15+ (speech recognition is limited on older versions)

### Backend Connection Issues
- Verify `BackendService.baseURL` matches deployed URL
- Check `apiSecret` matches backend configuration
- Test backend endpoint with curl or Postman

### Rate Limiting Issues
- Backend enforces daily limits for free users
- Premium users bypass rate limits
- Configure limits in backend `app.py`

### Missing Search Results
- Verify TMDB API key is valid
- Check Claude API key permissions
- Ensure backend environment variables are set

## Deployment Checklist

- [ ] Backend deployed to Render
- [ ] Environment variables configured in Render
- [ ] iOS app backend URL updated
- [ ] App icons added (all required sizes)
- [ ] Privacy Policy prepared
- [ ] App Store Connect app created
- [ ] In-app purchase products configured
- [ ] Tested on physical iOS device
- [ ] Build archive created for submission
- [ ] App Store submission completed

## Support

For issues or questions:
- Check README.md in project root
- Review backend logs on Render dashboard
- Test with Xcode debug console output
- Verify API key permissions and quotas

## Future Enhancements

- [ ] Watchlist functionality
- [ ] Social sharing of searches
- [ ] User reviews and ratings
- [ ] Personalized recommendations
- [ ] Offline search history
- [ ] Dark mode optimization
- [ ] iPad support
- [ ] visionOS support (Vision Pro)

---

Last Updated: March 2026
Version: 1.0.0
