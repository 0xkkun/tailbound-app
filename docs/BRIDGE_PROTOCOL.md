# Bridge Protocol

Communication between the WebView game and Flutter native layer.

## Transport

- **Web → Flutter:** `FlutterBridge.postMessage(JSON.stringify(message))`
- **Flutter → Web:** `CustomEvent('flutterBridgeResult', { detail: response })`

## Request Format

```json
{
  "id": "unique-message-id",
  "type": "command.name",
  "payload": { ... }
}
```

## Response Format

```json
{
  "id": "original-message-id",
  "type": "command.name",
  "success": true,
  "data": { ... },
  "error": null,
  "timestamp": 1709000000000
}
```

## Message Types

### Ads

#### `ad.request`
Shows a rewarded ad.

**Payload:**
| Field | Type | Description |
|-------|------|-------------|
| `adType` | `string` | One of: `artifact`, `revival`, `reroll`, `bundle` |

**Response data:** `{ "success": bool, "rewarded": bool }`

#### `ad.preload`
Preloads a rewarded ad for later display.

**Payload:**
| Field | Type | Description |
|-------|------|-------------|
| `adType` | `string` | One of: `artifact`, `revival`, `reroll`, `bundle` |

**Response data:** `{ "success": true }`

### Safe Area

#### `safeArea.get`
Returns device safe area insets (notch, navigation bar).

**Payload:** (empty)

**Response data:** `{ "top": double, "bottom": double, "left": double, "right": double }`

### Storage

#### `storage.set`
Stores a key-value pair persistently.

**Payload:**
| Field | Type | Description |
|-------|------|-------------|
| `key` | `string` | Storage key |
| `value` | `string` | Value to store |

**Response data:** `{ "success": true }`

#### `storage.get`
Retrieves a value by key.

**Payload:**
| Field | Type | Description |
|-------|------|-------------|
| `key` | `string` | Storage key |

**Response data:** `{ "success": true, "value": string | null }`

#### `storage.remove`
Removes a key from storage.

**Payload:**
| Field | Type | Description |
|-------|------|-------------|
| `key` | `string` | Storage key |

**Response data:** `{ "success": true }`

### Haptics

#### `haptic.impact`
Triggers device haptic feedback.

**Payload:**
| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `style` | `string` | `mediumImpact` | One of: `selectionClick`, `lightImpact`, `mediumImpact`, `heavyImpact`, `notificationSuccess`, `notificationWarning`, `notificationError`, `light` (legacy), `medium` (legacy), `heavy` (legacy) |

**Response data:** `{ "success": true }`

### Share

#### `share.open`
Opens the native share dialog.

**Payload:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | `string` | Yes | URL to share |
| `title` | `string` | No | Optional title prepended to URL |

**Response data:** `{ "success": true }`

### Analytics (Stub)

#### `analytics.click` / `analytics.impression`
Stub implementations for future analytics integration.

**Payload:**
| Field | Type | Description |
|-------|------|-------------|
| `params` | `object` | Analytics parameters |

### Game Center (Stub)

#### `gameCenter.openLeaderboard`
Opens Game Center leaderboard (not yet implemented).

#### `gameCenter.submitScore`
Submits a score to Game Center (not yet implemented).

**Payload:**
| Field | Type | Description |
|-------|------|-------------|
| `score` | `string` | Score value |

## App Environment

Injected at page load via `window.__APP_ENV__`:

```json
{
  "platform": "flutter",
  "os": "ios" | "android",
  "version": "1.0.10+11",
  "safeArea": { "top": 47, "bottom": 34, "left": 0, "right": 0 }
}
```

## Game Lifecycle

- `window.__GAME_PAUSE__()` — called before showing ads or on app background
- `window.__GAME_RESUME__()` — called after ads close or on app foreground
- Fallback: `window.__PIXI_APP__.ticker.stop()` / `.start()`
