# xlibgate 需求追溯矩阵

> 更新：2026-06-12（Matrix v1.0 — 完整 7 列矩阵）
> 来源：module/xlibgate/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | check imports：扫描 import 语句，检测禁止的依赖方向（业务域反向依赖基座、生产包依赖 testkitx），违规时输出文件路径和行号 | DoD: 所有 FR 有测试 | TC-001（import 边界违规） | TASK-XLIBGATE-002 | ⬜ |
| FR-002 | check gomod：执行 `go mod tidy` 检查 go.mod 整洁度，有 diff 时输出 diff 详情 | DoD: 所有 FR 有测试 | TC-002（go.mod 整洁） | TASK-XLIBGATE-003 | ⬜ |
| FR-003 | check baseline：验证所有模块 go.mod 中 `go` 指令版本与 expected 一致，不匹配时输出模块列表和版本差异 | DoD: 所有 FR 有测试 | TC-003（baseline 不匹配） | TASK-XLIBGATE-004 | ⬜ |
| FR-004 | check release：收集和校验 release evidence，缺失或不通过时输出失败列表 | DoD: 所有 FR 有测试 | TC-006（release evidence） | TASK-XLIBGATE-005 | ⬜ |
| FR-005 | check all：执行所有子检查，部分失败继续执行其余检查，汇总所有子检查结果 | DoD: 所有 FR 有测试 | TC-004, TC-005 | TASK-XLIBGATE-006 | ⬜ |
| FR-006 | 输出格式：支持 JSON（含 status/checks[]/summary）和 human-readable（含文件路径行号、带颜色终端输出） | DoD: 所有 FR 有测试 | TC-007 | TASK-XLIBGATE-006 | ⬜ |

---

