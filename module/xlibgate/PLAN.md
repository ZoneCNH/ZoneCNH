# xlibgate Trust Alignment 实现计划

> 来源：[SPEC.md](./SPEC.md) v1.1.1
> 范围说明：本计划覆盖 FR-012~FR-019（trust 子命令组）的全部 8 个 Trust Alignment 检查。
> 生成日期：2026-06-14
> 环境：本仓库仅含文档；实现计划描述 xlibgate Go 项目中 trust 子命令组的开发阶段。
> 前置条件：xlib-standard 已完成 Gate 和 Evidence 标准定义（.repo-contract.yaml、FOUNDATION-DEPS.yaml schema）。

---

## 1. 依赖 DAG

```text
TASK-XLIBGATE-010 (trust 子命令框架: trust.go, trust_identity.go, 统一 JSON 输出)
│
├── TASK-XLIBGATE-011 (trust identity) ──────────────┐
├── TASK-XLIBGATE-012 (trust template-residue)       │
├── TASK-XLIBGATE-013 (trust release-consistency)    │
├── TASK-XLIBGATE-014 (trust maturity)               │
├── TASK-XLIBGATE-015 (trust import-boundary)        │
├── TASK-XLIBGATE-016 (trust testkit-prod-import)    │
├── TASK-XLIBGATE-017 (trust secret-redaction)       │
└── TASK-XLIBGATE-018 (trust fleet-status)           │
    │                                                 │
    └── TASK-XLIBGATE-019 (集成测试 + 文档) ─────────┘
```

---

## 2. 实现顺序

### Phase 0: Trust 框架（1 task，阻塞全部）

| Task              | 交付物                                                    | 依赖   | Effort |
| ----------------- | --------------------------------------------------------- | ------ | ------ |
| TASK-XLIBGATE-010 | cmd/trust.go, 统一 JSON 输出 schema（§9.3.1），reason_code 枚举 | —      | 1h     |

**里程碑**：
- `xlibgate trust --help` 输出 8 子命令列表
- 所有 trust 子命令输出统一 JSON 格式 `{check, repo, status, severity, findings, reason_code, evidence}`
- `reason_code` 10 值枚举完整定义在 `scanner/trust/` 公共包中

### Phase 1: 核心 Trust 检查器（8 tasks，全部可并行）

| Task              | 子命令                   | FR      | 交付物                                             | 依赖 | Effort |
| ----------------- | ------------------------ | ------- | -------------------------------------------------- | ---- | ------ |
| TASK-XLIBGATE-011 | trust identity            | FR-012  | cmd/trust_identity.go, scanner/trust/identity.go   | 010  | 2h     |
| TASK-XLIBGATE-012 | trust template-residue    | FR-013  | cmd/trust_template.go, scanner/trust/template.go   | 010  | 2h     |
| TASK-XLIBGATE-013 | trust release-consistency | FR-014  | cmd/trust_release.go, scanner/trust/release.go     | 010  | 3h     |
| TASK-XLIBGATE-014 | trust maturity            | FR-015  | cmd/trust_maturity.go, scanner/trust/maturity.go   | 010  | 1.5h   |
| TASK-XLIBGATE-015 | trust import-boundary     | FR-016  | cmd/trust_boundary.go, scanner/trust/boundary.go   | 010  | 3h     |
| TASK-XLIBGATE-016 | trust testkit-prod-import | FR-017  | cmd/trust_testkit.go, scanner/trust/testkit.go     | 010  | 1.5h   |
| TASK-XLIBGATE-017 | trust secret-redaction    | FR-018  | cmd/trust_secret.go, scanner/trust/secret.go       | 010  | 2h     |
| TASK-XLIBGATE-018 | trust fleet-status        | FR-019  | cmd/trust_fleet.go, scanner/trust/fleet.go         | 010  | 3h     |

**Phase 1 并行度：8**（全部仅依赖 010，互相无依赖）

