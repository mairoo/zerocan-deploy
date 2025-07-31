# Github Actions 연동

주의: 실제 Github Actions Workflow 설정 및 Dockerfile은 프로젝트 저장소에 위치한다.

저장소 별 **Settings > Security > Secrets and variables > Actions > Repository secrets** 설정
- 백엔드
    - PREFIX
    - EXAMPLE_APPLICATION_PROD_YML
- 프론트엔드
    - PREFIX
    - DOTENV

## Self-hosted Runner 설치

**GitHub / 저장소 접속 후 Settings > Actions > Runners 메뉴로 이동 New self-hosted runner 버튼 클릭 후 실제 해시값 확인**

```shell
# 1. /opt/runner 디렉토리 생성
sudo mkdir -p /opt/example-{backend,front}-prod-runner

# 2. ubuntu 사용자 소유권 설정
sudo chown ubuntu:ubuntu /opt/example-*-prod-runner
```

### 백엔드 러너 설치 예시
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

### 프론트 러너 설치 예시

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

## 러너 서비스 등록 및 시작

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

## 러너 삭제 절차

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