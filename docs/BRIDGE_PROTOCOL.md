# Flutter Bridge Protocol

웹 게임(WebView)과 Flutter 네이티브 간 통신 프로토콜.

## 아키텍처

```
Web (JS)  ──→  FlutterBridge.postMessage(json)  ──→  Flutter (Dart)
Web (JS)  ←──  CustomEvent 'flutterBridgeResult'  ←──  Flutter (Dart)
```

- **요청**: 웹에서 `window.FlutterBridge.postMessage(JSON.stringify(request))` 호출
- **응답**: Flutter에서 `window.dispatchEvent(new CustomEvent('flutterBridgeResult', { detail }))` 발송

## 요청 포맷

```typescript
interface BridgeRequest {
  id: string;        // 고유 요청 ID (응답 매칭용)
  type: string;      // 커맨드 타입
  payload: object;   // 커맨드별 페이로드
}
```

## 응답 포맷

```typescript
interface BridgeResponse {
  id: string;        // 요청 ID (매칭)
  type: string;      // 커맨드 타입
  success: boolean;
  data?: object;     // 성공 시 데이터
  error?: string;    // 실패 시 에러 메시지
  timestamp: number; // 응답 시각 (ms)
}
```

## 웹에서 호출하는 법

```typescript
function callFlutterBridge(type: string, payload: object): Promise<any> {
  const id = crypto.randomUUID();

  return new Promise((resolve, reject) => {
    const handler = (e: CustomEvent) => {
      if (e.detail.id !== id) return;
      window.removeEventListener('flutterBridgeResult', handler);
      if (e.detail.success) resolve(e.detail.data);
      else reject(new Error(e.detail.error));
    };
    window.addEventListener('flutterBridgeResult', handler);

    window.FlutterBridge.postMessage(JSON.stringify({ id, type, payload }));
  });
}
```

---

## 커맨드 레퍼런스

### 광고

#### `ad.request` — 보상형 광고 표시

게임을 자동 pause → 광고 표시 → 종료 후 resume.

| 필드 | 타입 | 설명 |
|------|------|------|
| `adType` | `string` | `artifact` \| `revival` \| `reroll` \| `bundle` |

**응답 data:**
```json
{ "success": true, "rewarded": true }
```

- `success`: 광고가 정상 표시됐는지
- `rewarded`: 사용자가 보상을 받았는지 (중간에 닫으면 false)

#### `ad.preload` — 광고 미리 로드

| 필드 | 타입 | 설명 |
|------|------|------|
| `adType` | `string` | `artifact` \| `revival` \| `reroll` \| `bundle` |

**응답 data:**
```json
{ "success": true }
```

---

### 스토리지

SharedPreferences 기반. 앱 삭제 시 초기화됨.

#### `storage.set` — 저장

| 필드 | 타입 | 설명 |
|------|------|------|
| `key` | `string` | 저장 키 |
| `value` | `string` | 저장 값 (문자열만) |

**응답 data:**
```json
{ "success": true }
```

#### `storage.get` — 조회

| 필드 | 타입 | 설명 |
|------|------|------|
| `key` | `string` | 조회 키 |

**응답 data:**
```json
{ "success": true, "value": "stored_value" }
```
`value`는 없으면 `null`.

#### `storage.remove` — 삭제

| 필드 | 타입 | 설명 |
|------|------|------|
| `key` | `string` | 삭제할 키 |

**응답 data:**
```json
{ "success": true }
```

---

### 디바이스

#### `safeArea.get` — Safe Area 조회

페이로드 없음.

**응답 data:**
```json
{ "top": 47.0, "bottom": 34.0, "left": 0.0, "right": 0.0 }
```

> 참고: 정확한 값은 앱 시작 시 `window.__APP_ENV__.safeArea`로 자동 주입됨. 이 커맨드는 fallback용.

#### `haptic.impact` — 햅틱 피드백

**응답 data:**
```json
{ "success": true }
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `style` | `string` | 아래 표 참조 (기본값: `mediumImpact`) |

| style | iOS 매핑 | 용도 |
|-------|----------|------|
| `selectionClick` | UISelectionFeedback | UI 선택 |
| `lightImpact` | Light | 가벼운 터치 |
| `mediumImpact` | Medium | 일반 인터랙션 |
| `heavyImpact` | Heavy | 강한 피드백 |
| `notificationSuccess` | Light | 성공 알림 |
| `notificationWarning` | Medium | 경고 |
| `notificationError` | Heavy | 에러 |
| `light` | Light | 레거시 호환 |
| `medium` | Medium | 레거시 호환 |
| `heavy` | Heavy | 레거시 호환 |

#### `share.open` — 공유 다이얼로그

| 필드 | 타입 | 설명 |
|------|------|------|
| `url` | `string` | 공유할 URL |
| `title` | `string?` | 공유 텍스트 제목 (선택) |

**응답 data:**
```json
{ "success": true }
```

---

### 애널리틱스 (더미)

현재 로깅만 수행. 추후 Firebase Analytics 연동 예정.

#### `analytics.click` — 클릭 이벤트

| 필드 | 타입 | 설명 |
|------|------|------|
| `params` | `object?` | 이벤트 파라미터 |

**응답 data:**
```json
{ "success": true }
```

#### `analytics.impression` — 노출 이벤트

| 필드 | 타입 | 설명 |
|------|------|------|
| `params` | `object?` | 이벤트 파라미터 |

**응답 data:**
```json
{ "success": true }
```

---

### Game Center (더미)

현재 미구현. 항상 `success: false` 반환.

#### `gameCenter.openLeaderboard`

페이로드 없음.

**응답 data:**
```json
{ "success": false }
```

#### `gameCenter.submitScore`

| 필드 | 타입 | 설명 |
|------|------|------|
| `score` | `string?` | 제출할 점수 (nullable) |

**응답 data:**
```json
{ "success": false, "submitted": false }
```

---

## 자동 주입 환경변수

앱 시작 시 Flutter가 `window.__APP_ENV__`를 자동 주입:

```typescript
interface AppEnv {
  platform: 'flutter';
  os: 'ios' | 'android';
  version: string;       // "1.0.6+7" 형식
  safeArea: {
    top: number;
    bottom: number;
    left: number;
    right: number;
  };
}
```

## 게임 생명주기

Flutter가 호출하는 글로벌 함수 (웹에서 구현 필요):

| 함수 | 호출 시점 |
|------|-----------|
| `window.__GAME_PAUSE__()` | 앱 백그라운드 / 광고 표시 전 |
| `window.__GAME_RESUME__()` | 앱 포그라운드 / 광고 종료 후 |

Fallback: 위 함수 없으면 `window.__PIXI_APP__.ticker.stop()/start()` 시도.

---

## 디버그

### 디버그 URL 설정

```bash
# 에뮬레이터 (기본)
flutter run --dart-define=DEBUG_URL=http://10.0.2.2:5173/

# 실기기 (adb reverse 필요)
adb reverse tcp:5173 tcp:5173
flutter run
# 기본값 http://localhost:5173/ 사용
```

### 로그 확인

모든 브릿지 메시지는 `[Bridge]` 접두사로 로깅:
```
flutter logs | grep Bridge
```
