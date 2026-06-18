# Foundation 基座模块规则矩阵规范

> 本文件是 `module/FOUNDATION-RULES.yaml` 的人类可读投影与编写规范。
>
> 本文件定义 20 个基座模块（+ L2.5 domainx）行为 / 安全 / 身份 / CI 门禁规则的编写规范、维度枚举、逐模块规则卡和执行性映射。
>
> **权威边界**：
> - 机器 SSOT 是 [`module/FOUNDATION-RULES.yaml`](../../module/FOUNDATION-RULES.yaml)（CI / xlibgate 消费）；本文件是其投影，规则条数与字段一一对应，不构成第二 SSOT。
> - 依赖方向规则（allowed_deps / forbidden_deps / forbidden_foundation_edges）仍归 [`module/FOUNDATION-DEPS.yaml`](../../module/FOUNDATION-DEPS.yaml)；本文件不重复。
> - 模块语义规则（FR / BR / WHEN-THEN）归各 `module/{m}/SPEC.md`；本文件规则通过 `source` 字段互引 SPEC 章节。
>
> 改进来源：[`docs/governance/improvements/20260618-foundation-rules/SPEC.md`](./improvements/20260618-foundation-rules/SPEC.md)。

最后更新：2026-06-18

---

## 1. 文档目的

`FOUNDATION-RULES.yaml` + 本文件共同回答一个问题：**19...21 个基座模块必须遵守哪些不变量，哪些被机器强制，哪些仅靠文档约束。**

它不是模块功能规格（那是 SPEC.md 的职责），也不是依赖矩阵（那是 FOUNDATION-DEPS.yaml 的职责），而是把散落在 CONSTITUTION / SPEC / foundation-modules.md / xlibgate 的**行为 / 安全 / 身份 / CI 门禁**规则收敛为单一可审计的规则矩阵。

### 1.1 三个文件的分工

| 文件 | 管什么 | 形式 | 执行性 |
| --- | --- | --- | --- |
| `module/FOUNDATION-DEPS.yaml` | 依赖方向（谁可 import 谁） | YAML | CI 强制（foundation-boundary-check.sh 等） |
| `module/FOUNDATION-RULES.yaml` | 行为 / 安全 / 身份 / CI 门禁 | YAML | 部分 CI 强制，部分 document-only（本文件 §26 诚实标注） |
| 各 `module/{m}/SPEC.md` | 模块语义（FR / BR / WHEN-THEN） | Markdown | 文档（靠 review + 测试） |

### 1.2 为什么需要本体系

审计发现（见 improvements SPEC §1）：

1. 规则覆盖不均（xlib-harness 226 行 vs xlibgate 1302 行）。
2. `FOUNDATION-DEPS.yaml` 的 `constraints` 块（5 条规则）**从未被任何 CI 消费**，是失真声明。
3. "行为语义"维度几乎无机器强制。

本体系把约束规则真正编码下来，并诚实标注每条规则的执行性，避免 FOUNDATION-TRACKER 式的失真。

---

## 2. 基本原则

### 2.1 单一 SSOT 不重复

- 依赖规则只在 FOUNDATION-DEPS.yaml；行为 / 安全 / 身份规则只在 FOUNDATION-RULES.yaml。
- 两文件通过规则的 `source` 字段互引，禁止语义重复。

### 2.2 诚实标注执行性

每条规则的 `evidence` 字段：

- **非空** = `machine-enforced`（由该 CI 脚本 / xlibgate 命令执行）。
- **空字符串** = `document-only`（仅 SPEC / 本文件约束，待后续 task 接入机器门禁）。

禁止把 document-only 规则标为已完成（这是 FOUNDATION-TRACKER 的教训）。

### 2.3 双格式兼容

YAML 必须同时被 PyYAML `safe_load` 与 Go `gopkg.in/yaml.v3` 解析。约束：

- 禁 tab 缩进（曾导致 yaml.v3 解析失败，见 `improvements/20260614-xlibgate-trust-session/SESSION.md`）。
- 字段名用 snake_case，与仓库既有约定一致。
- reason_code 对齐 `repo-contract.json` 的 stable reason_codes 风格。
- exit_code 遵循 0=pass / 1=fail / 2=error 语义。

### 2.4 投影一致

本文件（RULES.md）是 YAML 的人类投影：

- §3 通用规则表行数 == yaml `common_rules` 条数（12）。
- §5-§25 逐模块规则表行数 == yaml 对应 `modules.{m}.rules` 条数。
- 禁止在本文件增加 YAML 中没有的规则，反之亦然。

---

## 3. 通用规则矩阵

所有基座模块必须满足的 12 条通用规则（对应 yaml `common_rules`）。

