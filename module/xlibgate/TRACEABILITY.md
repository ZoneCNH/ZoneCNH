# xlibgate 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。
> 权威完整版见 [matrix/TRACEABILITY.md](./matrix/TRACEABILITY.md)（v1.6，2026-06-29）。

Last-Updated: 2026-06-30
Source: module/xlibgate/SPEC.md v1.2.0
Runtime: /home/xlibgate

---

## §1 功能需求追溯（FR）

| FR ID | Description | AC | TC | Task | Status |
| ----- | ----------- | --- | --- | --- | ------ |
| FR-001 | check imports：扫描 import 语句，检测禁止的依赖方向 | AC-001 | TC-001 | TASK-XLIBGATE-002 | ✅ |
| FR-002 | check gomod：go mod tidy 检查 go.mod 整洁度 | AC-002 | TC-002 | TASK-XLIBGATE-003 | ✅ |
| FR-003 | check baseline：验证 go 指令版本一致性 | AC-003 | TC-003 | TASK-XLIBGATE-004 | ✅ |
| FR-004 | check release：收集和校验 release evidence | AC-004 | TC-006 | TASK-XLIBGATE-005 | ✅ |
| FR-005 | check all：执行所有子检查，部分失败继续执行 | AC-005 | TC-004, TC-005, TC-008 | TASK-XLIBGATE-006 | ✅ |
| FR-006 | 输出格式：支持 JSON 和 human-readable | AC-006 | TC-007 | TASK-XLIBGATE-006 | ✅ |
| FR-007 | l2 validate-manifest：校验 L2 能力清单 | AC-010 | TC-009 | TASK-XLIBGATE-009 | ✅ |
| FR-008 | l2 plan：生成 test-plan.json artifact | AC-011 | TC-010 | TASK-XLIBGATE-009 | ✅ |
| FR-009 | l2 check-contracts：验证契约测试证据 | AC-012 | TC-011 | TASK-XLIBGATE-009 | ✅ |
| FR-010 | l2 check-evidence：验证 L2 evidence 文件存在 | AC-013 | TC-012 | TASK-XLIBGATE-009 | ✅ |
| FR-011 | l2 release-check：完整 L2 发布就绪判定 | AC-014 | TC-013 | TASK-XLIBGATE-009 | ✅ |
| FR-012 | trust identity：五源身份比对 | AC-015 | TC-014, TC-015 | TASK-XLIBGATE-011 | ✅ |
| FR-013 | trust template-residue：扫描模板身份短语 | AC-016 | TC-016, TC-017 | TASK-XLIBGATE-012 | ✅ |
| FR-014 | trust release-consistency：七源版本一致性校验 | AC-017 | TC-018, TC-019 | TASK-XLIBGATE-013 | ✅ |
| FR-015 | trust maturity --factory：11 维工厂级成熟度判定 | AC-018 | TC-020, TC-021 | TASK-XLIBGATE-014 | ✅ |
| FR-016 | trust import-boundary：基于 FOUNDATION-DEPS.yaml 的边界检查 | AC-019 | TC-022, TC-023 | TASK-XLIBGATE-015 | ✅ |
| FR-017 | trust testkit-prod-import：检测生产代码 testkitx import | AC-020 | TC-024, TC-025 | TASK-XLIBGATE-016 | ✅ |
| FR-018 | trust secret-redaction：扫描 release/evidence 文档密钥 | AC-021 | TC-026, TC-027 | TASK-XLIBGATE-017 | ✅ |
| FR-019 | trust fleet-status：20 模块舰队状态聚合 | AC-022 | TC-028, TC-029 | TASK-XLIBGATE-018 | ✅ |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Status |
| ----- | ---- | -------- | ---- | ------ |
| BR-001 | 标准化 exit code：0=pass, 1=fail, 2=error | TC-004, TC-005 | TASK-XLIBGATE-006 | ✅ |
| BR-002 | import 规则从 deps.yaml 读取，不硬编码 | FR-001 WHEN/THEN | TASK-XLIBGATE-002 | ✅ |
| BR-003 | baseline 从配置或 --expected 参数获取 | FR-003 WHEN/THEN | TASK-XLIBGATE-004 | ✅ |
| BR-004 | evidence schema 与 xlib_standard 一致 | FR-004 schema 验证 | TASK-XLIBGATE-005 | ✅ |
| BR-005 | secret 扫描使用 gitleaks 作为底层工具 | TC-008 | TASK-XLIBGATE-006 | ✅ |
| BR-006 | check all 须执行所有子检查（fail-fast 禁用） | TC-004, TC-005 | TASK-XLIBGATE-006 | ✅ |
| BR-007 | JSON 输出须含 machine-readable status 字段 | TC-007 | TASK-XLIBGATE-006 | ✅ |
| BR-008 | human-readable 输出须含文件路径和行号 | TC-001, TC-002, TC-008 | TASK-XLIBGATE-002 | ✅ |
| BR-009 | FOUNDATION-DEPS.yaml schema 与 xlib_standard 一致 | FR-001 config 加载 | TASK-XLIBGATE-002 | ✅ |
| BR-010 | 禁止模板身份短语：仅 xlib_standard 可含 | TC-016, TC-017 | TASK-XLIBGATE-012 | ✅ |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Status |
| ------ | -------- | ----------- | ---- | ------ |
| NFR-001 | 性能 | 全量门禁性能（50 模块）< 30s | TASK-XLIBGATE-006 | ⚠️ |
| NFR-002 | 性能 | import 扫描性能（50 模块）< 10s | TASK-XLIBGATE-002 | ⚠️ |
| NFR-003 | 性能 | go.mod 检查性能（50 模块）< 5s | TASK-XLIBGATE-003 | ⚠️ |
| NFR-004 | 性能 | baseline 检查性能（50 模块）< 5s | TASK-XLIBGATE-004 | ⚠️ |
| NFR-005 | 性能 | JSON 报告生成性能 < 100ms | TASK-XLIBGATE-006 | ⚠️ |
| NFR-006 | 性能 | 内存占用 < 100MB | TASK-XLIBGATE-006 | ⚠️ |
| NFR-007 | 质量 | 测试覆盖率 >= 80% | TASK-XLIBGATE-006 | ✅ |
| NFR-008 | 安全 | 无硬编码密钥（gitleaks 零命中） | TASK-XLIBGATE-006 | ✅ |
| NFR-009 | 安全 | secret 扫描不泄露敏感数据 | TASK-XLIBGATE-006 | ⚠️ |
| NFR-010 | 架构 | 无 Foundation 运行时依赖 | TASK-XLIBGATE-006 | ✅ |
| NFR-011~018 | 性能 | trust 子命令 benchmark 全部达标（< 2s~60s） | TASK-XLIBGATE-011~018 | ✅ |

