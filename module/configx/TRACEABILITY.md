# configx 需求追溯矩阵

> 更新：2026-06-12（v2.3 — 覆盖缺口修复 I-02/03/04：追加 BR-008~011 + TC-008/009 + 仪表盘数值对齐）
> 来源：module/configx/SPEC.md v1.0.1
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | Load 文件加载（YAML/TOML/JSON） | AC-001 | TC-001, TC-006, TC-007 | TASK-CONFIGX-002 | ⬜ |
| FR-002 | WithEnvOverride 环境变量覆盖 | AC-002 | TC-001 | TASK-CONFIGX-004 | ⬜ |
| FR-003 | Validate schema 校验 | AC-003 | TC-002 | TASK-CONFIGX-005 | ⬜ |
| FR-004 | Get 并发安全读取 | AC-004 | TC-003 | TASK-CONFIGX-006 | ⬜ |
| FR-005 | Watch 配置监听（可选） | AC-005 | TC-004 | TASK-CONFIGX-007 | ⬜ |

---

## 2. 业务规则追溯（BR）

| BR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| BR-001 | 覆盖优先级：默认值→文件→环境变量→命令行 | 合并后值来自最高优先级源 | TC-001 | TASK-CONFIGX-003 | ⬜ |
| BR-002 | 启动时必须 schema 校验（fail-fast） | Validate 失败阻断启动 | TC-002 | TASK-CONFIGX-005 | ⬜ |
| BR-003 | 配置键使用点分路径（data.market.symbol） | 点分路径正确遍历嵌套 map | TC-001 | TASK-CONFIGX-003 | ⬜ |
| BR-004 | 环境变量前缀+下划线（APP_DATA_MARKET_SYMBOL） | 下划线→点分映射正确 | TC-001 | TASK-CONFIGX-004 | ⬜ |
| BR-005 | Reader 接口只读 | 不能通过 Reader 修改底层配置 | TC-005 | TASK-CONFIGX-006 | ⬜ |
| BR-006 | 配置值类型与 schema 一致 | 类型不匹配时报错 | TC-002 | TASK-CONFIGX-005 | ⬜ |
| BR-007 | 未定义配置键：忽略或 warning（strict 模式） | strict=true 时报错，strict=false 时忽略 | TC-002 | TASK-CONFIGX-005, TASK-CONFIGX-006 | ⬜ |
| BR-008 | 公共错误变量使用 `configx:` 前缀命名空间 | 错误变量均使用 `configx:` 前缀 | CI Gate: `go vet ./...` | TASK-CONFIGX-000 | ⬜ |
| BR-009 | Reader/Config/Option 接口遵循 Go 接口隔离原则 | 接口定义符合 ISP（小接口、单一职责） | CI Gate: `golangci-lint run` | TASK-CONFIGX-001 | ⬜ |
| BR-010 | Release 制品通过全部 CI Gate（编译/测试/覆盖率/vet/lint/secret） | 全部 CI Gate 通过 | TC-009 | TASK-CONFIGX-009 | ⬜ |
| BR-011 | 敏感字段（password/token/secret/key）自动脱敏 | 敏感字段读取/日志输出返回 `***` | TC-008 | TASK-CONFIGX-010 | ⬜ |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | Acceptance Criteria | Test Case | Task | Status |
|-----|-------------|---------------------|-----------|------|--------|
| NFR-001 | 配置加载性能（1000 key） | < 50ms | Benchmark | TASK-CONFIGX-006 | ⬜ |
| NFR-002 | Get 单次调用 | < 100ns | Benchmark | TASK-CONFIGX-006 | ⬜ |
| NFR-003 | 常驻内存 | < 5MB | Profiling | TASK-CONFIGX-006 | ⬜ |
| NFR-004 | 测试覆盖率 | ≥ 80% | CI Gate: `go test -coverprofile=coverage.out ./...` | TASK-CONFIGX-009 | ⬜ |
| NFR-005 | 不依赖 kernel（foundationx exit 已完成） | 编译通过 | CI Gate: `go build ./...` | TASK-CONFIGX-009 | ⬜ |
| NFR-006 | 敏感字段脱敏覆盖（password/token/secret/key） | 100% 敏感字段不可明文输出 | 安全测试: `gitleaks detect --no-git` | TASK-CONFIGX-010 | ⬜ |
| NFR-007 | 日志无凭据泄露 | 0 条泄露 | CI Gate: `gitleaks detect --no-git && grep -rE '(password\|token\|secret\|key)\s*[:=]\s*\w+' . --include='*.go' \| grep -v '***'` | TASK-CONFIGX-010 | ⬜ |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|----------------------|
| TC-001 | FR-001, FR-002, BR-001, BR-003, BR-004 | Given 默认值 `symbol=BTCUSDT`，文件中 `symbol=ETHUSDT`，环境变量 `APP_SYMBOL=SOLUSDT`；When 加载文件并应用环境变量覆盖；Then `Get("symbol")` 返回 `"SOLUSDT"`，点分路径和前缀映射正确 |
| TC-002 | FR-003, BR-002, BR-006, BR-007 | Given schema 要求 `symbol` 为 string；When 配置中 `symbol=123`（int）；Then `Validate()` 返回包含 `symbol: expected string, got int` 的错误；strict 模式下未知字段也报错 |
| TC-003 | FR-004 | Given 已加载配置；When 100 个 goroutine 并发调用 `Get("symbol")`；Then 无 data race，所有返回值一致 |
| TC-004 | FR-005 | Given 配置文件已加载并开启 Watch；When 文件内容变更且通过校验；Then Reader 读到新值并触发变更回调 |
| TC-005 | BR-005 | Given 已创建配置 Reader；When 调用读取接口；Then 不能通过 Reader 修改底层配置 |
| TC-006 | FR-001 | Given 调用 `Load("/nonexistent/config.yaml")`；When 文件不存在；Then 返回 `os.ErrNotExist`，配置不变 |
| TC-007 | FR-001 | Given 调用 `Load("invalid.yaml")` 文件内容为非法 YAML；When 解析失败；Then 返回 `ErrInvalidFormat`，配置不变 |
| TC-008 | BR-011 | Given 配置包含 `db.password=secret123`；When 通过 Reader.GetString("db.password") 读取或输出到日志；Then 返回值/日志内容为 `"***"`，不包含原始密码 |
| TC-009 | BR-010 | Given 所有 Task 实现完成；When 运行 `go test -race -count=1 ./...` 和 `gitleaks detect --no-git`；Then 所有测试通过，零 data race，零 secret 泄露，覆盖率 ≥ 80% |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | Task | 验收条件摘要 |
|----|-----------|------|-------------|
| AC-001 | FR-001 | 002 | Load 解析 YAML/TOML/JSON 成功；文件不存在返回 ErrNotExist；格式无效返回 ErrInvalidFormat |
| AC-002 | FR-002, BR-001 | 004 | 环境变量正确覆盖，优先级：默认值→文件→环境变量→命令行 |
| AC-003 | FR-003, BR-002 | 005 | Validate 通过返回 nil，失败返回所有违规字段（字段路径+预期类型+实际值） |
| AC-004 | FR-004 | 006 | Get 并发安全（-race 通过），key 不存在返回 nil |
| AC-005 | FR-005, BR-005 | 007 | Watch 通知 + Reader 只读视图（不可修改底层配置） |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 5 | FR-001 ~ FR-005 |
| FR 有 AC 覆盖 | 5/5 (100%) | |
| FR 有 TC 覆盖 | 5/5 (100%) | |
| FR 有 Task 分配 | 5/5 (100%) | |
| BR 总数 | 11 | BR-001 ~ BR-011 |
| BR 有 TC 覆盖 | 11/11 (100%) | BR-008/009 通过 CI Gate，BR-010 通过 TC-009，BR-011 通过 TC-008 |
| BR 有 Task 分配 | 11/11 (100%) | |
| NFR 总数 | 7 | NFR-001 ~ NFR-007 |
| AC 总数 | 5 | AC-001 ~ AC-005 |
| TC 总数 | 9 | TC-001 ~ TC-009 |
| Task 总数 | 10 | TASK-CONFIGX-000 ~ 010（008 已合并删除） |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-12 | v2.2 | 修复 Matrix 扣分：BR/NFR表头对齐标准格式；新增 TC-006（文件不存在）、TC-007（格式无效）；NFR验证方式命令化；TASK-008 删除后 Task 总数 11→10；TC 总数 5→7 |
| 2026-06-12 | v2.1 | 新增 NFR-006/007（安全脱敏+日志泄露扫描）；新增 §8 v1.0 Roadmap Coverage；Task 总数 10→11 |
| 2026-06-12 | v2.0 | 完整重写：7列矩阵 + BR行 + NFR行 + TC反向追溯 + AC注册表 + 覆盖率仪表盘 |
| 2026-06-09 | v1.0 | 初始版本（骨架） |