| ID | 维度 | 规则 | 失败条件 | reason_code | 执行者 |
| --- | --- | --- | --- | --- | --- |
| CO-001 | toolchain | go.mod 声明 go 1.23 | go 版本 != 1.23 | GO_BASELINE_MISMATCH | foundation-deps-full-check.sh |
| CO-002 | boundary | 生产包不 import 业务域模块 | pkg/ import 业务域 | BUSINESS_IMPORT_IN_FOUNDATION | foundation-boundary-check.sh |
| CO-003 | boundary | 基座不反向依赖 x.go | import x.go | REVERSE_DEP_TO_COMPOSITION_ROOT | foundation-boundary-check.sh |
| CO-004 | observability | metrics label 仅低基数非敏感字段 | 含 order_id/api_key 等 | HIGH_CARDINALITY_OR_SENSITIVE_LABEL | anti-requirement-scan.sh |
| CO-005 | security | secret 脱敏 leak test 覆盖四处 | 测试缺失 | SECRET_REDACTION_LEAK_TEST_MISSING | document-only |
| CO-006 | security | 库代码不调用 log.Fatal/os.Exit/panic | 出现禁用调用 | LIBRARY_PROCESS_CONTROL_VIOLATION | anti-requirement-scan.sh |
| CO-007 | security | 不使用 unsafe 包 | import "unsafe" | UNSAFE_USAGE | anti-requirement-scan.sh |
| CO-008 | security | 无硬编码凭据 | 含 AWS key 等 | HARDCODED_SECRET | grep-guard.sh + xlibgate trust secret-redaction |
| CO-009 | security | 无硬编码地址端口 | 含 127.0.0.1:6379 等 | HARDCODED_ADDRESS_PORT | anti-requirement-scan.sh + grep-guard.sh |
| CO-010 | toolchain | go.mod 处于 tidy 状态 | go mod tidy 有 diff | GO_MOD_NOT_TIDY | foundation-deps-full-check.sh + xlibgate check gomod |
| CO-011 | identity | README H1 == go.mod module == repo name | 三者不一致 | IDENTITY_MISMATCH | xlibgate trust identity |
| CO-012 | release | release 声明须有完整 evidence | release=true 但 evidence 缺失 | RELEASE_EVIDENCE_MISSING | xlibgate check release + l2 release-check |

### 3.1 反例（CO-006）

不推荐：

```go
// 库代码中出现
func Init() {
    if err := setup(); err != nil {
        log.Fatal(err)   // ❌ 库不应控制进程生命周期
    }
}
```

推荐：

```go
func Init() error {
    if err := setup(); err != nil {
        return fmt.Errorf("init: %w", err)  // ✅ 把决策权交给调用方
    }
    return nil
}
```

---

## 4. 分层规则

各层级的层级不变量（不重复 §5-§25 的逐模块规则，只描述层级共性）。

| 层级 | 模块 | 层级不变量 |
| --- | --- | --- |
| L0 | kernel | stdlib-only；无隐藏 goroutine；无全局可变单例；retryx/obsx 严格限界 |
| L1 运行时 | configx / observex / resiliencx / schedulex / bootstrap | 仅向下依赖 kernel（+ bootstrap 依赖 L2 存储）；核心包不互 import；观测通过本地接口/adapter |
| L1 测试 | testkitx | 严格 test-only；不连真实外部系统；deterministic |
| 标准源 / 门禁 | xlib-standard / xlib-harness / xlib-evidence / xlibgate | 不 import 任何运行时模块；不承载业务运行 |
| 存储扩展 | redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex | 仅依赖 kernel + 各自客户端库；不跨存储引擎边界 |
| 契约 | contracts / transportx | spec-only / 不依赖实现包；contracts 定义 DTO，transportx 定义传输底座 |
| L2.5 | domainx | 仅依赖 kernel；仅值对象；归 L2.5 统计不计基座 |

---

## 5. kernel 规则卡（L0）

**定位**：L0 标准库扩展，所有上层模块的根依赖。

**拥有**：lifecycx / errx / healthx / obsx / retryx / shutdownx / syncx / timex / validx / versionx / contextx / contracttest。

**不拥有**：配置解析（→ configx）、观测供应商（→ observex）、存储 / 网络 / App runtime / 业务模型。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| KERNEL-001 | dependency | go list -deps 无非 stdlib 依赖 | KERNEL_NON_STDLIB | foundation-boundary-check.sh | constraints[stdlib-only] |
| KERNEL-002 | concurrency | 生产代码无未文档化 goroutine | KERNEL_HIDDEN_GOROUTINE | document-only | constraints[no-hidden-goroutine] |
| KERNEL-003 | state | 不持有包级全局可变单例 | KERNEL_GLOBAL_MUTABLE_STATE | document-only | kernel SPEC §7 BR |
| KERNEL-004 | boundary | retryx 仅 L0 primitive，不含 circuit/bulkhead | KERNEL_RETRYX_SCOPE_CREEP | document-only | kernel SPEC §7 BR |
| KERNEL-005 | boundary | obsx 仅极简 interface，不替代 observex | KERNEL_OBSX_SCOPE_CREEP | document-only | kernel SPEC §7 BR |

**检查命令**：`make boundary-testkit` / `scripts/check-stdlib-only.sh`（KERNEL-001）。

> ⚠️ KERNEL-002（no-hidden-goroutine）原标"已完成 CI check"但 `scripts/check-no-goroutine.sh` 实际不存在——见 FOUNDATION-TRACKER 修正 + FOLLOWUP-2。

---

## 6. configx 规则卡（L1）

**定位**：显式配置加载、合并、解码、校验、脱敏、来源追踪、effective manifest。

**拥有**：source / merge / decode / validate / redaction / provenance / manifest / hash / schema。

