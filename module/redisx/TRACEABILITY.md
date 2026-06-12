# redisx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: docs/governance/TRACEABILITY.md（迁移前全局矩阵）

| Requirement | Description        | Acceptance Criteria | Test Case | Status |
| ----------- | ------------------ | ------------------- | --------- | ------ |
| FR-001      | Get                | key 存在返回字符串值+error=nil；key 不存在返回 redis.Nil；连接不可用返回连接错误 | TC-001    | ⬜     |
| FR-002      | Set                | TTL>0 设置值+过期时间返回 nil；TTL=0 设值无过期返回 nil；不可序列化返回序列化错误 | TC-001    | ⬜     |
| FR-003      | Del                | 删除存在的 key 幂等返回 nil；所有 key 不存在返回 nil（幂等） | TC-001    | ⬜     |
| FR-004      | Exists             | 返回存在的 key 数量（含 0）；连接不可用返回连接错误 | TC-005    | ⬜     |
| FR-005      | Expire             | key 存在设置 TTL 返回 nil；key 不存在返回 nil（不报错） | TC-005    | ⬜     |
| FR-006      | HGet / HSet        | HGet 存在 field 返回值；HGet 不存在返回 redis.Nil；HSet 写入 field 返回 nil | TC-006    | ⬜     |
| FR-007      | LPush / LRange     | LPush 插入列表头返回 nil；LRange 列表存在返回指定范围；列表不存在返回空切片 | TC-007    | ⬜     |
| FR-008      | Subscribe          | 连接正常返回 channel+nil；断连自动重连失败发错误到 channel；ctx 取消关闭订阅释放资源 | TC-008, TC-004 | ⬜     |
| FR-009      | Pipeline           | Pipeline() 返回新实例；Exec 成功按序返回全部结果；部分失败返回已成功+首个错误 | TC-003    | ⬜     |
| FR-010      | Locker.Acquire     | 锁未被持有 Acquire 返回 true；锁被持有返回 false；TTL 到期锁自动释放 | TC-002    | ⬜     |
| FR-011      | Locker.Release     | 持有者释放锁返回 nil；非持有者释放返回 ErrLockNotHeld 不释放锁 | TC-002    | ⬜     |
| FR-012      | Health             | PING 成功返回 {Ready:true, Live:true}；PING 失败返回 unhealthy+Message | TC-009    | ⬜     |
| BR-001      | 连接池大小默认 10     | 配置默认值为 10；CI Gate 编译 + go test 验证默认连接池大小 | CI Gate: 配置校验   | ⬜     |
| BR-002      | Codec 默认 JSON      | 单元测试：未指定 codec 时序列化/反序列化使用 JSON | TC-006（含 codec 校验） | ⬜     |
| BR-003      | 所有操作接受 context   | 编译器强制：Client 接口所有方法含 context.Context 参数 | CI Gate: go build    | ⬜     |
| BR-004      | 分布式锁唯一持有者标识  | Release 非持有者返回 ErrLockNotHeld（Lua 脚本原子校验） | TC-002    | ⬜     |
| BR-005      | 分布式锁必须设置 TTL   | Acquire(ctx, key, ttl) 签名强制 TTL 参数，不可省略 | TC-002    | ⬜     |
| BR-006      | Pipeline 原子性       | 单次网络往返发送所有命令；Exec 行为验证 | TC-003    | ⬜     |
| BR-007      | Health() 幂等无副作用  | 连续两次 Health() 调用返回一致结果，不改变 Redis 状态 | TC-009（含重复调用） | ⬜     |
| BR-008      | 断开自动重连可配置     | TC-004 验证重连行为；MaxRetries/重连间隔由 Option 控制 | TC-004    | ⬜     |
| BR-009      | 错误消息不含 key 实际值 | CI Gate gitleaks + 错误消息格式不含值内容 | CI Gate: gitleaks    | ⬜     |

---
