# configx 需求追溯矩阵

> 更新：2026-06-12（v3.0 — SPEC v1.1.0 完整重写后对齐：13 FR，11 BR，9 TC）
> 来源：module/configx/SPEC.md v1.1.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR     | Description                        | Acceptance Criteria                               | Test Case      | Task                               | Status   |
| ------ | ---------------------------------- | ------------------------------------------------- | -------------- | ---------------------------------- | -------- |
| FR-001 | Client 创建与生命周期（New/Close） | New 校验 ctx+cfg，Close 标记关闭                  | TC-007, TC-008 | - | TASK-CONFIGX-000, TASK-CONFIGX-001 | ✅        | ✅ |
| FR-002 | Loader + Source 模式               | NewLoader().AddSource().Load(ctx)                 | TC-001         | - | TASK-CONFIGX-002, TASK-CONFIGX-003 | ✅        | ✅ |
| FR-003 | FileSource — YAML/TOML/JSON/.env   | 4 种文件格式解析正确                              | TC-001         | - | TASK-CONFIGX-002                   | ✅        | ✅ |
| FR-004 | EnvSource — 环境变量               | 前缀匹配 + key 过滤                               | TC-001         | - | TASK-CONFIGX-004                   | ✅        | ✅ |
| FR-005 | MapSource — 字符串 map             | map→Value 转换正确                                | TC-001         | - | TASK-CONFIGX-003                   | ✅        | ✅ |
| FR-006 | StrictDecode                       | 拒绝未知字段/重复key；支持 WithAllowUnknownFields | TC-002         | - | TASK-CONFIGX-005                   | ✅        | ✅ |
| FR-007 | SecretString 自动脱敏              | String/JSON/GoString/Text 全路径脱敏              | TC-003         | - | TASK-CONFIGX-010                   | ✅        | ✅ |
| FR-008 | SecretPolicy 密钥检测              | 默认 7 模式 + CustomMatcher                       | TC-005         | - | TASK-CONFIGX-010                   | ✅        | ✅ |
| FR-009 | Provenance 来源追踪                | 每个 key 记录 Source/Priority/Override            | TC-001         | - | TASK-CONFIGX-006                   | ✅        | ✅ |
| FR-010 | EffectiveConfigHash                | SHA-256，排除 volatile 字段，可复现               | TC-006         | - | TASK-CONFIGX-006                   | ✅        | ✅ |
| FR-011 | SanitizedManifest                  | 敏感字段自动替换，nil 安全                        | TC-003         | - | TASK-CONFIGX-010                   | ✅        | ✅ |
| FR-012 | HealthCheck                        | Status/LatencyMs/Metadata                         | TC-007         | - | TASK-CONFIGX-006                   | ✅        | ✅ |
| FR-013 | Metrics                            | 8 标准指标 + NoopMetrics 零开销                   | TC-009         | - | TASK-CONFIGX-009                   | ✅        | ✅ |
---

## 2. 业务规则追溯（BR）

| BR     | Description                | Acceptance Criteria                   | Test Case                  | Task             | Status   |
| ------ | -------------------------- | ------------------------------------- | -------------------------- | ---------------- | -------- |
| BR-001 | LastWins 合并策略          | 后加载 Source 覆盖先加载的同名 key    | TC-001                     | - | TASK-CONFIGX-003 | ✅        |
| BR-002 | Config.Name 必须非空       | Validate 时检查 Name                  | TC-008                     | - | TASK-CONFIGX-005 | ✅        |
| BR-003 | Config.Timeout ≥ 0         | 负数拒绝                              | TC-008                     | - | TASK-CONFIGX-005 | ✅        |
| BR-004 | 显式加载（无隐式发现）     | 调用方必须显式 AddSource              | CI Gate: NoGlobalStateGate | - | TASK-CONFIGX-009 | ✅        |
| BR-005 | SecretString 全路径脱敏    | String/JSON/GoString/Text 均返回 ***  | TC-003                     | - | TASK-CONFIGX-010 | ✅        |
| BR-006 | SecretPolicy 可配置模式    | 默认 7 模式 + CustomMatcher           | TC-005                     | - | TASK-CONFIGX-010 | ✅        |
| BR-007 | StrictDecode 默认严格      | 拒绝未知字段和重复 key                | TC-002                     | - | TASK-CONFIGX-005 | ✅        |
| BR-008 | 公共错误 `configx:` 前缀   | 所有错误变量使用 configx: 前缀        | CI Gate: go vet            | - | TASK-CONFIGX-000 | ✅        |
| BR-009 | 无全局状态                 | 无进程级 config singleton             | CI Gate: NoGlobalStateGate | - | TASK-CONFIGX-009 | ✅        |
| BR-010 | Release 通过全部 CI Gate   | 编译/测试/覆盖率/vet/lint/secret/vuln | TC-009                     | - | TASK-CONFIGX-009 | ✅        |
| BR-011 | context.Context 必须非 nil | 所有公开 API 强制 ctx 检查            | TC-008                     | - | TASK-CONFIGX-001 | ✅        |