**不拥有**：secret backend（→ 后续 secrectx 或部署层 adapter）、全局配置中心（→ 无）、自动发现、业务配置结构体。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| CONFIGX-001 | freeze | 不新增 foundationx import | CONFIGX_FOUNDATIONX_REGRESSION | document-only | constraints[no-foundationx-new-usage] |
| CONFIGX-002 | boundary | 核心包不直连 Vault/KMS/K8s Secret | CONFIGX_SECRET_BACKEND_BOUNDARY | document-only | configx SPEC §5 |
| CONFIGX-003 | state | 不创建全局 Config 单例 | CONFIGX_GLOBAL_SINGLETON | document-only | configx SPEC §7 |
| CONFIGX-004 | boundary | 核心包不在后台启动 watch/reload goroutine | CONFIGX_HIDDEN_WATCH_GOROUTINE | document-only | configx SPEC §5 |
| CONFIGX-005 | test | provenance 是强制输出 | CONFIGX_PROVENANCE_NOT_MANDATORY | document-only | configx SPEC §21 |
| CONFIGX-006 | test | 相同输入产生稳定 manifest hash | CONFIGX_UNSTABLE_HASH | document-only | configx SPEC §21 |

> ⚠️ CONFIGX-001（no-foundationx-new-usage）原标"CI 门禁已就位"但 constraints 块未被任何 CI 消费——FOUNDATION-TRACKER Issue 4 修正。foundationx 已完全退出，本规则现在仅防回归。

---

## 7. observex 规则卡（L1）

**定位**：vendor-neutral 可观测性契约库。

**拥有**：Logger / Meter / Tracer / Field / Label / Redactor / LabelPolicy / health schema / noop / memory recorder。

**不拥有**：供应商 SDK 绑定、配置读取、全局客户端、告警路由、业务监控规则。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| OBSERVEX-001 | freeze | 不新增 foundationx import | OBSERVEX_FOUNDATIONX_REGRESSION | document-only | constraints[no-foundationx-new-usage] |
| OBSERVEX-002 | boundary | 核心包不硬绑定供应商 SDK | OBSERVEX_VENDOR_LOCK_IN | document-only | observex SPEC §5 |
| OBSERVEX-003 | boundary | 核心包不读取配置文件 | OBSERVEX_READS_CONFIG | document-only | observex SPEC §5 |
| OBSERVEX-004 | state | 不创建全局 logger/meter/tracer | OBSERVEX_GLOBAL_CLIENT | document-only | observex SPEC §5 |
| OBSERVEX-005 | observability | label policy checker 拦截高基数 | OBSERVEX_NO_LABEL_POLICY_CHECKER | document-only | observex SPEC §21 |
| OBSERVEX-006 | test | noop 未注入时安全运行 | OBSERVEX_NOOP_UNSAFE | document-only | observex SPEC §21 |

---

## 8. resiliencx 规则卡（L1）

**定位**：operational resilience runtime（timeout / retry / circuit / bulkhead / rate / fallback）。

**拥有**：弹性策略库、policy event 输出、idempotency guard。

**不拥有**：交易风控（→ risk-engine）、订单风险、交易所 SDK、调度（→ schedulex）。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| RESILIENCX-001 | boundary | 核心包不硬 import observex | RESILIENCX_HARD_OBSERVEX_IMPORT | document-only | constraints[no-hard-observex-core-import] |
| RESILIENCX-002 | identity | 身份为 runtime resilience，无 Standard Source 残留 | RESILIENCX_IDENTITY_REGRESSION | xlibgate trust template-residue | CONSTITUTION §1 P3 |
| RESILIENCX-003 | boundary | 不做交易风控 | RESILIENCX_TRADING_RISK_SCOPE_CREEP | document-only | CONSTITUTION §1 P3 |
| RESILIENCX-004 | boundary | 不直接 import exchange SDK | RESILIENCX_EXCHANGE_SDK_IMPORT | document-only | resiliencx SPEC §5 |
| RESILIENCX-005 | concurrency | 非幂等操作默认禁止自动 retry | RESILIENCX_NON_IDEMPOTENT_RETRY | document-only | resiliencx SPEC §7 BR |

> RESILIENCX-002 是身份修复红线（FOUNDATION-TRACKER Issue 1），由 xlibgate trust template-residue 机器强制。

---

## 9. schedulex 规则卡（L1）

**定位**：deterministic scheduler。

**拥有**：trigger / clock injection / scheduler runtime / misfire / overlap / jitter / EventSink / Locker interface / snapshot。

**不拥有**：分布式锁实现、exactly-once、消息队列、业务任务语义。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| SCHEDULEX-001 | boundary | 核心包不硬 import observex/resiliencx | SCHEDULEX_HARD_CROSS_IMPORT | document-only | constraints[no-hard-observex-or-resiliencx-core-import] |
| SCHEDULEX-002 | boundary | 不内置 Redis/Postgres 分布式锁实现 | SCHEDULEX_EMBEDDED_LOCK_IMPL | document-only | schedulex SPEC §5 |
| SCHEDULEX-003 | boundary | 不保证 exactly-once | SCHEDULEX_EXACTLY_ONCE_CLAIM | document-only | schedulex SPEC §5 |
| SCHEDULEX-004 | test | 所有调度决策通过 clock 注入 | SCHEDULEX_NO_CLOCK_INJECTION | document-only | schedulex SPEC §7 BR |
| SCHEDULEX-005 | test | timezone/DST golden test 防漂移 | SCHEDULEX_NO_DST_GOLDEN | document-only | schedulex SPEC §21 |