---

## 8. v1.0 Roadmap Coverage

以下能力由 [goal.md](../goal.md) 的 1.0 目标定义，当前 SPEC.md 尚未纳入，待 v1.0 开发阶段补充对应的 FR/BR/TC/AC：

| goal.md 能力 | 当前 SPEC 覆盖 | 计划纳入版本 |
|-------------|:---:|:---:|
| ConfigSource SPI（远程配置源扩展点） | ❌ | v1.0 |
| ConfigSnapshot（不可变配置快照） | ❌ | v1.0 |
| ConfigChangeEvent（热更新事件） | ❌ | v1.0 |
| bind(prefix, class) 强类型绑定 | ❌ | v1.0 |
| ConfigValidator SPI（自定义校验扩展） | ❌ | v1.0 |
| 热更新失败回滚 | ❌ | v1.0 |
| 审计日志（变更来源/操作者/脱敏 diff） | ❌ | v1.0 |
| 配置文档自动生成 | ❌ | v1.0 |
| 远程配置源 TLS 要求 | ❌ | v1.0 |
| 敏感字段脱敏（自动 + Reveal()） | ⚠️ 仅 SPEC §19 简要提及 | v0.3 (TASK-010) |

> **说明**：SPEC.md 描述当前 v0.1.4 已实现和即将实现的能力；goal.md 描述 v1.0 完整目标。gap 项不在当前阶段交付范围。
