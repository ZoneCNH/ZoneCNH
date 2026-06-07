# 自动发布

执行完整的发布流程：提交 → 推送 → 版本号 +1 → 打 tag → 推送 tag。

## 执行步骤

### 1. 检查当前状态
运行 `git status --short` 查看变更文件，`git log -3 --pretty=format:%s` 查看最近提交风格。

### 2. 暂存并提交
- 运行 `git add -A`
- 根据变更内容生成 Conventional Commits 格式的中文提交信息（`docs:`、`feat:`、`refactor:`、`fix:` 等）
- 运行 `git commit -m "<提交信息>"`

### 3. 推送到远程
- 运行 `git push origin main`

### 4. 版本号 +1
- 运行 `git tag --sort=-v:refname | head -1` 获取最新 tag
- 解析当前版本号（格式 `vX.Y.Z`）
- 递增 PATCH 版本号（`v0.2.0` → `v0.3.0`）
- 如果用户在 `$ARGUMENTS` 中指定了版本号，使用用户指定的版本

### 5. 创建并推送 tag
- 运行 `git tag <新版本号>`
- 运行 `git push origin <新版本号>`

### 6. 输出发布摘要
输出格式：
```
✅ 发布完成
  提交：<提交信息>
  版本：<旧版本> → <新版本>
  远程：origin/main
```

## 参数

`$ARGUMENTS`：可选，指定版本号（如 `v0.3.0`）。未指定则自动递增 PATCH。

## 约束

- 仅在 `main` 分支执行
- 如果没有变更文件，跳过提交步骤，只做版本 tag 推进
- 提交信息默认中文，模块名和命令保留英文
- 不要提交凭证、API key、账户 ID 等敏感信息