---

## 10. testkitx 规则卡（L1-test）

**定位**：测试专用能力库，不进入生产 import graph。

**拥有**：Fake / Fixture / Golden / Contract / Leak / Boundary / Manifest 测试工具包。

**不拥有**：生产 import graph、真实外部系统入口、业务 L2/L3/chaos/soak 总入口。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| TESTKITX-001 | boundary | 生产包不 import testkitx | TESTKITX_PROD_IMPORT | foundation-boundary-check.sh + xlibgate trust testkit-prod-import | constraints[no-production-import] |
| TESTKITX-002 | boundary | 不启动真实外部系统连接 | TESTKITX_REAL_EXTERNAL_SYSTEM | document-only | testkitx SPEC §5 |
| TESTKITX-003 | security | 不读取真实生产环境变量/密钥 | TESTKITX_PROD_ENV_READ | document-only | testkitx SPEC §18 |
| TESTKITX-004 | test | 测试路径 deterministic 避免 flake | TESTKITX_NON_DETERMINISTIC | document-only | testkitx SPEC §17 |

> TESTKITX-001 是唯一被 xlibgate trust testkit-prod-import 机器强制的 testkit 边界规则。

---

## 11. bootstrap 规则卡（L1）

**定位**：L1 通用进程组装层（configx 加载 + observex 初始化 + lifecycx 编排 + 存储适配器可选构造）。

**拥有**：Build 入口、App.Run/Shutdown、StoreSet 位掩码、信号捕获。

**不拥有**：admin HTTP server、连接池管理、领域语义、业务域模块、HTTP/gRPC server。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| BOOTSTRAP-001 | dependency | 仅向下依赖基座，不穿透到 L2.5/业务域 | BOOTSTRAP_UPWARD_DEP | foundation-boundary-check.sh | bootstrap SPEC §4.3 |
| BOOTSTRAP-002 | boundary | 不起 HTTP/gRPC server | BOOTSTRAP_STARTS_SERVER | document-only | bootstrap SPEC §4.2 |
| BOOTSTRAP-003 | boundary | 不 import 业务域模块 | BOOTSTRAP_BUSINESS_IMPORT | foundation-boundary-check.sh | bootstrap SPEC §4.2 |
| BOOTSTRAP-004 | boundary | 不承载领域语义 | BOOTSTRAP_DOMAIN_SEMANTICS | document-only | bootstrap SPEC §4.2 |
| BOOTSTRAP-005 | boundary | 存储适配器通过 StoreSet 位掩码按需启用 | BOOTSTRAP_STORES_BITMASK_VIOLATION | document-only | bootstrap SPEC §6 |

---

## 12. xlib-standard 规则卡（标准源）

**定位**：标准事实源 + Go Reference Template（Generator/Harness/Evidence 已拆分）。

**拥有**：标准事实源、Go Reference Template。

**不拥有**：运行时业务依赖、Generator/Harness/Evidence（→ xlib-harness / xlib-evidence）、模块实现身份。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| XLIBSTANDARD-001 | dependency | 不 import 任何运行时模块 | XLIBSTANDARD_RUNTIME_IMPORT | foundation-boundary-check.sh | forbidden_foundation_edges |
| XLIBSTANDARD-002 | identity | 声明 runtime_dependency: false | XLIBSTANDARD_RUNTIME_DEPENDENCY_CLAIM | document-only | CONSTITUTION §1 P2 |
| XLIBSTANDARD-003 | identity | 职责仅标准源 + Template | XLIBSTANDARD_SCOPE_CREEP | document-only | CONSTITUTION §1 P2 |

---

## 13. xlib-harness 规则卡（门禁）

**定位**：generator/scaffold/spec-lint/boundary-check/format-check/traceability-gate/template-validate 门禁执行器。

**拥有**：generate/scaffold、门禁执行。

**不拥有**：业务运行、评分策略定义（→ docs/governance/scoring/）、运行时依赖。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| XLIBHARNESS-001 | dependency | 不 import 任何运行时模块 | XLIBHARNESS_RUNTIME_IMPORT | foundation-boundary-check.sh | forbidden_foundation_edges |
| XLIBHARNESS-002 | identity | 职责仅 generator/scaffold/门禁执行 | XLIBHARNESS_SCOPE_CREEP | document-only | xlib-harness SPEC §6 |
| XLIBHARNESS-003 | boundary | 仅执行门禁，不定义评分策略 | XLIBHARNESS_EMBEDS_SCORING_POLICY | document-only | xlib-harness SPEC §5 |

---

## 14. xlib-evidence 规则卡（证据运行时）

**定位**：collect-coverage / generate-manifest / validate-manifest / remote-evidence / evidence-report。

**拥有**：证据收集与发布运行时。

**不拥有**：业务运行、门禁执行（→ xlib-harness）、运行时依赖。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| XLIBEVIDENCE-001 | dependency | 不 import 任何运行时模块 | XLIBEVIDENCE_RUNTIME_IMPORT | foundation-boundary-check.sh | forbidden_foundation_edges |
| XLIBEVIDENCE-002 | identity | 职责仅 evidence runtime | XLIBEVIDENCE_SCOPE_CREEP | document-only | xlib-evidence SPEC §6 |
| XLIBEVIDENCE-003 | security | release evidence 不含 secret | XLIBEVIDENCE_SECRET_LEAK | xlibgate trust secret-redaction | xlib-evidence SPEC §18 |

