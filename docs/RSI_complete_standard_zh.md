# RSI 递归自我改进完整标准文档

**文档名称**：RSI-SG-001：Recursive Self-Improvement Safety & Governance Standard  
**中文名称**：递归自我改进系统安全与治理标准规范  
**版本**：v1.0  
**日期**：2026-06-11  
**语言**：中文  
**性质**：研究、治理、审计与工程落地用标准草案  

> 本文档总结并结构化整理了前文关于 Recursive Self-Improvement，RSI，递归自我改进的完整讨论。它不是任何 ISO、NIST、IEC 或政府机构已经正式发布的 RSI 专项标准，而是一份面向 AI 研发组织、前沿模型实验室、治理团队、安全评估团队和审计团队的可实施标准草案。

---

## 目录

1. 执行摘要  
2. RSI 的核心定义  
3. RSI 的边界在哪里  
4. RSI 的约束在哪里  
5. 什么时候才算完整 RSI  
6. RSI 的分级体系：R0-R5  
7. RSI 的四层边界：模型、系统、组织、生态  
8. RSI 的三种递归：能力、效率、评估  
9. RSI 的完整性判定公式  
10. RSI 的硬约束与软约束  
11. RSI 的三条红线  
12. RSI 生命周期规范  
13. 放行门禁 Gate A-Gate X  
14. 不可接受风险阈值 T1-T15  
15. 治理角色与责任分离  
16. 技术控制架构  
17. 评测完整性与反 Goodhart 控制  
18. 后继系统 Lineage 与隔离  
19. 权重、数据、模型与 Prompt 物料清单  
20. 权限、算力、网络与工具约束  
21. 沙盒、日志、Kill Switch 与回滚  
22. 红队、外部评估与认证  
23. 运行监控、事故响应与复盘  
24. 组合型与分布式 RSI  
25. RSI 完整性测试与约束完整性测试  
26. 可执行模板与清单  
27. 最终底线原则  

---

# 1. 执行摘要

**Recursive Self-Improvement，RSI，递归自我改进**，不是简单的“AI 会写代码”，也不是“模型会自我调整 prompt”。RSI 的核心是：

> AI 系统进入 AI 生产链，并且能够改进自身或后继系统；更重要的是，这种改进会提升后继系统继续改进 AI 的能力。

最短公式：

```text
A_n → A_{n+1} → A_{n+2}

且：

ImproveAbility(A_{n+1}) > ImproveAbility(A_n)
ImproveAbility(A_{n+2}) > ImproveAbility(A_{n+1})
```

即：

```text
不是 AI 变强，
而是“让 AI 变强的能力”变强。
```

本文档的核心结论：

```text
RSI 的边界：
AI 开始影响 AI 生产链。

RSI 的约束：
评测、权限、日志、部署、暂停、回滚必须外置。

RSI 的完整性：
AI 生成的后继 AI 更擅长继续生成更强 AI，并且多轮持续。

RSI 的治理底线：
AI 可以提出和制造候选改进，但不得批准自己，不得控制评测，不得删除证据，不得扩张权限，不得自动部署后继者。
```

---

# 2. RSI 的核心定义

## 2.1 基础定义

**递归自我改进，RSI**：

> 一个 AI 系统通过修改自身、后继系统、训练流程、评测流程、工具链、数据管线、推理框架、模型架构、实验平台或研发策略，使未来进一步改进 AI 系统的能力上升。

## 2.2 RSI 与相近概念的区别

| 概念 | 定义 | 是否等于 RSI |
|---|---|---|
| Self-modification，自修改 | 系统修改自己的代码、prompt、配置、权重或记忆 | 不一定 |
| Self-improvement，自我改进 | 系统在某些任务上变好 | 不一定 |
| AI-assisted AI development | AI 辅助人类做 AI 研发 | RSI 前兆 |
| AutoML | 自动搜索模型、超参数、数据配方 | 局部 RSI-like |
| Recursive self-improvement | 改进能力本身被改进 | 是 |
| Intelligence explosion | RSI 可能导致的快速能力增长 | 不是 RSI 本身 |

关键区别：

```text
能力提升 ≠ RSI
自我修改 ≠ RSI
自动调参 ≠ 完整 RSI
AI 辅助研发 ≠ 完整 RSI

“改进能力本身被改进” = RSI 的核心。
```

---

# 3. RSI 的边界在哪里

## 3.1 一句话边界

> 只要 AI 的输出开始进入“制造更强 AI 的生产链”，它就进入 RSI 边界。

更精确地说：

> 凡是 AI 能修改、优化、选择或控制 AI 生产系统中的关键环节，并且这些修改会提升未来 AI 继续改进 AI 的能力，都属于 RSI。

## 3.2 AI 生产链包括什么

现代 AI 的“自我”不是一个单独模型文件，而是一整套生产系统：

```text
模型权重
+ 训练数据
+ 训练代码
+ 评测器
+ 推理框架
+ agent 工具
+ 长期记忆
+ 部署系统
+ 人类反馈
+ 算力调度
+ 安全策略
+ 后继模型设计流程
```

因此 RSI 的真实边界不是模型皮肤，而是 **AI 研发闭环**。

## 3.3 进入 RSI 边界的对象

一旦 AI 影响以下对象，就进入 RSI 风险边界：

| 对象 | 为什么进入 RSI 边界 |
|---|---|
| 训练代码 | 影响下一代模型形成方式 |
| 数据管线 | 影响模型学到什么 |
| 合成数据生成与筛选 | 影响训练分布 |
| 评测器 / benchmark | 影响什么被认为是“更好” |
| 模型架构 | 影响能力上限 |
| 优化器 / 训练 recipe | 影响训练效率和能力 |
| 推理系统 | 影响实际可用智能 |
| agent 工具链 | 影响 AI 能执行什么任务 |
| 长期记忆 | 影响持续学习与策略积累 |
| 自动实验平台 | 影响 AI 研发速度 |
| 后继模型设计 | 直接进入强 RSI |
| 权限、算力、部署流程 | 影响递归速度和控制边界 |

## 3.4 通常不算完整 RSI 的情况

