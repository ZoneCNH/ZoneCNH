# ISA: 三文档一致性审计 2026-06-15

## 1. 问题 — 痛点 + 为什么现在做？

STATUS.md / README.md / ARCHITECTURE.md 三文档之间存在系统性数量漂移。agent 凭常识编造计数（18 vs 14 Release、67% vs 62% 进度、有版本号 1/0/0 vs 2/3/3），而非逐表逐行 `grep` 统计。漂移累积导致三文档多处互不一致，且无机械门禁阻止新漂移注入。

为什么现在做：domainx 归属调整、strategies 404、7 个 v0.1.0-draft 模块新增等多重变更叠加，漂移风险达到峰值。不修复则 STATUS.md 失去事实源权威。

## 2. 现状 — 量化描述

| 指标 | 审计前 | 问题 |
|------|:-----:|------|
| GitHub Release 数 | 声称 18/20 | 实际 14/20（clickhousex/contracts/transportx/domainx 无 Release） |
| 平均进度 | 声称 67% | 实际 62%（重算 4955/80） |
| 域统计有版本号 | 分析域 1, 决策域 0, 执行域 0 | 实际 2/3/3（遗漏 7 个 v0.1.0-draft 模块） |
| 组件总数 | 81 | 80（strategies 404 已删除但计数未同步） |
| 同步检查表 | 5 处过时 | 自身就是错误源 |
| 404 链接 | 1 (strategies) | 策略引用散落三文档 |
| 仪表盘 5% 分布 | 15 | 22（7 个新模块 + 原 15） |
| ARCHITECTURE 版本 | 12 处滞后 | testkitx v0.4.0, redisx v1.0.0 等 |
| domainx 归属 | 三文档不一致 | README L2.5, ARCH 基座, STATUS L2.5 |
| observex 横切 | v0.3.1 | 实际 v1.0.0 |

## 3. 理想状态 — 用户视角的成功描述

运行 `python3 scripts/audit-status.py --network` 输出 22/22 PASS。三文档全部自洽，零 404，各有版本号/无版本号/进度分布/已有已创建全部满足自洽恒等式。后续任何数量变更被 CountGuard+CI 阻断，无法再凭空编造。

## 4. 不做什么

- 不修改任何模块的实际代码或 GitHub 仓库
- 不重写 ARCHITECTURE.md 或 README.md 全文
- 不修改 `docs/goal/`、`module/` 下的 SPEC 文件
- 不修改 ROADMAP.md 的时间线或任务内容（仅清理 strategies 引用）
- 不新增或删除任何 GitHub 仓库（仅清理已不存在的 strategies 文档引用）

## 5. 原则

1. **数量必须可复现验证**：任何计数变更必须附带 grep/awk/gh api one-liner 验证命令
2. **三文档同步不可协商**：STATUS 改则 README 和 ARCHITECTURE 必须同步检查
3. **事实源优先**：GitHub API 返回值 > 文档声称值；`grep` 实际行数 > 表格标注数
4. **预防优于修复**：宁可多写一个 hook/CI gate，不依赖 agent 自觉

## 6. 约束

- 所有变更通过 PR + squash merge 合入 main
- 不改动 `.foundationx/status/index.json`（机器事实源，由 xlibgate 生成）
- 不改动 `.config/` 下的 YAML 注册表
- CountGuard hook 不阻断非三文档的编辑

## 7. 目标

做完后我们将拥有：三文档全部自洽的 STATUS/README/ARCHITECTURE，一条 `python3 scripts/audit-status.py` 即可验证的机械化门禁，以及三层预防体系阻断后续漂移。

## 8. 验收标准（ISC）

- [x] ISC-1 domainx 三文件统一归基座（grep domainx 在三文档中均属基座）
- [x] ISC-2 仪表盘自洽：55+1+22+2=80, 37+43=80, 58+22=80（audit-status.py check 2）
- [x] ISC-3 ARCH 状态表 12 处版本/进度与 STATUS 对齐（逐行对比）
- [x] ISC-4 78 repos gh api 逐一验证，0 404（audit-status.py --network check 7）
- [x] ISC-5 同步表各域计数与组件表行数一致（audit-status.py check 3）
- [x] ISC-6 strategies 全部三文档引用已移除（grep -rn strategies | grep -v strategyx）
- [x] ISC-7 GitHub Release 14/20、git tag 18/20 与 `gh api` 验证一致
- [x] ISC-8 CountGuard hook + audit-status.py + CI gate 三层预防全部部署
- [x] ISC-9 `python3 scripts/audit-status.py` 22/22 PASS
- [x] ISC-10 域统计有版本号合计 37，各域分项与 awk 实际计数一致

