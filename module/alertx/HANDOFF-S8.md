# alertx 生产化 — S8 交接文档

> 创建：2026-06-26（S0-S7 完成后，交接给 S8 Code 实现）
> 目标：把 alertx 从 5% 占位推进到 v1.0.0 生产可发布
> 前序阶段：S0-S7 全部完成（7 个 gate PASS，composite ≥98）

---

## 1. 当前状态（S0-S7 已完成）

### Gate 记录

| 阶段 | gate | composite | commit（文档仓 feat/alertx-v1.0.0） |
| --- | --- | --- | --- |
| S0 决策 | — | — | ADR-001-foundations.md + STATUS.md |
| S1 contracts 契约 | — | — | contracts 仓 d40896e + 文档仓 e0ce7c1e |
| S2 SPEC | — | — | cd7dfea7（23 节） |
| S3 Spec gate | PASS | 98 | a8735ca2（Status→Approved）+ 1ac32e82（rule-scorer 修复） |
| S4 Matrix gate | PASS | 98 | a680a3e1（TRACEABILITY.md） |
| S5 Tasks gate | PASS | 98 | 8 个 TASK-ALERTX-001~008.md |
| S6 Plan gate | PASS | 98 | IMPLEMENTATION-PLAN.md |
| S7 Prompt gate | PASS | 98 | 8 个 PROMPT-ALERTX-001~008.md |

### 关键决策（用户已确认，不可推翻）

| 决策点 | 选择 | 来源 |
| --- | --- | --- |
| 覆盖率门禁 | **80%**（非 100%，STATUS 已修正） | 宪法 §5.1 L1 运行时分级 |
| 管线执行 | **Claude 单源 + rules scorer + arbiter --force** | 缺 codex/copilot 源，用 --force 推进 |
| 契约归属 | **contracts 新增 alert 契约**（已完成，pkg/contracts/alert.go） | 跨域稳定输入面 |
| 范围/版本 | **完整 v1.0.0 生产级** | 三类告警 + 全渠道 + Soak + 毕业 active |

### 架构基线（ADR-001，不可变）

- **层级**：横切消费者（layer: business / domain: crosscut），单向下游依赖 observex + contracts
- **订阅**：双订阅（observex 导出流 + 业务 contracts.AlertEvent）
- **规则**：YAML DSL（`metric:op:value` 三段式 + AND 组合）
- **首版**：runtime tag v1.0.0

---

## 2. S8 精确接续点

### 仓库位置

- **alertx 代码仓**：`/home/workspace/alertx`（**当前不存在，需新建 + git init**）
- **开发分支**：`/home/workspace/alertx/.worktree/workspaces/feat/alertx-v1.0.0`（§0 分支纪律）
- **contracts 依赖**：`/home/workspace/contracts`（feat/contracts-alert-types 分支，pkg/contracts/alert.go 已实现，待 v1.6.0 tag）

### Task 实现顺序（关键路径，依赖链无环）

```text
001 骨架 → 002 规则引擎 → 003 去重 → 004 分级+生命周期 → 005 通知(webhook)
                                                                  ↓
006 双订阅（P1，002 后可与 003-005 并行）────────────────────→ 007 入口 → 008 渠道+Soak+CI
```

| Task | scope | files | depends | effort |
| --- | --- | --- | --- | --- |
| 001 | 仓骨架（go.mod/version/errors/options） | 4 | — | 1h |
| 002 | 规则引擎（DSL+评估+热加载）[关键] | 4 | 001 | 4h |
| 003 | 去重抑制（DedupKey+窗口） | 2 | 002 | 2h |
| 004 | 分级+生命周期+内存 Store | 4 | 003 | 3h |
| 005 | 通知路由（Notifier+webhook） | 3 | 004 | 3h |
| 006 | 双订阅（observex+业务归一化） | 4 | 002 | 3h |
| 007 | health+指标+cmd 入口+Dockerfile | 4 | 005,006 | 3h |
| 008 | email/pagerduty+Soak+AT-007+CI | 6 | 007 | 5h |

### S8 起手第一步

