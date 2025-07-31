# 각종 설정 파일 보안

```shell
# .env 파일 검색
find . -name ".env*" -type f

# 1단계: 소유권 root:docker 변경
find . -name ".env*" -type f -exec sudo chown root:docker {} \;
find . -name "application*.yml" -type f -exec sudo chown root:docker {} \;

# 2단계: 권한 640 변경
find . -name ".env*" -type f -exec sudo chmod 640 {} \;
find . -name "application*.yml" -type f -exec sudo chmod 640 {} \;
```