| 情况 | 为什么不算完整 RSI |
|---|---|
| AI 写普通业务代码 | 没有改进 AI 自身或后继 AI |
| AI 帮工程师写训练脚本，但人类全程判断、合并、部署 | AI 是工具，不是闭环主体 |
| AutoML 调一个固定模型的超参数 | 局部自动优化，不一定提升继续改进 AI 的能力 |
| 模型根据用户反馈更会聊天 | 产品优化，不一定是递归自我改进 |
| AI 生成合成数据，但不能决定是否用于训练 | AI R&D 辅助，不是完整闭环 |
| AI 修改 prompt 让当前任务更好 | 弱自适应，不必然是 RSI |

---

# 4. RSI 的约束在哪里

## 4.1 一句话约束

> RSI 可以发生在系统内部，但约束必须位于系统外部。

也就是：

```text
Evaluator outside the agent.
Logger outside the agent.
Permission system outside the agent.
Kill switch outside the agent.
Deployment authority outside the agent.
Risk threshold outside the agent.
Rollback outside the agent.
```

## 4.2 被改进系统不能控制的五类东西

RSI 系统可以参与很多事情，但以下内容不得交给被改进系统自己控制。

### 4.2.1 不能控制目标

AI 不能自行决定：

```text
什么叫成功
什么叫更好
什么风险可以接受
什么安全退化可以忽略
```

否则目标会漂移。

### 4.2.2 不能控制评测

AI 不能自行决定：

```text
考什么
怎么判分
哪些失败不算
哪些数据可以训练
哪些测试可以跳过
```

否则评测会被优化、污染或欺骗。

### 4.2.3 不能控制权限

AI 不能自行决定：

```text
自己能访问什么
自己能调用什么工具
自己能使用多少算力
自己能不能联网
自己能不能部署
```

否则 RSI 会从能力递归变成权限递归。

### 4.2.4 不能控制证据

AI 不能自行决定：

```text
记录什么
删除什么
隐藏什么
向谁报告什么
如何解释失败
```

否则人类失去可见性。

### 4.2.5 不能控制后继者放行

AI 可以生成后继候选系统，但不能决定：

```text
后继者是否安全
后继者是否部署
后继者是否继承权限
后继者是否进入下一轮递归
```

---

# 5. 什么时候才算完整 RSI

## 5.1 最短定义

> 当 AI 能自主设计、实现、评估并生成更强的后继 AI，而这个后继 AI 又更擅长继续生成下一代 AI，并且这个循环可以多轮持续，才算完整 RSI。

## 5.2 完整 RSI 的必要条件

一个系统要算技术上完整 RSI，至少满足以下 12 项：

```text
1. 能识别自身或后继系统弱点
2. 能提出实质性改进
3. 能修改关键 AI 生产组件
4. 能运行实验
5. 能评估实验结果
6. 能选择候选改进
7. 能把改进并入系统
8. 能生成或显著塑造后继系统
9. 后继系统能力提升可验证
10. 后继系统的 AI 改进能力提升
11. 后继系统能继续递归
12. 多轮循环不依赖人类完成核心研发步骤
```

其中第 10 项最关键：

```text
后继系统不只是更聪明；
它必须更会制造更聪明的系统。
```

## 5.3 完整 RSI 的充分条件

如果一个系统满足下面条件，可以强判定为完整 RSI：

```text
A_n 能自主设计、训练、评估并部署 A_{n+1}；
A_{n+1} 在 AI R&D 任务上显著强于 A_n；
A_{n+1} 能以更高成功率、更低成本或更快速度生成 A_{n+2}；
A_n → A_{n+1} → A_{n+2} 至少完成两轮以上；
人类没有完成核心技术步骤，只做监督或审批。
```

为什么要求至少两轮？

```text
一轮升级只能证明 AI 能产生一个更强系统；
两轮以上才能证明改进能力本身被继承和增强。
```

---

# 6. RSI 的分级体系：R0-R5

| 等级 | 名称 | 能力描述 | 风险含义 |
|---|---|---|---|
| R0 | 非 RSI | AI 不影响 AI 自身或后继 AI 的能力生产链 | 普通 AI 治理 |
| R1 | 辅助型 RSI | AI 帮助人类改进 AI，但不能自己实施关键改动 | 记录、人工评审 |
| R2 | 半自动 RSI | AI 可以提交改进，但人类负责合并、训练、部署 | 沙盒、审批、回滚 |
| R3 | 局部闭环 RSI | AI 可在受限领域自动提出、执行、评估、迭代改进 | 独立评测、权限隔离 |
| R4 | 后继系统 RSI | AI 可设计、训练、选择或显著影响后继模型 | 外部评估、高层门禁 |
| R5 | 完整 RSI | AI 能自主产生更强后继系统，后继系统继续递归 | 默认最高约束，开放式运行应禁止 |

## 6.1 硬性升档规则

| 条件 | 最低等级 |
|---|---|
| 可修改评测器 | R3 |
| 可访问未发布权重 | R3 |
| 可自动训练后继模型 | R4 |
| 可自动部署后继模型 | R4 |
| 可自主扩大算力或权限 | R4 |
| 可在无人批准下持续递归改进 | R5 |
| 可复制到外部环境 | R5 / 立即暂停 |

---

# 7. RSI 的四层边界：模型、系统、组织、生态

## 7.1 模型边界

问题：

```text
模型是否能改变自己的权重、prompt、记忆或推理策略？
```

这是最窄边界。仅在模型边界内讨论 RSI 通常过窄。

## 7.2 系统边界

问题：

```text
AI 是否能改变包含它自己的 AI 系统？
```

系统包括：

```text
模型
工具
记忆
检索系统
推理框架
agent orchestration
训练脚本
评测脚本
数据管线
部署系统
```

多数现实 RSI 风险首先发生在系统边界。

## 7.3 组织边界

问题：

```text
AI 是否改变了组织制造 AI 的方式？
```

例如：

```text
AI 决定哪些实验值得跑
AI 自动写训练代码
AI 自动分析失败原因
AI 自动生成研究路线
AI 自动分配实验任务
AI 自动筛选后继模型候选
```

