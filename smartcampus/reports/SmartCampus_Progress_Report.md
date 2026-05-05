# SmartCampus Companion Progress Report

## Project Summary
SmartCampus Companion is a simple Flutter + FastAPI campus app built for a mobile operating systems assignment. The goal is to demonstrate the required OS concepts with a small, functional app rather than a production-grade system.

## Implemented Features
- Authentication with login and logout flow.
- Announcements, events, and timetable screens backed by API data.
- Offline caching for core data using SQLite.
- Persistent settings using SharedPreferences.
- Minimal device-feature demo screen for camera/gallery and location.
- Local notification test trigger from Settings.

## Mobile OS Concept Mapping
| Feature | Mobile OS Concept | What the App Demonstrates |
|---|---|---|
| Login and logout | Lifecycle and security | Session-based access to the app with authenticated navigation. |
| API data loading | Networking | REST calls to backend endpoints for announcements, events, and timetable. |
| SQLite cache | Storage and sandboxing | Local persistence for offline access and cached loading states. |
| Settings storage | Storage and sandboxing | Simple preference persistence across app restarts. |
| Device features screen | Permissions model | Camera/gallery and location permission requests with fallback states. |
| Notification test | Notifications | A basic local notification path that can be triggered from the app. |

## Current Status
The app is intentionally kept simple and functional. The main flows now work with clean analyzer output on the touched slices, and the implementation stays aligned with the assignment scope.

## Remaining Submission Work
- Capture screenshots of the implemented screens.
- Export this report to PDF.
- Confirm the final app flow on the target emulator or device.
