# 도커 기반 프로젝트 운영 배포 예제

## 우분투 서버

### 기본 설정

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

### `ubuntu` 관리 계정 (`ubuntu` 디폴트 계정은 이미 `sudo` 그룹에 속해 있음)

```
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

### 도커 시스템

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

### 호스트 nginx

#### 설치

```
sudo apt-get install nginx
sudo ufw allow "Nginx Full"
sudo ufw status
```

#### 설정

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

```
sudo ln -s /opt/docker/projects/example/host/example.com /etc/nginx/sites-enabled/example.com
sudo ln -s /opt/docker/projects/example/host/logrotate /etc/logrotate.d/example

# 주의: logrotate 원본 파일이 root 소유여야 함
sudo chown root:root /opt/docker/projects/example/host/logrotate
```

## Github Actions 연동

주의: 실제 Github Actions Workflow 설정 및 Dockerfile은 프로젝트 저장소에 위치한다.

저장소 별 **Settings > Security > Secrets and variables > Actions > Repository secrets** 설정
- 백엔드
    - PREFIX
    - EXAMPLE_APPLICATION_PROD_YML
- 프론트엔드
    - PREFIX
    - DOTENV

### Self-hosted Runner 설치

**GitHub / 저장소 접속 후 Settings > Actions > Runners 메뉴로 이동 New self-hosted runner 버튼 클릭 후 실제 해시값 확인**

```shell
# 1. /opt/runner 디렉토리 생성
sudo mkdir -p /opt/example-{backend,front}-prod-runner

# 2. ubuntu 사용자 소유권 설정
sudo chown ubuntu:ubuntu /opt/example-*-prod-runner
```

#### 백엔드 러너 설치 예시
```shell
# 3. 디렉토리로 이동
cd /opt/example-backend-prod-runner

# 4. 최신 runner 패키지 다운로드
curl -o actions-runner-linux-x64-2.326.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.326.0/actions-runner-linux-x64-2.326.0.tar.gz

# 5. 해시 검증
echo "9c74af9b4352bbc99aecc7353b47bcdfcd1b2a0f6d15af54a99f54a0c14a1de8  actions-runner-linux-x64-2.326.0.tar.gz" | shasum -a 256 -c

# 6. 압축 풀기
tar xzf ./actions-runner-linux-x64-2.326.0.tar.gz

# 7. Runner 생성 및 구성 시작
./config.sh --url https://github.com/계정/백엔드_프로젝트 --token GITHUB_등록_페이지_발급_토큰 

# 8. 구성 중 질문 답변:
# Enter the name of the runner group to add this runner to: [엔터]
# Enter the name of runner: example-backend-prod-runner
# Enter any additional labels (ex. label-1,label-2): backend,Production
# Enter name of work folder: [엔터]

# 9. 테스트 실행 및 ctrl + C 종료
./run.sh
```

#### 프론트 러너 설치 예시

```shell
# 1. /opt/runner 디렉토리 생성
sudo mkdir -p /opt/example-frontend-prod-runner

# 2. ubuntu 사용자 소유권 설정
sudo chown ubuntu:ubuntu /opt/example-frontend-prod-runner

# 3. 디렉토리로 이동
cd /opt/example-frontend-prod-runner

# 4. 최신 runner 패키지 다운로드
curl -o actions-runner-linux-x64-2.326.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.326.0/actions-runner-linux-x64-2.326.0.tar.gz

# 5. 해시 검증
echo "9c74af9b4352bbc99aecc7353b47bcdfcd1b2a0f6d15af54a99f54a0c14a1de8  actions-runner-linux-x64-2.326.0.tar.gz" | shasum -a 256 -c

# 6. 압축 풀기
tar xzf ./actions-runner-linux-x64-2.326.0.tar.gz

# 7. Runner 생성 및 구성 시작
./config.sh --url https://github.com/계정/프론트_프로젝트 --token GITHUB_등록_페이지_발급_토큰 

# 8. 구성 중 질문 답변:
# Enter the name of the runner group to add this runner to: [엔터]
# Enter the name of runner: example-frontend-prod-runner
# Enter any additional labels (ex. label-1,label-2): frontend,Production
# Enter name of work folder: [엔터]

# 9. 테스트 실행 및 ctrl + C 종료
./run.sh
```

### 러너 서비스 등록 및 시작

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

### 러너 삭제 절차

```shell
# 1. 서비스만 중지/제거 (예, 프론트 러너)
cd /opt/example-frontend-prod-runner
sudo ./svc.sh stop
sudo ./svc.sh uninstall

# 2. 디렉토리 삭제
cd /
sudo rm -rf /opt/example-frontend-prod-runner
```

**GitHub / 저장소 접속 후 Settings > Actions > Runners 메뉴로 이동 등록한 기존 runner 삭제**

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