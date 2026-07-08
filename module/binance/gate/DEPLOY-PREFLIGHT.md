# Binance 部署预检清单与执行手册

> **版本**：v1.0.0
> **生成日期**：2026-07-08
> **适用范围**：binance runtime（`github.com/ZoneCNH/binance`）生产部署到 `jp1 (84.247.154.45)`
> **关联文档**：`gate/RELEASE-CHECKLIST.md`、`gate/DEPLOYMENT-READINESS-CHECKLIST.md`、`release/DEPLOYMENT-ORCHESTRATION.md`
> **性质**：本文件为**预检 + 手册**，不触发任何部署动作。

---

## §0 当前状态快照（生成时实测）

| 项 | 值 | 来源 |
| --- | --- | --- |
| main HEAD | `fc96705`（#462 fix ci coverage artifact） | `git log` |
| 最新 tag | `v0.15.0` @ `52d9144` | `git ls-remote` |
| tag 与 HEAD 关系 | v0.15.0 落后 HEAD **1 提交**（#462） | `git rev-list --count` |
| 本地验证 | build/vet/race PASS、boundary 15/15、B4/B5 PASS；lint **8 warning / 0 error** | 本仓本地执行 |
| CI 远端 | 账户计费锁定（`account locked due to billing issue`），Actions 无法执行 | PR #1734 检查 |
| 技术负责人签字 | **空白** | DEPLOYMENT-READINESS Sign-Off |
| PR #1734（版本回刷） | 开放，CI 因计费锁失败 | gh |
| canary drill 脚本 | **不存在**（`scripts/` 无 canary 脚本） | `ls scripts/ \| grep canary` |
| 部署目标 | `jp1` `84.247.154.45`，SSH user `claude`，systemd + `healthz:8080` | `deploy/deploy.sh` |

---

## §1 部署前门禁预检（必须全绿方可执行）

| # | 检查项 | 当前状态 | 阻塞说明 |
| --- | --- | --- | --- |
| G1 | 技术负责人签字（DEPLOYMENT-READINESS Sign-Off） | ❌ 空白 | **硬门禁**，agent 不代签 |
| G2 | 账户 Actions 计费已恢复 | ❌ 锁定 | 否则 release-cd 与 `docker push ghcr.io` 均失败 |
| G3 | tag 在 main HEAD（B3） | ❌ 落后 1 提交 | 决定维持 v0.15.0@52d9144 或打新 tag 覆盖 #462 |
| G4 | 版本口径已合入 main（PR #1734） | ❌ 未合 | registry/SSOT 仍陈旧 |
| G5 | 本地 build/vet/race/boundary | ✅ PASS | 已验证 |
| G6 | B4 版本一致性 / B5 引用完整性 | ✅ PASS | 已验证（PR 合入后需复跑） |
| G7 | C7 lint 严格 0 warning | ⚠️ 8 warning | 预存，0 error；是否阻断由评审定 |
| G8 | canary drill 脚本存在（D1/D2） | ❌ 不存在 | RELEASE-CHECKLIST §5 验证项无脚本可跑 |
| G9 | `prod.env` 凭据已就位（jp1 `/opt/binance/secrets/prod.env`） | ⚠️ 需人工确认 | 不含明文凭据，部署前人工核对 |
| G10 | AGENTS.md「禁止 Docker」规则澄清 | ⚠️ 冲突 | `deploy.sh`/`docker-compose.prod.yml`/`k8s/` 依赖 Docker，需治理层澄清 |

> **结论**：当前 **G1–G4、G8 未过，G2 阻断整条 CD 链路**。在 G1–G4 解除前不得执行任何生产部署。

---

## §2 执行路径（两条，择一）

### 路径 A — 治理闭环（推荐）：release-cd 工作流
触发：`v*` tag 推送` 或 `gh workflow run release-cd.yml --ref main -f tag=vX.Y.Z`
流程（来自 `release-cd.yml`）：
1. `build-all`：self-hosted runner 交叉编译 linux/amd64 + linux/arm64（`make build-all`）
2. `docker`：build & push `ghcr.io/zonecnh/binance:vX.Y.Z`（需 G2 解除）
3. `github-release`：基于 tag 生成 GitHub Release + 上传二进制
4. `canary deploy`：灰度部署（需 G8 脚本/步骤具备）

### 路径 B — 直连生产：`deploy/deploy.sh`
用法：`./deploy.sh --env prod --tag vX.Y.Z [--dry-run]`
流程（来自 `deploy/deploy.sh`）：
1. `preflight`：校验 SSH key、SSH 连通 `jp1`、建目录
2. `build_and_push`：`docker build -t ghcr.io/zonecnh/binance:$TAG .` + `docker push`（需 G2）
3. `deploy`：scp `docker-compose.prod.yml` + systemd unit + `health-check.sh`；`systemctl stop` 旧服务；备份 current；`docker pull`；安装 systemd；`ln -sfn` current；`systemctl enable/start`
4. `health_check`：`curl http://127.0.0.1:8080/healthz` 轮询 12 次（HTTP 200 通过）
5. 成功 → `cleanup`（保留最近 5 个 release，prune 镜像）；失败 → `rollback`（回退到最新备份）

