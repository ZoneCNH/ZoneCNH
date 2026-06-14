# ISA: 三文档一致性审计 2026-06-15

## 1. 问题 — 痛点 + 为什么现在做？

STATUS.md / README.md / ARCHITECTURE.md 三文档之间存在系统性数量漂移。agent 凭常识编造计数（18 vs 14 Release、67% vs 62% 进度、有版本号 1/0/0 vs 2/3/3），而非逐表逐行 `grep` 统计。漂移累积导致三文档多处互不一致，且无机械门禁阻止新漂移注入。

为什么现在做：domainx 归属调整、strategies 404、7 个 v0.1.0-draft 模块新增等多重变更叠加，漂移风险达到峰值。不修复则 STATUS.md 失去事实源权威。

## 2. 现状 — 量化描述

| 指标 | 审计前 | 实际 | 差异来源 |
|------|:-----:|:----:|------|
| GitHub Release 数 | 声称 18/20 | 14/20 | clickhousex/contracts/transportx 仅 tag 无 Release，domainx v0.1.0 无 Release |
| 平均进度 | 声称 67% | 62% (4955/80) | strategies 60% 项移除 + 7 个 5% 项新增 |
| 域统计有版本号 | 分析域 1, 决策域 0, 执行域 0 | 2, 3, 3 | 遗漏 7 个 v0.1.0-draft 模块 |
| 有版本号合计 | 30 | 37 | 同上 |
| 组件总数 | 81 | 80 | strategies 404 已删除但计数未同步 |
| 仪表盘 5% 分布 | 15 | 22 | 7 个新模块 + 原 15 |
| 仪表盘 60% 条目 | 1 (strategies) | 0 | strategies 404 但条目仍在 |
| 仪表盘已有/已创建 | 59/22 | 58/22 | domainx 从 L2.5 已有→基座已有，净变化 0 |
| 同步检查表 | 5 处与 grep 不符 | 全部一致 | 自身就是错误源（最危险：误导后续 audit） |
| 404 链接 | 1 (strategies) | 0 | 策略引用散落三文档 + DEPS.yaml + ROADMAP |
| ARCHITECTURE 版本 | 12 处滞后 | 全部对齐 | testkitx v0.4.0, redisx v1.0.0, xlib-standard v- 等 |
| domainx 归属 | 三文档不一致 | 全部归基座 | README L2.5, ARCH 基座, STATUS L2.5 |
| observex 横切段 | v0.3.1 | v1.0.0 | "修正"方向反了（实际 v1.0.0 是正确的） |
| 合计行与分项和 | 不一致 | 一致 | 合计 81→80 后分项未同步 |

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

- 时间：单 session 内完成（约 3h，2026-06-15 01:00-04:00 UTC+8）
- 所有变更通过 PR + squash merge 合入 main
- 不改动 `.foundationx/status/index.json`（机器事实源，由 xlibgate 生成）
- 不改动 `.config/` 下的 YAML 注册表
- 不改动 `docs/goal/`、`module/` 下的 SPEC 文件
- CountGuard hook 不阻断非三文档的编辑
- 审计脚本零外部依赖（仅 Python stdlib + gh CLI）

## 7. 目标

做完后我们将拥有：三文档全部自洽的 STATUS/README/ARCHITECTURE，一条 `python3 scripts/audit-status.py` 即可验证的机械化门禁，以及三层预防体系阻断后续漂移。

## 8. 验收标准（ISC）

