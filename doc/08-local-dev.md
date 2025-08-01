# 로컬 개발 환경

## 디렉토리 구성

```
~/Projects/example/backend/
├── repo/                    # Spring Boot 소스코드
├── .env                     # 환경 변수
├── docker-compose.yml       # Docker 구성
└── Dockerfile.local         # 개발용 Dockerfile
```

## 외부 데이터베이스 MariaDB 또는 PostgreSQL 준비

- Keycloak 데이터베이스  (PostgreSQL)
- 백엔드 데이터베이스 (PostgreSQL 또는 MariaDB)

## `.env` 추가

```properties
PREFIX=example

# Keycloak PostgreSQL 설정
KEYCLOAK_POSTGRES_HOST=192.168.0.11
KEYCLOAK_POSTGRES_PORT=15432
KEYCLOAK_POSTGRES_DATABASE=keycloak
KEYCLOAK_POSTGRES_USER=keycloak
KEYCLOAK_POSTGRES_PASSWORD=secret_password_1234
```

## `docker-compose.yml` 추가

| 구분       | 도커     | 외부 노출 | 도커 내부 |
| ---------- | -------- | --------- | --------- |
| 인프라     | redis    | -         | 6379      |
| 인프라     | keycloak | 8081      | 8080      |
| 백엔드     | backend  | 8080      | 8080      |
| 프론트엔드 | frontend | 3000      | 3000      |

# Keycloak 초기 설정

## 임시 계정 `temp-admin` 생성

```shell
# 도커 컨테이너 시작
docker compose up -d keycloak

# temp-admin 생성
docker exec -it example-keycloak /opt/keycloak/bin/kc.sh bootstrap-admin user
Enter username [temp-admin]:temp-admin
Enter password: [비밀번호]
Enter password again: [비밀번호]

# 도커 컨테이너 재시작
docker compose restart keycloak
```

## Keycloak 영구 `admin` 계정 생성

1. **http://localhost:8081** 접속 후 `temp-admin`으로 로그인
2. 좌측 상단의 **Master** realm이 선택되어 있는지 확인
3. 좌측 메뉴에서 **Users** 클릭
4. **Create new user** 버튼 클릭

- Email verified: On (체크)
- Username: `admin`
- Email: `admin@example.com`
- First name: John
- Last name: Doe

5. Credentials 탭 비밀번호 저장

- Password: 비밀번호
- Password confirmation: 비밀번호 확인
- Temporary: Off (체크 안 함)

6. Role mapping 탭 관리자 역할 부여

`Realm roles` 선택 후 `Assign role`에서 `admin` 체크 후 `Assgin`

## `admin` 계정 로그인 후 `temp-admin` 계정 삭제

1. 로그아웃 (우측 상단 사용자명 클릭 → Sign out)
2. 새로 만든 계정으로 로그인:
   ```
   Username: admin
   Password: Test12#$
   ```
3. Keycloak 임시 계정 `temp-admin` 삭제

## example realm 생성

- Realm 생성: Realms → Create Realm → (Realm name: `example`)

## example realm 이메일 설정

템플릿

- From: help@example.com
- From display name: 고객센터
- Reply to: no-reply@example.com
- Reply to display name: 발신전용
- Envelope from: no-reply@example.com

연결 및 인증

- Host: smtp.mailgun.org (또는 smtp.gmail.com)
- Port: 587
- Encryption: Enable SSL (체크 안 함), Enable StartTLS (체크)
- Authentication: Enabled (체크)
- Username: postmaster@mg.example.com (또는 gmail 주소)
- Authentication Type: Password
- Password: Mailgun 발급 비밀번호 (또는 gmail 앱 비밀번호 16자리)

올바른 정보 입력 시 Test connection 누르면 관리자 이메일 주소로 테스트 이메일이 발송

참고: Mailgun 사용 시 오른쪽 상단 Account Settings > IP Access Management 메뉴에서 반드시 이메일 발송 IP 허용을 해야 인증 오류가 발생하지 않는다.

## master realm, example realm 이벤트 로깅 저장 설정

**각 realm별로 동일하게 설정**

- Event Listeners: jboss-logging + email
- User Events: Save events 체크, Expiration 90 days, 모든 이벤트 유지
- Admin Events: Save events 체크, Expiration 90 days, Include representation(관리자가 변경한 데이터의 상세 내용까지 함께 저장) 체크 안 함, 모든 이벤트
  유지

## example realm에서 example-backend client 생성

- Client 생성: Clients → Create Client →
    1. General Settings:
        - **Client type: OpenID Connect**
        - **Client ID: example-backend**
        - Name: (없음)
        - Description: (없음)
        - Always display in UI: OFF
    2. Capability Config:
        - **Client authentication: ON** (중요!)
        - Authorization: OFF
        - **Standard flow: ON**
        - **Direct access grants: ON**
        - Implicit flow: OFF
        - **Service accounts roles: ON**
        - OAuth 2.0 Device Authorization Grant: OFF
        - OIDC CIBA Grant: OFF
    3. Login Settings
        - Root URL: (없음)
        - Home URL: (없음)
        - Valid redirect URIs: http://localhost:8080/*
        - Valid post logout redirect URIs: (없음)
        - Web origins: (없음)

- `example-backend` 클라이언트 상세 보기 `Service accounts roles` 탭 선택
    - Assign role 버튼 누르고 Client roles 선택 후 역할 추가
        - `realm-management`: `manage-users`
        - `realm-management`: `view-users`
        - `realm-management`: `query-users`

- `example-backend` 클라이언트 설정 완료 후 `Credentials` 탭에서 Client Secret 복사

## `application-local.yml` 파일 생성 및 수정

```
<     url: jdbc:postgresql://postgresql:5432/database
<     username: username
<     password: password
<             client-secret: your-client-secret
<   client-secret: your-client-secret
```

# FAQ

## `docker compose` 기본 명령어

- `docker compose up`: 컨테이너 생성 + 시작 (`-d` 옵션: detached mode로 백그라운드 실행)
- `docker compose start`: 컨테이너 시작 (생성 x)
- `docker compose stop`: 컨테이너 중지 (삭제 x)
- `docker compose down`: 컨테이너 중지 + 삭제 (네트워크 삭제, 볼륨 유지-디폴트)

## **`--no-cache`가 필요한 경우**

1. **의존성 변경**: `build.gradle` 수정 후
2. **베이스 이미지 업데이트**: 최신 보안 패치 적용
3. **빌드 캐시 문제**: 이상한 빌드 오류가 발생할 때
4. **외부 리소스 변경**: 외부에서 다운로드하는 파일이 업데이트된 경우

## **`./gradlew clean build -x test`가 필요한 경우**

1. **빈 이름 충돌 또는 엔티티 변경**: Spring Bean, JPA Entity 구조 변경 시
2. **어노테이션 프로세싱**: QueryDSL, MapStruct 등 코드 생성 라이브러리 사용 시
3. **프로파일 변경**: application.yml의 프로파일 구성이 크게 변경된 경우

## **실무 권장사항**

```bash
# 문제 발생 시 단계적 해결
## 1단계: 일반적인 재빌드
docker compose build && docker compose up -d

## 2단계: 로컬 클린 빌드 (QueryDSL, Bean 충돌 등)
cd repo/ && ./gradlew clean build -x test && cd ..
docker compose up -d

## 3단계: 캐시 무시 빌드 (의존성 변경, 베이스 이미지 등)
docker compose build --no-cache && docker compose up -d
```