# macro_regime 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-17
- Layer: 分析域 · 宏观体制 (M引擎)
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`

> 本文档发布 macro_regime 基线。运行时实现为 Pending。

## 1. 摘要

macro_regime 是分析域的 M 引擎，分析宏观数据流，输出 M1-M7 宏观体制。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | M1-M7 宏观体制分类器、宏观指标管线、regime transition 检测 |
| Depends on | macro-data（MacroPoint）、domain-macro、flowx（数据管线） |
| Consumed by | regime-engine（M 分类输入） |

## 3. 功能需求

### FR-001: M 分类

WHEN WHEN 宏观数据流可用
THEN 输出 M1-M7 体制分类 + transition_probability

### FR-002: Transition 检测

WHEN WHEN 宏观指标变化
THEN 检测 regime transition 并计算概率


## 4. 行为约束

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed |
| BR-002 | 输出不可变，下游只读 |
| BR-003 | No lookahead |

## 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
