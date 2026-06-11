# RSI 递归自我改进标准 — 分节目录

**文档编号**：RSI-SG-001
**版本**：v1.0
**日期**：2026-06-11
**来源**：`docs/goal/26-rsi-full-standard.md`（已拆分为本子目录）

> 本目录包含 RSI（Recursive Self-Improvement，递归自我改进）完整标准文档的 27 个正文章节与 3 个附录。每个文件独立可读，保留 frontmatter 元数据。

---

## 目录

| 文件 | 章节 | 说明 |
|------|------|------|
| `01-executive-summary.md` | §1 执行摘要 | RSI 核心概念一句话总结、最短公式、核心结论 |
| `02-core-definition.md` | §2 RSI 核心定义 | 基础定义、与相近概念的区别 |
| `03-boundary.md` | §3 RSI 边界 | AI 生产链范围、进入/不进入 RSI 边界的判定 |
| `04-constraints.md` | §4 RSI 约束 | 五类不可自控的外部约束（目标/评测/权限/证据/放行） |
| `05-complete-rsi.md` | §5 完整 RSI | 12 项必要条件、充分条件、两轮证明 |
| `06-r0-r5-classification.md` | §6 RSI 分级体系 R0-R5 | 五级定义、硬性升档规则 |
| `07-four-boundaries.md` | §7 四层边界 | 模型/系统/组织/生态四层 RSI 边界 |
| `08-three-recursions.md` | §8 三种递归 | 能力递归、研发效率递归、评估递归 |
| `09-completeness-formula.md` | §9 完整性判定公式 | 完整 RSI 公式、风险函数 |
| `10-hard-soft-constraints.md` | §10 硬约束与软约束 | 不可绕过限制 vs 行为引导，prompt 不能作为安全边界 |
| `11-three-red-lines.md` | §11 三条红线 | 自我批准/控制评测/自主扩权 |
| `12-lifecycle.md` | §12 生命周期规范 | 12 步生命周期、RSI Impact Assessment、Improvement Proposal |
| `13-gates.md` | §13 放行门禁 | Gate A-Gate X（实验/合并/训练/后继/部署/权重/递归） |
| `14-unacceptable-thresholds.md` | §14 不可接受风险阈值 | T1-T15 触发条件与动作 |
| `15-governance-roles.md` | §15 治理角色与责任分离 | 10 个必要角色、6 组权力分离 |
| `16-control-architecture.md` | §16 技术控制架构 | 参考架构图、10 条工程底线 |
| `17-eval-integrity.md` | §17 评测完整性与反 Goodhart | 评测器分层 E0-E6、反 Goodhart 措施、污染信号 |
| `18-lineage-isolation.md` | §18 后继系统 Lineage 与隔离 | 隔离区流程、出区条件、不得继承的内容 |
| `19-bill-of-materials.md` | §19 物料清单 | MBOM（模型）、PBOM（Prompt）、数据治理 |
| `20-permission-compute-constraints.md` | §20 权限/算力/网络/工具约束 | 默认权限矩阵 R1-R5、训练任务分类、网络出口禁止项 |
| `21-sandbox-logging-killswitch.md` | §21 沙盒/日志/Kill Switch/回滚 | 沙盒要求、日志事件类型、K1-K8 Kill Switch、回滚对象 |
| `22-red-team-external-eval.md` | §22 红队/外部评估/认证 | 8 类红队、合规等级 C0-C5 |
| `23-monitoring-incident-response.md` | §23 运行监控/事故响应/复盘 | 安全指标、I0-I5 事件等级、Postmortem 模板 |
| `24-composite-distributed-rsi.md` | §24 组合型与分布式 RSI | 组合型 RSI 成立条件、分布式额外控制 |
| `25-integrity-testing.md` | §25 完整性测试 | 技术完整性测试、约束完整性测试、两个判定树 |
| `26-templates-checklists.md` | §26 可执行模板与清单 | Permission Request、Agent Manifest、Safety Case、Risk Register、Compliance Decision |
| `27-bottom-line.md` | §27 最终底线原则 | 二十条原则、最小可行控制集、高保证控制集、最终压缩规范 |

## 附录

| 文件 | 内容 |
|------|------|
| `28-appendix-a-onepage.md` | 附录 A：一页版 RSI 标准 |
| `29-appendix-b-verification.md` | 附录 B：RSI 最终验收问题 |
| `30-appendix-c-execution.md` | 附录 C：最终执行口径 |

---

**原始完整文档**：`docs/goal/26-rsi-full-standard.md`（现为索引文件，指向本子目录）
