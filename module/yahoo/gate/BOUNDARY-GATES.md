# yahoo Boundary Gates

## 必须通过

1. 禁止绕过共享基座直连基础设施客户端。
2. 禁止 provider DTO 暴露为跨模块公共 API。
3. 禁止在文档或代码中出现 secret 原值。
4. 禁止 client 直写业务数据库。
5. 禁止 server 直连 provider 抓取。
6. Redis/ClickHouse 不得声明为唯一权威源。

## 推荐检查命令

```bash
bash scripts/boundary-gates.sh
```

