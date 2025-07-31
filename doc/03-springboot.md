# applicaiton-prod.yml 파일 설정: 보안 원칙론보다는 실용성에 따른 접근 

- 호스트에서 수동 관리 및 볼륨 마운트로 런타임에 컨테이너에 주입
- 민감한 설정 일일에  이대해 최소 권한 원칙 적용(보안 권한: 640 root:docker)

```shell
 sudo chown root:docker /opt/docker/projects/example/backend/application-prod.yml
 sudo 640 /opt/docker/projects/example/backend/application-prod.yml
```