# Plan 001: 轮换 sre/ 子仓库中所有硬编码凭据

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat b4f486b..HEAD -- sre/secrets/ sre/.ssh/ sre/bootstrap/`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1 (严重 — 生产凭据在磁盘上)
- **Effort**: S（轮换操作约 30 分钟）
- **Risk**: MEDIUM（轮换期间 CI 可能短暂不可用，需提前通知）
- **Depends on**: none
- **Category**: security
- **Planned at**: commit `b4f486b`, 2026-06-15

## Why this matters

`sre/` 子仓库（独立的 git 仓库，物理上位于 ZoneCNH 仓库内）包含 3 类硬编码凭据：(1) `sre/secrets/.env:3` 中的 GitHub PAT — 被活动引导脚本 `source` 引用；(2) `sre/secrets/env/dev.md`、`prod.md`、`ci.md` 中的数据库/API 凭据 — 包含生产环境 Qdrant API key、ClickHouse 密码、Redis/PostgreSQL 密码；(3) `sre/.ssh/` 中 3 个 SSH 私钥，其中 2 个是 world-readable (`0664`)。虽然 `.env` 被 `.gitignore` 保护未进入 git 历史，但磁盘上的凭据可被任何能读取工作树的进程泄露。所有暴露凭据必须立即轮换。

## Current state

- `sre/` 是独立 git 仓库：`sre/.git` 存在，`git rev-parse --show-toplevel` 在 sre/ 内返回 `<workspace-root>/sre`
- `sre/secrets/.env:3` — GitHub PAT，格式 `GITHUB_TOKEN=ghp_...`
- `sre/secrets/env/dev.md:8,182,190,258` — dev 环境 API key、Qdrant key、ClickHouse 密码
- `sre/secrets/env/prod.md:194,202` — 生产环境 Qdrant API key、AccessKey secret
- `sre/secrets/env/ci.md:60-63` — CI 环境 Redis、PostgreSQL、TDengine、RabbitMQ 密码
- `sre/.ssh/id_ed25519` (mode `0600`)、`sre/.ssh/codeup_key` (`0664`)、`sre/.ssh/github_key` (`0664`)
- `sre/.gitignore:28` 已忽略 `.env` 文件，但 `.md` 文档中的凭据和 SSH 密钥未被忽略
- 引用 `.env` 的脚本：`sre/bootstrap/deploy-local-healthcheck.sh`、`sre/bootstrap/health-check.sh`、`sre/bootstrap/remove-offline-runners.sh`

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| 列出 sre 中所有含凭据的文件 | `grep -rn 'ghp_\|api_key\|password\|secret\|-----BEGIN' sre/secrets/ sre/.ssh/ 2>/dev/null \| grep -v '.git:'` | 输出找到的文件列表 |
| 验证 .gitignore 覆盖 | `cd sre && git check-ignore -v secrets/.env` | 返回 ignore 规则 |
| 检查 SSH 密钥权限 | `ls -la sre/.ssh/` | 当前权限状态 |
| GitHub PAT 轮换 | 在 github.com → Settings → Developer settings → PAT 中手动操作 | 新 token 生成成功 |

## Scope

**In scope** (需要操作的文件):
- `sre/secrets/.env` — 移除 PAT，改为占位符 + 文档说明
- `sre/secrets/env/dev.md` — 替换凭据为 `<SECRET:NAME>` 占位符
- `sre/secrets/env/prod.md` — 替换凭据为 `<SECRET:NAME>` 占位符
- `sre/secrets/env/ci.md` — 替换凭据为 `<SECRET:NAME>` 占位符
- `sre/.ssh/codeup_key` — 删除，从 `~/.ssh/` 引用
- `sre/.ssh/github_key` — 删除，从 `~/.ssh/` 引用
- `sre/.ssh/id_ed25519` — 删除，从 `~/.ssh/` 引用
- `sre/bootstrap/*.sh` — 更新 source 路径，改为从 OS keychain 或环境变量读取

**Out of scope** (禁止修改):
- `sre/.gitignore` — 已有正确的 `.env` 忽略规则
- 主仓库（ZoneCNH/ZoneCNH）中的任何文件
- GitHub Actions workflow 中的 secrets 配置（那是 GitHub UI 操作）

## Git workflow

- 在 `sre/` 仓库内操作：`cd sre && git checkout -b security/credential-rotation`
- Commit 格式：`security: rotate exposed credentials (b4f486b audit finding SEC-01/02/03)`
- 不要推送到远程，等操作员确认后手动推送

## Steps

### Step 1: 轮换所有暴露的凭据（在服务端操作）

**GitHub PAT**：登录 github.com → Settings → Developer settings → Personal access tokens → 找到对应 token → 点击 "Regenerate" → 复制新 token。记录新 token（后续步骤使用）。

**数据库/API 凭据**：登录各服务管理面板（Qdrant Cloud、ClickHouse Cloud 等），为 dev/prod/ci 环境生成新凭据。记录所有新凭据。

**SSH 密钥**：为 codeup、github、默认密钥各生成新密钥对：
```bash
ssh-keygen -t ed25519 -C "zonecnh-sre-codeup" -f ~/.ssh/sre_codeup_key
ssh-keygen -t ed25519 -C "zonecnh-sre-github" -f ~/.ssh/sre_github_key
ssh-keygen -t ed25519 -C "zonecnh-sre-default" -f ~/.ssh/sre_id_ed25519
```
将新公钥部署到对应服务器/服务。

**Verify**: 新凭据已在各自服务端生效（手动在服务控制台确认）。

### Step 2: 替换 sre/secrets/.env 中的 GitHub PAT

将 `sre/secrets/.env:3` 的 token 值替换为占位符：
```
GITHUB_TOKEN=<SET_VIA_ENV_OR_KEYCHAIN>
```

**Verify**: `grep -c 'ghp_' sre/secrets/.env` → `0`

### Step 3: 替换明文文档中的凭据

对 `sre/secrets/env/dev.md`、`prod.md`、`ci.md`：
- 搜索所有 `api_key`、`password`、`secret`、`token` 值
- 替换实际值为 `<SECRET:描述性名称>` 占位符（例如 `<SECRET:DEV_QDRANT_API_KEY>`）
- 在文件顶部添加说明："本文档中的 `<SECRET:*>` 是占位符，实际凭据存储在 GitHub Actions Secrets 或 HashiCorp Vault 中"

**Verify**: `grep -rnE '[a-z0-9]{32,}' sre/secrets/env/` → 无长随机字符串输出（只剩占位符）

### Step 4: 删除 SSH 私钥文件

```bash
cd sre
rm .ssh/codeup_key .ssh/github_key .ssh/id_ed25519
```

更新所有引用这些密钥的脚本和配置，改为引用 `~/.ssh/` 下的标准路径。

**Verify**: `ls sre/.ssh/` → 无 `*_key` 文件（只应有 `config`、`known_hosts` 等）

### Step 5: 更新引导脚本的凭据读取方式

修改 `sre/bootstrap/*.sh` 中 `source "$REPO_ROOT/secrets/.env"` 为从环境变量读取：
```bash
# 旧：source "$REPO_ROOT/secrets/.env"
# 新：从环境变量读取，CI 中由 GitHub Secrets 注入
: "${GITHUB_TOKEN:?required}"
```

**Verify**: `grep -rn 'source.*secrets/\.env' sre/bootstrap/` → 无结果

### Step 6: 提交变更

```bash
cd sre
git add -A
git commit -m "security: rotate exposed credentials

Findings SEC-01/02/03 from b4f486b audit:
- Removed GitHub PAT from secrets/.env
- Replaced plaintext DB/API credentials with <SECRET:> placeholders
- Removed SSH private keys from .ssh/
- Updated bootstrap scripts to read from environment variables

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Verify**: `cd sre && git diff --stat HEAD~1` → 变更范围限于上述文件

## Test plan

- 轮换后在对应的 CI 环境中运行 `health-check.sh`，确认新凭据有效
- `grep -rnE 'ghp_|sk-[a-zA-Z0-9]{32,}' sre/` → 无匹配
- `ls -la sre/.ssh/` → 无私钥文件
- GitHub Actions 运行一次自托管 runner 的健康检查 → 通过

## Done criteria

- [ ] `grep -rnE 'ghp_|sk-[a-zA-Z0-9]{32,}' sre/secrets/` 返回 0 结果
- [ ] `ls sre/.ssh/*_key` 返回 "No such file"
- [ ] `grep -rn 'source.*secrets/\.env' sre/bootstrap/` 返回 0 结果
- [ ] sre/ 仓库的 git 历史中新增一个 commit，移除所有凭据
- [ ] 所有暴露的凭据已在服务端轮换（旧凭据已撤销）
- [ ] `plans/README.md` 状态行已更新

## STOP conditions

- 无法确定某个凭据对应的服务/平台（例如不知道某个 API key 在哪里生成的）— 先跳过该项，记录在 commit message 中
- 轮换凭据后 CI 持续失败 — 恢复旧凭据，排查问题后再重新轮换
- `grep` 发现更多未列入本计划的凭据 — 记录位置，报告后继续执行本计划
- 发现任何凭据已进入 git 历史（`git log -p -- sre/secrets/` 有输出）— STOP，报告泄露范围，需要 `git filter-branch` 或 BFG 清理历史

## Maintenance notes

- 后续新增凭据时，必须通过 GitHub Actions Secrets 或环境变量注入，禁止放回 `sre/secrets/` 目录
- `sre/secrets/env/*.md` 现在是纯文档（仅含占位符），不应再包含实际凭据
- SSH 密钥应统一放在 `~/.ssh/` 下，禁止在工作树中存储私钥
- 建议配置 GitGuardian 或类似工具自动扫描新增凭据
- 建议在 CI 中增加 `grep` 检查：`grep -rnE 'ghp_|sk-[a-zA-Z0-9]{32,}' sre/ && echo "BLOCKED: possible credential" && exit 1`
