# binance 统一开发与发布入口设计

## 背景

`module/binance` 现在同时存在多份与流程相关的文档：`README.md`、`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`spec/ACCEPTANCE.md`、`gate/RELEASE-CHECKLIST.md`、`gate/DEPLOY-PREFLIGHT.md`、`release/DEPLOYMENT-ORCHESTRATION.md`。  
这些文档各自正确，但入口分散，读者需要自己拼接“开发 → 验证 → 发布”的路径。

## 目标

1. 形成一个唯一的流程入口。
2. 明确开发、验证、发布三段职责边界。
3. 让发布判断只依赖少数 SSOT 文档，不再靠读者手工串联。
4. 保留现有门禁和证据体系，不重做流程引擎。

## 非目标

1. 不重构 `module/binance` 的功能规格内容。
2. 不改 runtime 行为。
3. 不新增自动化脚本或 CI 工作流。
4. 不删除现有门禁文档，只调整入口关系。

## 方案

### 入口层

把 `module/binance/README.md` 定义为唯一导航页。它只回答三件事：

1. 去哪里开发
2. 去哪里验证
3. 去哪里发布

它不再承担完整流程说明，只做路由。

### 判定层

将下列文档视为发布判定的权威来源：

| 领域 | 权威文档 |
| --- | --- |
| 功能完成度 | `spec/SPEC.md` |
| 追溯闭合 | `matrix/TRACEABILITY.md` |
| 验收状态 | `spec/ACCEPTANCE.md` |
| 发布前门禁 | `gate/RELEASE-CHECKLIST.md` |
| 运行前预检 | `gate/DEPLOY-PREFLIGHT.md` |

判定层只回答“能不能发”，不描述具体操作步骤。

### 执行层

将 `release/DEPLOYMENT-ORCHESTRATION.md` 定位为发布操作手册，只保留：

1. 发布路径 A/B
2. 预检顺序
3. 失败回滚
4. 发布后验证

它不再充当入口，也不重复定义门禁结论。

## 信息流

```text
开发变更
  -> SPEC / TRACEABILITY / ACCEPTANCE 对齐
  -> RELEASE-CHECKLIST / DEPLOY-PREFLIGHT 预检
  -> 发布执行
  -> evidence 归档
```

规则很简单：上游负责“定义”，中游负责“判定”，下游负责“执行”。

## 失败分类

统一四类失败，避免文档之间互相抢职责：

| 类型 | 含义 | 处理方式 |
| --- | --- | --- |
| spec drift | 规格和实现不一致 | 先回修 SPEC / TRACEABILITY |
| readiness block | 验收未闭合 | 先补 ACCEPTANCE / evidence |
| release block | 发布前门禁未过 | 先修 RELEASE-CHECKLIST / DEPLOY-PREFLIGHT |
| runtime block | 运行态异常 | 先修 runtime 或回滚 |

## 推荐落地方式

1. 先把 `README.md` 改成唯一入口。
2. 再收敛 `release/DEPLOYMENT-ORCHESTRATION.md` 的角色。
3. 最后把 `gate/` 文档和 `spec/` 文档的职责说明写清楚。

## 成功标准

1. 读者只看 `README.md` 就知道下一步去哪。
2. `SPEC / TRACEABILITY / ACCEPTANCE` 只负责发布判定。
3. `RELEASE-CHECKLIST / DEPLOY-PREFLIGHT` 只负责发布门禁。
4. `DEPLOYMENT-ORCHESTRATION` 只负责执行，不再混合入口与判定。
5. 不需要额外口头解释，也能复原完整流程。
