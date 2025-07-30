#!/bin/bash
# Docker 정리 스크립트

# 로그 설정
LOG_FILE="/opt/docker/logs/cleanup.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date): Docker cleanup started" >> "$LOG_FILE"

# 정지된 컨테이너 삭제
docker container prune -f >> "$LOG_FILE" 2>&1

# 사용하지 않는 네트워크 삭제
docker network prune -f >> "$LOG_FILE" 2>&1

# 1주일 이상 된 이미지만 삭제 (안전)
docker image prune --filter "until=168h" -f >> "$LOG_FILE" 2>&1

# 사용하지 않는 볼륨 삭제 (주의: 데이터 손실 가능)
# docker volume prune -f >> "$LOG_FILE" 2>&1

# 디스크 사용량 로깅
echo "$(date): Disk usage after cleanup:" >> "$LOG_FILE"
df -h >> "$LOG_FILE"
docker system df >> "$LOG_FILE"

echo "$(date): Docker cleanup completed" >> "$LOG_FILE"