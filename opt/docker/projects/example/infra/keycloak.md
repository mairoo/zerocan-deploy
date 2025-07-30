# Keycloak 초기 설정 가이드

## 개요

- Keycloak: 인증 서버
- 백엔드: 권한 관리 (Group, Role 매핑)
- 환경별 Realm 분리로 개발/스테이징/운영 독립성 확보

## 초기 설정 순서

1. 임시 계정 `temp-admin` 생성
2. Keycloak 영구 계정 `admin` 생성
3. `admin` 계정 로그인 후 `temp-admin` 계정 삭제
4. `example-local-{username}`, `example-staging`, `example-prod` 등 realm 생성 및 각각 `example-api-client` 생성
5. `master`, `example-staging`, `example-prod` realm 이벤트 로깅, 이메일 서버 연동 설정

### Realm 구조
```
example-local-{username}/
├── example-api-client
└── users, roles, etc.

example-staging/
├── example-api-client
└── users, roles, etc.

example-prod/
├── example-api-client
└── users, roles, etc.
```

---

## 1. 임시 계정 `temp-admin` 생성

```shell
# 도커 컨테이너 시작
docker compose up -d keycloak-postgres keycloak

# temp-admin 생성
docker compose exec keycloak /opt/keycloak/bin/kc.sh bootstrap-admin user
Enter username [temp-admin]:temp-admin
Enter password: [비밀번호]
Enter password again: [비밀번호]

# 도커 컨테이너 재시작
docker compose restart keycloak
```

---

## 2. Keycloak 영구 `admin` 계정 생성

1. **http://localhost:8081** 또는 **http://keycloak.example.com** 접속 후 `temp-admin`으로 로그인
2. 좌측 상단의 **Master** realm이 선택되어 있는지 확인
3. 좌측 메뉴에서 **Users** 클릭
4. **Create new user** 버튼 클릭

### 사용자 정보 입력
- Email verified: On (체크)
- Username: `admin`
- Email: `admin@example.com`
- First name: John
- Last name: Doe

### 비밀번호 설정
**Credentials** 탭으로 이동:
- Password: 비밀번호
- Password confirmation: 비밀번호 확인
- Temporary: Off (체크 안 함)
- **Set password** 클릭

### 관리자 권한 부여
**Role mapping** 탭으로 이동:
1. `Realm roles` 선택
2. **Assign role** 클릭
3. `admin` 체크 후 **Assign** 클릭

---

## 3. `admin` 계정 로그인 후 `temp-admin` 계정 삭제

### admin 계정으로 로그인
1. 로그아웃 (우측 상단 사용자명 클릭 → **Sign out**)
2. 새로 만든 계정으로 로그인:
   ```
   Username: admin
   Password: [설정한 비밀번호]
   ```

### temp-admin 계정 삭제
1. **Users** 메뉴 클릭
2. `temp-admin` 사용자 검색
3. **Delete** 버튼으로 계정 삭제

---

## 4. Realm 및 Client 생성

### 4-1. 개발용 Realm 생성 (example-local-{username})

1. 좌측 상단 **Master** 클릭 → **Create Realm**
2. **Realm name**: `example-local-johndoe` (본인 이름으로 변경)
3. **Create** 클릭

### 4-2. 스테이징 Realm 생성 (example-staging)

1. **Create Realm** 클릭
2. **Realm name**: `example-staging`
3. **Create** 클릭

### 4-3. 운영 Realm 생성 (example-prod)

1. **Create Realm** 클릭
2. **Realm name**: `example-prod`
3. **Create** 클릭

### 4-4. 각 Realm에 example-api-client 생성

**각 Realm(`example-local-johndoe`, `example-staging`, `example-prod`)마다 아래 과정을 반복:**

1. 해당 Realm 선택
2. **Clients** → **Create Client** 클릭

#### General Settings
- **Client type**: OpenID Connect
- **Client ID**: `example-api-client`
- Name: (비워둠)
- Description: (비워둠)
- Always display in UI: OFF

#### Capability Config
- **Client authentication**: ON (중요!)
- Authorization: OFF
- **Standard flow**: ON
- **Direct access grants**: ON
- Implicit flow: OFF
- **Service accounts roles**: ON
- OAuth 2.0 Device Authorization Grant: OFF
- OIDC CIBA Grant: OFF

#### Login Settings (환경별로 다르게 설정)

**example-local-{username} realm:**
```
Valid redirect URIs: 
- http://localhost:8080/* (백엔드 스프링부트)
- http://localhost:3000/* (프론트엔드 Next.js)

Web origins:
- http://localhost:8080
- http://localhost:3000
```

**example-staging realm:**
```
Valid redirect URIs: 
- https://staging.example.com/*
- https://staging-api.example.com/auth/callback

Web origins:
- https://staging.example.com
```

**example-prod realm:**
```
Valid redirect URIs: 
- https://example.com/*
- https://api.example.com/auth/callback

Web origins:
- https://example.com
```

### 4-5. Service Account 역할 설정

각 `example-api-client`에 대해:

