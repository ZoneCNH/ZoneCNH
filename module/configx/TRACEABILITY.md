# configx 需求追溯矩阵

> 更新：2026-06-12（v2.0 — 完整 7 列矩阵）
> 来源：module/configx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | Load 文件加载（YAML/TOML/JSON） | AC-001 | TC-001 | TASK-CONFIGX-001 | ⬜ 已对齐 |
| FR-002 | WithEnvOverride 环境变量覆盖 | AC-002 | TC-001 | TASK-CONFIGX-002 | ⬜ 已对齐 |
| FR-003 | Validate schema 校验 | AC-003 | TC-002 | TASK-CONFIGX-003 | ⬜ 已对齐 |
| FR-004 | Get 并发安全读取 | AC-004 | TC-003 | TASK-CONFIGX-004 | ⬜ 已对齐 |
| FR-005 | Watch 配置监听（可选） | AC-005 | TC-004 | TASK-CONFIGX-005 | ⬜ 已对齐 |

---

## 2. 业务规则追溯（BR）

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | 覆盖优先级：默认值→文件→环境变量→命令行 | 配置源优先级混乱 | TC-001 | TASK-CONFIGX-002 | ⬜ |
| BR-002 | 启动时必须 schema 校验（fail-fast） | 运行时才发现配置错误 | TC-002 | TASK-CONFIGX-003 | ⬜ |
| BR-003 | 配置键使用点分路径（data.market.symbol） | 路径格式不一致 | TC-001 | TASK-CONFIGX-001 | ⬜ |
| BR-004 | 环境变量前缀+下划线（APP_DATA_MARKET_SYMBOL） | 映射关系混乱 | TC-001 | TASK-CONFIGX-002 | ⬜ |
| BR-005 | Reader 接口只读 | 运行时配置被修改 | TC-005 | TASK-CONFIGX-004 | ⬜ |
| BR-006 | 配置值类型与 schema 一致 | 类型转换失败 | TC-002 | TASK-CONFIGX-003 | ⬜ |
| BR-007 | 未定义配置键：忽略或 warning | 未知 key 导致行为不确定 | TC-002 | TASK-CONFIGX-003 | ⬜ |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | 配置加载性能（1000 key） | < 50ms | Benchmark | TASK-CONFIGX-009 | ⬜ |
| NFR-002 | Get 单次调用 | < 100ns | Benchmark | TASK-CONFIGX-009 | ⬜ |
| NFR-003 | 常驻内存 | < 5MB | Profiling | TASK-CONFIGX-009 | ⬜ |
| NFR-004 | 测试覆盖率 | ≥ 80% | go tool cover | TASK-CONFIGX-009 | ⬜ |
| NFR-005 | 不依赖 kernel（L1→L0 允许） | 编译通过 | go build | TASK-CONFIGX-009 | ⬜ |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|----------------------|
| TC-001 | FR-001, FR-002, BR-001 | 默认值+文件+环境变量覆盖 → Get("symbol") 返回环境变量值 |
| TC-002 | FR-003, BR-002, BR-006 | schema 类型不匹配 → Validate() 返回错误列表 |
| TC-003 | FR-004 | 100 goroutine 并发 Get → 无 race，返回值一致 |
| TC-004 | FR-005 | 文件变更且通过校验 → Reader 读到新值 + callback |
| TC-005 | BR-005 | Reader 只读视图 → 不能修改底层配置 |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | Task | 验收条件摘要 |
|----|-----------|------|-------------|
| AC-001 | FR-001 | 001 | Load 解析 YAML/TOML/JSON，文件不存在/格式错误返回正确错误 |
| AC-002 | FR-002, BR-001 | 002 | 环境变量正确覆盖，优先级正确 |
| AC-003 | FR-003, BR-002 | 003 | Validate 通过返回 nil，失败返回所有违规字段 |
| AC-004 | FR-004 | 004 | Get 并发安全，key 不存在返回 nil |
| AC-005 | FR-005, BR-005 | 005 | Watch 通知 + Reader 只读 |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 5 | FR-001 ~ FR-005 |
| FR 有 AC 覆盖 | 5/5 (100%) | |
| FR 有 TC 覆盖 | 5/5 (100%) | |
| FR 有 Task 分配 | 5/5 (100%) | |
| BR 总数 | 7 | BR-001 ~ BR-007 |
| BR 有 TC 覆盖 | 7/7 (100%) | |
| BR 有 Task 分配 | 7/7 (100%) | |
| NFR 总数 | 5 | NFR-001 ~ NFR-005 |
| AC 总数 | 5 | AC-001 ~ AC-005 |
| TC 总数 | 5 | TC-001 ~ TC-005 |
| Task 总数 | 10 | TASK-CONFIGX-000 ~ 009 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-12 | v2.0 | 完整重写：7列矩阵 + BR行 + NFR行 + TC反向追溯 + AC注册表 + 覆盖率仪表盘 |
| 2026-06-09 | v1.0 | 初始版本（骨架） |