## 9. 测试策略

每项 ISC 对应验证方法：

| ISC | 方法 | 命令/工具 |
|-----|------|-----------|
| 1 | grep 三文档 domainx 行归属 | `grep -n domainx STATUS.md README.md ARCHITECTURE.md` |
| 2 | 仪表盘 vs 合计 | audit-status.py check 2 |
| 3 | 逐行对比 | 人工 + audit-status.py check 1 |
| 4 | 78 repos 逐一 HTTP 200 | `audit-status.py --network` check 7 |
| 5 | 同步表 vs grep 计数 | audit-status.py check 3 |
| 6 | 三文档 grep strategies | `grep -rn strategies STATUS.md README.md ARCHITECTURE.md \| grep -v strategyx` |
| 7 | gh api 逐一查 Release/tag | 人工核查表 D, F |
| 8 | 文件存在 + hook 测试 | `ls .claude/hooks/count-guard.mjs scripts/audit-status.py .github/workflows/audit-status.yml` |
| 9 | 运行审计脚本 | `python3 scripts/audit-status.py` |
| 10 | awk 逐域数版本 | `awk -F'\|'` 逐域计数 |

## 10. 功能清单

| 优先级 | 功能 | ISC |
|:------:|------|:---:|
| P0 | 基座版本 vs GitHub Release 逐一核对并修正 | 7 |
| P0 | strategies 404 全文件移除 + 决策域/仪表盘/风险清单同步 | 6 |
| P0 | domainx 三文档归属统一 | 1 |
| P0 | 域统计有版本号补齐（2/3/3） | 10 |
| P1 | 仪表盘全部递推重算（总数/已有/已创建/进度/分布） | 2 |
| P1 | 同步检查表自审计并修正 | 5 |
| P1 | ARCHITECTURE 状态表版本/进度对齐 | 3 |
| P1 | 78 repos 全量 404 扫描 | 4 |
| P2 | CountGuard hook 部署 + 升级为 block 模式 | 8 |
| P2 | audit-status.py 脚本 + CI gate | 8, 9 |
| P2 | CLAUDE.md 规则固化 | -- |

## 11. 决策记录

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-06-15 | domainx 归入基座（三文档统一） | ARCH 和 STATUS 已将 domainx 列在基座，README 滞后 |
| 2026-06-15 | strategies 全文件删除（非改为纯文本） | 仓库 404，保留引用违反模块-仓库强制对应规则 |
| 2026-06-15 | 同步表 STATUS 列用 unique repos (78) 非 domain-sum (80) | 与 README/ARCH 可比；domain-sum 在表注说明 |
| 2026-06-15 | CountGuard 高危模式 block（exit 2）非 warn-only | 组件总数/平均进度/有版本号是最常编造的三项；告警不足以阻止 |
| 2026-06-15 | CI gate 阻断非告警 | audit-status.py 是确定性工具，假阳性概率极低 |
| 2026-06-15 | `有版本号` 含 v0.1.0-draft | draft 仍是在表格中有明确非空非 `-` 版本号的条目 |

## 12. 变更日志

| 日期 | 变更 |
|------|------|
| 2026-06-15 01:00 | 审计启动：19 基座 vs GitHub Release 逐一核对 |
| 2026-06-15 01:30 | domainx 归并 + strategies 移除 |
| 2026-06-15 02:00 | 域统计、仪表盘、同步表递推重算 |
| 2026-06-15 02:30 | CLAUDE.md 规则固化 + CountGuard 部署 |
| 2026-06-15 03:00 | audit-status.py + CI gate 部署 |
| 2026-06-15 03:30 | CountGuard 升级 block 模式 |
| 2026-06-15 04:00 | R7 恢复 + 日期修正 + 最终审计 PASS |

## 13. 最终验证

- [x] ISC 1 通过（grep domainx 三文档，全部归基座）
- [x] ISC 2 通过（audit-status.py check 2: 4/4）
- [x] ISC 3 通过（ARCH 状态表 12 处对齐）
- [x] ISC 4 通过（78 repos, 0 404）
- [x] ISC 5 通过（audit-status.py check 3: 3/3）
- [x] ISC 6 通过（strategies refs: 0）
- [x] ISC 7 通过（14/20 Release, 18/20 tag, gh api verified）
- [x] ISC 8 通过（三层预防全部部署）
- [x] ISC 9 通过（22/22 PASS）
- [x] ISC 10 通过（awk 逐域计数 = 37）
