# binance 统一开发与发布入口 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `module/binance` 的开发、验证、发布收敛成一个唯一入口，减少读者在 `README`、`gate`、`release`、`spec` 之间手工拼接流程的成本。

**Architecture:** `module/binance/README.md` 负责唯一导航；`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`spec/ACCEPTANCE.md` 负责发布判定；`gate/RELEASE-CHECKLIST.md`、`gate/DEPLOY-PREFLIGHT.md` 负责发布前门禁；`release/DEPLOYMENT-ORCHESTRATION.md` 只保留执行细节。入口、判定、执行三层分离，避免同一职责在多份文档里重复出现。

**Tech Stack:** Markdown, ripgrep (`rg`), Git diff, existing module/binance governance docs.

## Global Constraints

- 不重构 `module/binance` 的功能规格内容。
- 不改 runtime 行为。
- 不新增自动化脚本或 CI 工作流。
- 不删除现有门禁文档，只调整入口关系。
- 入口层只负责路由，不承担完整流程说明。

---

### Task 1: Consolidating the module entrypoint in `README.md`

**Files:**
- Modify: `module/binance/README.md`

**Interfaces:**
- Consumes: current `README.md` top-level role/Read Next structure, plus existing links to `spec/`, `gate/`, `release/`, and `design/`.
- Produces: a single navigation page that tells readers where to go for development, validation, and release.

- [ ] **Step 1: Replace the current mixed-role introduction with a short entrypoint summary**

Use this text at the top of the file:

```md
## 入口导航

`module/binance` 只保留三条主线：

- 开发：`goal/goal.md`、`spec/SPEC.md`、`design/DESIGN.md`
- 验证：`matrix/TRACEABILITY.md`、`spec/ACCEPTANCE.md`
- 发布：`gate/RELEASE-CHECKLIST.md`、`gate/DEPLOY-PREFLIGHT.md`、`release/DEPLOYMENT-ORCHESTRATION.md`

其余文档保持原位，但不再在 README 里展开成完整流程。
```

- [ ] **Step 2: Rebuild the “Read Next” section as the only detailed index**

Keep the links, but group them by the three main routes above so a reader can jump from the entry page directly to the correct layer.

- [ ] **Step 3: Verify the README no longer reads like a duplicate spec or release manual**

Run:

```bash
cd /home/workspace/ZoneCNH
rg -n "入口导航|开发：|验证：|发布：" module/binance/README.md
rg -n "Release Gate|发布前门禁|部署预检|执行手册" module/binance/README.md
```

Expected:
- The new navigation block is present.
- The README does not duplicate detailed gate or deployment instructions.

---

### Task 2: Separating release gate and preflight responsibilities

**Files:**
- Modify: `module/binance/gate/RELEASE-CHECKLIST.md`
- Modify: `module/binance/gate/DEPLOY-PREFLIGHT.md`

**Interfaces:**
- Consumes: current gate tables, current preflight status snapshot, and existing release references.
- Produces: two clearly separated docs where one answers “can we release?” and the other answers “what blocks execution?”

- [ ] **Step 1: Add a role sentence to `RELEASE-CHECKLIST.md`**

Insert immediately under the header:

```md
> **职责**：本文件只负责发布前门禁判定，不描述开发路径、也不展开执行细节。
```

- [ ] **Step 2: Add a role sentence to `DEPLOY-PREFLIGHT.md`**

Insert immediately under the header:

```md
> **职责**：本文件只负责发布执行前预检，列出阻塞条件与执行路径，不定义功能验收。
```

- [ ] **Step 3: Remove any language that implies these two files own the full release lifecycle**

Keep the existing gate rows and status snapshot, but make sure the prose around them uses the new responsibility split:
- `RELEASE-CHECKLIST.md` = publish gate
- `DEPLOY-PREFLIGHT.md` = execution preflight

- [ ] **Step 4: Verify the responsibility split is explicit**

Run:

```bash
cd /home/workspace/ZoneCNH
rg -n "只负责发布前门禁判定|只负责发布执行前预检" module/binance/gate/*.md
rg -n "不描述开发路径|不定义功能验收" module/binance/gate/*.md
```

Expected:
- Each file has one explicit responsibility sentence.
- No new execution logic was introduced.

---

### Task 3: Reframing release orchestration as execution-only

**Files:**
- Modify: `module/binance/release/DEPLOYMENT-ORCHESTRATION.md`

**Interfaces:**
- Consumes: current release execution steps, rollback procedure, and health check thresholds.
- Produces: a release execution manual that assumes the reader already passed README → gate → preflight.

- [ ] **Step 1: Add an execution-only role note near the top**

Use this text:

```md
> **职责**：发布执行层手册；入口和判定请分别查看 `README.md` / `gate/` / `spec/`。
```

- [ ] **Step 2: Tighten the summary so it no longer looks like a handoff landing page**

Replace the current executive-summary wording with a short execution summary that only lists:
- release path A (tag/workflow)
- release path B (direct deploy)
- rollback
- post-release smoke

- [ ] **Step 3: Keep historical version examples, but mark them as examples**

If the document still mentions `v0.12.0`, keep it as a historical reference only and make it clear it is not the current routing source.

- [ ] **Step 4: Verify the file reads like a runbook, not an entrypoint**

Run:

```bash
cd /home/workspace/ZoneCNH
rg -n "职责|执行层手册|release path A|release path B|rollback|post-release smoke" module/binance/release/DEPLOYMENT-ORCHESTRATION.md
```

Expected:
- The manual is clearly execution-only.
- It no longer competes with `README.md` for being the entry page.

---

## Self-Review Checklist

- [ ] `README.md` is the only navigation entry.
- [ ] `gate/RELEASE-CHECKLIST.md` and `gate/DEPLOY-PREFLIGHT.md` have distinct responsibilities.
- [ ] `release/DEPLOYMENT-ORCHESTRATION.md` reads as execution-only.
- [ ] No runtime behavior or CI workflows were added.
- [ ] No spec content was rewritten.

