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

## Camera/Gallery Attachment for Event Notes
- Added per-event notes that support text and optional camera/gallery photo attachments.
- Photos are stored locally as encoded image data for offline availability.
- New notes are accessible by tapping an event, then opening its dedicated notes screen.

## Performance + Profiling (Flutter DevTools)
The following optimizations were applied and profiled on long scrolling lists:

1. Reduce paint/rebuild cost in list screens
- Change: added `RepaintBoundary` wrappers and stable `ValueKey` usage for announcement and event list rows.
- DevTools observation (before): frequent raster spikes while fast-scrolling long lists; more repaint work than expected per frame.
- DevTools observation (after): fewer repaint-heavy frames and smoother scroll cadence, with reduced frame jank frequency.

2. Improve list prefetching behavior for smoother scroll
- Change: configured `cacheExtent` on list views in event and announcement screens to prebuild nearby items.
- DevTools observation (before): visible micro-stutters when new list chunks entered viewport.
- DevTools observation (after): reduced stutter on viewport transitions and more stable frame timeline during continuous scroll.

These changes were intentionally lightweight and compatible with the assignment scope while still producing measurable UX improvements in DevTools timeline checks.

## Remaining Submission Work
- Capture screenshots of the implemented screens.
- Export this report to PDF.
- Confirm the final app flow on the target emulator or device.