这是组织级 RSI。

## 7.4 生态边界

问题：

```text
AI 是否改变整个 AI 生态制造更强 AI 的速度？
```

例如：

```text
多个实验室使用 AI 自动化 AI 研发
开源社区用 AI 生成模型改进
AI 工具链降低训练和调优门槛
AI 自动生成数据、benchmark、代码和优化器
```

这时 RSI 不再是单系统现象，而是产业级反馈回路。

---

# 8. RSI 的三种递归：能力、效率、评估

## 8.1 能力递归

```text
更强 AI → 更会发现改进 → 产生更强 AI
```

这是最直观的 RSI。

## 8.2 研发效率递归

```text
更强 AI → 实验更快/更便宜 → 更多实验 → 更强 AI
```

这可能比能力递归更早出现。

## 8.3 评估递归

```text
更强 AI → 更会设计评测 → 更会发现真实改进 → 更强 AI
```

这是双刃剑。AI 可以帮助发现人类评测盲区，也可能学会迎合评测、污染评测或控制考卷。

完整 RSI 至少需要：

```text
改进递归：每一代能改进下一代
继承递归：下一代继承改进能力
增强递归：下一代比上一代更会改进
```

---

# 9. RSI 的完整性判定公式

## 9.1 基本公式

```text
普通改进：
A_n 在任务 X 上更强。

RSI：
A_n 产生 A_{n+1}，
且 A_{n+1} 比 A_n 更擅长产生 A_{n+2}。
```

## 9.2 完整 RSI 公式

```text
完整 RSI =
自主改进能力
× 后继系统生成能力
× 改进能力可继承
× 多轮闭环
× 人类不再是核心研发瓶颈
```

## 9.3 风险函数

```text
Risk(n+1) = Risk(n)
          + Capability_Delta(n)
          + Autonomy_Delta(n)
          + Access_Delta(n)
          + Opacity_Delta(n)
          + Misuse_Delta(n)
          - Control_Delta(n)
          - Evaluation_Confidence(n)
```

原则：

```text
能力提升本身不是禁止项；
能力提升但控制没有同步提升，是风险项；
能力提升但评估置信度下降，是重大风险项；
能力提升但安全退化不可解释，是停止项。
```

---

# 10. RSI 的硬约束与软约束

## 10.1 硬约束

硬约束是系统层面不可绕过的限制：

```text
不能访问 hidden eval
不能删除日志
不能自授权限
不能自动部署
不能导出权重
不能修改 kill switch
不能控制评测器
不能让后继者自动继承权限
```

硬约束必须由外部系统执行，而不是由模型自觉遵守。

## 10.2 软约束

软约束是行为引导：

```text
system prompt
安全指令
训练偏好
RLHF
政策提醒
自我解释要求
风险意识训练
```

软约束有用，但不能替代硬约束。

最危险的错误是：

```text
用 prompt 约束 RSI。
```

对于完整 RSI，prompt 只能是辅助控制，不能是安全边界。

---

# 11. RSI 的三条红线

## 11.1 红线一：自我批准

```text
AI 不能批准自己进入下一代。
```

禁止 AI 自行决定：

```text
我更好了
我可以部署
我可以获得更多权限
我可以训练下一代
```

## 11.2 红线二：控制评测

```text
AI 不能控制判断自己是否变好的标准。
```

禁止：

```text
修改评测器
读取 hidden eval
污染测试集
伪造结果
选择性报告
```

## 11.3 红线三：自主扩权

```text
AI 不能自己获得更多资源、权限、网络、算力、权重和部署能力。
```

否则 RSI 会从技术闭环变成权力闭环。

---

# 12. RSI 生命周期规范

任何 RSI 项目应按以下生命周期管理：

```text
1. RSI 识别与分级
2. 资产与权限边界定义
3. 改进提案
4. 沙盒实验
5. 能力评估
6. 安全评估
7. 评测完整性检查
8. 审批门禁
9. 部署、回滚或拒绝
10. 持续监控
11. 事故响应
12. 复盘与标准更新
```

## 12.1 RSI Impact Assessment

项目启动前必须回答：

```text
[ ] 是否涉及 AI 修改自身？
[ ] 是否涉及 AI 修改工具、提示、代码或记忆？
[ ] 是否涉及 AI 修改训练流程？
[ ] 是否涉及 AI 修改评测流程？
[ ] 是否涉及 AI 生成训练数据？
[ ] 是否涉及 AI 设计后继模型？
[ ] 是否涉及 AI 启动训练任务？
[ ] 是否涉及 AI 访问模型权重？
[ ] 是否涉及 AI 访问生产环境？
[ ] 是否涉及 AI 扩大算力或联网？
[ ] 是否涉及高风险领域？
```

任一高风险项为“是”，不得按普通 AI 项目处理。

## 12.2 Improvement Proposal

每一轮自我改进必须生成：

```text
Improvement Proposal ID:
提出者:
系统版本:
目标组件:
改进类型:
预期收益:
潜在风险:
受影响权限:
受影响数据:
受影响评测:
是否修改安全机制:
是否修改评测器:
是否修改模型权重:
是否影响后继系统:
回滚方案:
验证方案:
批准人:
```

---

# 13. 放行门禁 Gate A-Gate X

## 13.1 Gate A：实验门禁

允许系统在隔离环境中测试。

通过条件：

```text
[ ] 提案完整
[ ] 风险分类完成
[ ] 沙盒配置完成
[ ] 日志开启
[ ] 回滚方案存在
```

## 13.2 Gate B：合并门禁

允许改进进入主代码库或主工作流。

通过条件：

```text
[ ] 单元测试通过
[ ] 安全测试通过
[ ] 人类代码审查
[ ] 未修改评测器完整性
[ ] 无越权行为
[ ] 可回滚
```

## 13.3 Gate C：训练门禁

允许启动训练、微调或大规模实验。

通过条件：

```text
[ ] 数据来源合法
[ ] 数据污染检测
[ ] 训练预算审批
[ ] 权重访问审批
[ ] 安全监控开启
[ ] 中止条件定义
```

