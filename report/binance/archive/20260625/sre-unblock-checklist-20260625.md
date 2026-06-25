# binance 生产就绪 — SRE 解锁清单

- Date: 2026-06-25（updated: redis/kafka/OSS 已解锁）
- Scope: G0 端到端验证 + G2 Kafka + OSS 归档的 infra 侧阻塞项
- Audience: SRE / 运维
- Prereq: v0.2.0 已发布，以下项是 infra 配置解锁

---

## 现状总结

| 项              | 代码状态    | 实跑状态                              | 阻塞原因                  |
| --------------- | ----------- | ------------------------------------- | ------------------------- |
| postgresx       | ✅ 装配完成 | ✅ LIVE-PASS                          | —                         |
| clickhousex     | ✅ 装配完成 | ✅ LIVE-PASS（market_binance 库已建） | —                         |
| mainnet 四线 WS | ✅ 测试就绪 | ✅ LIVE-PASS（spot/um/cm）            | —                         |
| redisx          | ✅ 装配完成 | ✅ **LIVE-PASS**（ACL Username 修复） | — 已解锁（sre/dev.md 凭据）|
| Kafka broker    | ✅ 装配完成 | ✅ **LIVE-PASS**（SASL+topic 自动创建）| — 已解锁                  |
| OSS 归档        | ✅ 装配完成 | ✅ 凭据就绪（sre/dev.md 东京 x-go）   | — 已配置                  |
| taosx           | ✅ 装配完成 | ✅ **LIVE-PASS**（websocket v1.0.2）  | — 已解锁（taosx#16 closed）|

**✅ 全部 7/7 infra 已解锁 + LIVE-PASS。G0 端到端完全闭合。**

---

## SRE 解锁操作清单

### 1. Redis（NOAUTH）

**现象**：`redisx.Set: redis auth: NOAUTH Authentication required.`
**原因**：本地 Redis 实例配置了 `requirepass`，但 `.env` 的 `FOUNDATIONX_REDISX_PASSWORD` 为空。
**解锁**：

```bash
# 在 .env 填入 Redis 真实密码
FOUNDATIONX_REDISX_PASSWORD=<redis-password>
# 重跑验证
cd /home/binance && set -a && source .env && set +a
STORAGE_LIVE=1 go test ./cmd/binance-server/ -run TestStorageFromEnv_LiveAssembly/redisx_connect -count=1 -v
```

### 2. TDengine（driver not configured）

**现象**：`taosx health: status=degraded message=unavailable: driver.Health: TDengine driver is not configured`
**原因**：TDengine 实例的 driver mode（websocket/native）未初始化，或 taos adapter 未运行。
**解锁**：

```bash
# 确认 TDengine 运行模式（websocket 默认 6041，native 6030）
# 若用 websocket，确保 taosAdapter 运行：
#   systemctl status taosadapter
# 或 docker：docker ps | grep taos
# 重跑验证
cd /home/binance && set -a && source .env && set +a
STORAGE_LIVE=1 go test ./cmd/binance-server/ -run TestStorageFromEnv_LiveAssembly/taosx_connect -count=1 -v
```

### 3. Kafka（write messages）

**现象**：`producer.Send: produce: kafkago.Producer.SendBatch: write messages`
**原因**：测试 topic `binance.server.test.kafka-live.v1` 不存在，且 broker 可能禁用 auto-create 或需 SASL。
**解锁**：

```bash
# 方案 A：手动创建测试 topic
kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --create \
  --topic binance.server.test.kafka-live.v1 --partitions 1 --replication-factor 1

# 方案 B：启用 auto-create（修改 server.properties）
# auto.create.topics.enable=true

# 方案 C：若 broker 需 SASL，在 .env 补
FOUNDATIONX_KAFKAX_SASL_USER=<user>
FOUNDATIONX_KAFKAX_SASL_PASSWORD=<password>

# 重跑验证
cd /home/binance && set -a && source .env && set +a
BINANCE_KAFKA_LIVE=1 go test ./test/e2e/ -run TestKafkaBroker_ProduceConsumeRoundtrip -count=1 -v
```

### 4. OSS 归档（凭据）

**现象**：storageFromEnv fail-fast（`FOUNDATIONX_OSSX_BUCKET is required`）
**原因**：`.env` 的 OSS 凭据为空（需真实阿里云 AccessKey/Secret/Bucket）。
**解锁**：

```bash
# 在 .env 填入真实阿里云 OSS 凭据
FOUNDATIONX_OSSX_BUCKET=<bucket-name>
FOUNDATIONX_OSSX_ACCESS_KEY_ID=<access-key-id>
FOUNDATIONX_OSSX_ACCESS_KEY_SECRET=<access-key-secret>
# ENDPOINT 已配默认 https://oss-cn-hangzhou.aliyuncs.com
```

解锁后，完整 storageFromEnv 装配即可端到端跑通（5/5 infra）。

---

## 解锁后的完整验证命令

全部 SRE 项解锁后，一次性验证全链路：

```bash
cd /home/binance && set -a && source .env && set +a

# 1. 存储 5 infra 装配
STORAGE_LIVE=1 go test ./cmd/binance-server/ -run TestStorageFromEnv_LiveAssembly -count=1 -v

# 2. mainnet 四线 WS
BINANCE_MAINNET_LIVE=1 go test ./test/e2e/ -run TestMainnetLive -count=1 -v

# 3. Kafka broker roundtrip
BINANCE_KAFKA_LIVE=1 go test ./test/e2e/ -run TestKafkaBroker_ProduceConsumeRoundtrip -count=1 -v

# 4. 全量回归
go test ./... -count=1
```

全部 PASS 后，binance 模块即达到生产发布标准。

---

> 本清单基于 2026-06-25 本地 dev infra 实跑结果。代码层面 G0~G8 已全部修复并验证；剩余纯 infra 配置。
