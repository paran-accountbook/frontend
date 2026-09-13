# 소비로그 Flutter 앱

소비로그의 iOS·Android 클라이언트입니다.

## 사전 준비

- Flutter 3.44.0 이상
- Dart 3.12.0 이상
- iOS 실행 시 Xcode와 CocoaPods
- Android 실행 시 Android Studio와 Android SDK

설치 상태는 다음 명령으로 확인합니다.

```bash
flutter doctor
```

## 로컬 실행

### 1. 저장소 준비

```bash
git clone https://github.com/paran-accountbook/frontend.git
cd frontend
```

### 2. 환경 변수 설정

`.env.example`을 복사해 Git에 포함되지 않는 로컬 설정 파일을 만듭니다. `.env`는 Flutter 의존성을 받거나 앱을 빌드하기 전에 준비해야 합니다.

```bash
cp .env.example .env
```

`.env`에서 실행 환경에 맞는 값을 설정합니다.

```dotenv
APP_ENV=development
API_BASE_URL=https://api.sobilog.kr/
TERMS_DOCUMENT_URL=
ENABLE_DEBUG_LOG=true
```

`API_BASE_URL` 끝의 `/` 유무는 모두 지원합니다. `.env`에는 비밀값을 넣을 수 있으므로 커밋하지 않습니다.

### 3. 의존성 설치

```bash
flutter pub get
```

### 4. 실행 기기 확인

```bash
flutter devices
```

iOS 시뮬레이터가 보이지 않으면 macOS에서 다음 명령으로 실행합니다.

```bash
open -a Simulator
```

Android는 Android Studio의 Device Manager에서 에뮬레이터를 먼저 실행합니다.

### 5. 앱 실행

연결된 기기가 하나라면 다음 명령으로 실행합니다.

```bash
flutter run
```

기기가 여러 개라면 `flutter devices`에 표시된 ID를 지정합니다.

```bash
flutter run -d <device-id>
```

## 검사 및 테스트

```bash
flutter analyze
flutter test
```

iOS 시뮬레이터용 빌드만 확인하려면 다음 명령을 사용합니다.

```bash
flutter build ios --simulator --no-codesign
```

## 자주 발생하는 문제

### 환경 변수 변경이 반영되지 않음

Hot Reload만 하지 말고 앱을 완전히 종료한 뒤 `flutter run`을 다시 실행합니다. 필요하면 빌드 캐시를 정리합니다.

```bash
flutter clean
flutter pub get
flutter run
```

### iOS 의존성 오류

```bash
cd ios
pod install
cd ..
flutter run
```

### API 연결 실패

- `.env`의 `API_BASE_URL`이 실제 접근 가능한 주소인지 확인합니다.
- `https://<주소>/health`가 `200`을 반환하는지 확인합니다.
- iOS·Android 기기의 네트워크 연결 상태를 확인합니다.
