# 도커 기반 프로젝트 배포 예제

## 운영 환경 포트 매핑

### 호스트 nginx

| 서비스 | 도메인               | 포트 | 프록시 대상      |
| ------ | -------------------- | ---- | ---------------- |
| nginx  | api.example.com      | 443  | → localhost:8800 |
| nginx  | www.example.com      | 443  | → localhost:8300 |
| nginx  | keycloak.example.com | 443  | → localhost:8801 |
| nginx  | grafana.example.com  | 443  | → localhost:9300 |

### 도커 컨테이너

| 서비스            | 이미지 버전                      | 외부포트 | 내부포트 | 역할           |
| ----------------- | -------------------------------- | -------- | -------- | -------------- |
| redis             | redis:alpine                     | -        | 6379     | 내부전용       |
| keycloak-postgres | postgres:15-alpine               | 15432    | 5432     | 관리용         |
| keycloak          | quay.io/keycloak/keycloak:26.3.1 | 8801     | 8080     | 인증서버       |
| nginx-api         | nginx:alpine                     | 8800     | 8080     | API 로드밸런서 |
| backend-1         | ${PREFIX}-backend:latest         | -        | 8080     | 내부전용       |
| backend-2         | ${PREFIX}-backend:latest         | -        | 8080     | 내부전용       |
| prometheus        | prom/prometheus:latest           | -        | 9090     | 내부전용       |
| grafana           | grafana/grafana:latest           | 9300     | 3000     | 모니터링       |
| nginx-www         | nginx:alpine                     | 8300     | 3000     | 웹 로드밸런서  |
| frontend-1        | ${PREFIX}-frontend:latest        | -        | 3000     | 내부전용       |
| frontend-2        | ${PREFIX}-frontend:latest        | -        | 3000     | 내부전용       |

백엔드 SDK 이미지 버전
- eclipse-temurin:21-jdk-alpine
- eclipse-temurin:21-jre-alpine

프론트엔드 SDK 이미지 버전
- node:18-alpine

## 개발 환경 포트 매핑

### 데이터베이스 (RDS 또는 별도 서버 자체 운영)

| 서비스            | 외부포트 | 내부포트 | 역할                  |
| ----------------- | -------- | -------- | --------------------- |
| keycloak-postgres | 15432    | 5432     | 인증서버 데이터베이스 |
| backend-mariadb   | 13306    | 3306     | 백엔드 데이터베이스   |

### 도커 컨테이너

| 서비스   | 외부포트 | 내부포트 | 역할          |
| -------- | -------- | -------- | ------------- |
| redis    | -        | 6379     | 내부전용      |
| keycloak | 8081     | 8080     | 인증서버      |
| backend  | 8080     | 8080     | 브라우저 접속 |
| frontend | 3000     | 3000     | 브라우저 접속 |