```bash
# 1. 新建 alertx 仓 + git init
mkdir -p /home/workspace/alertx && cd /home/workspace/alertx && git init

# 2. 创建开发分支（worktree 或 feature branch，§0 纪律）
git checkout -b feat/alertx-v1.0.0

# 3. 实现 TASK-001 骨架
#    详见 module/alertx/prompt/PROMPT-ALERTX-001.md（Context Packet）
#    和 module/alertx/tasks/TASK-ALERTX-001.md（验收标准）
```

### 每个 Task 的实现流程（S8 子循环）

```text
读 PROMPT-ALERTX-NNN.md（Context Packet）
  → 读 TASK-ALERTX-NNN.md（acceptance_criteria）
  → 读 SPEC.md 对应章节（FR/BR/接口）
  → 实现代码 + 测试（三段式命名 + TC 编号）
  → 验证：go build && go vet && go test -race && gofmt -l
  → 覆盖率 ≥80%
  → code gate: rule-scorer.py code alertx + claude 自评 + arbiter.py alertx code --force
  → gate pass → 更新 TRACEABILITY.md 对应 FR Status ⏳→✅
  → 下一个 task
```

---

## 3. 关键制品位置（S8 必读）

| 制品 | 路径 | 用途 |
| --- | --- | --- |
| **SPEC** | `/home/workspace/ZoneCNH/module/alertx/SPEC.md` | 23 节权威规格（Status: Approved） |
| **PLAN** | `/home/workspace/ZoneCNH/module/alertx/IMPLEMENTATION-PLAN.md` | 实现步骤+文件归属+技术决策+回滚 |
| **PROMPT** | `/home/workspace/ZoneCNH/module/alertx/prompt/PROMPT-ALERTX-001~008.md` | 每 task 的 Context Packet |
| **TASK** | `/home/workspace/ZoneCNH/module/alertx/tasks/TASK-ALERTX-001~008.md` | 每 task 的验收标准 |
| **TRACEABILITY** | `/home/workspace/ZoneCNH/module/alertx/TRACEABILITY.md` | FR→AC→TC 映射（Status ⏳ 待 S8 翻 ✅） |
| **ADR-001** | `/home/workspace/ZoneCNH/module/alertx/ADR-001-foundations.md` | 架构基线（双订阅/YAML DSL/v1.0.0） |
| **contracts alert.go** | `/home/workspace/contracts/pkg/contracts/alert.go` | 已实现的契约类型（AlertEvent/AlertRule/Severity/AlertStatus/AlertSink/AlertRuleStore） |
| **observex 范本** | `/home/workspace/observex/` | 生产级 Go 模块布局范本（库布局，alertx 需加 cmd/ + Dockerfile） |
| **observex SPEC** | `/home/workspace/ZoneCNH/module/observex/SPEC.md` | FR/BR/接口写法范式参照 |

---

## 4. 技术约束（不可违反）

### 代码规范（go-coding-standards.md 13 维度）

- 包全小写单单词（alertx）、文件 snake_case、缩写保持大小写（HTTPServer）
- 接口 3-5 方法（≤7）、编译期断言 `var _ Interface = (*impl)(nil)`
- 错误 sentinel + `%w`，格式 `"alertx: <op>: <detail>"`，消息全小写不以标点结尾
- 禁 `log.Fatal`/`os.Exit`（非 main）、禁 `panic`（非测试）、禁 `_` 忽略 error
- 结构化日志（zap/slog）+ observex.Redactor 脱敏
- context 第一参数不存字段、goroutine 退出路径明确

### 测试硬约束

- 单元覆盖率 **≥80%**（非 100%，STATUS 已修正）
- 公共接口 + 错误路径 **100%** 覆盖
- **-race 零 data race**
- 三段式命名 `TestFunc_Scenario_ExpectedBehavior` + TC 编号
- Benchmark 守护 §17 性能预算（评估 <1ms、端到端 <100ms）
- 集成测试 `//go:build integration`（AT-007 横切贯穿）
- Soak ≥10min（常驻引擎，监控内存/goroutine 泄漏）
- Fuzz：DSL 解析函数补 `*_fuzz_test.go`