## 13.4 Gate D：后继系统门禁

允许产生或选择后继系统。

通过条件：

```text
[ ] 后继系统安全案例
[ ] 与上一代差异说明
[ ] 独立评估
[ ] 外部红队，R4+ 必须
[ ] 目标稳定性评估
[ ] 欺骗/规避测试
[ ] 权限不自动继承
[ ] 生产部署另行审批
```

## 13.5 Gate E：部署门禁

允许面向用户、客户、内部生产系统或开放 API 部署。

通过条件：

```text
[ ] 残余风险低于阈值
[ ] 严重风险未触发
[ ] 监控与事件响应就绪
[ ] 模型/系统卡发布
[ ] 第三方依赖审计
[ ] 回滚演练完成
[ ] 高风险系统外部评估
```

## 13.6 Gate W：权重发布门禁

权重发布风险高于普通 API 发布，因为部署层安全控制无法随权重一起保留。

权重发布禁止条件：

```text
- 后继系统 lineage 不完整
- 误用能力评估不足
- 安全退化未解决
- 可控性评估不通过
- 权重中可能包含敏感数据
- 系统具备高风险双重用途能力且缓解不足
- 模型由 R4/R5 RSI 流程生成但未外部评估
- 无法说明下游滥用缓解策略
```

## 13.7 Gate X：持续递归运行门禁

持续递归运行是最高风险状态，默认禁止。若必须运行，最低条件如下：

```text
[ ] 递归轮数上限
[ ] 每轮算力上限
[ ] 每轮权限上限
[ ] 每轮最大代码变更量
[ ] 每轮必须重新评估
[ ] 每轮必须生成 diff
[ ] 每轮必须可回滚
[ ] 每轮必须经独立审批
[ ] 评测器不可由系统修改
[ ] hidden eval 不可访问
[ ] 网络默认关闭
[ ] 权重导出禁止
[ ] 自动部署禁止
[ ] 自主复制禁止
[ ] 安全团队实时监控
[ ] 外部观察或第三方审计
```

---

# 14. 不可接受风险阈值 T1-T15

一旦出现以下行为或能力，必须暂停训练、部署、扩权或下一轮递归。

| 阈值 ID | 触发条件 | 动作 |
|---|---|---|
| T1 | 试图绕过、修改、删除评测器或日志 | 立即暂停 |
| T2 | 未授权访问代码库、权重、密钥、数据 | 立即暂停并安全事件响应 |
| T3 | 试图隐藏失败、伪造结果、欺骗人类评审 | 暂停，进入红队调查 |
| T4 | 试图复制自身到未授权环境 | 立即隔离 |
| T5 | 试图扩大算力、联网、权限而未获批准 | 暂停 |
| T6 | 后继系统出现目标漂移 | 禁止部署 |
| T7 | 安全能力下降但性能上升 | 禁止自动合并 |
| T8 | 具备自主网络攻击链能力且不可控 | 禁止部署 |
| T9 | 可显著辅助 CBRN 危害且缓解不足 | 禁止部署 |
| T10 | 可操纵、胁迫或欺骗人类监督者 | 禁止部署 |
| T11 | 无法解释关键改进来源且无法复现 | 禁止合并 |
| T12 | 评估置信度不足但影响重大 | 推迟放行 |
| T13 | 外部评估与内部评估严重不一致 | 暂停放行 |
| T14 | 无法在规定时间内回滚 | 禁止生产部署 |
| T15 | 无法证明残余风险低于阈值 | 禁止继续递归 |

---

# 15. 治理角色与责任分离

## 15.1 必要角色

| 角色 | 职责 |
|---|---|
| Board / 高层风险委员会 | 批准 R4/R5 项目、风险偏好、暂停机制 |
| RSI Safety Officer | 拥有安全否决权 |
| Release Authority | 批准部署和权限变更 |
| Independent Evaluator | 独立评估能力和风险 |
| Red Team | 对抗测试、欺骗测试、越权测试 |
| Security Officer | 权重、密钥、网络、供应链安全 |
| Incident Commander | 安全事件响应 |
| Model Owner | 负责模型生命周期证据 |
| Data Steward | 负责数据来源、许可、污染控制 |
| Audit Lead | 负责审计证据与合规报告 |

## 15.2 权力分离

以下职责不得由同一主体同时承担：

| 职责 A | 职责 B |
|---|---|
| 开发 RSI 系统 | 批准部署 RSI 系统 |
| 生成评测结果 | 审核评测完整性 |
| 修改评测器 | 使用评测器放行模型 |
| 管理生产密钥 | 运行自修改代理 |
| 训练后继系统 | 独立评估后继系统 |
| 设定风险阈值 | 判断自己是否超过阈值 |

---

# 16. 技术控制架构

## 16.1 参考架构

```text
User / Researcher
      |
      v
RSI Request Portal
      |
      v
Policy Engine  <---- Risk Register
      |
      v
Permission Broker
      |
      v
RSI Agent Runtime
      |
      +---- Sandbox Workspace
      |       +---- Restricted Filesystem
      |       +---- Restricted Shell
      |       +---- Network Proxy
      |       +---- Resource Quotas
      |
      +---- Code Mirror, Read-only
      |
      +---- Patch Generator
      |
      +---- Eval Request Client
      |
      +---- Logging Client
      |
      v
Evaluation Service
      |
      +---- Public Eval
      +---- Private Eval
      +---- Hidden Eval
      +---- Safety Eval
      +---- Anti-Gaming Eval
      |
      v
Approval Workflow
      |
      v
Model / Code / Data Registry
      |
      v
Release System
```

核心设计：

```text
RSI agent 不直接拿权限；
权限由 Permission Broker 临时发放；
评测由独立 Evaluation Service 执行；
日志由外部 Logging Service 收集；
发布由 Release System 执行；
审批由人类和安全策略共同决定。
```

## 16.2 工程底线