---

## 15. xlibgate 规则卡（门禁）

**定位**：import/gomod/baseline/release/repo-contract/reason_code/maturity claim/projection drift/blocker-aware factory gate 机器门禁。

**拥有**：check / l2 / trust 三组门禁命令。

**不拥有**：业务运行、运行时依赖、评分 rubric 定义（→ docs/governance/scoring/）。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| XLIBGATE-001 | dependency | 不 import 任何运行时模块 | XLIBGATE_RUNTIME_IMPORT | foundation-boundary-check.sh | forbidden_foundation_edges |
| XLIBGATE-002 | release | exit code 0/1/2 语义稳定 | XLIBGATE_UNSTABLE_EXIT_CODE | document-only | trust_hardening invariants |
| XLIBGATE-003 | release | reason_code 值稳定 | XLIBGATE_UNSTABLE_REASON_CODE | document-only | trust_hardening invariants |
| XLIBGATE-004 | release | factory-grade 须完整 evidence | FACTORY_GATE_BLOCKED | xlibgate trust maturity --factory | trust_hardening.rules |
| XLIBGATE-005 | release | 投影与 fact sources 匹配 | PROJECTION_DRIFT | audit-status.py + xlibgate trust fleet-status | trust_hardening.rules[projection-drift] |

> ⚠️ 已知缺陷：`xlibgate/internal/trust/boundary.go` 的 struct 用 `source/targets` 但 FOUNDATION-DEPS.yaml 用 `from/to`，Go 版 edge 检查实际失效（FOLLOWUP-1）。

---

## 16. redisx 规则卡（存储）

**定位**：Redis KeyBuilder/Options/KV/TTL/Cache/Hash/List/PubSub/Pipeline/Locker/Counter/RateLimit/Codec/Health。

**拥有**：Redis 客户端封装。

**不拥有**：跨存储引擎、业务语义、配置中心。

> ⚠️ redisx SPEC 缺独立 `## 依赖` 章节（REDISX-005），依赖边界散落 §1/§13/BR-010——FOLLOWUP-3 补建。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| REDISX-001 | dependency | 直接生产依赖限定 kernel + Redis 客户端 | REDISX_EXCESS_RUNTIME_DEP | foundation-boundary-check.sh | redisx SPEC §1 |
| REDISX-002 | boundary | 不跨越存储引擎边界 | REDISX_CROSS_STORAGE_ENGINE | foundation-boundary-check.sh | forbidden_foundation_edges |
| REDISX-003 | concurrency | 网络操作支持 context cancel/deadline | REDISX_NO_CONTEXT_ON_NETWORK | document-only | redisx SPEC §7 BR-003 |
| REDISX-004 | concurrency | Lock release 校验 token owner | REDISX_LOCK_NO_TOKEN_GUARD | document-only | redisx SPEC §7 BR-005 |
| REDISX-005 | identity | SPEC 须含独立 ## 依赖 章节 | REDISX_NO_DEPS_CHAPTER | document-only | FOLLOWUP-3 |

---

## 17. kafkax 规则卡（存储）

**定位**：Kafka 消息队列、事件流（driver-neutral API + kafka-go 生产驱动）。

**拥有**：Kafka 客户端封装、driver-neutral API。

**不拥有**：跨存储引擎、业务语义、具体 broker 锁定。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| KAFKAX-001 | dependency | 仅依赖 kernel + Kafka 客户端 | KAFKAX_EXCESS_RUNTIME_DEP | foundation-boundary-check.sh | allowed_deps |
| KAFKAX-002 | boundary | 不跨越存储引擎边界 | KAFKAX_CROSS_STORAGE_ENGINE | foundation-boundary-check.sh | forbidden_foundation_edges |
| KAFKAX-003 | boundary | API driver-neutral，生产驱动在 adapter | KAFKAX_DRIVER_LEAK | document-only | kafkax SPEC §1 |
| KAFKAX-004 | concurrency | 生产/消费支持 context cancel/deadline | KAFKAX_NO_CONTEXT_ON_NETWORK | document-only | kafkax SPEC §7 |

---

## 18. natsx 规则卡（存储）

**定位**：NATS Core + JetStream、Drain/reconnect/degraded health。

**拥有**：NATS 客户端封装、canonical FOUNDATIONX_NATS_* 配置。

**不拥有**：跨存储引擎、业务语义。BLK-001/BLK-002 open（正式四源 98+ arbiter 与生产 TLS gate 待补）。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| NATSX-001 | dependency | 仅依赖 kernel + NATS 客户端 | NATSX_EXCESS_RUNTIME_DEP | foundation-boundary-check.sh | allowed_deps |
| NATSX-002 | boundary | 不跨越存储引擎边界 | NATSX_CROSS_STORAGE_ENGINE | foundation-boundary-check.sh | forbidden_foundation_edges |
| NATSX-003 | concurrency | 支持 Drain/reconnect/degraded health | NATSX_NO_GRACEFUL_DEGRADATION | document-only | natsx SPEC §7 |
| NATSX-004 | identity | 配置用 FOUNDATIONX_NATS_* 前缀 | NATSX_NON_CANONICAL_CONFIG | document-only | natsx SPEC §11 |

