# SmartCampus Companion — Flutter Mobile App

A mobile app that demonstrates essential mobile OS concepts using Flutter & Dart. The app helps students navigate daily campus life: schedules, announcements, campus maps, and safety alerts. Works reliably online and offline.

## Quick Start

### Prerequisites
- Flutter SDK (3.11+) and Dart
- Android Studio / Xcode for emulator (or physical device)
- Backend server running on `localhost:8000`

### Project Structure

```
smartcampus/
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/               # UI screens
│   │   ├── login_screen.dart
│   │   ├── main_screen.dart   # Bottom navigation wrapper
│   │   ├── home_screen.dart   # Dashboard
│   │   └── settings_screen.dart
│   ├── services/              # Business logic
│   │   ├── auth_service.dart  # API calls + secure storage
│   │   └── auth_provider.dart # State management (Provider)
│   ├── models/                # Data models
│   │   └── user.dart
│   ├── utils/
│   │   ├── constants.dart     # API URLs + storage keys
│   │   └── router.dart        # Go Router configuration
│   └── widgets/               # Reusable widgets (placeholder)
├── pubspec.yaml               # Dependencies
└── README.md
```

## Installation

1. **Get dependencies:**
   ```bash
   cd smartcampus
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

   Or run on a specific device:
   ```bash
   flutter run -d chrome        # Web (experimental)
   flutter run -d android       # Android emulator
   flutter run -d ios           # iOS simulator
   ```

## Demo Credentials

- **Email:** `test@campus.com`
- **Password:** `password`

## Current Features ✅

### Phase 1: Authentication & Navigation
- [x] Login screen with email/password
- [x] Secure token storage using `FlutterSecureStorage`
- [x] Session persistence (auto-login on app restart)
- [x] Bottom navigation (Home, Announcements, Settings)
- [x] Settings screen with logout
- [x] Go Router-based navigation with auth guards

### Phase 1: Backend
- [x] FastAPI server with CORS support
- [x] Login endpoint with JWT token generation
- [x] Logout endpoint
- [x] Health check endpoint
- [x] API documentation (Swagger UI)

### Architecture
- **State Management:** Provider (ChangeNotifier pattern)
- **Navigation:** Go Router with auth-based redirect
- **Data Persistence:** FlutterSecureStorage (tokens) + SharedPreferences (settings)
- **HTTP Client:** http package
- **Security:** JWT tokens, secure storage for sensitive data

## Next Milestones

### Phase 2: Data Fetching & Offline Support
- [ ] Fetch announcements from API
- [ ] Fetch events/timetable from API
- [ ] SQLite database for offline caching
- [ ] Detect online/offline status
- [ ] Display offline banner when needed
- [ ] Sync cached data when back online

### Phase 3: Database & Export
- [ ] SQLite schema for announcements, events, timetable
- [ ] Export schedule as JSON
- [ ] Periodic cache refresh in background

### Phase 4: Device Features & Permissions
- [ ] Camera/gallery for event notes
- [ ] Location services for campus POIs
- [ ] Accelerometer demo
- [ ] Runtime permissions management

### Phase 5: Notifications & Background
- [ ] Local notifications for class reminders
- [ ] Background task scheduling
- [ ] Notification deep-linking

### Phase 6: Performance Profiling
- [ ] Flutter DevTools profiling
- [ ] Identify optimization opportunities
- [ ] Before/after performance metrics

## Configuration

### API Base URL
Edit `lib/utils/constants.dart` to change the API endpoint:
```dart
const String apiBaseUrl = 'http://localhost:8000/api';
```

For production, update this to your deployed API.

### Secure Storage Keys
The app uses these keys in secure storage:
- `auth_token` — JWT access token
- `user_email` — User's email

## Running Tests

(To be implemented in later phases)

```bash
flutter test
```

## Build for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### "Connection refused" error
- Make sure the FastAPI server is running on `localhost:8000`
- Run: `cd backend && uvicorn main:app --reload`

### Emulator can't reach localhost
- Android emulator: Use `10.0.2.2:8000` instead of `localhost:8000`
- To fix in the app, add a configuration for debug builds

### Token storage not working
- Ensure `flutter_secure_storage` plugin initialization
- Check platform-specific requirements for Android/iOS

## Mobile OS Concepts Demonstrated

- **App Lifecycle:** Initialization, auth check, state restoration
- **Storage:** Secure storage, SharedPreferences, SQLite
- **Networking:** HTTP requests, offline detection, caching
- **Permissions:** Runtime permissions for camera, location
- **Notifications:** Local notifications, background tasks
- **Security:** JWT tokens, secure credential storage

## Contributing

This is a learning project. Feel free to extend features or add improvements!

## License

MIT
