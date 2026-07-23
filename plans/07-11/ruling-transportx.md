# 治理裁决 RULING-002: transportx Go module major path

**裁决日期**: 2026-07-11
**裁决编号**: RULING-002
**裁决者**: FoundationX Governance
**状态**: FINAL

## 背景

transportx 当前 go.mod 声明为 `github.com/xhyperium/xlib-standard`，但 repo-contract 指明模块名应为 `transportx`。这是 Go module identity breaking change。分析报告 §2.2 矛盾 2（行 L787 vs L801）将此标记为 HIGH 严重度。

TRN-001 工作包要求修复 module identity，但未裁定迁移后是否需要 `/v2` 后缀。当前 tag 历史为 v1.0.0 到 v1.1.1-spec，全部为 spec-only 发布，且 `production_import_allowed=false` 意味着无生产消费者。

## 裁决

**module path 改为 `github.com/xhyperium/transportx`，不加 `/v2` 后缀。**

### 决策树

```
go.mod 当前是 github.com/xhyperium/xlib-standard?
├── YES → 这是 module identity change (breaking)
    ├── 现有消费者存在吗？
│   │   ├── NO (production_import_allowed=false) → /v1 可接受
│   │   │   └── 裁决: go.mod → github.com/xhyperium/transportx (无 /v2)
│   │   │       理由: 没有生产消费者需要迁移 import path
│   │   └── YES → 需要 /v2
│   │       └── 裁决: go.mod → github.com/xhyperium/transportx/v2
│   │           理由: Go module major version 语义强制
│   └── 特殊: 旧 tag v1.1.1-spec 是 spec-only
│       → 裁决: v1.1.1-spec 标记为 retracted
└── NO → 无操作
```

### 采用理由

1. `production_import_allowed=false` — 无生产消费者需要迁移 import path，因此 `/v1` 路径合法
2. 旧 tag (v1.0.0–v1.1.1-spec) 只是 spec-only release，不是 runtime 发布，不构成 Go module 语义中的 "v1 已经被占用"
3. 在 Go module 语义中，无生产消费者意味着 v1 路径干净可用
4. 使用 `/v2` 会引入不必要的语义复杂度 — transportx 还未进行过任何 runtime 的 v1 发布

### 附加裁决

- 旧 tag v1.0.0 到 v1.1.1-spec 标记为 `retract`，注释说明是 spec-only 发布
- 如果未来发现未记录的消费者，首次发布时升到 `/v2`

## 实施步骤

### 步骤 1：修改 go.mod

```bash
# transportx 仓库
cd /home/workspace/transportx

# 修改 module path
sed -i 's|module github.com/xhyperium/xlib-standard|module github.com/xhyperium/transportx|' go.mod

# 添加 retract 指令
cat >> go.mod << 'GOEOF'

// retract spec-only releases predating runtime module
retract [v1.0.0, v1.1.1-spec]
GOEOF
```

go.mod 最终结构：

```go
module github.com/xhyperium/transportx

go 1.26.5

retract [v1.0.0, v1.1.1-spec]
```

### 步骤 2：批量更新 import path

```bash
# 更新所有 .go 文件的 import path
find . -name '*.go' -exec sed -i \
  's|github.com/xhyperium/xlib-standard|github.com/xhyperium/transportx|g' {} +

# 验证 import 一致性
go list -m all | grep -E 'xlib-standard|transportx'
# 期望输出: github.com/xhyperium/transportx (无 xlib-standard)
```

### 步骤 3：外部消费者验证

```bash
# 验证外部消费者可以正确导入
mkdir -p /tmp/transportx-consumer && cd /tmp/transportx-consumer
go mod init example.com/consumer
go get github.com/xhyperium/transportx@latest

cat > main.go << 'EOF'
package main
import "github.com/xhyperium/transportx"
func main() {}
EOF

go build ./...
# 期望: 编译成功，无 xlib-standard 残留
```

### 步骤 4：TRN-001 工作包记录裁决

在 TRN-001 工作包文档中追加裁决记录：

```markdown
## TRN-001 补充：module major path 裁决

- **裁决日期**: 2026-07-11
- **裁决结果**: `/v1` (无 /v2 后缀)
- **理由**: `production_import_allowed=false`，无生产消费者需要迁移 import path
- **回退条件**: 若发现未被记录的消费者，必须在首次 `/v2` 发布前解决
- **旧 tag 处置**: v1.0.0–v1.1.1-spec 标记为 `retract`，说明是 spec-only 发布
```

## 受影响的制品

| 制品路径 | 变更类型 | 说明 |
|---------|---------|------|
| `/home/workspace/transportx/go.mod` | 修改 | module path + retract |
| `/home/workspace/transportx/**/*.go` | 修改 | import path 替换 |
| `/home/workspace/transportx/TRN-001` | 追加 | 裁决记录 |

## 回退条件

如果发现未被记录的生产消费者依赖 `github.com/xhyperium/xlib-standard` import path，则在新分支创建 `/v2` module path (`github.com/xhyperium/transportx/v2`)，并将旧的 `/v1` path 标记为 deprecated。

回退触发条件：
1. 外部消费者 `go get github.com/xhyperium/transportx@latest` 后编译失败
2. Go module proxy 缓存中存在对 `xlib-standard` path 的引用
3. 任何 ZoneCNH 模块的 `go.mod` 中出现 `require github.com/xhyperium/xlib-standard`

## 关联工作包

| 工作包 | 模块 | 优先级 | 关系 |
|-------|------|--------|------|
| TRN-001 | transportx | P0 | module identity 修复 |

## 签署

本裁决由 FoundationX Governance 根据分析报告 `/home/workspace/ZoneCNH/report/07-11/07-11-analysis.md` §2.2 矛盾 2 和 §P0-2 生成。裁决为 FINAL 状态，不可上诉，回退仅可在回退条件满足时触发。