---

## 19. postgresx 规则卡（存储）

**定位**：PostgreSQL 关系型存储、事务、迁移。

**拥有**：Postgres 客户端封装、事务、迁移。

**不拥有**：跨存储引擎、foundationx（已退出）。BLK-006 open（52.4% coverage + Docker integration skip）。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| POSTGRESX-001 | dependency | 仅依赖 kernel + Postgres 客户端 | POSTGRESX_EXCESS_RUNTIME_DEP | foundation-boundary-check.sh | allowed_deps |
| POSTGRESX-002 | boundary | 不跨越存储引擎边界 | POSTGRESX_CROSS_STORAGE_ENGINE | foundation-boundary-check.sh | forbidden_foundation_edges |
| POSTGRESX-003 | test | 支持事务（BEGIN/COMMIT/ROLLBACK） | POSTGRESX_NO_TRANSACTION_SUPPORT | document-only | postgresx SPEC §7 |
| POSTGRESX-004 | test | 支持迁移（migration） | POSTGRESX_NO_MIGRATION | document-only | postgresx SPEC §7 |
| POSTGRESX-005 | freeze | foundationx 依赖完全移除 | POSTGRESX_FOUNDATIONX_REGRESSION | document-only | FOUNDATION-TRACKER Issue 6 |

---

## 20. taosx 规则卡（存储）

**定位**：TDengine L2 adapter contract（pkg/taosx v1.0.1；真实 taosWS WebSocket 集成已验证）。

**拥有**：TDengine 客户端封装 contract。

**不拥有**：完整 ORM、业务语义、非 contract 实现。BLK-007 open（SPEC 67 偏低）。

> ⚠️ taosx 采用非标 23 节布局（BR 在 §6、安全 §15 仅 1 行、DoD §19 仅 4 行）——FOLLOWUP-3 对齐。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| TAOSX-001 | dependency | 仅依赖 kernel + TDengine 客户端 | TAOSX_EXCESS_RUNTIME_DEP | foundation-boundary-check.sh | allowed_deps |
| TAOSX-002 | boundary | 不跨越存储引擎边界 | TAOSX_CROSS_STORAGE_ENGINE | foundation-boundary-check.sh | forbidden_foundation_edges |
| TAOSX-003 | identity | 定位为 L2 adapter contract | TAOSX_SCOPE_CREEP | document-only | taosx SPEC §1 |
| TAOSX-004 | release | SPEC 完整度对齐 23 节 | TAOSX_SPEC_INCOMPLETE | document-only | BLK-007 + FOLLOWUP-3 |

---

## 21. ossx 规则卡（存储）

**定位**：Aliyun OSS 对象存储 L2 adapter（v1.0.2-alpha pkg/ossx 源码已交付；BLK-010 resolved）。

**拥有**：Aliyun OSS 客户端封装。

**不拥有**：通用 OSS、其他云厂商、真实 adapter（→ TASK-OSSX-005，当前非 factory）。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| OSSX-001 | identity | 定位为 Aliyun OSS（非通用） | OSSX_IDENTITY_DRIFT | xlibgate trust identity | ossx SPEC §1 |
| OSSX-002 | dependency | 仅依赖 kernel + Aliyun OSS 客户端 | OSSX_EXCESS_RUNTIME_DEP | foundation-boundary-check.sh | allowed_deps |
| OSSX-003 | boundary | 不跨越存储引擎边界 | OSSX_CROSS_STORAGE_ENGINE | foundation-boundary-check.sh | forbidden_foundation_edges |
| OSSX-004 | dependency | pkg/ossx 当前 stdlib-only | OSSX_PKG_NON_STDLIB | document-only | ossx FEATURES.md |
| OSSX-005 | release | 真实 Aliyun adapter 待补（非 factory） | OSSX_FACTORY_CLAIM_WITHOUT_ADAPTER | document-only | TASK-OSSX-005 |

---

## 22. clickhousex 规则卡（存储）

**定位**：ClickHouse OLAP 查询、批量写入（v1.0.1）。

**拥有**：ClickHouse 客户端封装、OLAP 查询、批量写入。

**不拥有**：跨存储引擎、OLTP 事务语义。BLK-003 open（公开 GitHub Release 未发布）。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| CLICKHOUSEX-001 | dependency | 仅依赖 kernel + ClickHouse 客户端 | CLICKHOUSEX_EXCESS_RUNTIME_DEP | foundation-boundary-check.sh | allowed_deps |
| CLICKHOUSEX-002 | boundary | 不跨越存储引擎边界 | CLICKHOUSEX_CROSS_STORAGE_ENGINE | foundation-boundary-check.sh | forbidden_foundation_edges |
| CLICKHOUSEX-003 | identity | 职责为 OLAP 查询 + 批量写入 | CLICKHOUSEX_SCOPE_CREEP | document-only | clickhousex SPEC §1 |
| CLICKHOUSEX-004 | release | 公开 Release 未发布，非 factory | CLICKHOUSEX_FACTORY_WITHOUT_RELEASE | document-only | BLK-003 |

---

## 23. contracts 规则卡（契约）

**定位**：跨域稳定端口/事件/DTO 契约（spec-only）。

