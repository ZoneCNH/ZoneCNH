# module/binance BOUNDARY GATES

> 版本：v2.0.0
> 更新日期：2026-06-21
> 参见：`DEEP-ANALYSIS.md §0`（分布式架构约束）

## 1. 目的

边界门禁防止 `module/binance` 超越其设计边界扩张，并强制执行分布式 C/S 架构约束。

**所有门禁必须在 CI 中可执行。**

---

## 2. Gate: No Legacy binance-market

禁止引用：

```text
module/binance-market
github.com/ZoneCNH/binance-market
binance-market
docs/services/binance-market-client-svc.md
```

仅允许在以下路径出现（历史归档）：

```text
docs/migrations/remove-binance-market.md
CHANGELOG.md
module/binance/          （自引用：SPEC 历史描述、Task 文件名）
docs/report/
```

```bash
#!/usr/bin/env bash
set -euo pipefail
allow_re='docs/migrations/remove-binance-market.md|CHANGELOG.md|module/binance/|docs/report/'
forbidden_re='module/binance-market|github\.com/ZoneCNH/binance-market|binance-market|docs/services/binance-market-client-svc\.md'
hits="$(grep -R -n -E "$forbidden_re" . \
  --include='*.md' --include='*.go' --include='go.mod' --include='*.yaml' || true)"
if [ -n "$hits" ]; then
  disallowed="$(printf '%s\n' "$hits" | grep -v -E "$allow_re" || true)"
  [ -z "$disallowed" ] || { echo "FAIL: legacy binance-market reference"; echo "$disallowed"; exit 1; }
fi
echo "PASS: No legacy binance-market"
```

---

## 3. Gate: Client Must Not Import Server Internals

禁止：

```text
internal/client  ->  internal/server/*
cmd/binance-client -> internal/server/*
```

允许（分布式架构下 client 的合法依赖）：

```text
client -> natsx JetStream（网络发布，不是 Go import）
client -> module/domain_market（语义类型）
client -> pkg/config, pkg/observability（共享包）
```

```bash
grep -R -n -E 'internal/server|module/binance/server' \
  ./internal/client ./cmd/binance-client 2>/dev/null && {
  echo "FAIL: client imports server internals — violation of distributed boundary"
  exit 1
} || echo "PASS: Client boundary gate"
```

---

## 4. Gate: Server Must Not Import Client Internals

禁止：

```text
internal/server  ->  internal/client/*
cmd/binance-server -> internal/client/*
```

允许（分布式架构下 server 的合法依赖）：

```text
server -> natsx JetStream（网络订阅，不是 Go import）
server -> module/domain_market（语义类型）
server -> redisx, postgresx, taosx, kafkax, ossx, gin（存储和 API 层）
server -> pkg/config, pkg/observability（共享包）
```

```bash
grep -R -n -E 'internal/client|module/binance/client' \
  ./internal/server ./cmd/binance-server 2>/dev/null && {
  echo "FAIL: server imports client internals — violation of distributed boundary"
  exit 1
} || echo "PASS: Server boundary gate"
```

---

## 5. Gate: No cs Package as Runtime Dependency

> ⚡ v2.0.0 新增 — 分布式架构强制门禁

`internal/cs` 包是同进程桥接骨架，在 v2.0.0 中**必须删除**，不得成为 client 或 server 的运行时依赖。

禁止（运行时代码中引用 cs 包）：

```text
internal/client/*.go    import "github.com/ZoneCNH/binance/internal/cs"
internal/server/*.go    import "github.com/ZoneCNH/binance/internal/cs"
cmd/*/main.go           import "github.com/ZoneCNH/binance/internal/cs"
```

允许（仅历史参考）：

```text
internal/cs/doc.go      （归档标记，不被 import）
```

```bash
#!/usr/bin/env bash
set -euo pipefail
cs_hits="$(grep -R -n '"github.com/ZoneCNH/binance/internal/cs"' \
  ./internal/client ./internal/server ./cmd \
  --include='*.go' 2>/dev/null || true)"
if [ -n "$cs_hits" ]; then
  echo "FAIL: internal/cs package imported in runtime code — must be deleted in v2.0.0"
  echo "$cs_hits"
  exit 1
fi
echo "PASS: No cs package runtime import"
```

