# 최소 Grafana 모니터링 설정

## 개요

Prometheus = 데이터 수집기 + 창고

- 온도계, 습도계처럼 계속 데이터 수집
- 수집한 데이터를 창고에 체계적으로 저장
- Prometheus 웹 노출을 아예 제거

Grafana = 리포트 생성기 + 대시보드

- 창고에서 데이터를 가져와서
- 예쁜 차트와 그래프로 만들어 보여줌

## 접속 정보

- **Grafana**: https://grafana.example.com
    - 사용자: `admin`
    - 비밀번호: `.env`에서 설정한 값

- **Prometheus**: 외부 접속 불가

## 첫 번째 대시보드 만들기

Grafana 접속 후:

1. **+ → Dashboard → Add new panel**
2. **Query**: `jvm_memory_used_bytes{area="heap"}`
3. **Panel title**: "JVM Heap Memory Usage"
4. **Save**

## 권장 첫 번째 메트릭들

1. **JVM 메모리**: `jvm_memory_used_bytes{area="heap"}`
2. **HTTP 요청 수**: `http_server_requests_seconds_count`
3. **CPU 사용률**: `process_cpu_usage`
4. **애플리케이션 시작 시간**: `application_started_time_seconds`

## 도커 이미지 재생성 및 재시작

```shell
docker compose down
docker volume rm example-grafana-data
docker compose up -d
```