**里程碑（每 Task）**：
- 对应 `check` 子命令可独立运行
- Exit code 正确：0=pass, 1=fail, 2=error
- JSON 输出符合 §9.3.1 schema
- `--help` 输出参数说明
- TASK-XLIBGATE-011：五源比对（README H1 / go.mod / .repo-contract.yaml / public_package / 身份声明）全部通过 ✓
- TASK-XLIBGATE-012：BR-010 五条禁止短语全部检测，xlib-standard 自跳
- TASK-XLIBGATE-013：七源版本一致性检测，--offline/--online 模式切换
- TASK-XLIBGATE-014：11 维工厂级判定逐项验证，拒绝单个百分比
- TASK-XLIBGATE-015：消费 FOUNDATION-DEPS.yaml，kernel stdlib-only 特殊检测
- TASK-XLIBGATE-016：生产路径检测 + 测试路径豁免，--strict 模式
- TASK-XLIBGATE-017：secrets/私有端点检测 + 输出脱敏
- TASK-XLIBGATE-018：20 模块聚合 → index.json，--summary-only 模式

### Phase 2: 集成 + 文档（1 task）

| Task              | 交付物                                              | 依赖               | Effort |
| ----------------- | --------------------------------------------------- | ------------------ | ------ |
| TASK-XLIBGATE-019 | 集成测试（trust 全链路），README.md trust 章节，CHANGELOG | 011–018            | 2h     |

**里程碑**：
- `xlibgate trust fleet-status --repos-root testdata/foundation-root --output /tmp/index.json` 生成正确聚合
- 所有 trust 子命令集成测试通过
- README.md 包含 trust 命令参考和快速开始
- TC-014~TC-029 全部有对应测试

---

## 3. 关键路径

```text
010 → 018 (fleet-status, 3h) → 019 (2h)
```

**关键路径工期**：1 + 3 + 2 = **6h**

---

## 4. 并行策略

### Phase 1（最大并行度 8）

所有 8 个 trust 检查器仅依赖 010（框架），互相无依赖，可完全并行开发。

### 并行收益

| 策略         | 总工时                  |
| ------------ | ----------------------- |
| 全串行       | 1 + 19 + 2 = **22h**    |
| Phase 1 并行 | 1 + 3 + 2 = **~6h**     |

---

## 5. 文件冲突分析

| 文件                          | 创建 Task | 冲突风险    |
| ----------------------------- | --------- | ----------- |
| cmd/trust.go                  | 010       | 无          |
| cmd/trust_identity.go         | 011       | 无          |
| cmd/trust_template.go         | 012       | 无          |
| cmd/trust_release.go          | 013       | 无          |
| cmd/trust_maturity.go         | 014       | 无          |
| cmd/trust_boundary.go         | 015       | 无          |
| cmd/trust_testkit.go          | 016       | 无          |
| cmd/trust_secret.go           | 017       | 无          |
| cmd/trust_fleet.go            | 018       | 无          |
| scanner/trust/identity.go     | 011       | 无          |
| scanner/trust/template.go     | 012       | 无          |
| scanner/trust/release.go      | 013       | 无          |
| scanner/trust/maturity.go     | 014       | 无          |
| scanner/trust/boundary.go     | 015       | 无          |
| scanner/trust/testkit.go      | 016       | 无          |
| scanner/trust/secret.go       | 017       | 无          |
| scanner/trust/fleet.go        | 018       | 无          |
| scanner/trust/common.go       | 010       | ⚠️ 只读     |
| cmd/root.go                   | 010       | ⚠️ 顺序执行 |

仅 `cmd/root.go` 在 010（注册 trust 父命令）中存在冲突风险。其余文件无冲突——8 个 checker 的文件完全正交。

---

## 6. 测试策略