---

## 6. Gate: No Same-Process C/S Communication

> ⚡ v2.0.0 新增 — 分布式架构强制门禁

client 和 server 必须通过 natsx JetStream **网络通信**，禁止任何 Go interface 直调。

禁止模式：

```text
# 禁止：client 持有 IngestClient（server 接口）
type Sender struct { ingest IngestClient ... }

# 禁止：server Process() 被 client 直接调用
s.Process(ctx, cs.IngestRequest{...})

# 禁止：cmd 中同时 wire client + server（smoke 除外）
```

允许：

```text
# 允许：cmd/binance-smoke 可同进程集成（仅测试/演示用途）
# 允许：natsx embedded server 在 smoke 中使用
```

```bash
#!/usr/bin/env bash
set -euo pipefail

# 检查 client 是否持有 IngestClient/IngestServer interface
cs_interface="$(grep -R -n -E 'IngestClient|IngestServer' \
  ./internal/client ./cmd/binance-client \
  --include='*.go' 2>/dev/null || true)"
if [ -n "$cs_interface" ]; then
  echo "FAIL: client references IngestClient/IngestServer — same-process communication forbidden"
  echo "$cs_interface"
  exit 1
fi

# 检查 server 是否在 main 中同时 wire client connector
dual_wire="$(grep -R -n -E 'catalog\.|connector\.|Spot\.|spot\.' \
  ./cmd/binance-server \
  --include='*.go' 2>/dev/null || true)"
if [ -n "$dual_wire" ]; then
  echo "WARN: server cmd references client connector types — verify not same-process coupling"
  echo "$dual_wire"
fi

echo "PASS: No same-process C/S communication detected"
```

---

## 7. Gate: Binance Server Owns Binance-Specific Storage Only

> v2.0.0 变更 — 原 Gate 5「不做存储」已反转：server 现在**拥有** Binance 专属存储。

`binance/server` **允许**拥有：

```text
taosx     → Binance 行情时序数据（binance_ticks / binance_bars / binance_depth）
postgresx → Binance 合约元数据（binance_instruments）+ 幂等日志 + 审计
redisx    → Binance 行情热缓存（tick:{product_line}:{symbol}）
ossx      → Binance 历史数据归档
kafkax    → Binance 行情事件发布（binance.market.* topic）
```

`binance/server` **禁止**拥有：

```text
exchange-neutral storage engine（由 module/market_data 拥有）
cross-exchange query API（由 module/market_data 拥有）
strategy / signal storage（属于分析域）
order / portfolio storage（属于执行域）
```

```bash
forbidden_ownership="$(grep -R -n -E \
  'Owns.*exchange.neutral|cross.exchange.*query|strategy.*storage|order.*storage|portfolio.*storage' \
  module/binance --include='*.md' || true)"
[ -z "$forbidden_ownership" ] || {
  echo "FAIL: binance claims exchange-neutral/cross-exchange ownership"
  echo "$forbidden_ownership"; exit 1
}
echo "PASS: Storage ownership gate"
```

---

## 8. Gate: Wire Contract Externality

`module/binance` 的 runtime wire 仅允许使用 `natsx` subject + `domain_market.MarketFactEnvelope` JSON，不得定义独立的 proto 或 wire schema。

禁止：

```text
module/binance/proto/*
module/binance 定义本地 wire service/schema
module/binance 定义 canonical wire enum SSOT
```

```bash
#!/usr/bin/env bash
set -euo pipefail
[ ! -d "module/binance/proto" ] || { echo "FAIL: proto/ dir exists"; exit 1; }
proto_files="$(find module/binance -name '*.proto' 2>/dev/null || true)"
[ -z "$proto_files" ] || { echo "FAIL: .proto files found"; echo "$proto_files"; exit 1; }
echo "PASS: Wire contract externality gate"
```

---

## 9. Gate: Domain-Market Is Semantic Source

`module/binance` 不得独立定义 canonical market 语义。