1. **Service accounts roles** 탭 선택
2. **Assign role** 버튼 클릭
3. **Client roles** 선택
4. `realm-management` 선택 후 다음 역할 추가:
   - `manage-users`
   - `view-users`
   - `query-users`

### 4-6. Client Secret 복사

각 `example-api-client`의 **Credentials** 탭에서 **Client Secret** 복사 및 저장

---

## 5. 이벤트 로깅 및 이메일 서버 연동 설정

### 5-1. 이메일 서버 설정

**각 Realm(`master`, `example-staging`, `example-prod`)별로 설정:**

1. **Realm settings** → **Email** 탭

#### 템플릿 설정
- From: `help@example.com`
- From display name: `고객센터`
- Reply to: `no-reply@example.com`
- Reply to display name: `발신전용`
- Envelope from: `no-reply@example.com`

#### 연결 및 인증 설정
- Host: `smtp.mailgun.org` (또는 `smtp.gmail.com`)
- Port: `587`
- Encryption: Enable SSL (체크 안 함), Enable StartTLS (체크)
- Authentication: Enabled (체크)
- Username: `postmaster@mg.example.com` (또는 Gmail 주소)
- Authentication Type: Password
- Password: Mailgun 발급 비밀번호 (또는 Gmail 앱 비밀번호 16자리)

2. **Test connection** 클릭하여 테스트 이메일 발송 확인

> **참고**: Mailgun 사용 시 Account Settings > IP Access Management에서 이메일 발송 IP 허용 필요

### 5-2. 이벤트 로깅 설정

**각 Realm(`master`, `example-staging`, `example-prod`)별로 동일하게 설정:**

1. **Realm settings** → **Events** 탭

#### Event Config
- Event Listeners: `jboss-logging` + `email` 선택

#### User Events Settings
- Save events: 체크
- Expiration: `90` days
- 모든 이벤트 타입 선택 유지

#### Admin Events Settings
- Save events: 체크
- Expiration: `90` days
- Include representation: 체크 안 함 (성능상 이유)
- 모든 이벤트 타입 선택 유지

---

## 스프링부트 연동 설정

### docker-compose.yml 업데이트

```yaml
backend-1:
  # ... 기존 설정
  depends_on:
    - redis
    - mariadb
    - keycloak  # 추가
  environment:
    # ... 기존 환경변수
    - KEYCLOAK_AUTH_SERVER_URL=http://keycloak:8080  # 추가
```

### application.yml 설정 예시

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${KEYCLOAK_AUTH_SERVER_URL}/realms/${KEYCLOAK_REALM}
      client:
        registration:
          keycloak:
            client-id: ${KEYCLOAK_CLIENT_ID}
            client-secret: ${KEYCLOAK_CLIENT_SECRET}
            scope: openid,profile,email
            authorization-grant-type: authorization_code
        provider:
          keycloak:
            issuer-uri: ${KEYCLOAK_AUTH_SERVER_URL}/realms/${KEYCLOAK_REALM}

keycloak:
  realm: ${KEYCLOAK_REALM}
  client-id: ${KEYCLOAK_CLIENT_ID}
  client-secret: ${KEYCLOAK_CLIENT_SECRET}
  server-url: ${KEYCLOAK_AUTH_SERVER_URL}
```

### 환경별 설정

**개발환경 (.env.local):**
```bash
KEYCLOAK_REALM=example-local-johndoe
KEYCLOAK_CLIENT_ID=example-api-client
KEYCLOAK_CLIENT_SECRET=[로컬용 클라이언트 시크릿]
KEYCLOAK_AUTH_SERVER_URL=http://localhost:8082
```

**스테이징 (.env.staging):**
```bash
KEYCLOAK_REALM=example-staging
KEYCLOAK_CLIENT_ID=example-api-client
KEYCLOAK_CLIENT_SECRET=[스테이징용 클라이언트 시크릿]
KEYCLOAK_AUTH_SERVER_URL=https://keycloak.example.com
```

**운영 (.env.prod):**
```bash
KEYCLOAK_REALM=example-prod
KEYCLOAK_CLIENT_ID=example-api-client
KEYCLOAK_CLIENT_SECRET=[운영용 클라이언트 시크릿]
KEYCLOAK_AUTH_SERVER_URL=https://keycloak.example.com
```

---

## 완전 초기화 방법

### Keycloak 데이터 완전 삭제

```bash
# 컨테이너 중지 및 삭제
docker compose down keycloak keycloak-postgres

# 볼륨 삭제 (데이터 완전 삭제)
docker volume rm ${PREFIX}-keycloak-postgres-data
docker volume rm ${PREFIX}-keycloak-data
```

---

## 유용한 관리 명령어

```shell
# 도커 실행 상태 확인
docker compose ps

# Keycloak 로그 확인
docker compose logs -f keycloak

# PostgreSQL 직접 접근
docker compose exec keycloak-postgres psql -U ${KEYCLOAK_POSTGRES_USER} -d ${KEYCLOAK_POSTGRES_DATABASE}

# PostgreSQL root 계정 접근
docker compose exec keycloak-postgres psql -U postgres
```