| 测试类型     | 覆盖 Task   | 工具 / 命令                                                  |
| ------------ | ----------- | ------------------------------------------------------------ |
| 单元测试     | 011–018     | `go test -race -count=1 ./scanner/trust/...`                 |
| 验收测试     | 011–018     | TC-014~TC-029（Given/When/Then），每 FR 2 条                 |
| 边界测试     | 011–018     | §13 Edge Cases 中 10 个 trust 边界场景                        |
| Benchmark    | 011–018     | `go test -bench=. -benchmem ./...`（§17 Performance Budget） |
| 集成测试     | 019         | `xlibgate trust fleet-status --repos-root testdata/...`       |
| 覆盖率       | ALL         | `go tool cover` ≥ 80%                                        |
| Race 检测    | ALL         | `go test -race -count=1 ./...`                               |
| Self-check   | 019         | `xlibgate trust identity --repo .` → pass                    |

---

## 7. 风险与缓解

| 风险                                         | 概率 | 影响   | 风险值 | 关联 Task | 缓解                                      | 检测方式                            |
| -------------------------------------------- | :--: | :----: | :----: | :-------: | ----------------------------------------- | ----------------------------------- |
| FOUNDATION-DEPS.yaml schema 不稳定           | 20%  | Medium | 0.40   | 015       | Phase 1 前与 xlib-standard 对齐 schema    | YAML schema 校验                    |
| GitHub API 速率限制（release-consistency）   | 15%  | Low    | 0.15   | 013       | 默认 --offline 模式，--online 仅手动触发  | HTTP 403 检测 + 友好错误提示        |
| 20 模块硬编码在 fleet-status                 | 10%  | Low    | 0.10   | 018       | Phase 2 前评估是否需要 --expected-count    | --repos-root 下实际模块数验证       |
| .repo-contract.yaml 在部分模块中缺失         | 30%  | Medium | 0.60   | 011–018   | FR 中各检查均定义 CONTRACT_PARSE_ERROR 路径 | reason_code=CONTRACT_PARSE_ERROR     |
| maturity 11 维数据源不完整                   | 20%  | Medium | 0.40   | 014       | FR-015 拒绝单百分比，逐维独立判定         | 11 维逐项判定输出                   |
| 符号链接循环导致 secret-redaction 无限扫描   | 5%   | High   | 0.25   | 017       | 最大深度 3 层限制（Edge Cases 已定义）    | 深度计数器 + 循环检测               |
| BR-010 短语精确匹配误报（部分匹配）          | 10%  | Low    | 0.10   | 012       | BR-010 明确"精确字符串匹配，含标点和空格" | TC-016 验证（完整短语不匹配时不报） |

---

## 8. 总工时估算

| Phase    | Tasks   | 串行 Effort | 并行 Effort            |
| -------- | ------- | ----------- | ---------------------- |
| Phase 0  | 1       | 1h          | 1h                     |
| Phase 1  | 8       | 19h         | 3h（最长 task）        |
| Phase 2  | 1       | 2h          | 2h                     |
| **总计** | **10**  | **22h**     | **~6h**（充分利用并行）|

---

## 9. 与现有 check/l2 子命令的关系

trust 子命令组独立于 check 和 l2，不与现有代码共享运行时状态。以下跨组关系需要注意：

| 关系 | 说明 |
|------|------|
| trust import-boundary vs check imports | trust 版消费 FOUNDATION-DEPS.yaml（xlib-standard 定义），check 版消费 xlibgate.yaml。两者独立实现，不共享扫描逻辑。 |
| trust testkit-prod-import vs check imports（testkitx 规则） | trust 版有严格路径分类（生产/测试/示例）和 --strict 模式；check 版仅检查 deps.yaml 中的 testkitx 禁止规则。 |
| trust secret-redaction vs check all（secret_scan） | trust 版扫描 release/evidence 文档中的明文密钥；check 版通过 gitleaks 扫描源码。互补不重叠。 |
| trust fleet-status vs check all | check all 在单模块 CI 中运行；fleet-status 跨 20 模块聚合。两者输入粒度不同。 |
