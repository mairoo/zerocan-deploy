# HTTPS 서버 (Keycloak)
server {
	listen 443 ssl http2;
	server_name keycloak.example.com;

	ssl_certificate /opt/docker/projects/example/host/example.com.pem;
	ssl_certificate_key /opt/docker/projects/example/host/example.com.key;

	access_log /opt/docker/projects/example/infra/logs/keycloak-access.log;
	error_log /opt/docker/projects/example/infra/logs/keycloak-error.log;

	location / {
		proxy_pass http://localhost:8801;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto https; # 강제로 https 설정
		proxy_set_header X-Forwarded-Host $host;
		proxy_set_header X-Forwarded-Port 443; # https 포트 명시

		# WebSocket 지원
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection "upgrade";
	}
}

# HTTPS 서버 (백엔드)
server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	server_name api.example.com;

	ssl_certificate /opt/docker/projects/example/host/example.com.pem;
	ssl_certificate_key /opt/docker/projects/example/host/example.com.key;

	# SSL 보안 설정
	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
	ssl_prefer_server_ciphers off;
	ssl_session_cache shared:SSL:10m;
	ssl_session_timeout 10m;

	# HSTS 헤더 (HTTPS 강제)
	add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

	# 요청 크기 제한
	client_max_body_size 10M;

	# 보안 헤더
	add_header X-Frame-Options DENY;
	add_header X-Content-Type-Options nosniff;
	add_header X-XSS-Protection "1; mode=block";

	# 프록시 설정
	proxy_buffer_size 128k;
	proxy_buffers 4 256k;
	proxy_busy_buffers_size 256k;
	proxy_connect_timeout 10s;
	proxy_send_timeout 30s;
	proxy_read_timeout 30s;

	# 로그 설정
	access_log /opt/docker/projects/example/backend/logs/host-access.log;
	error_log /opt/docker/projects/example/backend/logs/host-error.log;

	location / {
		proxy_pass http://localhost:8800;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto https; # 강제로 https 설정
		proxy_set_header X-Forwarded-Host $host;
		proxy_set_header X-Forwarded-Port 443; # https 포트 명시
	}
}

# HTTPS 서버 (Grafana)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name grafana.example.com;

    # SSL 인증서 경로
    ssl_certificate /opt/docker/projects/example/host/example.com.pem;
    ssl_certificate_key /opt/docker/projects/example/host/example.com.key;

    # SSL 보안 설정
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS 헤더
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 보안 헤더 (Grafana용으로 조정)
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    # X-Frame-Options는 Grafana 임베딩을 위해 제거

    # 요청 크기 제한
    client_max_body_size 10M;

    # 프록시 설정
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;
    proxy_connect_timeout 10s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;

    # 로그 설정
    access_log /opt/docker/projects/example/monitoring/logs/grafana-access.log;
    error_log /opt/docker/projects/example/monitoring/logs/grafana-error.log;

    location / {
        proxy_pass http://localhost:9300;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 지원 (Grafana 실시간 업데이트)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
    }
}

# HTTPS 서버 (프론트엔드)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.example.com;

    # SSL 인증서 경로
    ssl_certificate /opt/docker/projects/example/host/example.com.pem;
    ssl_certificate_key /opt/docker/projects/example/host/example.com.key;

    # SSL 보안 설정
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS 헤더 (HTTPS 강제)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 요청 크기 제한
    client_max_body_size 10M;

    # 보안 헤더
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # 프록시 설정
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;
    proxy_connect_timeout 10s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;

    # 로그 설정
    access_log /opt/docker/projects/example/frontend/logs/host-access.log;
    error_log /opt/docker/projects/example/frontend/logs/host-error.log;

    location / {
        proxy_pass http://localhost:8300;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 설정 (Next.js SSR에 필요)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
    }
}

# 명시하지 않은 모든 요청: 반드시 가장 하단에 위치
server {
	listen 443 ssl http2 default_server;
	listen [::]:443 ssl http2 default_server;
	server_name _;

	# SSL 인증서 (기본값 사용)
	ssl_certificate /opt/docker/projects/example/host/example.com.pem;
	ssl_certificate_key /opt/docker/projects/example/host/example.com.key;

	# SSL 보안 설정
	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
	ssl_prefer_server_ciphers off;
	ssl_session_cache shared:SSL:10m;
	ssl_session_timeout 10m;

	# 보안 헤더
	add_header X-Frame-Options DENY;
	add_header X-Content-Type-Options nosniff;
	add_header X-XSS-Protection "1; mode=block";

	# 로그 설정
	access_log /opt/docker/projects/example/infra/logs/default-access.log;
	error_log /opt/docker/projects/example/infra/logs/default-error.log;

	# 404 페이지 반환 (보안상 403보다 404가 더 안전)
	location / {
		return 404;
	}
}