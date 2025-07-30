#!/bin/bash

check_health() {
    local service=$1
    echo "⏳ Waiting for $service to be healthy..."
    for i in {1..36}; do  # 3분 대기 (5초 * 36)
        # 백엔드 헬스체크 (Spring Actuator)
        if docker compose exec -T $service curl -f -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
            echo "✅ $service is healthy!"
            return 0
        fi
        echo -n "."
        sleep 5
    done
    echo "❌ $service failed to become healthy!"
    return 1
}

restart_service() {
    local service=$1
    echo "🔄 Restarting $service..."
    docker compose stop $service
    docker compose up -d $service
    if check_health $service; then
        return 0
    else
        return 1
    fi
}

# 백엔드 서비스 순차적 재시작
echo "🔄 Backend rolling restart..."

# backend-1 재시작
if restart_service "backend-1"; then
    echo "✅ backend-1 restarted successfully"
else
    echo "❌ backend-1 restart failed"
    exit 1
fi

# backend-2 재시작
if restart_service "backend-2"; then
    echo "✅ backend-2 restarted successfully"
else
    echo "❌ backend-2 restart failed"
    exit 1
fi

echo "🎉 All backend services restarted successfully!"