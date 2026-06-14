# TASK-NATSX-008 实现 Prompt

## 任务

配置契约：foundationx.nats.* 加载、默认值、环境变量、旧别名兼容

## 规格引用

module/natsx/SPEC.md#11-config-schema

## 验收标准

§11: foundationx.nats.* 默认值正确; §11: FOUNDATIONX_NATS_* 优先于 legacy NATS_*; §11: 配置错误不打印 token/password/nkey/credentials

## 验证

NFR-008 verified via TC-008

## 优先级

P1

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
