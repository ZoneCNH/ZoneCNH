# Binance 模块安全策略

> 本文档是 `module/binance/` 的治理级安全入口，配合 `gate/SECURITY.md` 使用。

## 1. 适用范围

- 本文件适用于 `module/binance/` 规格、计划、追溯与证据文档。
- 运行时代码安全实现以 `/home/workspace/binance` 仓库为准。

## 2. 安全目标

- 防止凭证、密钥、账户标识进入本仓库。
- 保持文档中的安全声明与 runtime 实现状态一致。
- 确保安全类 issue（如 GAP-E37/E44/E45）有可追溯证据链。

## 3. 敏感信息红线

禁止提交以下内容：

- API Key、Secret、Token、私有 endpoint。
- 账户 ID、实名信息、身份证件、手机号、邮箱等个人敏感数据。
- 真实交易策略参数、生产数据库连接串、内网地址。

发现后必须：

1. 立即停止扩散（不再复制到其他文档）。
2. 在 issue 中登记事件编号与影响范围。
3. 按仓库治理流程执行清理与审计闭环。

## 4. 漏洞报告流程

1. 使用 GitHub issue 在 `ZoneCNH/ZoneCNH` 主仓报告，标签含 `governance-trap` 或 `runtime-gap`。
2. 标注影响面：spec / matrix / gate / plan / runtime。
3. 给出复现步骤、风险级别、期望修复窗口。
4. 修复后补齐 evidence，并在 TRACEABILITY 中回填关联。

## 5. 依赖与供应链

- 文档仓不新增运行时依赖。
- 涉及运行时依赖的安全声明，必须引用 runtime 仓实际状态，不可凭推测填写。
- 安全结论以可验证证据为准，不接受“应当安全”式描述。

## 6. 发布前安全检查

发布前至少确认：

- 安全相关 issue 状态与文档投影一致。
- `module/binance/todo.md` 与 GitHub/Beads 状态一致。
- `gate/SECURITY.md`、`SECURITY.md`、`CONTRIBUTING.md` 三者链接可达。

## 7. 联系与升级

- 常规安全问题：通过主仓 issue 流转。
- 高风险问题：优先暂停发布声明，先修复再恢复推进。

[RULES I BROKE]：无