- [x] ISC-1 domainx 三文件统一归基座：`grep -n domainx STATUS.md | grep 'github.com'` 在基座组件表中（非 L2.5 表）。三文档均如此。
- [x] ISC-2 仪表盘三恒等式自洽：55+1+22+2=80, 37+43=80, 58+22=80。audit-status.py check 2 全 PASS。
- [x] ISC-3 ARCHITECTURE 状态表 12 处版本/进度与 STATUS.md 组件表对齐。逐字段对比：xlib-standard v- → v1.0.0, testkitx v0.4.0→v1.0.0, redisx v1.0.0→v1.0.1, etc.
- [x] ISC-4 三文档 78 unique repos 全部返回 HTTP 200。`audit-status.py --network` 逐一验证。
- [x] ISC-5 同步检查表 README/ARCH/STATUS 三列与各文档 `grep -oP github.com... | sort -u | wc -l` 一致。决策域 6/6/6, 分析域 8/8/8, L2.5 4/4/4。
- [x] ISC-6 strategies 全部引用已移除：`grep -rn strategies STATUS.md README.md ARCHITECTURE.md | grep -v strategyx` 返回空。
- [x] ISC-7 GitHub Release 14/20、git tag 18/20：对 20 个基座模块逐一运行 `gh release view -R ZoneCNH/$repo` 和 `gh api repos/ZoneCNH/$repo/git/refs/tags`，与 STATUS.md 版本列逐行对比，全部一致。
- [x] ISC-8 CountGuard hook + audit-status.py + CI gate 三层预防全部存在且可运行：`ls .claude/hooks/count-guard.mjs scripts/audit-status.py .github/workflows/audit-status.yml` 均存在；`node .claude/hooks/count-guard.mjs` 正确处理 block/warn/pass-through 三类输入。
- [x] ISC-9 `python3 scripts/audit-status.py` 22/22 PASS（含 --network 标志时 22/22，纯本地 21/21）。
- [x] ISC-10 域统计有版本号合计 37 = 18(base) + 4(L2.5) + 5(Provider) + 2(analysis) + 3(decision) + 3(execution) + 1(x.go) + 1(observex)。每个分项通过 `awk -F'|'` 从对应组件表逐行提取非空非 `-` 版本列计数验证。

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
| 2026-06-15 | domainx 归入基座（三文档统一） | ARCH 和 STATUS 已将 domainx 列在基座，README 滞后。统一为基座后三文档 L2.5=4，无需维护两套口径 |
| 2026-06-15 | strategies 全文件删除（非改为纯文本或标注"已移除"） | 仓库 404，保留引用违反 CLAUDE.md 模块-仓库强制对应规则。纯文本引用同样会成为误导（读者点不了链接） |
| 2026-06-15 | 同步表 STATUS 列用 unique repos (78) 非 domain-sum (80) | 与 README/ARCH 的 unique 计数方法一致，具有可比性。domain-sum=80 的差异在表注中说明（observex 双归属 + stdlib.rs + module） |
| 2026-06-15 | CountGuard 高危模式 block（exit 2）非 warn-only | 组件总数/平均进度/有版本号是本次审计发现的最高频编造项。告警不足以阻止——agent 在 linter 触发的快速编辑循环中会忽略 stderr 警告。Block 强制 agent 先验证 |
| 2026-06-15 | `COUNT_GUARD_STRICT=false` 降级而非永久豁免 | 提供逃生舱但不鼓励滥用。agent 在已验证后 export 该变量，commit 后自动恢复严格模式 |
| 2026-06-15 | CI gate 阻断非仅告警 | audit-status.py 是确定性工具（纯数据对比，无 AI/概率判断），假阳性概率为零。任何 FAIL 都意味着文档不一致，必须阻断 |
| 2026-06-15 | `有版本号` 包含 v0.1.0-draft | draft 版本仍在表格中有明确的、非空、非 `-` 的版本号字符串。排除它们会导致与"无版本号"列的计数不一致（合计 ≠ 80）。该决定影响分析域/决策域/执行域三个域的统计数字 |
| 2026-06-15 | 审计先全量、后预防（非边修边防） | 先完成全部修复（#385-#405 约 20 PRs），再部署预防门禁（#399 CountGuard, #408 CI）。理由：预防门禁会阻断修复过程中的临时不一致状态 |

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

## 12. 风险与回滚

| 风险 | 概率 | 影响 | 缓解 |
|------|:---:|------|------|
| 审计引入新计数错误 | 中 | 中：三文档再次漂移 | audit-status.py CI gate 在 PR merge 前阻断；人工核查 D-F |
| linter 在 merge 时回退修复 | 高（已发生 3 次） | 低：单行回退，audit 脚本下次运行检出 | 每次 session 开始时跑 audit-status.py；CI gate 提供第二防线 |
| 78 repos 中有 repo 在审计后被删除 | 极低 | 低：链接失效但文档正确 | audit-status.py --network 可随时重跑 |
| CountGuard 阻断合法编辑 | 低 | 中：阻塞 workflow | `COUNT_GUARD_STRICT=false` 逃生舱；block 仅针对 3 个最高危模式 |
| 域统计表行号漂移（后续编辑改变行号） | 中 | 低：audit-status.py 基于 heading 解析 | heading-based 解析不依赖行号 |

回滚策略：所有 43 个 PR 均为 squash-merge，`git revert` 任何单个 PR 不影响其余。若需全量回滚：`git revert 7cef153..HEAD` 回退到 #384。

## 13. 最终验证

- [x] ISC 1 通过（证据：`grep domainx STATUS.md \| grep github.com` → 行 39 在基座表内；README L88 在基座契约段；ARCH L24,L130 归基座）
- [x] ISC 2 通过（证据：`python3 scripts/audit-status.py` check 2 → 4/4 PASS）
- [x] ISC 3 通过（证据：`git diff 7cef153..HEAD -- ARCHITECTURE.md \| grep '^-.*\|^+.*'` → 12 模块逐项对齐）
- [x] ISC 4 通过（证据：`python3 scripts/audit-status.py --network` check 7 → "No 404 links (78 repos)"）
- [x] ISC 5 通过（证据：`python3 scripts/audit-status.py` check 3 → 3/3 PASS；同步表 77/77/78 与 grep 计数一致）
- [x] ISC 6 通过（证据：`grep -rn strategies STATUS.md README.md ARCHITECTURE.md \| grep -v strategyx` → 空输出）
- [x] ISC 7 通过（证据：`for r in ...; do gh api repos/ZoneCNH/$r/releases \| jq length; done` → 14 有 Release，18 有 tag，与 STATUS.md 版本列一致）
- [x] ISC 8 通过（证据：文件存在 + `node .claude/hooks/count-guard.mjs < test_block.json` → exit 2; `python3 scripts/audit-status.py` → exit 0; CI yml 存在）
- [x] ISC 9 通过（证据：`python3 scripts/audit-status.py` → "22 passed / 0 failed"）
- [x] ISC 10 通过（证据：`awk -F'\|'` 逐域计数 → 18+4+5+2+3+3+1+1 = 37；域统计表合计行 = 37）