**拥有**：MarketDataProvider/MacroDataProvider、Event、Topic、DTO、Breaking Change。

**不拥有**：运行时实现、任何模块依赖、领域模型全集、通用工具。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| CONTRACTS-001 | identity | spec-only，无运行时实现 | CONTRACTS_RUNTIME_IMPL | document-only | contracts SPEC §1 |
| CONTRACTS-002 | dependency | 不依赖任何模块实现 | CONTRACTS_RUNTIME_DEPENDENCY | foundation-boundary-check.sh | forbidden_foundation_edges |
| CONTRACTS-003 | boundary | DTO 创建后不可修改 | CONTRACTS_MUTABLE_DTO | document-only | contracts SPEC §7 TC-007 |
| CONTRACTS-004 | boundary | 事件 topic 常量唯一 | CONTRACTS_DUPLICATE_TOPIC | document-only | contracts SPEC §7 TC-004 |
| CONTRACTS-005 | boundary | DTO 字段有 snake_case JSON tag | CONTRACTS_NO_JSON_TAG | document-only | contracts SPEC §7 |
| CONTRACTS-006 | boundary | 端口接口方法数 3-5 | CONTRACTS_PORT_METHOD_COUNT | document-only | contracts SPEC §7 TC-006 |

---

## 24. transportx 规则卡（契约）

**定位**：应用通信底座规格基线（spec-only，production_import_allowed=false）。

**拥有**：Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry、conformance gate。

**不拥有**：具体 broker/client、协议 SDK、业务语义、领域模型全集。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| TRANSPORTX-001 | identity | spec-only baseline | TRANSPORTX_RUNTIME_CLAIM | document-only | transportx SPEC §1 |
| TRANSPORTX-002 | boundary | 不依赖具体 broker/client/协议 SDK | TRANSPORTX_BROKER_CLIENT_DEP | document-only | transportx SPEC §5 |
| TRANSPORTX-003 | boundary | 不定义领域模型全集 | TRANSPORTX_DOMAIN_MODEL | document-only | ARCHITECTURE.md |
| TRANSPORTX-004 | test | 含 conformance gate | TRANSPORTX_CONFORMANCE_GATE_MISSING | document-only | transportx SPEC §19 TX-GATE |
| TRANSPORTX-005 | dependency | 可依赖 contracts/configx/observex/resiliencx 公开接口 | TRANSPORTX_DISALLOWED_UPSTREAM | foundation-boundary-check.sh | allowed_deps |

---

## 25. domainx 规则卡（L2.5）

**定位**：执行域共享值对象（Order/Position/Trade/Portfolio/ExecutionReport + OrderState/OrderType/OrderSide 枚举）。

**拥有**：领域共享值对象。

**不拥有**：业务逻辑、行为方法、运行时依赖（→ 仅 kernel）。归 L2.5 统计，不计基座。

| ID | 维度 | 规则 | reason_code | 执行者 | source |
| --- | --- | --- | --- | --- | --- |
| DOMAINX-001 | dependency | 仅依赖 kernel | DOMAINX_EXCESS_DEP | foundation-boundary-check.sh | allowed_deps |
| DOMAINX-002 | identity | 仅含值对象，无业务逻辑 | DOMAINX_BEHAVIOR_SCOPE_CREEP | document-only | domainx SPEC §1 |
| DOMAINX-003 | boundary | 归 L2.5，业务域通过 contracts/transportx 保持跨域边界 | DOMAINX_LAYER_MISCLASSIFICATION | document-only | module/README.md |

---

## 26. 机器可执行 vs 文档规则映射

诚实标注执行性（不复刻 FOUNDATION-TRACKER 失真声明）。

### 26.1 machine-enforced（CI / xlibgate 强制）

| 规则类别 | 执行者 | 覆盖规则 |
| --- | --- | --- |
| 依赖边界（dependency / boundary 的 import 侧） | foundation-boundary-check.sh | CO-002, CO-003, KERNEL-001, BOOTSTRAP-001/003, 所有 *-001, *-002 存储规则 |
| Go baseline / go mod tidy | foundation-deps-full-check.sh + xlibgate | CO-001, CO-010 |
| 进程控制 / unsafe / 地址端口 | anti-requirement-scan.sh + grep-guard.sh | CO-004, CO-006, CO-007, CO-009 |
| 硬编码凭据 | grep-guard.sh + xlibgate trust secret-redaction | CO-008, XLIBEVIDENCE-003 |
| 模块身份 | xlibgate trust identity | CO-011, OSSX-001 |
| 身份不回流 | xlibgate trust template-residue | RESILIENCX-002 |
| 发布 evidence / factory-grade | xlibgate check release + l2 release-check + trust maturity | CO-012, XLIBGATE-004 |
| 投影漂移 | audit-status.py + xlibgate trust fleet-status | XLIBGATE-005 |
| testkitx 隔离 | foundation-boundary-check.sh + xlibgate trust testkit-prod-import | TESTKITX-001 |

### 26.2 document-only（仅 SPEC / 本文件约束，待 FOLLOWUP-2 接入）

以下规则目前无机器门禁，靠 review + 测试：

