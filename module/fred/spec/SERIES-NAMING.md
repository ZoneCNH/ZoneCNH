# FRED Series ID 命名规范

<!-- Spec-Version: v1.1.0 -->
<!-- Last-Updated: 2026-07-08 -->
<!-- Authority: module/fred/spec/SPEC.md §5.2 + SERIES-CATALOG.md -->
<!-- Closes: OPEN-CAT-1 -->

---

## §1 概述

本文档定义 fred 模块所有 Series ID 的命名规则，作为 SERIES-CATALOG.md 和 SPEC.md §5.2 的配套规范（SSOT）。

---

## §2 FRED-native 序列命名规则

### §2.1 基本规则

- 使用 FRED 官方 `series_id`，全大写，字母+数字，最长 20 字符。
- 直接映射 `https://fred.stlouisfed.org/series/{series_id}` 可访问的序列。
- 禁止自造别名或缩写。

### §2.2 合法示例

| FRED series_id | 描述 |
|----------------|------|
| `CPIAUCSL` | 消费者价格指数（城市平均，季调） |
| `FEDFUNDS` | 联邦基金有效利率 |
| `GDP` | 美国 GDP |
| `UNRATE` | 失业率 |
| `DGS10` | 10 年期美国国债收益率 |
| `DEXUSEU` | 美元/欧元汇率 |
| `BAMLH0A0HYM2EY` | 高收益债利差 |
| `VIXCLS` | CBOE VIX 收盘价（✅ 正确） |
| `WTREGEN` | 外汇储备（✅ 正确） |

### §2.3 禁止使用的非官方别名

| 禁止使用 | 正确 ID | 来源 |
|----------|---------|------|
| ~~`VXVCLS`~~ | `VIXCLS` | SPEC.md §5.2 风险行已修正 |
| ~~`WDTGAL`~~ | `WTREGEN` | SPEC.md §5.2 流动性行已修正 |
| ~~`JPNASSETS`~~ | 待确认（外部路由，见 §3）| SPEC.md §5.2 央行资产负债表 |

---

## §3 外部路由序列规则

### §3.1 定义

外部路由序列是指**不直接通过 FRED v1 API 获取**，而是通过 FRED 接入的第三方来源序列。其数据可能来自 ECB、BOJ、BIS 等外部数据提供方。

### §3.2 标识规则

外部路由序列**必须**在 SERIES-CATALOG.md 条目中标注 `source_component` 字段：

```yaml
series_id: JPNASSETS    # FRED 官方 series_id（若存在）
source_component: boj.balance_sheet  # 实际数据提供方路由标识
provider: BOJ           # 提供方简称
is_external_routed: true
note: "日本央行资产负债表，通过 FRED 第三方接入，需校验 FRED 可用性"
```

### §3.3 覆盖率计算排除

外部路由序列**不计入** FRED API 采集覆盖率（分母为 FRED-native 序列）。Admin 覆盖审计输出格式：
```json
{
  "total_fred_native": 246,
  "covered": 198,
  "missing": 48,
  "external_routed": 12
}
```

---

## §4 OPEN-CAT-1 关闭记录

`OPEN-CAT-1` 是 SPEC.md §5.2 中 Series ID 使用非官方别名引发的已知缺口问题。

| 问题 ID | 涉及字段 | 旧值 | 正确值 | 修复版本 | 状态 |
|---------|----------|------|--------|----------|------|
| OPEN-CAT-1-A | SPEC.md §5.2 风险行 | `VXVCLS` | `VIXCLS` | v1.1.0 | ✅ 已修复 |
| OPEN-CAT-1-B | SPEC.md §5.2 流动性行 | `WDTGAL` | `WTREGEN` | v1.1.0 | ✅ 已修复 |
| OPEN-CAT-1-C | SERIES-CATALOG 条目缺失 `VIXCLS` | — | 待补录 | — | 🔧 待修复 |
| OPEN-CAT-1-D | SERIES-CATALOG 条目缺失 `WTREGEN` | — | 待补录 | — | 🔧 待修复 |
| OPEN-CAT-1-E | `JPNASSETS` 来源确认 | — | 待确认是否 FRED-native 或外部路由 | — | 🔧 待确认 |

---

## §5 Schema-Aware TDengine 旁路规则

- Series ID 长度 ≤ 20 字符时，使用 TDengine stable tag 直接映射。
- Series ID 超过 20 字符时，通过 schema-aware 旁路表（`series_id_map`）映射，查询时自动关联。
- 映射表由 `internal/server/taos_schema.go` 管理，不得在业务层硬编码 ID 截断。

---

## §6 验证规则

在 `spec/SERIES-CATALOG.md` 更新时，CI 门禁 `scripts/validate-series-naming.sh` 执行：

```bash
# 验证无非官方别名
grep -E '\b(VXVCLS|WDTGAL|JPNASSETS)\b' spec/SERIES-CATALOG.md && echo "FAIL: 非官方别名" && exit 1

# 验证外部路由序列有 source_component
python3 scripts/validate-series-naming.py spec/SERIES-CATALOG.md

echo "PASS"
```

---

> 本文档关闭 OPEN-CAT-1。后续 series ID 疑问以本文档为 SSOT，通过 PR 提交变更。
