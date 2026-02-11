# AGENTS.md — tailbound-app

Flutter WebView wrapper for [Tailbound](https://github.com/0xkkun/tailbound) web game.

## Architecture

```
lib/
├── main.dart              # App entry, WebView setup, lifecycle, exit dialog
├── ad_manager.dart        # AdMob: rewarded, interstitial, banner (singleton)
├── services/
│   └── bridge_service.dart  # JS ↔ Flutter bridge (storage, haptic, ads, analytics)
└── l10n/
    ├── app_ko.arb         # Korean (template)
    ├── app_en.arb         # English
    └── app_localizations* # Generated — do NOT edit
```

## Key Patterns

- **Bridge protocol**: Web sends JSON via `FlutterBridge` JavaScriptChannel → `bridge_service.dart` routes by `type` field → returns result as JSON callback
- **Storage**: `SharedPreferences` (not localStorage) — web reads/writes via bridge `storage.get`/`storage.set`/`storage.remove`
- **Ads**: `AdManager` singleton — rewarded (4 types), interstitial, banner. Debug mode uses Google test ad IDs automatically (`kDebugMode`)
- **Lifecycle**: `AppLifecycleState` observer → `__GAME_PAUSE__`/`__GAME_RESUME__` injected to WebView
- **Environment injection**: `__APP_ENV__` injected on `onPageStarted` (platform, OS, safeArea)

## Commands

```bash
# Dev
flutter run                    # Debug on connected device
flutter analyze                # Lint
dart format .                  # Format (CI enforces)
flutter gen-l10n               # Regenerate localizations after arb changes

# Build
flutter build apk --release
flutter build ios --release --no-codesign

# Deploy (Android)
git tag v1.0.X && git push origin v1.0.X  # Triggers GitHub Actions → Play Store
```

## CI

- **Quality**: format check → analyze → test
- **Build**: Android APK (debug) + iOS (debug, no codesign)
- **Deploy**: Tag push `v*` → Fastlane → Google Play internal track

## Bridge Commands (Web ↔ Flutter)

All 11 commands must stay in sync between web (`bridgeService.ts`) and Flutter (`bridge_service.dart`):

| Command | Direction | Purpose |
|---------|-----------|---------|
| `storage.get` | Web → Flutter | Read SharedPreferences |
| `storage.set` | Web → Flutter | Write SharedPreferences |
| `storage.remove` | Web → Flutter | Delete from SharedPreferences |
| `haptic.impact` | Web → Flutter | Trigger haptic feedback |
| `ad.request` | Web → Flutter | Show rewarded ad |
| `ad.preload` | Web → Flutter | Preload ads for session |
| `safeArea.get` | Web → Flutter | Get safe area insets |
| `share.open` | Web → Flutter | Share content |
| `analytics.click` | Web → Flutter | Track click event |
| `analytics.impression` | Web → Flutter | Track impression |
| `gameCenter.openLeaderboard` | Web → Flutter | Open Game Center |
| `gameCenter.submitScore` | Web → Flutter | Submit score |

## Rules

- **Format before commit**: `dart format .` — CI rejects unformatted code
- **Analyze clean**: `flutter analyze --fatal-infos`
- **Bridge sync**: Adding a new command? Update BOTH `bridgeService.ts` (web) AND `bridge_service.dart` (Flutter)
- **l10n**: Edit `.arb` files, run `flutter gen-l10n`, never edit `app_localizations*.dart` directly
- **Ad IDs**: Production IDs in `ad_manager.dart` maps, test IDs auto-selected in debug
- **No force push** to main
