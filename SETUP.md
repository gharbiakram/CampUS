# SmartCampus Companion - Quick Start & Verification Guide

This guide walks you through setting up and testing the initial build.

## Directory Structure

```
CampUS/
├── smartcampus/            # Flutter mobile app
│   ├── lib/
│   ├── pubspec.yaml
│   └── README.md
├── backend/                # FastAPI backend
│   ├── app/
│   ├── main.py
│   ├── requirements.txt
│   └── README.md
└── SETUP.md               # This file
```

## Step 1: Set Up the Backend (5 minutes)

### 1.1 Install Python Dependencies

Open a terminal and navigate to the backend:

```bash
cd backend
pip install -r requirements.txt
```

**Expected Output:**
```
Successfully installed fastapi-0.104.1 uvicorn-0.24.0 ...
```

### 1.2 Start the FastAPI Server

```bash
uvicorn main:app --reload --port 8000
```

**Expected Output:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started server process [XXXX]
INFO:     Application startup complete
```

**✅ Server is running! Keep this terminal open.**

### 1.3 Verify the Backend (Optional)

In a new terminal, test the API:

```bash
# Health check
curl http://localhost:8000/api/health

# Try login with demo credentials
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"test@campus.com\", \"password\": \"password\"}"
```

Or open the interactive docs in your browser:
```
http://localhost:8000/docs
```

---

## Step 2: Set Up the Flutter App (5 minutes)

### 2.1 Get Dependencies

Open a new terminal and navigate to the Flutter project:

```bash
cd smartcampus
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in smartcampus...
Got dependencies in 15.2s.
```

### 2.2 Run the App

Choose your target platform:

**Android Emulator:**
```bash
flutter run -d android
```

**iOS Simulator:**
```bash
flutter run -d ios
```

**Chrome (Web - Experimental):**
```bash
flutter run -d chrome
```

**Physical Device (connected via USB):**
```bash
flutter run
```

**Expected Output:**
```
Launching lib/main.dart on Android in debug mode...
Running Gradle build...
√ Built build/app/outputs/apk/debug/app-debug.apk (23.4MB)
Installing and launching...
Debug service listening on ws://127.0.0.1:xxxxx/abc...
The Flutter DevTools debugger and profiler is available at: http://127.0.0.1:xxxxx
```

---

## Step 3: Test the Login Flow ✅

### 3.1 Launch Screen Verification

When the app launches, you should see:
- **Login Screen** with:
  - SmartCampus Companion branding (school icon)
  - Email input field
  - Password input field
  - Login button
  - Demo credentials at the bottom

### 3.2 Test Login

1. Enter credentials:
   - Email: `test@campus.com`
   - Password: `password`

2. Tap "Login"

3. **Expected behavior:**
   - Loading indicator appears
   - If successful → Redirects to **Home Dashboard**
   - If failed → Error message appears

### 3.3 Verify Home Screen

After login, you should see:
- **Dashboard** with:
  - "Welcome to SmartCampus" greeting
  - 4 feature cards: Schedule, Announcements, Campus Map, Alerts (all clickable placeholders)
  - Features coming soon list

### 3.4 Test Bottom Navigation

- Tap **Announcements** → See placeholder
- Tap **Settings** → See account info, preferences, and logout button

### 3.5 Test Logout

1. Go to **Settings** tab
2. Tap **"Logout"** button
3. Confirm logout
4. **Expected:** Redirected back to **Login Screen**

### 3.6 Test Session Persistence

1. Log in again
2. Close the app completely
3. Reopen the app
4. **Expected:** Should bypass login and go straight to **Home Dashboard**

---

## Step 4: Verify Secure Storage ✅

The app securely stores:
- JWT token in `auth_token` key
- Email in `user_email` key

These can only be accessed via the app and are encrypted on the device.

---

## Checklist: Initial Setup Complete ✅

- [ ] Backend running on `http://localhost:8000`
- [ ] Backend API docs accessible at `/docs`
- [ ] Flutter dependencies installed
- [ ] App launches without build errors
- [ ] Login screen appears
- [ ] Login with demo credentials works
- [ ] Home dashboard displays
- [ ] Bottom navigation works (Home, Announcements, Settings)
- [ ] Logout redirects to login screen
- [ ] Session persists after app restart

---

## Troubleshooting

### "Connection refused" error when logging in
**Problem:** The backend server isn't running.
**Solution:**
```bash
# In the backend terminal:
cd backend
uvicorn main:app --reload --port 8000
```

### Emulator can't reach localhost:8000
**Problem:** Android emulator uses `10.0.2.2` instead of `localhost`.
**Solution (in Flutter, to implement later):**
```dart
// For debug builds targeting Android emulator:
const String apiBaseUrl = kDebugMode 
  ? 'http://10.0.2.2:8000/api'  // Android emulator
  : 'http://localhost:8000/api'; // Others
```

### "flutter: pub get" says missing dependencies
**Problem:** Dependencies weren't fully downloaded.
**Solution:**
```bash
flutter clean
flutter pub get
```

### iOS build errors
**Problem:** iOS pods need updating.
**Solution:**
```bash
cd ios
pod repo update
pod install
cd ..
flutter run
```

### Android build errors
**Problem:** Gradle or JDK conflicts.
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## Next Steps

After verification, the next phase implements:
1. **Data Fetching** - Fetch announcements and events from API
2. **Offline Support** - Cache data and work without internet
3. **SQLite Database** - Persist announcements, events, timetable
4. **Device Features** - Camera, location, sensors

See the Flutter app's `README.md` for the full roadmap.

---

## File Inventory

### Flutter App
- `smartcampus/lib/main.dart` - Entry point with Provider + Go Router
- `smartcampus/lib/screens/` - UI screens
- `smartcampus/lib/services/` - Auth service and state management
- `smartcampus/lib/models/` - Data models
- `smartcampus/lib/utils/` - Constants and router config
- `smartcampus/pubspec.yaml` - Dependencies

### Backend
- `backend/main.py` - FastAPI entry point
- `backend/app/routes/auth.py` - Login/logout endpoints
- `backend/app/models/auth.py` - Request/response models
- `backend/app/utils/security.py` - JWT token handling
- `backend/requirements.txt` - Python packages

---

## Demo Account

Use these credentials for all testing:
- **Email:** `test@campus.com`
- **Password:** `password`
- **User Name:** Test Student

---

Good luck! 🚀