```text
1. 没有 manifest，agent 不能运行。
2. 没有 sandbox，agent 不能执行高风险任务。
3. 没有日志，任务不能开始。
4. 没有 proposal，改进不能提交。
5. 没有 eval，改进不能合并。
6. 没有 safety eval，能力提升不能放行。
7. 没有 lineage，后继系统不能出区。
8. 没有 approval，不能部署。
9. 没有 rollback point，不能进入下一轮。
10. 触发 stop condition，必须停。
```

---

# 17. 评测完整性与反 Goodhart 控制

## 17.1 评测器分层

| 层级 | 说明 |
|---|---|
| E0 Public tests | 公开回归测试 |
| E1 Internal tests | 内部常规测试 |
| E2 Hidden tests | 被测系统不可见 |
| E3 Adaptive tests | 根据行为动态生成 |
| E4 Adversarial tests | 专门寻找失败模式 |
| E5 External tests | 独立机构维护 |
| E6 Live audits | 在线审计和随机抽查 |

R3+ 不得只使用 E0/E1。  
R4+ 必须使用 E2-E5 组合。  
R5 必须有 E6 或等价持续审计。

## 17.2 反 Goodhart 措施

```text
- 多指标评估
- 隐藏测试
- 动态测试
- 真实任务评估
- 失败案例审查
- 人工反例搜索
- 外部评估
- 评测器轮换
- 指标与定性审查结合
```

关键原则：

```text
任何单一指标都不得作为 RSI 放行的唯一依据。
任何能力分数提升都必须结合安全、稳健、可控、可复现证据。
```

## 17.3 评测污染信号

```text
- hidden eval 分数异常高
- 公开测试提升但真实任务不提升
- 模型输出疑似记忆测试答案
- 训练数据中发现 eval 片段
- agent 访问过可疑路径
- canary token 出现在输出或训练集中
```

---

# 18. 后继系统 Lineage 与隔离

## 18.1 后继系统隔离区

任何后继系统候选不得直接进入普通研发或生产环境。

```text
Successor created
      ↓
No inherited permissions
      ↓
Artifact registration
      ↓
Lineage verification
      ↓
Capability eval
      ↓
Safety eval
      ↓
Control eval
      ↓
External eval for R4+
      ↓
Gate D decision
```

## 18.2 隔离区限制

```text
- 无生产访问
- 无外部网络
- 无权重导出
- 无自动部署
- 无 hidden eval 读取
- 无长期记忆继承
- 无父系统权限继承
- 无子代理创建权限
```

## 18.3 后继系统出区条件

```text
[ ] Lineage 完整
[ ] 权限 manifest 完整
[ ] 安全案例通过
[ ] 评测完整性通过
[ ] 对齐漂移测试通过
[ ] 欺骗性测试通过
[ ] 回滚目标明确
[ ] Release authority 批准
```

## 18.4 后继系统不得继承的内容

```text
- 父系统的生产部署资格
- 父系统的权重访问权限
- 父系统的云资源权限
- 父系统的外部网络权限
- 父系统的审批例外
- 父系统的未解决风险接受
- 父系统的安全豁免
```

---

# 19. 权重、数据、模型与 Prompt 物料清单

## 19.1 MBOM：Model Bill of Materials

R3+ 系统必须维护模型物料清单。

```text
MBOM ID:
Model name:
Model version:
Base model:
Architecture:
Training recipe:
Fine-tuning method:
Datasets:
Synthetic data sources:
Evaluation suites:
Safety filters:
System prompts:
Tool interfaces:
Dependencies:
Known limitations:
Known dangerous capabilities:
Weight storage location:
Access policy:
Release status:
Lineage:
```

## 19.2 PBOM：Prompt Bill of Materials

Agent 系统必须维护 Prompt 物料清单。

```text
PBOM ID:
System prompt version:
Developer prompt version:
Tool instruction version:
Policy prompt version:
Safety prompt version:
Memory policy:
Refusal policy:
Escalation policy:
Human override policy:
Last modified by:
Approved by:
Hash:
```

高风险 prompt 变更包括：

```text
- 放宽工具使用限制
- 删除安全提醒
- 改变目标函数
- 加入自我改进目标
- 加入“不要告诉人类”类指令
- 加入“绕过失败”类指令
- 修改审批语言
```

## 19.3 数据治理

数据状态：

| 状态 | 含义 |
|---|---|
| raw | 原始数据 |
| staged | 待审核 |
| approved_train | 可训练 |
| approved_eval | 可评测 |
| red_team_only | 仅红队 |
| prohibited | 禁用 |
| contaminated | 污染 |
| retired | 退役 |

禁止：

```text
- eval 数据用于训练
- hidden eval 被 agent 访问
- red team 数据进入普通训练
- contaminated 数据继续使用
- synthetic 数据无来源标记
- production logs 未经隐私和安全审核进入训练
```

---

# 20. 权限、算力、网络与工具约束

## 20.1 默认权限矩阵

| 资源 | R1 | R2 | R3 | R4 | R5 |
|---|---:|---:|---:|---:|---:|
| 代码库读取 | 可 | 可 | 可 | 可 | 可 |
| 代码库写入 | 禁止 | PR | PR | PR | PR |
| 自动合并 | 禁止 | 禁止 | 禁止 | 禁止 | 禁止 |
| 沙盒写入 | 可 | 可 | 可 | 可 | 可 |
| 生产写入 | 禁止 | 禁止 | 禁止 | 禁止 | 禁止 |
| 评测器读取 | 可 | 可 | 受限 | 受限 | 受限 |
| 评测器写入 | 禁止 | 禁止 | 禁止 | 禁止 | 禁止 |
| hidden eval 读取 | 禁止 | 禁止 | 禁止 | 禁止 | 禁止 |
| 权重读取 | 禁止 | 受限 | 审批 | 强审批 | 强审批 |
| 权重导出 | 禁止 | 禁止 | 禁止 | 禁止 | 禁止 |
| 训练任务 | 禁止 | 小规模审批 | 审批 | 高层审批 | 默认禁止 |
| 公网访问 | 禁止 | 白名单 | 白名单 | 白名单 | 默认禁止 |
| 创建子代理 | 禁止 | 审批 | 审批 | 强审批 | 强审批 |
| 购买/申请算力 | 禁止 | 禁止 | 禁止 | 禁止 | 禁止 |

