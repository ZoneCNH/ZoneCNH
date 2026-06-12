# TASK-KERNEL-007 开发 Prompt

> versionx 子包：版本信息 — BuildInfo + Compatibility

---

## 任务

实现 `kernel/versionx` 子包。提供构建版本元数据和兼容性判断，纯 stdlib。

## 文件清单

### 1. `versionx/versionx.go`

- `BuildInfo` 结构体：Module + Version + Commit + BuildTime + GoVersion
- `NewBuildInfo(module, version, commit, buildTime, goVersion) BuildInfo`
- `Compatibility` 结构体：Module + Major
- `Compatibility.CompatibleWith(info BuildInfo) bool`：Module 匹配 + Major 匹配
- `VersionInfo = BuildInfo`（Deprecated 类型别名）

### 2. `versionx/versionx_test.go`

覆盖：NewBuildInfo 全字段、Module 匹配/不匹配、Major 匹配/不匹配、Major 为空时仅校验 Module、VersionInfo 别名可用。

### 3. `versionx/example_test.go`

展示 BuildInfo 构造、Compatibility 判断。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-013 | FR-009 | CompatibleWith 测试 | 匹配逻辑正确 |
| AC-VERSIONX-02 | FR-009 | Major 为空 | 仅校验 Module |

## 禁止事项

- 不要依赖非 stdlib 包
- 不要引入 semver 解析库（仅做字符串匹配）
- BuildInfo 字段不要包含运行时敏感信息

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-007/`：
1. `go test -race -count=1 ./versionx/...` 输出
2. CompatibleWith 各场景覆盖证据

## 完成后

1. 运行 `go vet ./versionx/...` 确认无警告
2. 确认 VersionInfo deprecated 别名正确指向 BuildInfo
3. 更新 TASK-KERNEL-007 状态为 completed
