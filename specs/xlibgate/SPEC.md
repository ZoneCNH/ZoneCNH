# xlibgate 完整规格

> 基座 · 机器门禁。import 边界、go.mod、Go baseline、release evidence 机器检查。

最后更新：2026-06-07

---

## 1. 定位

`xlibgate` 是 Foundation 的机器可执行门禁，负责在 CI 中验证依赖矩阵、import 边界、Go baseline 和 release evidence。

### 核心职责

- import 边界扫描（生产包不依赖 testkitx，业务域不反向依赖）
- go.mod 整洁度检查
- Go baseline 对齐检查（Foundation 模块共享 Go toolchain）
- release evidence 收集和校验
- 依赖矩阵验证（consumes `FOUNDATION-DEPS.yaml`）
- testkitx 边界检查
- secret 扫描门禁

### 明确不做

- 不参与运行时
- 不是库或框架
- 不承载业务逻辑
- 不替代 CI 平台本身

---

## 2. 接口契约

### 2.1 CLI 命令

```bash
# import 边界检查
xlibgate check imports --config deps.yaml

# go.mod 整洁度
xlibgate check gomod --path ./...

# Go baseline 对齐
xlibgate check baseline --expected 1.23

# release evidence
xlibgate check release --evidence evidence.json

# 全量门禁
xlibgate check all --config deps.yaml
```

### 2.2 配置

```yaml
# xlibgate.yaml
baseline:
  go_version: "1.23"

imports:
  forbidden:
    - source: "github.com/ZoneCNH/testkitx"
      targets: ["*"]
    - source: "github.com/ZoneCNH/binance"
      targets: ["github.com/ZoneCNH/kernel", "github.com/ZoneCNH/configx"]

release:
  require:
    - test_coverage >= 80%
    - race_test_pass
    - secret_scan_pass
    - gomod_tidy
    - vet_clean
```

### 2.3 契约约束

- 所有检查命令返回标准化 exit code（0=pass, 1=fail, 2=error）
- 输出格式支持 JSON 和 human-readable
- 检查结果可输出为 CI artifact

---

## 3. 目录结构

```
xlibgate/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── main.go                     # CLI 入口
├── cmd/
│   ├── root.go
│   ├── check.go
│   ├── imports.go
│   ├── gomod.go
│   ├── baseline.go
│   └── release.go
├── scanner/
│   ├── imports.go
│   ├── gomod.go
│   └── baseline.go
├── evidence/
│   ├── collector.go
│   └── validator.go
├── config.go
├── report.go
├── testdata/
│   └── *.yaml
├── example_test.go
└── integration_test.go
```

---

## 4. 依赖

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | 所有 Foundation 模块（仅扫描，不 import） |
| YAML 解析库 | 所有业务域 |
| Go AST 解析库 | |

---

## 5. CI Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | ≥ 80% | 覆盖率不足 |
| 自检 | `xlibgate check all --config xlibgate.yaml` | 自身门禁不通过 |

---

## 6. 测试矩阵

| 测试场景 | 验证点 |
|----------|--------|
| import 违规检测 | 业务域反向依赖 Foundation → 报错 |
| testkitx 边界 | 生产包依赖 testkitx → 报错 |
| go.mod 不整洁 | `go mod tidy` 有 diff → 报错 |
| baseline 不匹配 | go.mod 中 go 版本 != expected → 报错 |
| release evidence 缺失 | 必需 evidence 项缺失 → 报错 |
| config 解析 | 无效 YAML → 报错 |
| exit code | pass=0, fail=1, error=2 |

---

## 7. 性能预算

| 操作 | 目标 |
|------|------|
| 全量门禁（50 模块） | < 30s |
| import 扫描 | < 10s |

---

## 8. 发布 DoD

- [ ] CLI 帮助文档完整
- [ ] 所有 check 子命令有示例
- [ ] exit code 文档化
- [ ] JSON 输出格式文档化
- [ ] 测试覆盖率 ≥ 80%