## 2. 业务规则追溯（BR）

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | 标准化 exit code：0=pass, 1=fail, 2=error | CI 无法正确判断门禁结果 | TC-004（部分失败→exit 1）, TC-005（错误→exit 2） | TASK-XLIBGATE-006 | ⬜ |
| BR-002 | import 规则从 deps.yaml 读取，不硬编码 | 规则变更需改代码重新编译 | FR-001 WHEN/THEN `--config` 参数覆盖 | TASK-XLIBGATE-002 | ⬜ |
| BR-003 | baseline 从配置或 `--expected` 参数获取，不硬编码 | 版本升级需改代码 | FR-003 WHEN/THEN 参数和配置 fallback | TASK-XLIBGATE-004 | ⬜ |
| BR-004 | evidence schema 与 xlib-standard 定义的 Evidence 标准一致 | 跨工具 evidence 不可互操作 | FR-004 schema 验证（JSON 格式 + 必需字段） | TASK-XLIBGATE-005 | ⬜ |
| BR-005 | secret 扫描使用 gitleaks 作为底层工具 | 自研扫描器漏报 | `check all` 中 gitleaks 集成调用 | TASK-XLIBGATE-006 | ⬜ |
| BR-006 | check all 必须执行所有子检查，即使前面检查已失败 | 部分检查被跳过，门禁不完整 | TC-004（部分失败后继续）, TC-005（error 后继续） | TASK-XLIBGATE-006 | ⬜ |
| BR-007 | JSON 输出必须包含 machine-readable 的 status 字段 | CI 解析失败 | TC-007（JSON 字段完整性） | TASK-XLIBGATE-006 | ⬜ |
| BR-008 | human-readable 输出必须包含文件路径和行号 | 开发者无法定位违规位置 | TC-001（违规含文件路径行号）, TC-002（diff 位置信息） | TASK-XLIBGATE-002 | ⬜ |
| BR-009 | 依赖矩阵文件 `FOUNDATION-DEPS.yaml` schema 与 xlib-standard 定义一致 | deps.yaml 解析失败 | FR-001 config 加载（YAML 解析 + schema 校验） | TASK-XLIBGATE-002 | ⬜ |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | 全量门禁性能（50 模块） | < 30s | Benchmark `BenchmarkCheckAll` | TASK-XLIBGATE-006 | ⬜ |
| NFR-002 | import 扫描性能（50 模块） | < 10s | Benchmark `BenchmarkCheckImports` | TASK-XLIBGATE-002 | ⬜ |
| NFR-003 | go.mod 检查性能（50 模块） | < 5s | Benchmark `BenchmarkCheckGomod` | TASK-XLIBGATE-003 | ⬜ |
| NFR-004 | baseline 检查性能（50 模块） | < 5s | Benchmark `BenchmarkCheckBaseline` | TASK-XLIBGATE-004 | ⬜ |
| NFR-005 | JSON 报告生成性能 | < 100ms | Benchmark `BenchmarkReportJSON` | TASK-XLIBGATE-006 | ⬜ |
| NFR-006 | 内存占用 | < 100MB | Profiling `go test -memprofile` | TASK-XLIBGATE-006 | ⬜ |
| NFR-007 | 测试覆盖率 | ≥ 80% | `go tool cover -func` | TASK-XLIBGATE-006 | ⬜ |
| NFR-008 | 无硬编码密钥 | 全仓扫描零命中 | `gitleaks detect --no-git` | TASK-XLIBGATE-006 | ⬜ |
| NFR-009 | secret 扫描不泄露敏感数据 | 错误消息只含文件路径和行号 | review 错误输出格式 | TASK-XLIBGATE-006 | ⬜ |
| NFR-010 | 无 Foundation 运行时依赖 | `go list -deps` 零命中 ZoneCNH 模块 | CI gate `go list -deps ./...` | TASK-XLIBGATE-006 | ⬜ |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|---------------------|
| TC-001 | FR-001, BR-008 | Given 配置禁止业务域 import 基座层，When 扫描到 `binance` import `kernel`，Then 输出违规详情（文件路径、行号），exit code 1 |
| TC-002 | FR-002 | Given 项目 go.mod 已 tidy，When 运行 `check gomod`，Then 输出 pass，exit code 0 |
| TC-003 | FR-003 | Given 配置要求 Go 1.23，某模块 go.mod 指定 1.22，When 运行 `check baseline --expected 1.23`，Then 输出不匹配模块列表，exit code 1 |
| TC-004 | FR-005, BR-001, BR-006 | Given imports 检查失败，gomod 检查通过，When 运行 `check all`，Then 输出所有子检查结果，imports 为 fail，gomod 为 pass，exit code 1 |
| TC-005 | FR-005, BR-001, BR-006 | Given imports 检查正常，baseline 检查因配置缺失报 error，When 运行 `check all`，Then imports 结果正常输出，baseline 标记为 error，继续执行其余检查，exit code 2 |
| TC-006 | FR-004 | Given release evidence 文件存在且 schema 合法，When 运行 `check release`，Then 输出 pass，exit code 0 |
| TC-007 | FR-006, BR-007 | Given 检查结果包含 pass、fail 和 error，When 使用 JSON 输出，Then 输出包含 status、checks[]、summary 字段 |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | Task | 验收条件摘要 |
|----|-----------|------|-------------|
| AC-001 | FR-001 | 002 | import 违规检测输出文件路径、行号、违规 import 路径，合规时 pass，exit code 0 |
| AC-002 | FR-002 | 003 | go.mod tidy 无 diff → pass（exit 0），有 diff → 输出 diff 详情（exit 1），无 go.mod → error（exit 2） |
| AC-003 | FR-003 | 004 | baseline 匹配 → pass（exit 0），不匹配 → 输出模块列表（exit 1），无 expected → error（exit 2） |
| AC-004 | FR-004 | 005 | evidence 完整且通过 → pass（exit 0），缺失 → 输出缺失列表（exit 1），格式无效 → error（exit 2） |
| AC-005 | FR-005 | 006 | 全部 pass → exit 0，任一 fail → exit 1，任一 error → exit 2（所有子检查均执行） |
| AC-006 | FR-006 | 006 | 默认 human-readable（含颜色），`--output json` 输出含 status/checks[]/summary，`--artifact` 写入文件 |
| AC-007 | BR-001 | 006 | exit code 映射：所有 pass→0，任一 fail→1（非 error 覆盖），任一 error→2 |
| AC-008 | BR-009 | 002 | FOUNDATION-DEPS.yaml 解析正确，schema 校验通过，无效 yaml → ErrConfigInvalid |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 6 | FR-001 ~ FR-006 |
| FR 有 AC 覆盖 | 6/6 (100%) | |
| FR 有 TC 覆盖 | 6/6 (100%) | |
| FR 有 Task 分配 | 6/6 (100%) | |
| BR 总数 | 9 | BR-001 ~ BR-009 |
| BR 有 TC 覆盖 | 9/9 (100%) | |
| BR 有 Task 分配 | 9/9 (100%) | |
| NFR 总数 | 10 | NFR-001 ~ NFR-010 |
| AC 总数 | 8 | AC-001 ~ AC-008 |
| TC 总数 | 7 | TC-001 ~ TC-007 |
| Task 总数 | 7 | TASK-XLIBGATE-000 ~ 006 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-12 | v1.0 | 初始版本：完整 7 列矩阵 + BR 行 + NFR 行 + TC 反向追溯 + AC 注册表 + 覆盖率仪表盘 |
