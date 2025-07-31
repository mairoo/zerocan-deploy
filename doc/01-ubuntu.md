# 우분투 서버

## 기본 설정

```shell
# 패키지 업데이트
apt-get update && apt-get dist-upgrade
apt-get autormeove
apt-get autoclean

# 타임존 설정
timedatectl set-timezone Asia/Seoul

# 로케일 설정
apt-get install -y language-pack-ko
update-locale LANG=en_US.UTF-8

# 호스트 이름 (필요 시)
hostnamectl
hostnamectl set-hostname my-server-name

# vim 디폴트
update-alternatives --config editor
```

## `ubuntu` 관리 계정 (`ubuntu` 디폴트 계정은 이미 `sudo` 그룹에 속해 있음)

```shell
visudo
```

```
%sudo   ALL=(ALL:ALL) NOPASSWD: ALL
```

로컬 컴퓨터에서

```shell
# SSH 키 생성 (이미 있다면 생략)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

원격 서버에서

```shell
# ubuntu 계정으로 전환
sudo su - ubuntu

# .ssh 디렉토리 생성
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# authorized_keys 파일 생성
nano ~/.ssh/authorized_keys
# 여기에 로컬의 ~/.ssh/id_rsa.pub 내용 복사 붙여넣기

# 파일 권한 설정
chmod 600 ~/.ssh/authorized_keys
```

루트 원격 접속 금지 및 키 접속만 허용

```shell
sudo vi /etc/ssh/sshd_config
```

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

```shell
sudo service ssh restart
```

## 도커 시스템

https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

```shell
# 도커 공식 GPG 키 추가
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# APT 소스에 저장소 추가
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# 도커 패키지 설치
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 도커 설치 확인
docker run hello-world

sudo mkdir -p /opt/docker
sudo chown ubuntu:ubuntu /opt/docker
cd /opt/docker
mkdir projects scripts logs

# ubuntu 계정 docker 그룹에 추가하여 sudo 권한 필요 없이 접근
sudo usermod -aG docker ubuntu

# 현재 세션에 그룹 변경사항 적용
newgrp docker

# 도커 정리 작업 스크립트 및 로그 디렉토리 생성
mkdir -p /opt/docker/{logs,scripts}
```

## 호스트 nginx

### 설치

```
sudo apt-get install nginx
sudo ufw allow "Nginx Full"
sudo ufw status
```

### 설정

`/etc/nginx/sites-enabled/default`

```
server {
listen 80;
listen [::]:80;

    server_name _;
    root /var/www/html;
    index index.html index.htm;
    
    # 서버 정보 숨기기
    server_tokens off;
    
    # 숨김 파일 차단
    location ~ /\. {
        deny all;
    }
    
    # 기본 위치
    location / {
        try_files $uri $uri/ =404;
    }
    
    # PHP 차단 (불필요시)
    location ~ \.php$ {
        return 404;
    }
}
```

`/etc/nginx/nginx.conf`

```
http {
    # 서버 토큰 숨기기
    server_tokens off;
    
    # 파일 업로드 크기 제한
    client_max_body_size 10M;
    
    # 기존 설정들...
}
```

```shell
# 설정 확인
sudo nginx -t

# 적용
sudo systemctl reload nginx
```

## 프로젝트 디렉토리 구성

```
/opt/docker/
├── logs/                           # 도커 정리 작업 로그
├── scripts/                        # cleanup.sh 등 스크립트
└── projects/example/
    ├── backend/logs/               # 백엔드 애플리케이션 로그
    ├── frontend/logs/              # 프론트엔드 애플리케이션 로그  
    ├── monitoring/logs/            # Grafana 로그
    ├── infra/logs/                 # Keycloak, Default 로그
    └── host/                       # nginx 설정, logrotate 설정, SSL 인증서
```

```shell
# 프로젝트 로그 디렉토리 생성
mkdir -p /opt/docker/projects/example/{backend,frontend,monitoring,infra}/logs/

# 로그 디렉토리도 www-data가 쓸 수 있도록 권한 조정
sudo chown www-data:www-data /opt/docker/projects/example/backend/logs/
sudo chown www-data:www-data /opt/docker/projects/example/frontend/logs/
sudo chown www-data:www-data /opt/docker/projects/example/monitoring/logs/
sudo chown www-data:www-data /opt/docker/projects/example/infra/logs/

# 디렉토리 권한 설정 (www-data가 파일 생성/삭제 가능하도록)
sudo chmod 755 /opt/docker/projects/example/backend/logs/
sudo chmod 755 /opt/docker/projects/example/frontend/logs/
sudo chmod 755 /opt/docker/projects/example/monitoring/logs/
sudo chmod 755 /opt/docker/projects/example/infra/logs/
```

## nginx 설정 및 logrotate 설정 심볼릭 링크

```shell
sudo ln -s /opt/docker/projects/example/host/example.com /etc/nginx/sites-enabled/example.com
sudo ln -s /opt/docker/projects/example/host/logrotate /etc/logrotate.d/example

# 주의: logrotate 원본 파일이 root 소유여야 함
sudo chown root:root /opt/docker/projects/example/host/logrotate
```

## 도커 정리 스크립트 
- [cleanup.sh](/opt/docker/scripts/cleanup.sh)

```shell
crontab -e
0 3 * * * /opt/docker/scripts/cleanup.sh
```

## 주기적 백업 전략

```shell
# 백업 디렉토리 생성
sudo mkdir -p /backup

# 백업 실행
cd /opt && sudo tar czvfp /backup/docker-$(date +%Y%m%d).tgz --exclude='*/logs' docker/
```