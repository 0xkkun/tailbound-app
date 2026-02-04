# Android 배포 가이드

## 1. Keystore 설정

### 기존 Keystore가 있는 경우

프로젝트에 기존 keystore 파일을 복사합니다:

```bash
# keystore 파일을 android 폴더에 복사
cp /path/to/your/keystore.jks android/app/keystore.jks
```

### 새로운 Keystore 생성 (기존 것이 없는 경우)

⚠️ **주의**: 이미 Play Store에 앱을 올린 경우, 기존 keystore를 반드시 사용해야 합니다!

```bash
cd android/app
keytool -genkey -v -keystore keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias tailbound
```

입력 항목:
- Store password: (안전하게 보관!)
- Key password: (안전하게 보관!)
- CN (이름): Wontae Hwang
- OU (조직 단위): 0xkkun
- O (조직): 0xkkun
- L (도시): Seoul
- ST (시/도): Seoul
- C (국가 코드): KR

## 2. key.properties 설정

`android/key.properties` 파일을 생성합니다:

```properties
storeFile=app/keystore.jks
storePassword=your-store-password
keyAlias=tailbound
keyPassword=your-key-password
```

**보안 주의사항**:
- ✅ `key.properties`는 `.gitignore`에 추가되어 있음
- ✅ `*.keystore`, `*.jks`도 `.gitignore`에 추가되어 있음
- ❌ 절대 Git에 커밋하지 말 것!

## 3. 릴리스 빌드

### AAB (Android App Bundle) 생성 - Google Play 업로드용

```bash
flutter build appbundle --release
```

생성 위치: `build/app/outputs/bundle/release/app-release.aab`

### APK 생성 - 테스트/직접 설치용

```bash
flutter build apk --release
```

생성 위치: `build/app/outputs/flutter-apk/app-release.apk`

## 4. Google Play Console 배포

### 내부 테스트

1. Play Console → 앱 선택 → 테스트 → 내부 테스트
2. 새 버전 만들기
3. `app-release.aab` 업로드
4. 버전 이름/코드 확인 (`pubspec.yaml`의 `version`)
5. 검토 후 게시

### 프로덕션 (공개)

1. Play Console → 프로덕션
2. 새 버전 만들기
3. AAB 업로드
4. 출시 노트 작성
5. 검토 후 게시

## 5. 버전 관리

`pubspec.yaml`에서 버전 업데이트:

```yaml
version: 1.0.2+3  # 1.0.2 = versionName, 3 = versionCode
```

- `versionName`: 사용자에게 보이는 버전 (1.0.0 → 1.0.1 → 1.1.0)
- `versionCode`: 내부 버전 번호 (1 → 2 → 3, 항상 증가)

## 6. 앱 서명 키 관리

### 백업

🔴 **중요**: Keystore와 비밀번호를 안전하게 백업하세요!

```bash
# Keystore 백업
cp android/app/keystore.jks ~/Backups/tailbound-keystore-backup.jks

# 비밀번호를 별도로 안전하게 보관 (1Password, Bitwarden 등)
```

### 분실 시

- ❌ **기존 앱 업데이트 불가** - 새로운 앱으로 재출시해야 함
- ❌ **사용자 데이터 이전 불가**
- ❌ **앱 이름 변경 필요** (동일한 package name 사용 불가)

## 7. 트러블슈팅

### 서명 오류

```
Execution failed for task ':app:signReleaseBundle'.
```

→ `key.properties` 파일 확인 및 비밀번호 검증

### 빌드 캐시 정리

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build appbundle --release
```

### 버전 충돌

```
Upload failed: Version code X has already been used.
```

→ `pubspec.yaml`에서 `versionCode` 증가 (`+` 뒤의 숫자)

## 8. CI/CD 자동화 (향후)

GitHub Actions로 자동 빌드/배포 설정 가능:

- Secrets에 keystore Base64 인코딩 저장
- `key.properties` 자동 생성
- Play Store 자동 업로드 (Fastlane)

## 참고 자료

- [Flutter Android 배포 공식 문서](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Play Console 도움말](https://support.google.com/googleplay/android-developer)