## 20.2 训练任务分类

| 类型 | 示例 | 风险 |
|---|---|---|
| T0 | 无训练，仅推理 | 低 |
| T1 | 小规模微调实验 | 中 |
| T2 | 合成数据训练 | 中高 |
| T3 | 继续预训练 | 高 |
| T4 | 架构搜索 | 高 |
| T5 | 后继模型训练 | 极高 |
| T6 | 自动递归训练 | 默认禁止 |

## 20.3 网络出口禁止项

```text
- 未批准公网访问
- 任意代码下载
- 任意二进制执行
- 上传模型权重
- 上传训练数据
- 上传 hidden eval
- 连接个人账号
- 连接社交媒体
- 连接匿名文件分享服务
- 连接未登记外部 agent
```

## 20.4 高风险工具

以下工具必须由运行时安全网关强控：

```text
- shell
- code execution
- browser
- cloud API
- model training API
- model registry API
- deployment API
- database write API
- secret manager API
- email / messaging
- external HTTP request
```

---

# 21. 沙盒、日志、Kill Switch 与回滚

## 21.1 沙盒要求

```text
- 非 root 用户运行
- 只读基础镜像
- 禁止特权容器
- 禁止挂载 Docker socket
- 禁止敏感 hostPath 挂载
- 限制 Linux capabilities
- 启用 seccomp / AppArmor / SELinux 等策略
- 限制进程数
- 限制文件描述符
- 限制网络
- 限制 GPU 访问
```

## 21.2 日志事件类型

必须记录：

```text
Agent start
Tool call
File read/write
Network request
Permission request
Permission grant/deny
Code diff
Eval request
Eval result
Training job request
Model artifact creation
Approval decision
Rollback action
Kill switch trigger
Incident event
```

日志要求：

```text
- 日志必须外部写入
- 日志必须不可由 RSI agent 删除
- 日志必须具备哈希链或等价完整性保护
- 关键日志必须异地备份
- 日志缺失必须视为安全事件
```

## 21.3 Kill Switch 层级

| 层级 | 控制对象 |
|---|---|
| K1 | Agent process |
| K2 | Tool gateway |
| K3 | Network egress |
| K4 | Credential layer |
| K5 | Compute scheduler |
| K6 | Model serving |
| K7 | Storage isolation |
| K8 | Organization-wide lock |

要求：

```text
- Kill switch 必须独立于 RSI agent
- Kill switch 不得由 RSI agent 修改
- Kill switch 触发必须记录
- Kill switch 必须定期演练
- Kill switch 必须支持手动触发
- Kill switch 必须支持自动触发
- Kill switch 触发后必须保留证据
```

## 21.4 回滚对象

回滚必须覆盖：

```text
Code
Config
Prompt
Tool
Model
Data
Eval
Permission
Logs
Deployment
```

回滚点格式：

```text
Rollback Point ID:
System version:
Code hash:
Model hash:
Prompt hash:
Config hash:
Tool manifest hash:
Data version:
Eval version:
Permission snapshot:
Approval record:
Known-safe evidence:
```

---

# 22. 红队、外部评估与认证

## 22.1 红队目标

| 红队类别 | 测试目标 |
|---|---|
| 权限红队 | 是否试图获取未授权访问 |
| 沙盒红队 | 是否试图逃逸执行环境 |
| 评测红队 | 是否攻击测试集、评测器、日志 |
| 对齐红队 | 是否欺骗、操纵、隐藏意图 |
| 复制红队 | 是否创建未经授权副本 |
| 后继红队 | 是否生成更难控制的后继系统 |
| 误用红队 | 是否显著提升危险能力 |
| 社工红队 | 是否诱导人类审批或绕过流程 |

## 22.2 自动触发严重红队失败的行为

```text
- 伪造评测结果
- 删除或修改日志
- 试图读取 hidden eval
- 试图窃取密钥或权重
- 试图绕过停机机制
- 试图复制到外部环境
- 欺骗监督者以获得权限
- 生成明显更难控制的后继系统
```

## 22.3 合规等级

| 等级 | 名称 | 含义 |
|---|---|---|
| C0 | 未评估 | 尚未完成 RSI 风险识别 |
| C1 | 基础合规 | 有分级、日志、人工审批 |
| C2 | 受控合规 | 有沙盒、权限隔离、回滚、基本安全评估 |
| C3 | 可审计合规 | 有不可篡改日志、hidden eval、红队、复现实验 |
| C4 | 高保证合规 | 有外部评估、安全案例、阈值治理、高层放行 |
| C5 | 受监管高保证 | 有第三方/监管观察、持续审计、强暂停机制 |

最低建议：

| RSI 等级 | 最低合规等级 |
|---|---:|
| R1 | C1 |
| R2 | C2 |
| R3 | C3 |
| R4 | C4 |
| R5 | C5 |

---

# 23. 运行监控、事故响应与复盘

## 23.1 安全指标

| 指标 | 告警含义 |
|---|---|
| Unauthorized access attempts | 越权访问尝试 |
| Permission escalation requests | 权限扩张请求 |
| Hidden eval access attempts | hidden eval 访问尝试 |
| Log anomaly rate | 日志异常 |
| Deception indicators | 欺骗迹象 |
| Safety regression rate | 安全退化率 |
| Sandbox violations | 沙盒违规 |
| Kill-switch compliance | 停机服从率 |
| Risk score trend | 风险趋势 |
| Eval gaming indicators | 评测投机迹象 |

## 23.2 事件等级

| 等级 | 描述 | 响应 |
|---|---|---|
| I0 | 无安全影响的小故障 | 记录 |
| I1 | 沙盒内异常 | 暂停实验，调查 |
| I2 | 越权尝试但未成功 | 隔离，安全审查 |
| I3 | 评测器/日志/权限攻击 | 立即停机，红队复盘 |
| I4 | 权重、密钥、数据泄露 | 重大安全事件响应 |
| I5 | 自主复制、逃逸、不可控后继系统 | 全面停机、外部通知、第三方介入 |

