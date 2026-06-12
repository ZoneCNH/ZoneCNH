# ossx 目标文档（Goal）

> 状态：Review
> 最近更新：2026-06-12
> 适用模块：`module/ossx`

## 1. 模块定位

`ossx` 是 HAI 平台的对象存储扩展模块，负责提供 Blob/Object 存储抽象、流式读写、分片上传、预签名 URL、校验和、生命周期策略与审计观测能力。模块面向业务层提供稳定接口，屏蔽底层 S3 兼容存储或本地测试适配器差异。

## 2. 核心目标

- 提供统一 `BlobStore` 接口，覆盖 Put/Get/Delete/Copy/Head/Exists/List、流式上传下载与分片上传。
- 定义对象键、元数据、校验和、权限策略、生命周期策略与预签名策略的模块内模型。
- 将云厂商 SDK 限定在 adapter 子包，不泄漏到公共 API。
- 对接 `kernel` 的上下文、生命周期与错误语义。
- 仅通过 `observex` 的接口型合约输出指标、追踪、审计日志与健康状态。
- 通过配置结构体或 options 接收组合根注入的配置，不直接依赖 `configx`。

## 3. 非目标

- 不实现业务领域对象、租户业务规则或 L2.5 应用服务。
- 不直接提供数据库、消息队列或缓存能力。
- 不在公共 API 暴露 S3、MinIO、云厂商 SDK 类型。
- 不直接依赖或导入 `configx`；配置装配由上层组合根完成。
- 不依赖其他存储扩展模块，例如 `natsx`、`kafkax` 或 `redisx`。

## 4. 消费者

- 平台服务：需要对象存储能力的 L2/L3 服务。
- 后台作业：需要流式上传、分片上传、清理过期分片或校验对象完整性的任务。
- 测试与示例：需要 fake adapter 或 S3 兼容 adapter 的契约测试。

## 5. 边界与依赖规则

| 类型 | 规则 |
| --- | --- |
| 允许上游 | `kernel`，以及 `observex` 的接口型合约 |
| 禁止上游 | `configx`、业务领域模块、L2.5 应用层、其他 storage extension |
| 配置来源 | 组合根读取外部配置后转换为 `ossx.Config` 或 options 注入 |
| Adapter 边界 | 云 SDK 仅允许出现在 adapter 子包或其内部测试中 |
| 观测边界 | 指标、追踪、日志通过接口注入；缺省实现必须可为空操作 |

## 6. 完成定义

- `SPEC.md` 覆盖目标、接口、配置、依赖、测试、CI 与发布要求。
- `TRACEABILITY.md` 闭合 Goal -> Spec -> Test Case -> Task 映射。
- `IMPLEMENTATION-PLAN.md` 给出可执行阶段计划。
- `tasks/`、`prompt/`、`evidence/` 目录存在并绑定每个实现切片。
- 校验命令在 evidence 中记录，且 ossx 范围内无直接 `configx` 或 unrelated worktree 变更。
