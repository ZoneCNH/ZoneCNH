# 投影层自动化生成计划

> 来源: issue #1095 / 报告 A6 / §5 路线图 #12
> 创建: 2026-06-25
> 状态: Proposed

## 问题

当前 STATUS.md / ARCHITECTURE.md / README.md 投影层全手工块，30d churn STATUS 270 / ARCH 189 / README 144。业务域 52 模块无机器事实源。

## 目标

投影层从事实层机器生成，手工块最小化，降低文档同步 churn ≥50%。

## 事实层扩展计划

### 阶段 1: 基座层（已完成）
- index.json 已含 21 基座模块（spec/impl/release/factory/live/blocker）

### 阶段 2: 业务域扩展
- 新增 `.foundationx/status/business-modules.json` schema
- 字段: module / layer / spec_status / impl_progress / tasks_coverage / ac_coverage / tc_coverage / evidence_coverage / tests_pass / release_tag
- 数据来源: audit-status.py 扫描 module/*/SPEC.md + TRACEABILITY.md + tasks/ 生成

### 阶段 3: 投影生成器
- `scripts/generate-projections.py` 从 index.json + business-modules.json 生成 STATUS.md / ARCHITECTURE.md 表格行
- 手工块仅保留叙述性文字，表格行机器生成

## 依赖
- issue #1086（tasks 拆分，提供 tasks_coverage 数据源）
- issue #1094（CI gate，提供 pipeline 右段数据）

## 验收
- [ ] business-modules.json schema 定义
- [ ] audit-status.py 增 business-modules 扫描
- [ ] generate-projections.py 原型
- [ ] STATUS.md 表格行 50%+ 机器生成
- [ ] 30d churn STATUS.md 降至 <150
