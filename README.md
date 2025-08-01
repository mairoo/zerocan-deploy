# 도커 기반 프로젝트 배포 예제

## 운영 환경 포트 매핑

### 호스트 nginx

| 서비스 | 도메인               | 포트 | 프록시 대상      |
| ------ | -------------------- | ---- | ---------------- |
| nginx  | api.example.com      | 443  | → localhost:8800 |
| nginx  | www.example.com      | 443  | → localhost:8300 |
| nginx  | keycloak.example.com | 443  | → localhost:8801 |
| nginx  | grafana.example.com  | 443  | → localhost:9300 |

### 도커 컨테이너

| 서비스            | 이미지 버전                           | 외부포트 | 내부포트 | 역할           |
| ----------------- | -------------------------------- | -------- | -------- | -------------- |
| redis             | redis:alpine                     | -        | 6379     | 내부전용       |
| keycloak-postgres | postgres:15-alpine               | 15432    | 5432     | 관리용         |
| keycloak          | quay.io/keycloak/keycloak:26.3.1 | 8801     | 8080     | 인증서버       |
| nginx-api         | nginx:alpine                     | 8800     | 8080     | API 로드밸런서 |
| backend-1         | ${PREFIX}-backend:latest         | -        | 8080     | 내부전용       |
| backend-2         | ${PREFIX}-backend:latest         | -        | 8080     | 내부전용       |
| prometheus        | prom/prometheus:latest           | -        | 9090     | 내부전용       |
| grafana           | grafana/grafana:latest           | 9300     | 3000     | 모니터링       |
| nginx-www         | nginx:alpine                     | 8300     | 3000     | 웹 로드밸런서  |
| frontend-1        | ${PREFIX}-frontend:latest        | -        | 3000     | 내부전용       |
| frontend-2        | ${PREFIX}-frontend:latest        | -        | 3000     | 내부전용       |

백엔드 SDK 이미지 버전
- eclipse-temurin:21-jdk-alpine
- eclipse-temurin:21-jre-alpine

프론트엔드 SDK 이미지 버전
- node:18-alpine

## 개발 환경 포트 매핑

### 데이터베이스 (RDS 또는 별도 서버 자체 운영)

| 서비스            | 외부포트 | 내부포트 | 역할                  |
| ----------------- | -------- | -------- | --------------------- |
| keycloak-postgres | 15432    | 5432     | 인증서버 데이터베이스 |
| backend-mariadb   | 13306    | 3306     | 백엔드 데이터베이스   |

### 도커 컨테이너

| 서비스   | 외부포트 | 내부포트 | 역할          |
| -------- | -------- | -------- | ------------- |
| redis    | -        | 6379     | 내부전용      |
| keycloak | 8081     | 8080     | 인증서버      |
| backend  | 8080     | 8080     | 브라우저 접속 |
| frontend | 3000     | 3000     | 브라우저 접속 |

## 인프라 옵션 비교

### 1. Vultr.com Cloud Compute / High Performance

| vCPUs    | 메모리 | 대역폭 | 스토리지 | 가격 | 서비스 가능 (예상)   | 동접자 수 (예상) |
| -------- | ------ | ------ | -------- | ---- | -------------------- | ---------------- |
| 4 vCPUs  | 12GB   | 7TB    | 260GB    | $72  | 1개 서비스 (~4.3GB)  | 200~500          |
| 8 vCPUs  | 16GB   | 8TB    | 350GB    | $96  | 2개 서비스 (~8.6GB)  | 500~1000         |
| 12 vCPUs | 24GB   | 12TB   | 500GB    | $144 | 5개 서비스 (~21.5GB) | 1250~1750        |

- AMD EPYC 4vCPUs (다수 도커 컨테이너 실행 시 멀티 스레드 성능이 Intel Xeon 대비 약간 우세)
- 방화벽 무료 제공
- Auto Backup (월 $14.4) 미사용: github이 소스 코드 백업 장치 역할
- DDOS Protection (월 $10) 미사용: cloudflare 웹 방화벽이 80/443 포트 보호 / 방화벽이 22 포트 보호
- AWS RDS, S3 별도 이용

### 2. 코로케이션 (HP DL360 GEN9)

| CPU             | 메모리 | 스토리지  | 대역폭                          | 서비스 가능 (예상) | 동접자 수 (예상) |
| --------------- | ------ | --------- | ------------------------------- | ------------------ | ---------------- |
| 12코어/24스레드 | 32GB   | 500GB SSD | 1000Mbps Dedicated / Max 30Mbps | 7개 서비스 (~28GB) | 1750~2250        |

- Intel Xeon E5-2620V3 2.4GHz × 2EA
- DDR4 32GB ECC 메모리

### 서비스 구성 (공통)

**서비스 1개 예상 메모리 사용량 = ~3.3GB**

- Redis: ~200MB
- Backend-1: ~1GB
- Backend-2: ~1GB
- Backend Nginx: ~50MB
- Frontend-1: ~500MB
- Frontend-2: ~500MB
- Frontend Nginx: ~50MB

**운영체제 + 도커 오버헤드 = ~1GB or ~2GB**

### 순간 최대 속도 비교

- **Vultr High Performance**: 0.5~3Gbps 가능, 순간 1Gbps 초과도 허용됨, 월간 트래픽 제한 있음
- **AWS EC2**: 0.5~400Gbps 가능, 트래픽 무제한 요금 종량제
- **국내 IDC**: 1Gbps Dedicated/ Max 0.03Gbps (Dedicated와 Max는 모순적 표기)

### 요약

- **국내 IDC** / 최대 7개 서비스 / 30만원
    - 7개 서비스를 모두 활용하지 못하면 비용 효율성 저하
    - 운영체제 + 도커 오버헤드 고려하면 실질적으로 6개 서비스가 최대
    - 전용선임에도 순간 최대 속도는 클라우드 대비 제한적 (30Mbps)
    - 물리적 장애 시 상당한 다운타임 발생 가능
    - **단일 장애점(SPOF): 하나의 물리 서버에 모든 서비스가 집중되어 전체 서비스 동시 중단 위험**

- **Vultr** / 6개 서비스 / 40만원 (8 vCPUs x 3개 기준)
    - 필요에 따라 유연한 스케일링 가능
    - 순간 대역폭은 우수하나 월간 트래픽 제한
    - 클라우드 관리 편의성
    - **위험 분산: 여러 인스턴스에 서비스 분산으로 부분 장애 시에도 일부 서비스는 정상 운영 가능**

**30만원짜리 사놓고 실제로 5개 쓰면 6만원, 40만원짜리 사놓고 실제로 6개 쓰면 6.67만원**

- docker compose 수준 배포 관리 = 개발자 감당 수준
- docker swarm 또는 kubernetes 도입 수준 배포 관리 = 인프라 전담 관리자 필요