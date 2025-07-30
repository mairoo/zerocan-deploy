# 도커 기반 프로젝트 운영 배포 예제

## 디렉토리 구성

```
/opt/docker/
├── logs/                           # 도커 정리 작업 로그
├── scripts/                        # cleanup.sh 등 스크립트
└── projects/zerocan/
    ├── backend/logs/               # 백엔드 애플리케이션 로그
    ├── frontend/logs/              # 프론트엔드 애플리케이션 로그  
    ├── monitoring/logs/            # Grafana 로그
    ├── infra/logs/                 # Keycloak, Default 로그
    └── host/                       # nginx 설정, logrotate 설정, SSL 인증서
```

```shell
sudo mkdir -p /opt/docker
sudo chown ubuntu:ubuntu /opt/docker

# 도커 정리 작업 스크립트 및 로그 디렉토리 생성
mkdir -p /opt/docker/{logs,scripts}

# 프로젝트 로그 디렉토리 생성
mkdir -p /opt/docker/projects/zerocan/{backend,frontend,monitoring,infra}/logs/

# 로그 디렉토리도 www-data가 쓸 수 있도록 권한 조정
sudo chown www-data:www-data /opt/docker/projects/zerocan/backend/logs/
sudo chown www-data:www-data /opt/docker/projects/zerocan/frontend/logs/
sudo chown www-data:www-data /opt/docker/projects/zerocan/monitoring/logs/
sudo chown www-data:www-data /opt/docker/projects/zerocan/infra/logs/

# 디렉토리 권한 설정 (www-data가 파일 생성/삭제 가능하도록)
sudo chmod 755 /opt/docker/projects/zerocan/backend/logs/
sudo chmod 755 /opt/docker/projects/zerocan/frontend/logs/
sudo chmod 755 /opt/docker/projects/zerocan/monitoring/logs/
sudo chmod 755 /opt/docker/projects/zerocan/infra/logs/
```

## nginx 설정 및 logrotate 설정 심볼릭 링크

```
sudo ln -s /opt/docker/projects/zerocan/host/zerocan.com /etc/nginx/sites-enabled/zerocan.com
sudo ln -s /opt/docker/projects/zerocan/host/logrotate /etc/logrotate.d/zerocan

# 주의: logrotate 원본 파일이 root 소유여야 함
sudo chown root:root /opt/docker/projects/zerocan/host/logrotate
```

## Github Actions 연동

주의: 실제 Github Actions Workflow 설정 및 Dockerfile은 프로젝트 저장소에 위치한다.

저장소 별 **Settings > Security > Secrets and variables > Actions > Repository secrets** 설정
- 백엔드
    - PREFIX
    - ZEROCAN_APPLICATION_PROD_YML
- 프론트엔드
    - PREFIX
    - DOTENV

### Self-hosted Runner 설치

**GitHub / 저장소 접속 후 Settings > Actions > Runners 메뉴로 이동 New self-hosted runner 버튼 클릭 후 실제 해시값 확인**

```shell
# 1. /opt/runner 디렉토리 생성
sudo mkdir -p /opt/pincoin-{backend,front}-prod-runner

# 2. ubuntu 사용자 소유권 설정
sudo chown ubuntu:ubuntu /opt/pincoin-*-prod-runner
```

#### 백엔드 러너 설치 예시
```shell
# 3. 디렉토리로 이동
cd /opt/pincoin-backend-prod-runner

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
# Enter the name of runner: pincoin-backend-prod-runner
# Enter any additional labels (ex. label-1,label-2): backend,Production
# Enter name of work folder: [엔터]

# 9. 테스트 실행 및 ctrl + C 종료
./run.sh
```

#### 프론트 러너 설치 예시

```shell
# 1. /opt/runner 디렉토리 생성
sudo mkdir -p /opt/pincoin-frontend-prod-runner

# 2. ubuntu 사용자 소유권 설정
sudo chown ubuntu:ubuntu /opt/pincoin-frontend-prod-runner

# 3. 디렉토리로 이동
cd /opt/pincoin-frontend-prod-runner

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
# Enter the name of runner: pincoin-frontend-prod-runner
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
cd /opt/pincoin-frontend-prod-runner
sudo ./svc.sh stop
sudo ./svc.sh uninstall

# 2. 디렉토리 삭제
cd /
sudo rm -rf /opt/pincoin-frontend-prod-runner
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
sudo chown www-data:www-data /opt/docker/projects/zerocan/backend/logs/host-*.log
sudo chown www-data:www-data /opt/docker/projects/zerocan/frontend/logs/host-*.log
sudo chown www-data:www-data /opt/docker/projects/zerocan/monitoring/logs/grafana-*.log
sudo chown www-data:www-data /opt/docker/projects/zerocan/infra/logs/keycloak-*.log
sudo chown www-data:www-data /opt/docker/projects/zerocan/infra/logs/default-*.log

# logrotate 설정 문법 검사
sudo logrotate -d /etc/logrotate.d/zerocan

# 강제로 로테이션 실행
sudo logrotate -f /etc/logrotate.d/zerocan
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