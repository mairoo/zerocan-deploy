# logrotate

소유권 일관성 유지
- 호스트 nginx 로그: www-data www-data (nginx 프로세스 실행 유저)
- 도커 내부 로그: root root (도커 컨테이너는 보통 root로 실행)

```shell
# 호스트 nginx 로그 파일들만 www-data로 변경
sudo chown www-data:www-data /opt/docker/projects/example/backend/logs/host-*.log
sudo chown www-data:www-data /opt/docker/projects/example/frontend/logs/host-*.log
sudo chown www-data:www-data /opt/docker/projects/example/monitoring/logs/grafana-*.log
sudo chown www-data:www-data /opt/docker/projects/example/infra/logs/keycloak-*.log
sudo chown www-data:www-data /opt/docker/projects/example/infra/logs/default-*.log

# logrotate 설정 문법 검사
sudo logrotate -d /etc/logrotate.d/example

# 강제로 로테이션 실행
sudo logrotate -f /etc/logrotate.d/example
```