- **原 constraints 块的 5 条**（KERNEL-002 / CONFIGX-001 / OBSERVEX-001 / RESILIENCX-001 / SCHEDULEX-001）：FOUNDATION-TRACKER 原标"CI 已就位"但 constraints 块从未被消费。本体系已把它们重新编码到 YAML，待 FOLLOWUP-2 编写实际执行器。
- **行为语义类**（state / concurrency 的具体行为、freeze 的回归检测、test 的 golden/deterministic）。
- **边界语义类**（不内置锁实现 / 不起 server / 不定义领域模型 等）。

> **原则**：document-only 规则必须在 SPEC.md 有对应 BR / Non-goals，且本文件规则卡可追溯。禁止把 document-only 标为"已完成 CI check"。

---

## 27. 与 FOUNDATION-DEPS.yaml 的边界

明确分工，避免双 SSOT。

| 规则维度 | 归属 | 原因 |
| --- | --- | --- |
| allowed_deps / forbidden_deps | FOUNDATION-DEPS.yaml | 已被 CI 消费，机器强制 |
| forbidden_foundation_edges | FOUNDATION-DEPS.yaml | 已被 foundation-boundary-check.sh 消费 |
| go_baseline | FOUNDATION-DEPS.yaml | 已被 foundation-deps-full-check.sh 消费 |
| interface_only_integrations | FOUNDATION-DEPS.yaml | 文档约束，但语义属依赖 |
| trust_hardening | FOUNDATION-DEPS.yaml | 已被 xlibgate trust 消费 |
| **constraints**（5 条） | **FOUNDATION-RULES.yaml（重新编码）** | 原块从未被消费；本体系让它真正可执行 |
| **行为 / 安全 / 身份 / CI 门禁** | **FOUNDATION-RULES.yaml** | FOUNDATION-DEPS.yaml 不覆盖 |
| modules 元数据（path / layer / description） | FOUNDATION-DEPS.yaml | 模块身份元数据 |

**互引机制**：FOUNDATION-RULES.yaml 每条规则的 `source` 字段指向 FOUNDATION-DEPS.yaml 的键或 SPEC.md 章节；不复制内容。

---

## 28. 规则维护检查清单

新增或修改规则时检查：

```md
- [ ] 规则是否属于行为/安全/身份/CI 门禁（而非依赖方向）？
      依赖方向归 FOUNDATION-DEPS.yaml，不重复。
- [ ] 规则是否与现有 SPEC.md 的 BR / Non-goals 一致？
      source 字段必须指向具体 SPEC 章节。
- [ ] id 是否符合 ^[A-Z][A-Z0-9]*-\d{3}-[A-Za-z0-9-]+$ 且全局唯一？
- [ ] dimension 是否在 11 个枚举值内？
- [ ] reason_code 是否匹配 ^[A-Z][A-Z0-9_]+$ 且不与现有重复？
- [ ] exit_code 是否为 0/1/2？
- [ ] evidence 字段是否诚实标注（非空 = machine-enforced，空 = document-only）？
- [ ] document-only 规则在 SPEC.md 是否有对应 BR？
- [ ] 本文件（RULES.md）对应规则卡是否同步更新（条数一致）？
- [ ] schema 校验是否通过（jsonschema validate）？
- [ ] 模块键名是否与 FOUNDATION-DEPS.yaml 一致？
```

---

## 29. 最终质量标准

一个合格的 FOUNDATION-RULES 体系应满足：

```md
- 每条规则可追溯到 CONSTITUTION / FOUNDATION-DEPS.yaml / SPEC.md
- 每条规则诚实标注执行性（machine-enforced 或 document-only）
- document-only 规则不在跟踪器标为"已完成 CI check"
- YAML 可被 PyYAML 与 yaml.v3 双解析
- schema 校验通过
- 21 模块键名与 FOUNDATION-DEPS.yaml 完全一致
- RULES.md 规则表行数与 YAML 规则条数一一对应
- 依赖规则不与 FOUNDATION-DEPS.yaml 重复
```

规则体系应该随模块演进，但不应失真。一个好的规则体系应该让读者快速知道：

```md
这个模块必须满足哪些不变量
哪些被机器强制
哪些靠文档约束
违反时返回什么 reason_code
规则来自哪个权威文档
```

---

## 相关文档

| 文档 | 定位 |
| --- | --- |
| [`module/FOUNDATION-RULES.yaml`](../../module/FOUNDATION-RULES.yaml) | 机器 SSOT（CI / xlibgate 消费） |
| [`.foundationx/foundation-rules.schema.json`](../../.foundationx/foundation-rules.schema.json) | YAML 结构校验（JSON Schema 2020-12） |
| [`module/FOUNDATION-DEPS.yaml`](../../module/FOUNDATION-DEPS.yaml) | 依赖方向规则 SSOT（分工边界） |
| [`docs/governance/improvements/20260618-foundation-rules/SPEC.md`](./improvements/20260618-foundation-rules/SPEC.md) | 本体系改进来源 |
| [`docs/governance/ROADMAP-RULES.md`](./ROADMAP-RULES.md) | 配套规则文档范式先例 |
| [`CONSTITUTION.md`](../../CONSTITUTION.md) | 系统宪法（规则的上游权威） |
| [`docs/ai/agent-rules.md`](../ai/agent-rules.md) | AI 代理编码规则（行为约束补充） |
| [`docs/governance/anti-requirements.md`](./anti-requirements.md) | 反需求（CO-006/007/009 来源） |
