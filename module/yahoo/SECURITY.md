# yahoo SECURITY

1. 禁止提交 API key、token、账号等敏感信息。
2. 文档仅允许引用 `sre/secrets/env/dev.md` 键名，不允许记录值。
3. 所有外部响应先归档 OSS，再进入规范化流程，便于审计与回放。
4. 所有对外事件必须带版本号与幂等键。