```bash
#!/usr/bin/env bash
set -euo pipefail
pl_hits="$(grep -R -n -E \
  'ProductLine\s*(string|=|:).*\"(spot|usdm_futures|coinm_futures|options)\"' \
  module/binance --include='*.md' --include='*.go' || true)"
[ -z "$pl_hits" ] || { echo "FAIL: binance defines canonical ProductLine"; echo "$pl_hits"; exit 1; }
echo "PASS: Domain-Market gate"
```

---

## 10. Gate: Admin Surface Cannot Cross Module Boundaries

Client admin 只操作 client 本地状态。Server admin 只操作 server 本地状态。

```bash
#!/usr/bin/env bash
set -euo pipefail
client_cross="$(grep -R -n -E 'client.*admin.*(server|dispatch|idempotency)' \
  module/binance/client --include='*.md' --include='*.go' || true)"
[ -z "$client_cross" ] || { echo "FAIL: client admin crosses server boundary"; echo "$client_cross"; exit 1; }
server_cross="$(grep -R -n -E 'server.*admin.*(client|connector|spool)' \
  module/binance/server --include='*.md' --include='*.go' || true)"
[ -z "$server_cross" ] || { echo "FAIL: server admin crosses client boundary"; echo "$server_cross"; exit 1; }
echo "PASS: Admin boundary gate"
```

---

## 11. Gate: go.mod Dependency Compliance

> ⚡ v2.0.0 新增 — 确保分布式架构依赖声明规范

Client 二进制（`cmd/binance-client`）**禁止**将以下包声明为 `direct` 依赖（这些属于 server）：

```text
github.com/ZoneCNH/redisx
github.com/ZoneCNH/postgresx
github.com/ZoneCNH/taosx
github.com/ZoneCNH/kafkax
github.com/ZoneCNH/ossx
github.com/gin-gonic/gin
```

Server 二进制（`cmd/binance-server`）**必须**将以下包声明为 `direct` 依赖（禁止 `// indirect`）：

```text
github.com/ZoneCNH/natsx
github.com/ZoneCNH/redisx
github.com/ZoneCNH/postgresx
github.com/ZoneCNH/taosx
github.com/ZoneCNH/kafkax
github.com/ZoneCNH/ossx
github.com/gin-gonic/gin
```

```bash
#!/usr/bin/env bash
set -euo pipefail
# 检查 server 侧 infra 模块未被标记为 indirect
for mod in natsx redisx postgresx taosx kafkax ossx; do
  if grep -q "ZoneCNH/${mod}.*// indirect" go.mod 2>/dev/null; then
    echo "FAIL: ZoneCNH/${mod} is indirect — must be direct dependency of binance-server"
    exit 1
  fi
done
if grep -q 'gin-gonic/gin.*// indirect' go.mod 2>/dev/null; then
  echo "FAIL: gin-gonic/gin is indirect — must be direct dependency of binance-server"
  exit 1
fi
if ! grep -q 'gin-gonic/gin' go.mod 2>/dev/null; then
  echo "FAIL: gin-gonic/gin not in go.mod — required for binance-server REST API"
  exit 1
fi
echo "PASS: go.mod dependency compliance"
```

---

## 门禁汇总

| Gate | 名称 | 版本 | 类型 |
|:----:|------|:----:|:----:|
| 2 | No Legacy binance-market | v1.0 | 历史清理 |
| 3 | Client Must Not Import Server | v1.0 | 边界隔离 |
| 4 | Server Must Not Import Client | v1.0 | 边界隔离 |
| 5 | **No cs Package Runtime Dependency** | **v2.0 新增** | **分布式强制** |
| 6 | **No Same-Process C/S Communication** | **v2.0 新增** | **分布式强制** |
| 7 | Server Owns Binance-Specific Storage | v2.0 变更 | 所有权 |
| 8 | Wire Contract Externality | v2.0 变更 | 边界隔离 |
| 9 | Domain-Market Semantic Source | v1.0 | 语义边界 |
| 10 | Admin Surface Boundary | v1.0 | 边界隔离 |
| 11 | **go.mod Dependency Compliance** | **v2.0 新增** | **分布式强制** |
