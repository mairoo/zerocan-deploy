# 도커 기반 프로젝트 운영 배포 예제

## 디렉토리 파일 구성

```
/opt/docker/scripts/
/opt/docker/scripts/cleanup.sh
/opt/docker/logs/
/opt/docker/projects/pincoin/
/opt/docker/projects/pincoin/infra/
/opt/docker/projects/pincoin/backend/
/opt/docker/projects/pincoin/frontend/
/opt/docker/projects/pincoin/monitoring/
/opt/docker/projects/pincoin/ssl/
```

## Git Actions 연동

## 포트 매핑

### 호스트 nginx

| 서비스   | 도메인                  | 포트  | 프록시 대상           |
|-------|----------------------|-----|------------------|
| nginx | api.example.com      | 443 | → localhost:8800 |
| nginx | www.example.com      | 443 | → localhost:8300 |
| nginx | keycloak.example.com | 443 | → localhost:8801 |
| nginx | grafana.example.com  | 443 | → localhost:9300 |

### 도커 컨테이너

| 서비스               | 외부포트  | 내부포트 | 역할        |
|-------------------|-------|------|-----------|
| redis             | -     | 6379 | 내부전용      |
| keycloak-postgres | 15432 | 5432 | 관리용       |
| keycloak          | 8801  | 8080 | 인증서버      |
| nginx-api         | 8800  | 8080 | API 로드밸런서 |
| backend-1         | -     | 8080 | 내부전용      |
| backend-2         | -     | 8080 | 내부전용      |
| prometheus        | -     | 9090 | 내부전용      |
| grafana           | 9300  | 3000 | 모니터링      |
| nginx-web         | 8300  | 3000 | 웹 로드밸런서   |
| frontend-1        | -     | 3000 | 내부전용      |
| frontend-2        | -     | 3000 | 내부전용      |

## 도커 정리 스크립트

```
crontab -e
0 3 * * * /opt/docker/scripts/cleanup.sh
```