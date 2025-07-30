# 도커 기반 프로젝트 운영 배포 예제

## nginx 설정 및 logrotate 설정 심볼릭 링크

```
sudo ln -s /opt/docker/projects/pincoin/host/pincoin.kr /etc/nginx/sites-enabled/pincoin.kr
sudo ln -s /opt/docker/projects/pincoin/host/logrotate /etc/logrotate.d/pincoin

# 주의: logrotate 원본 파일이 root 소유여야 함
sudo chown root:root /opt/docker/projects/pincoin/host/logrotate
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
| nginx-www         | 8300  | 3000 | 웹 로드밸런서   |
| frontend-1        | -     | 3000 | 내부전용      |
| frontend-2        | -     | 3000 | 내부전용      |

## logrotate

소유권 일관성 유지
- 호스트 nginx 로그: www-data www-data (nginx 프로세스 실행 유저)
- 도커 내부 로그: root root (도커 컨테이너는 보통 root로 실행)

```
# 호스트 nginx 로그 파일들만 www-data로 변경
sudo chown www-data:www-data /opt/docker/projects/pincoin/backend/logs/host-*.log
sudo chown www-data:www-data /opt/docker/projects/pincoin/frontend/logs/host-*.log
sudo chown www-data:www-data /opt/docker/projects/pincoin/monitoring/logs/grafana-*.log
sudo chown www-data:www-data /opt/docker/projects/pincoin/infra/logs/keycloak-*.log
sudo chown www-data:www-data /opt/docker/projects/pincoin/infra/logs/default-*.log

# 로그 디렉토리도 www-data가 쓸 수 있도록 권한 조정
sudo chown www-data:www-data /opt/docker/projects/pincoin/backend/logs/
sudo chown www-data:www-data /opt/docker/projects/pincoin/frontend/logs/
sudo chown www-data:www-data /opt/docker/projects/pincoin/monitoring/logs/
sudo chown www-data:www-data /opt/docker/projects/pincoin/infra/logs/

# 디렉토리 권한 설정 (www-data가 파일 생성/삭제 가능하도록)
sudo chmod 755 /opt/docker/projects/pincoin/backend/logs/
sudo chmod 755 /opt/docker/projects/pincoin/frontend/logs/
sudo chmod 755 /opt/docker/projects/pincoin/monitoring/logs/
sudo chmod 755 /opt/docker/projects/pincoin/infra/logs/

# logrotate 설정 문법 검사
sudo logrotate -d /etc/logrotate.d/pincoin

# 강제로 로테이션 실행
sudo logrotate -f /etc/logrotate.d/pincoin
```

## 도커 정리 스크립트

```
crontab -e
0 3 * * * /opt/docker/scripts/cleanup.sh
```