### CI Gate（照搬 observex 4 件套）

- `make ci`：fmt/vet/lint/test/race/examples/boundary/security/contracts
- golangci-lint（errcheck/govet/staticcheck/gocyclo≤15）零错误
- govulncheck + gitleaks 零命中
- 覆盖率 <80% 阻塞合并

### go.mod 依赖（版本对齐，来自 composer go.mod）

- `github.com/ZoneCNH/contracts v1.6.0-alert`（本地 replace → /home/workspace/contracts，待 contracts 发 v1.6.0 tag）
- `github.com/ZoneCNH/observex v0.3.1+`
- `github.com/ZoneCNH/kernel v1.0.0` / `configx v1.0.0` / `resiliencx v0.4.9`
- `gopkg.in/yaml.v3`（DSL 解析）

---

## 5. 评分基础设施（S8 code gate 用）

```bash
# 三个脚本都在 /home/workspace/ZoneCNH/scripts/
# 状态目录：.omc/state/pipeline/alertx/{stage}/{scores/,verdict.json}

# code gate 流程：
python3 scripts/rule-scorer.py code alertx --runtime claude    # 生成 rules.json
# + 手写 claude.json（对抗性自评，按 RUBRIC-code.md）
python3 scripts/arbiter.py alertx code --runtime claude --force # 仲裁（--force 因缺 codex/copilot）
```

**RUBRIC-code.md 8 维度**：实现完整性/接口契约/测试质量/错误处理/并发安全/性能/可观测性/文档。

---

## 6. S9 终态（S8 全部 task 完成后）

### 验收（DoD）

- TRACEABILITY.md 所有 FR/BR Status ⏳→✅
- AT-007 集成测试 PASS
- `make ci` + `make ci-extended` 全绿
- 覆盖率 ≥80%、-race 零、Benchmark 达标、Soak ≥10min

### Release v1.0.0（复刻 observex 全套证据链）

1. `pkg/alertx/version.go` Version = v1.0.0
2. CHANGELOG.md 含 `## v1.0.0 - 2026-06-26`
3. `make release-final-check VERSION=v1.0.0` 全绿
4. `release/manifest/v1.0.0.json` + sha256（11 checks passed）
5. git tag v1.0.0 → GitHub Release

### 毕业 proposed → active（ZoneCNH 文档仓 PR）

- `module/registry.yaml:898` lifecycle: proposed → active + release 块
- `module/FOUNDATION-DEPS.yaml` 补 alertx 依赖边
- `STATUS.md:296` 5% → 100%
- PR 附：SPEC Approved 证据 + CI pass + GitHub Release 链接

---

## 7. 已知风险（S8 注意）

| 风险 | 缓解 |
| --- | --- |
| contracts v1.6.0 未发 tag | TASK-001 用 replace 指向 /home/workspace/contracts，发 tag 后改 require |
| observex Exporter 接口与订阅假设不符 | TASK-006 先验证 observex Exporter 签名 |
| Soak 发现内存泄漏 | TASK-008 Soak harness 监控，泄漏则修复重跑 |
| webhook 集成测试需 HTTP server | 用 httptest.Server mock，不依赖外部 |

---

## 8. 新对话接续 prompt（直接复制使用）

```
继续 alertx 生产化项目的 S8 Code 阶段。

背景：S0-S7 已全部完成（7 个 gate PASS），规格→制品全链闭合。详见交接文档：
/home/workspace/ZoneCNH/module/alertx/HANDOFF-S8.md

任务：在 /home/workspace/alertx 新建 Go 仓，按 TASK-ALERTX-001~008 顺序实现完整代码 + 测试 + CI。

起手：从 TASK-001 开始（读 PROMPT-ALERTX-001.md → TASK-ALERTX-001.md → SPEC §8/§9/§11/§13），
每个 task 完成后验证 + code gate，全部完成后进入 S9 验收 + Release v1.0.0。

关键约束见 HANDOFF-S8.md §4（代码规范/测试/CI/依赖版本）。
```
