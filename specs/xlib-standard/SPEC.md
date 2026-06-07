# xlib-standard 完整规格

> 基座 · 标准事实源。标准事实源、模板、Gate 与 Evidence；不参与运行时依赖。

最后更新：2026-06-07

---

## 1. 定位

`xlib-standard` 是 Foundation 的标准事实源，定义模块应该长什么样、怎么测试、怎么发布。它不参与运行时，不被任何生产代码 import。

### 核心职责

- Go Reference Template（模块目录结构模板）
- 标准事实源（命名规范、接口规范、错误规范）
- Gate 定义（CI gate 清单和阈值）
- Evidence 定义（release evidence 清单）
- 模块骨架生成器

### 明确不做

- 不是运行时依赖
- 不承载业务逻辑
- 不替代 `xlibgate`（机器执行）
- 不替代 `testkitx`（测试工具）

---

## 2. 标准规范

| 规范 | 内容 |
|------|------|
| 命名 | Go 命名规范 + `foundationx_` 指标前缀 |
| 错误 | `errors.New("module: description")` 格式 |
| 接口 | 窄接口、编译期检查、godoc 注释 |
| 目录 | `internal/` 隔离实现、`testdata/` 存储测试数据 |
| 配置 | YAML schema + 环境变量覆盖 |

---

## 3. Gate 清单

| Gate | 标准 | 阻塞级别 |
|------|------|----------|
| 编译 | `go build ./...` | 必须 |
| 测试 | `go test ./... -race -count=1` | 必须 |
| 覆盖率 | ≥ 80% | 必须 |
| vet | `go vet ./...` | 必须 |
| lint | `golangci-lint run` | 必须 |
| 依赖检查 | `go mod tidy && git diff --exit-code` | 必须 |
| Secret 扫描 | `gitleaks detect --no-git` | 必须 |
| Benchmark | 结果附在 PR | 建议 |

---

## 4. Evidence 清单

| Evidence | 格式 | 必需 |
|----------|------|------|
| test_coverage | JSON（total, per_package） | 是 |
| race_test | boolean | 是 |
| secret_scan | JSON（findings） | 是 |
| benchmark | text | 否 |
| dependency_graph | DOT / JSON | 否 |

---

## 5. 目录结构

```
xlib-standard/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── template/                   # 模块模板
│   ├── go.mod.tmpl
│   ├── README.md.tmpl
│   └── ...
├── specs/                      # 标准规范文档
│   ├── naming.md
│   ├── errors.md
│   ├── interfaces.md
│   ├── directory.md
│   └── config.md
├── gates/                      # Gate 定义
│   ├── common.yaml
│   └── module-specific/
├── evidence/                   # Evidence 定义
│   └── schema.json
└── scripts/
    └── init.sh
```

---

## 6. 特殊说明

`xlib-standard` 不是 Go 模块。它是文档和模板集合，不编译、不测试、不发布为 Go 包。

---

## 7. 发布 DoD

- [ ] 模板可直接生成可编译的模块骨架
- [ ] 所有规范文档有示例
- [ ] Gate 清单与 `xlibgate` 配置一致
- [ ] Evidence schema 与 CI artifact 格式一致
