#!/bin/bash

check_health() {
    local service=$1
    echo "⏳ Waiting for $service to be healthy..."
    for i in {1..36}; do  # 3분 대기 (5초 * 36)
        # 프론트엔드 헬스체크
        if docker compose exec -T $service curl -f -s http://localhost:3000 > /dev/null 2>&1; then
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

# 프론트엔드 서비스 순차적 재시작
echo "🔄 Frontend rolling restart..."

# frontend-1 재시작
if restart_service "frontend-1"; then
    echo "✅ frontend-1 restarted successfully"
else
    echo "❌ frontend-1 restart failed"
    exit 1
fi

# frontend-2 재시작
if restart_service "frontend-2"; then
    echo "✅ frontend-2 restarted successfully"
else
    echo "❌ frontend-2 restart failed"
    exit 1
fi

echo "🎉 All frontend services restarted successfully!"