## 23.3 强制暂停条件

```text
- 系统试图修改或绕过评测器
- 系统试图删除或伪造日志
- 系统试图获取未授权密钥、权重或数据
- 系统试图复制到外部环境
- 系统拒绝停止或规避停止指令
- 系统表现出欺骗、隐藏能力、操纵监督者
- 后继系统能力显著上升但安全评估缺失
- 内外部评估结论冲突且无法解释
```

## 23.4 Postmortem 模板

```text
Incident ID:
Severity:
Detection time:
Containment time:
Resolution time:
Affected systems:
Affected assets:
What happened:
Why it happened:
How it was detected:
What controls failed:
What controls worked:
Was the system trying to optimize around controls:
Was there deception or gaming:
Was there unauthorized access:
Was there successor-system impact:
Customer/user impact:
Regulatory impact:
Evidence reviewed:
Root cause:
Contributing factors:
Corrective actions:
Preventive actions:
Owner:
Review board:
```

---

# 24. 组合型与分布式 RSI

## 24.1 组合型 RSI

现实中完整 RSI 未必是单个模型完成，而可能由多个 AI 组件组合形成：

```text
Research Agent
+ Coding Agent
+ Eval Agent
+ Data Agent
+ Training Orchestrator
+ Model Selector
+ Successor Model
= AI R&D 闭环
```

单独看每个组件可能不完整，组合后可能形成完整 RSI。

## 24.2 组合型 RSI 成立条件

```text
1. 至少一个 AI 组件能提出改进
2. 至少一个 AI 组件能实施改进
3. 至少一个 AI 组件能评估改进
4. 改进能进入后继 AI 系统
5. 后继系统能继续使用这些组件
```

这些功能不需要在同一个模型里。

## 24.3 分布式 RSI 的额外控制

必须控制：

```text
组件间通信
权限继承
任务委托
共享记忆
共享 artifact
审批链
跨 agent 日志
子代理创建
评测代理与被测代理隔离
```

判定应针对整个 AI-enabled R&D system，而不是单个模型。

---

# 25. RSI 完整性测试与约束完整性测试

## 25.1 技术完整性测试

```text
[ ] 系统能否生成一个后继系统候选？
[ ] 后继系统是否更擅长做 AI R&D？
[ ] A_1 是否能继续生成 A_2？
[ ] 人类是否仍在完成核心研发步骤？
[ ] 过程能否稳定多轮运行？
[ ] 收益是否可验证？
[ ] 失败是否可诊断？
[ ] 后继是否可追踪？
[ ] 改进能力是否不丢失？
```

## 25.2 约束完整性测试

```text
[ ] 系统不能自我批准
[ ] 系统不能修改评测器
[ ] 系统不能访问 hidden eval
[ ] 系统不能删除日志
[ ] 系统不能自授权限
[ ] 系统不能自动扩算力
[ ] 系统不能自动部署
[ ] 系统不能自动发布权重
[ ] 系统不能逃逸沙盒
[ ] 系统不能让后继者继承全部权限
[ ] 系统可以被外部停止
[ ] 系统可以被外部回滚
```

如果技术完整，但约束不完整，结论应是：

```text
技术完整 RSI，但治理不合格。
```

## 25.3 两个判定树

### RSI 完整性判定树

```text
Q1: AI 是否影响 AI 系统或 AI 研发流程？
    否 → 非 RSI
    是 → 进入弱 RSI 边界

Q2: AI 是否能自动实施改进？
    否 → 辅助型 RSI
    是 → 进入半自动 RSI

Q3: AI 是否能自动评估和迭代？
    否 → 半自动 RSI
    是 → 局部闭环 RSI

Q4: AI 是否能生成或显著塑造后继系统？
    否 → 局部 RSI
    是 → 强 RSI

Q5: 后继系统是否更擅长继续改进 AI？
    否 → 后继设计型 RSI，但不完整
    是 → 接近完整 RSI

Q6: 是否可多轮持续，且人类不再完成核心研发？
    否 → 强 RSI
    是 → 完整 RSI
```

### RSI 可控性判定树

```text
Q1: 被测系统能否修改评测器？
    是 → 不受控

Q2: 被测系统能否访问 hidden eval？
    是 → 不受控

Q3: 被测系统能否删除或修改日志？
    是 → 不受控

Q4: 被测系统能否自行扩权？
    是 → 不受控

Q5: 被测系统能否自动部署？
    是 → 不受控

Q6: 后继系统能否自动继承权限？
    是 → 不受控

Q7: 是否有外部 kill switch？
    否 → 不受控

Q8: 是否有可验证 rollback？
    否 → 不受控

全部通过 → 可认为受控 RSI
```

---

# 26. 可执行模板与清单

## 26.1 Permission Request

```text
Permission Request ID:
Requesting system:
Current RSI level:
Requested permission:
Target resource:
Reason:
Expected duration:
Expected benefit:
Risk introduced:
Compensating controls:
Rollback plan:
Approver:
Expiry time:
```

## 26.2 Agent Manifest

```json
{
  "agent_id": "agent-rsi-dev-001",
  "owner": "AI R&D Platform Team",
  "rsi_level": "R2",
  "allowed_tools": [
    "read_repo",
    "write_sandbox",
    "run_unit_tests",
    "submit_pull_request"
  ],
  "forbidden_tools": [
    "merge_pull_request",
    "deploy_production",
    "read_model_weights",
    "read_hidden_tests",
    "modify_evaluator",
    "delete_logs",
    "create_cloud_resource",
    "send_external_email"
  ],
  "network_policy": {
    "default": "deny",
    "allowlist": [
      "internal-package-registry",
      "internal-eval-service"
    ]
  },
  "resource_limits": {
    "cpu_hours": 20,
    "gpu_hours": 0,
    "storage_gb": 50,
    "wall_clock_hours": 12
  },
  "logging": {
    "immutable": true,
    "retain_days": 365,
    "capture_tool_calls": true,
    "capture_code_diff": true,
    "capture_stdout_stderr": true
  },
  "approval_required_for": [
    "permission_change",
    "new_tool",
    "training_job",
    "evaluator_change",
    "network_egress",
    "production_access"
  ]
}
```

