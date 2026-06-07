
xlib-standard
  governs / generates / audits

kernel
  primitive only

configx / observex / testkitx / resiliencx / schedulex
  cross-cutting foundations

redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex
  infrastructure adapters

contracts
  proto / schema / DTO / event envelope / capability / quality / SDK interface

market-data
  exchange + crypto analytics facts

macro-data
  macro + policy + calendar + market proxy facts

market-engine
  market facts → S state

macro-engine
  macro facts → M state

regime-engine
  M + S → action/risk/permission

x.go
  strategy / risk / execution / backtest / orchestration



使用agent teams 执行
深度分析 /home/specs

使用agent teams 执行 优化

物理约束

设置 copilot + claude 自动执行review

使用 subagent review







每个子模块，
目的
解决问题，
checklist







结构债：分层违规 import、L2 互相耦合、循环依赖、上帝模块
实现债：重复代码、过时模式、补丁热点
测试债：缺失测试 / 脆弱测试 / 金字塔倒置
文档债：ADR 缺失、文档与代码不一致
依赖债：过期 / 废弃 / 有 CVE 的第三方库
领域债：模型与业务语言不一致（DDD 视角）






Module