> ⚠️ `deploy.sh` 在 `--env prod` 且无 `--dry-run` 时会交互式 `read -p "Confirm? (yes/no):"`，**不会静默部署**。

---

## §3 分步执行手册（在 G1–G4 解除后）

### 步骤 0：解除预检阻塞
- [ ] G1：技术负责人在 `DEPLOYMENT-READINESS-CHECKLIST.md` Sign-Off 签字
- [ ] G2：账户管理者恢复 GitHub Actions 配额/结清账单
- [ ] G3：决定版本——(a) 接受 v0.15.0@52d9144（#462 视为 out-of-scope）；或 (b) 在 HEAD `fc96705` 打新 tag `v0.15.1`/`v0.16.0`
- [ ] G4：合入 PR #1734，复跑 B4/B5
- [ ] G8：补 canary drill 脚本或明确 canary 步骤；G10：治理层澄清 Docker 规则

### 步骤 1：本地复验（CI 仍不可用时的最低保障）
```bash
cd /home/workspace/binance
export GOWORK=off
go build ./... && go vet ./... && go test ./... -race
bash scripts/boundary-gates.sh
bash /home/workspace/ZoneCNH/.github/ci/binance-version-consistency-check.sh
bash /home/workspace/ZoneCNH/.github/ci/binance-reference-integrity-check.sh
```

### 步骤 2：打 tag（若选 G3-b）
```bash
cd /home/workspace/binance && git checkout main && git pull
git tag -a v0.15.1 -m "Release v0.15.1"
git push origin v0.15.1        # 触发 release-cd（路径 A）
```

### 步骤 3：触发 CD（路径 A）
- 观察 `release-cd.yml` 运行：`gh run list --branch main`；确认 build-all / docker / github-release / canary 全绿。
- 若走路径 B 直连：
```bash
cd /home/workspace/binance
./deploy.sh --env prod --tag v0.15.1 --dry-run   # 先 dry-run 校验
./deploy.sh --env prod --tag v0.15.1             # 交互确认后真实部署
```

### 步骤 4：部署后验证
- [ ] `curl -s http://84.247.154.45:8080/healthz` → 200
- [ ] `curl -s http://84.247.154.45:8080/metrics` 可采
- [ ] 观察 `binance-server` / `binance-client` systemd 状态（`systemctl status`）
- [ ] 检查告警/consumer-lag/error-rate（DEPLOYMENT-READINESS D2 项）

### 步骤 5：回滚（异常时）
- 自动：health_check 失败 → `deploy.sh rollback()` 回退到最新备份
- 手动：`ssh claude@84.247.154.45` → `systemctl stop binance-client binance-server` → 切换 `current` 软链到 `$BACKUP/<ts>` → `systemctl start`

---

## §4 风险与注意事项

- **计费锁（G2）是整条链路的总开关**：未解除前，路径 A 的 docker push 与路径 B 的 `docker push ghcr.io` 都会失败；路径 B 的 `docker pull` 在 jp1 侧同样依赖镜像已推送成功。
- **tag 与 HEAD 一致性（G3）**：若维持 v0.15.0@52d9144，则 #462（coverage artifact 非阻断）不进本次发布；若需含入则必须打新 tag。
- **凭据（G9）**：`prod.env` 含 PG/TDengine/Redis/NATS/OSS 密码，绝不入 git；仅人工 scp 到 jp1 `/opt/binance/secrets/prod.env` 并 `chmod 600`。
- **Docker 规则冲突（G10）**：AGENTS.md 明令「禁止 Docker」，而部署机制依赖 Docker；执行前需治理层书面澄清，否则 agent 不应执行 `docker` 相关命令。
- **canary 缺口（G8）**：RELEASE-CHECKLIST §5 D1/D2 无脚本支撑，灰度验证需补步骤后方可声称 canary PASS。

---

## §5 本文件不执行的动作（红线）

- 不代签技术负责人签字（G1）
- 不绕过账户计费锁（G2）
- 不打 tag / 不推送 / 不触发 release-cd
- 不运行 `deploy.sh` 真实部署（`--env prod` 无 `--dry-run`）
- 不触碰 `prod.env` 或任何生产凭据
- 不执行 `docker` 命令（除非 G10 澄清且 G2 解除）

[RULES I BROKE]：无（仅生成文档，未执行任何部署/构建/推送/签字动作；现状数据均来自本会话实测并标注来源）。
