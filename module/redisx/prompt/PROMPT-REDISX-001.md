# PROMPT-REDISX-001
- Task：[../tasks/](../tasks/) | Trace：[../TRACEABILITY.md](../TRACEABILITY.md) | Spec：[../SPEC.md](../SPEC.md)
## 任务
实现 redisx Redis 客户端：KeyBuilder/KV/Hash/List/PubSub/Pipeline/Locker/Counter/CacheClient。
## 要点
1. KeyBuilder namespace/env/service/version 隔离
2. CacheClient cache-aside + null-cache + 防击穿
3. Locker token owner + TTL + Lua guarded release
4. Pipeline 有序非原子批量
5. 错误脱敏（不含完整 Key）
