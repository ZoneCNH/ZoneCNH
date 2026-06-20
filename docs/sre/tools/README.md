
## boundary-gates-template.sh — 通用 9 道边界门禁模板

参数化的 CI 边界门禁模板，供 20 个 adapter 复制使用。

### 用法

```bash
# 复制到 {module}/scripts/ 并替换模块名
sed 's/{module}/fred/' docs/sre/tools/boundary-gates-template.sh > <workspace>/fred/scripts/boundary-gates.sh
chmod +x <workspace>/fred/scripts/boundary-gates.sh

# 如有迁移历史（legacy name），额外设置 LEGACY_NAME
sed -e 's/{module}/binance/' -e 's/^LEGACY_NAME=""/LEGACY_NAME="binance-market"/' \
  docs/sre/tools/boundary-gates-template.sh > <workspace>/binance/scripts/boundary-gates.sh

# 运行
./scripts/boundary-gates.sh
```

### 9 道门禁

| § | 门禁 | 说明 |
| --- | --- | --- |
| §2 | no-legacy | 无遗留模块引用（迁移历史） |
| §3 | client-no-server | client 不 import server |
| §4a | server-no-client | server 不 import client |
| §4b | server-cmd-no-client | server cmd 不 import client |
| §5 | no-storage-query-strategy | 不 import 其他业务域 |
| §6 | no-local-proto | 无 .proto（wire schema 归 contracts） |
| §7 | no-canonical-ssot | 不声明自己是 canonical SSOT |
| §8 | no-xlib_standard | go.mod 无 xlib_standard |
| §9 | no-storage-adapter | go.mod 无 L2 存储适配器（adapter 零存储） |

不存在的结构（如无 internal/client）自动跳过对应门禁。

### 部署状态

20 adapter 全部已部署并合并到各自 main（P5 完成）。

## boundary-gates-template.sh — 通用 9 道边界门禁模板

参数化的 CI 边界门禁模板，供 20 个 adapter 复制使用。

### 用法

```bash
# 复制到 {module}/scripts/ 并替换模块名
sed 's/{module}/fred/' docs/sre/tools/boundary-gates-template.sh > <workspace>/fred/scripts/boundary-gates.sh
chmod +x <workspace>/fred/scripts/boundary-gates.sh

# 如有迁移历史（legacy name），额外设置 LEGACY_NAME
sed -e 's/{module}/binance/' -e 's/^LEGACY_NAME=""/LEGACY_NAME="binance-market"/' \
  docs/sre/tools/boundary-gates-template.sh > <workspace>/binance/scripts/boundary-gates.sh

# 运行
./scripts/boundary-gates.sh
```

### 9 道门禁

| § | 门禁 | 说明 |
| --- | --- | --- |
| §2 | no-legacy | 无遗留模块引用（迁移历史） |
| §3 | client-no-server | client 不 import server |
| §4a | server-no-client | server 不 import client |
| §4b | server-cmd-no-client | server cmd 不 import client |
| §5 | no-storage-query-strategy | 不 import 其他业务域 |
| §6 | no-local-proto | 无 .proto（wire schema 归 contracts） |
| §7 | no-canonical-ssot | 不声明自己是 canonical SSOT |
| §8 | no-xlib_standard | go.mod 无 xlib_standard |
| §9 | no-storage-adapter | go.mod 无 L2 存储适配器（adapter 零存储） |

不存在的结构（如无 internal/client）自动跳过对应门禁。

### 部署状态

20 adapter 全部已部署并合并到各自 main（P5 完成）。