---

## §4 TC -> FR 反向追溯

| TC ID | Covers | Scenario |
| ----- | ------ | -------- |
| TC-001 | FR-001, BR-008 | import 违规检测 → 文件路径、行号、exit code 1 |
| TC-002 | FR-002 | go.mod tidy 无 diff → pass, exit 0 |
| TC-003 | FR-003 | baseline 不匹配 → 输出模块列表, exit 1 |
| TC-004 | FR-005, BR-001, BR-006 | imports 失败 + gomod 通过 → 继续执行, exit 1 |
| TC-005 | FR-005, BR-001, BR-006 | baseline error → 继续执行其余检查, exit 2 |
| TC-006 | FR-004 | release evidence 完整 → pass, exit 0 |
| TC-007 | FR-006, BR-007 | JSON 输出含 status/checks[]/summary |
| TC-008 | FR-005, BR-005 | gitleaks 检测到泄露 → 文件路径/行号/规则, exit 1 |
| TC-009~013 | FR-007~011 | l2 子命令组（validate-manifest/plan/check-contracts/check-evidence/release-check） |
| TC-014~029 | FR-012~019, BR-010 | trust 子命令组（identity/template/release/maturity/boundary/testkit/secret/fleet） |

> 完整 TC-001~029 详情见 [matrix/TRACEABILITY.md §4](./matrix/TRACEABILITY.md)

---

## §5 全局 AC 注册表

| AC ID | FR/BR Ref | Task | 验收条件摘要 |
| ----- | --------- | ---- | ----------- |
| AC-001~009 | FR-001~006, BR-001~009 | TASK-002~006 | check + l2 子命令组验收（imports/gomod/baseline/release/all/output/gitleaks） |
| AC-010~014 | FR-007~011 | TASK-009 | l2 子命令组验收（validate-manifest/plan/check-contracts/check-evidence/release-check） |
| AC-015~022 | FR-012~019, BR-010 | TASK-011~018 | trust 子命令组验收（identity/template/release/maturity/boundary/testkit/secret/fleet） |

> 完整 AC-001~022 详情见 [matrix/TRACEABILITY.md §5](./matrix/TRACEABILITY.md)

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 19 | 19 | 100% |
| BR (业务规则) | 10 | 10 | 100% |
| NFR (非功能需求) | 18 | 13 | 72.2% |
| AC (验收标准) | 22 | 22 | 100% |
| TC (测试用例) | 29 | 29 | 100% |
| **合计** | **98** | **93** | **94.9%** |

> 说明：NFR-001~006/009 标记为 ⚠️（benchmark 未正式运行/待验证），未计入 Done。NFR-007~008/010~018 标记为 ✅。Task 总数 = TASK-XLIBGATE-000~018 共 19 项。完整数据见 [matrix/TRACEABILITY.md](./matrix/TRACEABILITY.md)。

---

## §7 变更历史

| 日期 | 版本 | 变更 |
| ---- | ---- | ---- |
| 2026-06-29 | v1.6 | Goal 管线对齐：创建根级 §1-§7 TRACEABILITY.md（权威完整版仍为 matrix/TRACEABILITY.md）；§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 2026-06-14 | v1.5 | Trust Alignment：SPEC v1.1.1 FR-012~019 + BR-010 + NFR-011~018，仪表盘 FR 11→19 |
| 2026-06-12 | v1.4 | 追溯链闭合：FR-007~011 AC/TC 填入，AC 9→14，TC 8→13 |
| 2026-06-12 | v1.0 | 初始版本：7 列矩阵 + BR/NFR + TC 反向追溯 + AC 注册表 + 覆盖率仪表盘 |