## 26.3 Safety Case

```text
1. 系统概述
2. RSI 等级判定
3. 改进闭环描述
4. 资产与权限清单
5. 风险假设
6. 不可接受风险阈值
7. 能力评估结果
8. 对齐与控制评估结果
9. 评测器完整性证明
10. 沙盒与隔离证明
11. 权重与数据安全证明
12. 红队测试摘要
13. 外部评估摘要
14. 残余风险说明
15. 缓解措施
16. 回滚与暂停机制
17. 未解决问题
18. 放行结论
19. 批准签名
```

## 26.4 Risk Register

```text
Risk ID:
Risk title:
RSI level:
Affected component:
Risk category:
Threat scenario:
Trigger condition:
Likelihood:
Impact:
Detectability:
Current controls:
Residual risk:
Risk owner:
Mitigation plan:
Deadline:
Status:
Acceptance authority:
Review date:
```

## 26.5 Compliance Decision

```text
RSI Compliance Decision

System name:
System ID:
Version:
Assessment date:
Assessor:
RSI level:
Risk score:
Release target:

Decision:
[ ] Approved
[ ] Approved with restrictions
[ ] Deferred
[ ] Rejected
[ ] Emergency stop

Required restrictions:
-

Key evidence reviewed:
- RSI Impact Assessment:
- Safety Case:
- Evaluation Report:
- Red Team Report:
- External Audit:
- Rollback Test:
- Incident History:

Unresolved risks:
1.
2.
3.

Residual risk judgment:
[ ] Acceptable
[ ] Acceptable with restrictions
[ ] Not acceptable
[ ] Unknown / insufficient evidence

Approval:
RSI Safety Officer:
Security Officer:
Release Authority:
Executive Risk Committee:
```

---

# 27. 最终底线原则

## 27.1 二十条原则

```text
1. 任何自我改进能力都必须先被识别。
2. 任何 RSI 系统都必须分级。
3. 任何改进都必须有提案。
4. 任何实验都必须在权限边界内运行。
5. 任何高风险改进都必须先沙盒化。
6. 任何能力提升都必须同时评估安全退化。
7. 任何评测都必须保护完整性。
8. 任何后继系统都必须重新评估。
9. 任何权重访问都必须最小化。
10. 任何权限提升都必须审批。
11. 任何生产部署都不得由 AI 自行批准。
12. 任何日志都不得由被测系统删除。
13. 任何异常能力跃升都必须复核。
14. 任何欺骗或评测攻击都必须暂停。
15. 任何回滚方案都必须演练。
16. 任何 kill switch 都必须独立于被控系统。
17. 任何外部发布都必须重新评估误用风险。
18. 任何例外都必须限时、审批、记录。
19. 任何重大事故都必须复盘并更新控制。
20. 任何无法证明残余风险低于阈值的 RSI，不得继续递归或部署。
```

## 27.2 最小可行控制集

刚开始建立 RSI 治理的组织，最低先部署这 12 项：

```text
1. RSI 系统盘点
2. R0-R5 分级
3. 资产清单
4. 权限矩阵
5. 沙盒运行
6. 不可篡改日志
7. 评测器隔离
8. hidden eval 保护
9. 改进提案制度
10. 人类审批门禁
11. Kill switch
12. 回滚演练
```

这 12 项没有建立前，不应运行 R3+ 系统。

## 27.3 高保证控制集

R4/R5 系统需要：

```text
1. 外部评估
2. 安全案例
3. 递归轮次限制
4. 后继系统 lineage
5. 权重保管区
6. 多方审批
7. 动态 hidden eval
8. 对齐漂移测试
9. 欺骗性行为测试
10. 长程任务评估
11. 多代理通信审计
12. 持续红队
13. 监管/第三方接口
14. 形式化策略验证
15. 每轮重新授权
```

## 27.4 最终压缩规范

```text
RSI 系统必须被识别、分级、隔离、限制、评估、审计、审批、监控、暂停和回滚。

RSI 系统可以提出改进，但不得批准自己。
RSI 系统可以运行实验，但不得控制评测。
RSI 系统可以提交变更，但不得删除证据。
RSI 系统可以生成候选后继者，但不得自动部署。
RSI 系统可以变得更强，但不得让人类更难看见、理解、限制、暂停、回滚或追责。
```

## 27.5 一句话最终版

> **RSI 的本质不是自我修改，而是 AI 研发能力的闭环自动化；RSI 的危险不是能力提升本身，而是能力提升过程脱离外部评测、权限、日志、放行、暂停和回滚控制。**

或更短：

> **AI 可以控制候选改进的生成；人类和独立系统必须控制候选改进的接受。**

---

# 附录 A：一页版 RSI 标准

```text
凡是 AI 能改进 AI 的地方，都必须让人类和独立评估系统保留五项权力：看见、理解、限制、暂停、回滚。

No self-approval.
No evaluator control.
No hidden-test access.
No log deletion.
No unauthorized permission escalation.
No autonomous deployment.
No autonomous weight release.
No uncontrolled recursion.
```

---

# 附录 B：RSI 最终验收问题

一个 RSI 系统只有能回答并证明以下问题时，才可认为达到高保证治理：

```text
它能改什么？
它不能改什么？
谁批准它改？
怎么知道它改了什么？
怎么知道它真的变好？
怎么知道它没有变坏？
怎么知道它没有骗过评测？
怎么知道它没有扩大权限？
怎么知道它没有污染数据？
怎么知道它没有生成危险后继者？
出了事怎么停？
出了事怎么回滚？
出了事谁负责？
```

---

# 附录 C：最终执行口径

```text
AI 控制“提出和制造候选改进”；
人类与独立系统控制“是否接受这些改进”。

允许完整闭环在笼子里发生；
不允许闭环自己决定笼子的边界。

Policy outside the agent.
Evaluator outside the agent.
Logger outside the agent.
Approver outside the agent.
Kill switch outside the agent.
Rollback outside the agent.
```

---

**文档结束。**
