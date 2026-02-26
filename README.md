# Tailbound App

A Flutter wrapper for the [Tailbound](https://tailbound.vercel.app) web game, providing native capabilities via a JavaScript bridge.

## Architecture

```
┌─────────────────────────────────────────┐
│  WebView (Tailbound web game)           │
│  ┌───────────────────────────────────┐  │
│  │ FlutterBridge JS Channel          │  │
│  └──────────────┬────────────────────┘  │
└─────────────────┼───────────────────────┘
                  │ JSON messages
┌─────────────────▼───────────────────────┐
│  BridgeService                          │
│  - Message parsing (BridgeMessage)      │
│  - Command routing                      │
│  - Response dispatch (BridgeResponse)   │
├─────────────────────────────────────────┤
│  Native Services                        │
│  - AdManager (Google Mobile Ads)        │
│  - SharedPreferences (via cache)        │
│  - HapticFeedback                       │
│  - Share                                │
│  - Firebase Messaging (FCM)             │
└─────────────────────────────────────────┘
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.9.0
- Xcode (for iOS)
- Android Studio (for Android)

### Build & Run

```bash
# Install dependencies
flutter pub get

# Run in debug mode (connects to localhost:5173)
flutter run

# Run with custom debug URL
flutter run --dart-define=DEBUG_URL=http://192.168.1.100:5173/

# Build release
flutter build ios --release
flutter build apk --release
```

### Analysis & Tests

```bash
flutter analyze    # Static analysis (must show 0 issues)
flutter test       # Unit tests
```

## Bridge Protocol

See [docs/BRIDGE_PROTOCOL.md](docs/BRIDGE_PROTOCOL.md) for the full message specification.

## Key Files

| File | Description |
|------|-------------|
| `lib/main.dart` | App entry point, WebView setup, lifecycle management |
| `lib/services/bridge_service.dart` | JS ↔ Flutter bridge message handler |
| `lib/models/bridge_message.dart` | Typed models for bridge messages |
| `lib/ad_manager.dart` | Google Mobile Ads management (rewarded, interstitial, banner) |
| `lib/widgets/exit_confirm_dialog.dart` | Exit confirmation dialog with banner ad |
| `lib/services/preferences_service.dart` | Cached SharedPreferences wrapper |