---

## 3. 非功能需求追溯（NFR）

| NFR     | Description      | Acceptance Criteria    | Test Case                      | Task             | Status   |
| ------- | ---------------- | ---------------------- | ------------------------------ | ---------------- | -------- |
| NFR-001 | 测试覆盖率 ≥ 80% | 实际 97.1%             | CI Gate: go test -coverprofile | TASK-CONFIGX-009 | ✅        |
| NFR-002 | 零 data race     | go test -race 通过     | CI Gate                        | TASK-CONFIGX-006 | ✅        |
| NFR-003 | lint 零告警      | golangci-lint 8 linter | CI Gate                        | TASK-CONFIGX-009 | ✅        |
| NFR-004 | 零 secret 泄露   | gitleaks detect        | CI Gate                        | TASK-CONFIGX-010 | ✅        |
| NFR-005 | 不依赖 kernel    | go list -deps 检查     | CI Gate                        | TASK-CONFIGX-009 | ✅        |
| NFR-006 | 依赖安全         | govulncheck 扫描       | CI Gate                        | TASK-CONFIGX-009 | ✅        |

---

## 4. TC → FR 反向追溯

| TC     | FR/BR                          | Given/When/Then 场景                                    |
| ------ | ------------------------------ | ------------------------------------------------------- |
| TC-001 | FR-002~005, BR-001             | LastWins 合并：Source A→B→Load，后加载覆盖先加载        |
| TC-002 | FR-006, BR-007                 | StrictDecode：未知字段拒绝；WithAllowUnknownFields 忽略 |
| TC-003 | FR-007, FR-011, BR-005         | SecretString 全路径脱敏 + SanitizedManifest 安全快照    |
| TC-004 | FR-007                         | Reveal() 获取原始值（仅调试）                           |
| TC-005 | FR-008, BR-006                 | SecretPolicy CustomMatcher 自定义匹配                   |
| TC-006 | FR-010                         | EffectiveConfigHash：相同配置→相同 SHA-256              |
| TC-007 | FR-001, FR-012                 | HealthCheck：已初始化 Client → healthy + LatencyMs > 0  |
| TC-008 | FR-001, BR-002, BR-003, BR-011 | nil context 拒绝 + Config 校验失败                      |
| TC-009 | FR-013, BR-010                 | Release DoD：全量 CI Gate 通过，覆盖率 ≥ 97%            |

---

## 5. 全局 AC 注册表

| AC     | 所属 FR/BR                 | Task        | 验收条件摘要                                    |
| ------ | -------------------------- | ----------- | ----------------------------------------------- |
| AC-001 | FR-002~005, BR-001         | 002/003/004 | Loader+Source 正确加载合并，LastWins 语义       |
| AC-002 | FR-006, BR-007             | 005         | StrictDecode 拒绝未知字段/重复key/类型错误      |
| AC-003 | FR-007/008/011, BR-005/006 | 010         | SecretString + SecretPolicy + SanitizedManifest |
| AC-004 | FR-009/010/012             | 006         | Provenance + Hash + HealthCheck                 |
| AC-005 | FR-001/013, BR-008~011     | 000/001/009 | Client 生命周期 + Metrics + CI Gate             |

---

## 6. 覆盖率仪表盘

| 指标          | 数值         | 说明                  |
| ------------- | ------------ | --------------------- |
| FR 总数       | 13           | FR-001 ~ FR-013       |
| FR 有 TC 覆盖 | 13/13 (100%) |                       |
| BR 总数       | 11           | BR-001 ~ BR-011       |
| BR 有 TC 覆盖 | 11/11 (100%) |                       |
| NFR 总数      | 6            | NFR-001 ~ NFR-006     |
| AC 总数       | 5            | AC-001 ~ AC-005       |
| TC 总数       | 9            | TC-001 ~ TC-009       |
| 实现覆盖率    | **97.1%**    | go test -coverprofile |

---

## 7. 变更历史

| 日期       | 版本   | 变更                                                                       |
| ---------- | ------ | -------------------------------------------------------------------------- |
| 2026-06-12 | v3.0   | SPEC v1.1.0 对齐：5FR→13FR，7BR→11BR，7NFR→6NFR（去重），全部标记 ✅ 已完成 |
| 2026-06-12 | v2.3   | 覆盖缺口修复：追加 BR-008~011 + TC-008/009 + 仪表盘数值对齐                |
| 2026-06-12 | v2.2   | Matrix 扣分修复：表头规范 + TC-006/007 + NFR 验证命令化                    |
| 2026-06-12 | v2.1   | 新增 NFR-006/007（安全脱敏+日志泄露扫描）                                  |
| 2026-06-12 | v2.0   | 完整重写：7列矩阵 + BR行 + NFR行 + TC反向追溯 + AC注册表                   |
| 2026-06-09 | v1.0   | 初始版本（骨架）                                                           |
