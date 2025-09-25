# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project type: Flutter mobile app (Android/iOS)

Commands

- Prereqs
  - Ensure Flutter SDK is installed and on PATH
  - Install dependencies: flutter pub get
  - List connected devices/emulators: flutter devices

- Run (debug)
  - Android (pick a device by ID): flutter run -d <DEVICE_ID> --dart-define=API_BASE=http://localhost:8000
  - iOS (requires macOS/Xcode): flutter run -d <IOS_DEVICE_ID> --dart-define=API_BASE=https://your.api

- Build (release)
  - Android APK: flutter build apk --release --dart-define=API_BASE=https://your.api
  - Android App Bundle: flutter build appbundle --release --dart-define=API_BASE=https://your.api
  - iOS: flutter build ios --release --dart-define=API_BASE=https://your.api

- Tests
  - Run all tests: flutter test
  - Run a single file: flutter test test/widget_test.dart
  - Run tests matching a name: flutter test --plain-name "pattern"
  - (Optional) Provide API base for tests if needed: flutter test --dart-define=API_BASE=http://localhost:8000

- Linting and formatting
  - Static analysis: flutter analyze
  - Auto-fix lint suggestions (where safe): dart fix --apply
  - Format code: dart format .

- Maintenance
  - Clean build artifacts: flutter clean
  - Upgrade dependencies: flutter pub upgrade

Configuration notes

- API base URL
  - The app reads the API base from a compile-time define: String.fromEnvironment('API_BASE').
  - Default is http://localhost:8000 if not provided.
  - Pass via --dart-define on run/test/build commands (examples above).

High-level architecture

- Entry point and DI
  - lib/main.dart is the entry point. The app is wrapped with ProviderScope (Riverpod) to provide dependency injection and state management.
  - Providers
    - apiBaseUrlProvider: reads compile-time API base (API_BASE)
    - tokenProvider: StateProvider<String?> holding the authenticated bearer token

- Screens
  - LoginScreen
    - Collects credentials and POSTs to {API_BASE}/api/login
    - On success, stores the bearer token in tokenProvider and routes to DashboardScreen
  - DashboardScreen
    - Fetches data with http using the bearer token:
      - Realtime KPIs: GET {API_BASE}/api/dashboard/realtime
      - Alerts list: GET {API_BASE}/api/dashboard/alerts
      - Historical series: GET {API_BASE}/api/dashboard/historical?metric=...&period=...
    - Transforms historical series into points rendered with fl_chart

- UI composition
  - Theming (lib/theme.dart): Dark Material 3 theme, Inter font, custom card and color scheme
  - Reusable widgets (lib/widgets)
    - AppHeader: title bar with last-updated text
    - KpiCard: displays a KPI with value/unit and accent icon
    - AlertsCarousel and AlertBanner: rotating alert messages with a call-to-action
    - LineChartPanel: metric/period selectors and a line chart (fl_chart) for historical data

- Platform projects
  - android/: Standard Gradle-based module. build outputs are redirected to ../../build by android/build.gradle.kts
  - ios/: Standard Xcode project/workspace under ios/Runner. App name and metadata in ios/Runner/Info.plist

Repo conventions

- Lints: analysis_options.yaml includes package:flutter_lints/flutter.yaml. Use flutter analyze to check.
- State management: hooks_riverpod with flutter_hooks for widget lifecycle convenience.
- Networking: package:http with manual JSON decode. Authorization header uses the bearer token from tokenProvider.

Notes for agents

- On Windows, iOS build/run is not available; use Android devices/emulators.
- The sample test at test/widget_test.dart appears to be the default Flutter template and may not reflect the current app structure; update it (e.g., to pump SolnovaApp) before relying on it for assertions.
