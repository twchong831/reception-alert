# 방문 알림 & AS 접수 앱

## APK 빌드 & 설치

```bash
# 빌드
cd /mnt/d/src_workspace/github/reception-alert/app
flutter build apk --release

# APK 파일 위치
# app/build/app/outputs/flutter-apk/app-release.apk

# 태블릿 USB 연결 후 설치 (기존 앱 유지하며 업데이트)
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 웹 디버그

```bash
flutter run -d chrome
```

## 역할

| 역할 | 설명 |
|------|------|
| 접수 태블릿 | 1층 로비 방문객/AS 접수 |
| 팀 알림 태블릿 | 방문 알림 수신 |
| AS 접수 태블릿 | AS 접수 알림 수신 및 처리 |
| 대표이사 태블릿 | 커피/음료 요청 및 호출 |
| 관리자 태블릿 | 팀 관리 및 기록 조회 |

## 서버 포트

- 서버: `8803`
