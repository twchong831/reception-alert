# 방문객 안내 & AS 접수 알림 시스템

> Flutter + Dart 서버 기반 / 시놀로지 NAS Docker 구동 / Android 태블릿 전용

---

## 1. 개요

사무실 1층 접수 태블릿에서 방문 팀을 선택하면, 해당 팀의 태블릿에 **소리와 함께 전체화면 알람**이 표시되는 실시간 방문객 안내 시스템. AS 접수 기능 포함.

### 사용 환경

| 항목 | 내용 |
|------|------|
| 네트워크 | 사무실 내부 LAN (WiFi 전용) |
| 서버 | 시놀로지 NAS — Docker (Container Manager) |
| 클라이언트 | Android 태블릿 (단일 APK) |
| 통신 | WebSocket (ws://) — LAN 전용, SSL 불필요 |

---

## 2. 기술 스택

### 서버 — Dart

| 패키지 | 용도 |
|--------|------|
| `shelf` | HTTP 서버 |
| `shelf_router` | REST 라우팅 |
| `shelf_web_socket` | WebSocket 처리 |
| `uuid` | 팀 등록 코드 생성 |

- 데이터 영속성: **JSON 파일** (Docker volume 마운트)
- 재시작 후 데이터 유지

### 앱 — Flutter (Android)

| 패키지 | 용도 |
|--------|------|
| `riverpod` | 상태 관리 |
| `web_socket_channel` | WebSocket 클라이언트 |
| `audioplayers` | 알람 소리 재생 |
| `shared_preferences` | 역할·서버 IP 로컬 저장 |
| `dio` | REST API 호출 |

---

## 3. 시스템 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                   사무실 내부 LAN                     │
│                                                     │
│  ┌──────────────┐   POST /api/visit   ┌───────────┐ │
│  │  접수 태블릿  │ ─────────────────► │           │ │
│  │ (1층 로비)   │                    │ Dart 서버  │ │
│  └──────────────┘                    │           │ │
│                                      │ :8080     │ │
│  ┌──────────────┐   WebSocket push   │           │ │
│  │  팀 태블릿   │ ◄─────────────────  │ (Docker)  │ │
│  │ (각 팀 자리) │                    │           │ │
│  └──────────────┘                    │ 시놀로지   │ │
│                                      │ NAS       │ │
│  ┌──────────────┐   WebSocket        │           │ │
│  │ 관리자 태블릿 │ ◄─────────────────► └───────────┘ │
│  └──────────────┘                                   │
└─────────────────────────────────────────────────────┘
```

### NAS 설정

```
Container Manager
└── docker-compose.yml
    ├── image: dart:stable
    ├── port: 8080:8080
    └── volume: /volume1/visitor-app/data → /app/data  (JSON 영속성)
```

- NAS IP는 공유기 DHCP에서 **고정 할당** 권장
- 태블릿 앱에서 서버 IP 최초 1회 입력 후 저장

---

## 4. 앱 — 역할 구조

태블릿마다 최초 실행 시 역할을 선택하며, 이후 재시작 시 자동 접속.

```
최초 실행
└── 역할 선택 화면
    ├── 접수 태블릿   → 서버 IP 입력 → 고정
    ├── 팀 태블릿     → 서버 IP + 등록코드 입력 → 팀 인증
    └── 관리자 태블릿 → 서버 IP + 관리자 비밀번호 입력
```

설정값은 `SharedPreferences`에 저장.

---

## 5. 팀 등록 플로우

```
관리자 앱
└── 팀 생성 (팀명 입력)
     └── 서버가 6자리 등록코드 발급 (예: KM-4829)
          └── 관리자가 해당 팀에 코드 전달

팀 태블릿 (최초 실행)
└── "팀 알림 태블릿" 선택
     └── 서버 IP + 등록코드 입력
          └── 서버 인증 성공
               └── 팀 ID·팀명 저장 → 팀 화면 진입
                    └── 이후 재실행 시 자동 접속
```

---

## 6. 화면 구성

### 6-1. 접수 태블릿 (`reception_screen.dart`)

- 팀 버튼 그리드 (탭 → 방문자 정보 입력 모달)
- 방문자 정보: 성함, 소속 회사, 방문 목적
- **AS 접수 버튼** (별도 모달)
- AS 접수 정보: 회사명, 연락처, 제품명, 증상, 우선순위

### 6-2. 팀 알림 태블릿 (`team_screen.dart`)

- 대기 중 방문객 카드 목록
- **새 알림 수신 시:**
  - 전체화면 알람 오버레이
  - `audioplayers`로 알람음 재생 (확인 전까지 반복)
  - 방문자명, 소속, 방문 목적 표시
- 확인 / 처리 완료 버튼

> AS팀 태블릿: 등록코드로 `as` 팀으로 인증하면 AS 접수 탭 추가 표시

### 6-3. 관리자 태블릿 (`admin_screen.dart`)

| 탭 | 기능 |
|----|------|
| 팀 관리 | 팀 추가, 등록코드 발급·확인, 팀 삭제 |
| 방문 기록 | 전체 방문 로그 (상태 필터) |
| AS 현황 | 전체 AS 접수 목록, 상태 업데이트 |

---

## 7. 실시간 통신 흐름

### 방문 알림

```
접수 태블릿
└── 팀 선택 + 방문자 정보 입력
     └── POST /api/visit
          └── 서버: 해당 팀 WebSocket 으로 push
               └── 팀 태블릿: alarm_overlay 표시 + 알람음
                    └── 확인 버튼 → PATCH /api/visit/:id (status: confirmed)
                         └── 처리 완료 → PATCH /api/visit/:id (status: done)
```

### AS 접수

```
접수 태블릿
└── AS 접수 폼 작성
     └── POST /api/as
          └── 서버: 'as' 팀 WebSocket 으로 push
               └── AS팀 태블릿: 알람 + AS 내용 표시
                    └── 상태 업데이트 (접수→처리중→완료)
```

---

## 8. 프로젝트 디렉터리 구조

```
visitor-app/
├── server/                        # Dart 서버
│   ├── bin/
│   │   └── server.dart            # 진입점
│   ├── lib/
│   │   ├── handlers/
│   │   │   ├── auth_handler.dart  # 팀 등록·코드 인증
│   │   │   ├── visit_handler.dart # 방문 알림 API
│   │   │   └── as_handler.dart    # AS 접수 API
│   │   ├── models/
│   │   │   ├── team.dart
│   │   │   ├── visit.dart
│   │   │   └── as_ticket.dart
│   │   ├── services/
│   │   │   └── ws_manager.dart    # WebSocket 연결 관리
│   │   └── store.dart             # 메모리 + JSON 파일 영속성
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── pubspec.yaml
│
└── app/                           # Flutter 앱
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── ws_service.dart        # WebSocket 싱글톤
        │   ├── api_service.dart       # REST 호출 (dio)
        │   └── storage.dart           # SharedPreferences
        ├── models/
        │   ├── team.dart
        │   ├── visit.dart
        │   └── as_ticket.dart
        ├── screens/
        │   ├── role_setup/
        │   │   ├── role_select_screen.dart
        │   │   ├── reception_setup_screen.dart
        │   │   ├── team_register_screen.dart  # 코드 입력
        │   │   └── admin_setup_screen.dart
        │   ├── reception_screen.dart
        │   ├── team_screen.dart
        │   └── admin/
        │       ├── admin_screen.dart
        │       ├── team_manage_tab.dart
        │       ├── visit_log_tab.dart
        │       └── as_log_tab.dart
        └── widgets/
            ├── alarm_overlay.dart     # 전체화면 알람
            ├── visit_card.dart
            └── as_card.dart
```

---

## 9. REST API 목록

| Method | Path | 설명 |
|--------|------|------|
| `GET` | `/api/teams` | 팀 목록 조회 |
| `POST` | `/api/teams` | 팀 생성 + 등록코드 발급 |
| `DELETE` | `/api/teams/:id` | 팀 삭제 |
| `POST` | `/api/auth/team` | 등록코드로 팀 인증 |
| `POST` | `/api/auth/admin` | 관리자 인증 |
| `POST` | `/api/visit` | 방문 알림 전송 |
| `PATCH` | `/api/visit/:id` | 방문 상태 업데이트 |
| `GET` | `/api/visit` | 방문 기록 조회 |
| `POST` | `/api/as` | AS 접수 |
| `PATCH` | `/api/as/:id` | AS 상태 업데이트 |
| `GET` | `/api/as` | AS 목록 조회 |

---

## 10. 개발 순서

```
1단계  Dart 서버
       └── 모델 정의 → store.dart → ws_manager → REST 핸들러 → 서버 진입점

2단계  Docker 설정
       └── Dockerfile → docker-compose.yml → NAS 배포 테스트

3단계  Flutter 앱
       └── 모델 정의 → core 서비스 → 역할 설정 화면
            → 접수 화면 → 팀 알림 화면 → 관리자 화면

4단계  통합 테스트
       └── LAN 환경 실기기 테스트 → 알람 소리 확인 → 데이터 영속성 확인
```

---

*최종 확정: 2026-04-10*
