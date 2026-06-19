import { execSync, execFileSync } from "child_process";
import { readdirSync, readFileSync, existsSync, statSync, rmSync } from "fs";
import { join, dirname, relative } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, "../..");
const loopsDir = join(projectRoot, ".claude/loops");

const run = (cmd) => {
  try {
    return execSync(cmd, { encoding: "utf-8", timeout: 3000 }).trim();
  } catch {
    return "";
  }
};

// ISC-3c: 分支名来自 git 输出（可能含特殊字符），用 execFileSync 传单参数数组防 shell 注入
const isAncestor = (br) => {
  try {
    execFileSync("git", ["merge-base", "--is-ancestor", br, "main"], { stdio: "ignore", timeout: 3000 });
    return true; // exit 0 = br 是 main 的祖先（已合入）
  } catch {
    return false;
  }
};

const branch = run("git rev-parse --abbrev-ref HEAD 2>/dev/null") || "（非 git 目录）";
const status = run("git status --short 2>/dev/null") || "";
const log = run("git log --oneline -10 2>/dev/null") || "";

const lines = ["--- SessionStart Hook ---", "分支: " + branch];

// === Branch discipline guard ===
if (branch === "main") {
  lines.push("---", "⚠️ 当前在 main 分支！CLAUDE.md 禁止在 main 上直接编辑。请创建 feature 分支：");
  lines.push("   git checkout -b docs/<module>-<描述>");
}

// === Stale working tree guard ===
const originDiff = run("git diff origin/main --stat 2>/dev/null") || "";
if (originDiff) {
  lines.push("---", "⚠️ 工作区与 origin/main 存在差异 — 可能使用了过时的文件版本。运行 git pull origin main 同步后重新开始：");
  const diffLines = originDiff.split("\n").filter(Boolean);
  lines.push(...diffLines.slice(0, 5).map(l => "   " + l));
  if (diffLines.length > 5) lines.push("   ... 还有 " + (diffLines.length - 5) + " 个文件");
}

if (status) {
  lines.push("---", "变更:");
  lines.push(status);
} else {
  lines.push("---", "无未提交变更");
}

if (log) {
  lines.push("---", "最近 10 条提交:");
  lines.push(log);
}

// Harness 状态感知（阶段 + 模式）
const statePath = join(projectRoot, ".claude/.harness-state");
if (existsSync(statePath)) {
  try {
    const state = JSON.parse(readFileSync(statePath, "utf-8"));
    lines.push("---");
    lines.push("Harness 状态: 阶段=" + (state.phase || "build") + "  模式=" + (state.mode || "full"));
  } catch {}
}

// Loop 状态 (hot state — 从 STATE.md 提取)
const loopStatePath = join(loopsDir, "STATE.md");
if (existsSync(loopStatePath)) {
  const sc = readFileSync(loopStatePath, "utf-8");
  const phaseMatch = sc.match(/\*\*Phase\*\*: (.+)/);
  const lastRunMatch = sc.match(/\*\*Last Run\*\*: (.+)/);
  const findingsMatch = sc.match(/\*\*Findings Open\*\*: (.+)/);
  const phase = phaseMatch ? phaseMatch[1] : "unknown";
  const lastRun = lastRunMatch ? lastRunMatch[1] : "never";
  const findings = findingsMatch ? findingsMatch[1] : "0";
  lines.push("---", "Loop 状态: Phase=" + phase + " | Last Run=" + lastRun + " | Open Findings=" + findings);

  // LOG.md 最近摘要
  const logPath = join(loopsDir, "LOG.md");
  if (existsSync(logPath)) {
    const logContent = readFileSync(logPath, "utf-8");
    const entries = logContent.split("\n").filter(l => l.includes("|") && l.includes("auto") && !l.includes("Timestamp |"));
    const recent = entries.slice(-3);
    if (recent.length > 0) {
      lines.push("  最近 GC 扫描:");
      for (const e of recent) {
        const cols = e.split("|").map(c => c.trim()).filter(Boolean);
        if (cols.length >= 3) lines.push("    " + cols[0] + " → " + cols[2]);
      }
    }
  }
}

// 加载最近 5 次审查报告
const reviewsDir = join(projectRoot, ".claude/reviews");
if (existsSync(reviewsDir)) {
  const reviewFiles = readdirSync(reviewsDir)
    .filter(f => f.endsWith(".md"))
    .sort()
    .reverse()
    .slice(0, 5);

  if (reviewFiles.length > 0) {
    lines.push("---", "最近 " + reviewFiles.length + " 次审查:");
    for (const file of reviewFiles) {
      const content = readFileSync(join(reviewsDir, file), "utf-8");
      const flagSection = (content.split("### 规则检查\n")[1] || "").split("\n###")[0] || "";
      const flags = flagSection.split("\n").filter(l => l.trim());
      lines.push(file.replace(".md", ""));
      lines.push(...flags.map(f => "  " + f));
    }
  }
}

// 检查 CLAUDE.md 是否未初始化
const claudeMdPath = join(projectRoot, "CLAUDE.md");
if (existsSync(claudeMdPath)) {
  const claudeContent = readFileSync(claudeMdPath, "utf-8");
  if (claudeContent.includes("【待填写")) {
    lines.push("---", "⚠️ CLAUDE.md 还有占位符未替换，请对 AI 说：帮我初始化 Harness");
  }
}

// === Worktree 孤儿 GC（保守：dry-run 默认，WORKTREE_GC_CLEAN=1 才真删）===
// 实现 CLAUDE.md §工作区 GC：扫描 .worktree/ 下已 git-forget 的孤儿目录，
// 仅在 mtime > 24h 且非白名单时报告；显式 WORKTREE_GC_CLEAN=1 才真正删除。
const worktreeBase = join(projectRoot, ".worktree");
if (existsSync(worktreeBase)) {
  const cleanMode = process.env.WORKTREE_GC_CLEAN === "1";
  const TTL_MS = 24 * 3600 * 1000;
  const PROTECT = new Set(["note.md", "v2.md"]);

  // 注册的 worktree 路径（git worktree list）
  const registered = new Set(
    run("git worktree list --porcelain 2>/dev/null")
      .split("\n")
      .filter(l => l.startsWith("worktree "))
      .map(l => l.slice("worktree ".length).trim())
  );
  // 排除主 worktree，避免其路径作为 .worktree/* 的前缀污染判定
  const regSub = new Set([...registered].filter(r => r !== projectRoot));

  // 候选：.worktree/<top> 与 .worktree/<top>/<sub>
  const candidates = [];
  for (const top of readdirSync(worktreeBase, { withFileTypes: true })) {
    if (!top.isDirectory()) continue;
    const tp = join(worktreeBase, top.name);
    candidates.push(tp);
    for (const sub of readdirSync(tp, { withFileTypes: true })) {
      if (sub.isDirectory()) candidates.push(join(tp, sub.name));
    }
  }

  const classify = (c) => {
    if (registered.has(c)) return "self";
    for (const r of regSub) {
      if (c === r) return "self";
      if (c.startsWith(r + "/")) return "inside-active";
      if (r.startsWith(c + "/")) return "active-container";
    }
    return "ORPHAN";
  };

  // 白名单：目录直接含 note.md / v2.md 文件则保护
  const hasProtectedFile = (dir) => {
    try {
      return readdirSync(dir, { withFileTypes: true })
        .some(e => e.isFile() && PROTECT.has(e.name));
    } catch {
      return false;
    }
  };

  // 护栏：worktree 残骸检测。被 `git worktree forget` 的工作区仍保留 `.git` 文件
  // （主仓库 .git 是目录；worktree 工作区的 .git 是文件，内容 `gitdir: ...`）。
  // 真删时跳过此类孤儿，避免丢失工作区里未 commit 的改动（已 commit 的提交在
  // 分支 ref 上，不随目录删除丢失；仅未提交工作区改动会丢）。
  const hasWorktreeRemnant = (dir) => {
    try {
      const g = join(dir, ".git");
      return existsSync(g) && statSync(g).isFile();
    } catch {
      return false;
    }
  };

  // 护栏：未提交改动检测（与轨道 A hasWorktreeRemnant 对称）。
  // 轨道 B 用 `git worktree remove --force`，--force 会丢弃工作区未提交改动；
  // 故 remove 前先 status --porcelain，输出非空即 dirty → 跳过保护。
  // ISC-3c 同源：路径来自 git 输出，用 execFileSync 数组形式防注入。
  const hasUncommittedChanges = (dir) => {
    try {
      const out = execFileSync("git", ["-C", dir, "status", "--porcelain"], { encoding: "utf-8", timeout: 3000 });
      return out.trim().length > 0;
    } catch {
      return false;
    }
  };

  const now = Date.now();
  const orphans = candidates
    .filter((c) => classify(c) === "ORPHAN")
    .filter((c) => !hasProtectedFile(c))
    .map((c) => ({ path: c, ageMs: now - statSync(c).mtimeMs }))
    .filter((o) => o.ageMs > TTL_MS)
    .sort((a, b) => b.ageMs - a.ageMs);

  if (orphans.length > 0) {
    // 预分类：哪些是 worktree 残骸（真删时受护栏保护）
    const tagged = orphans.map((o) => ({ ...o, remnant: hasWorktreeRemnant(o.path) }));
    const remnantCount = tagged.filter((o) => o.remnant).length;
    lines.push("---");
    lines.push("🧹 Worktree 孤儿 GC（" + (cleanMode ? "✅ CLEAN 模式" : "dry-run，设 WORKTREE_GC_CLEAN=1 真删") + "）：发现 " + orphans.length + " 个 >24h 孤儿" + (remnantCount > 0 ? "（其中 " + remnantCount + " 个 worktree 残骸将受保护）" : ""));
    for (const o of tagged.slice(0, 15)) {
      lines.push("   " + Math.floor(o.ageMs / 3600000) + "h  " + relative(projectRoot, o.path) + (o.remnant ? "  🛡️ 残骸受保护" : ""));
    }
    if (tagged.length > 15) lines.push("   ... 还有 " + (tagged.length - 15) + " 个");
    if (cleanMode) {
      let removed = 0;
      let guarded = 0;
      for (const o of tagged) {
        // 护栏：跳过 worktree 残骸，保护其工作区未提交改动
        if (o.remnant) { guarded++; continue; }
        try { rmSync(o.path, { recursive: true, force: true }); removed++; } catch {}
      }
      lines.push("   已删除 " + removed + "/" + orphans.length + " 个" + (guarded > 0 ? "，保护 " + guarded + " 个 worktree 残骸" : ""));
    }
  }

  // === ISC-1~4: 「已合入可清理」类别（与 ORPHAN 正交）===
  // 这些 worktree 仍被 git worktree list 管理，但其分支已合入 main。合入即报告，不受 TTL_MS 约束。
  // 默认仅报告（给 git worktree remove 提示）；WORKTREE_GC_CLEAN=1 时 git worktree remove --force（非 rmSync，
  // 避免裸删目录留 .git/worktrees 元数据残留）。尊重 note.md/v2.md 白名单。
  {
    // ISC-1: 解析 porcelain 的 branch 行，按 worktree 块聚合 path → branch 映射
    const wtPorcelain = run("git worktree list --porcelain 2>/dev/null");
    const pathToBranch = new Map();
    let curPath = null;
    for (const line of wtPorcelain.split("\n")) {
      if (line.startsWith("worktree ")) {
        curPath = line.slice("worktree ".length).trim();
      } else if (line.startsWith("branch ")) {
        const bn = line.slice("branch ".length).trim().replace(/^refs\/heads\//, "");
        if (curPath) pathToBranch.set(curPath, bn);
      } else if (line === "") {
        curPath = null; // ISC-3b: detached HEAD 块无 branch 行，自然不入 map
      }
    }

    const mergedStale = [];
    for (const [wtPath, wtBranch] of pathToBranch) {
      if (wtPath === projectRoot) continue; // ISC-3a: 主 worktree 过滤
      if (hasProtectedFile(wtPath)) continue; // ISC-4: 尊重 PROTECT 白名单
      if (isAncestor(wtBranch)) mergedStale.push({ path: wtPath, branch: wtBranch }); // ISC-2/3c
    }

    if (mergedStale.length > 0) {
      // 预检测 dirty：与轨道 A 残骸保护对称，--force 会丢弃未提交改动，故提前标记
      const tagged = mergedStale.map((m) => ({ ...m, dirty: hasUncommittedChanges(m.path) }));
      const dirtyCount = tagged.filter((m) => m.dirty).length;
      lines.push("---");
      lines.push("♻️ 已合入可清理（分支已合入 main）：" + mergedStale.length + " 个" + (cleanMode ? "（CLEAN：git worktree remove）" : "（dry-run）") + (dirtyCount > 0 ? "（其中 " + dirtyCount + " 个 🛡️ 有未提交改动" + (cleanMode ? "，将跳过" : "") + "）" : ""));
      for (const m of tagged.slice(0, 15)) {
        lines.push("   " + relative(projectRoot, m.path) + "  ← " + m.branch + (m.dirty ? "  🛡️ 有未提交改动" : ""));
      }
      if (tagged.length > 15) lines.push("   ... 还有 " + (tagged.length - 15) + " 个");
      if (!cleanMode) {
        lines.push("   提示：git worktree remove \"" + tagged[0].path + "\"" + (tagged[0].dirty ? "  ⚠️ 该工作区有未提交改动，remove --force 会丢弃" : ""));
      } else {
        let removed = 0;
        let guarded = 0;
        for (const m of tagged) {
          // 护栏：跳过 dirty 工作区，保护其未提交改动（与轨道 A 残骸保护对称）
          if (m.dirty) { guarded++; continue; }
          try { execFileSync("git", ["worktree", "remove", "--force", m.path], { stdio: "ignore", timeout: 5000 }); removed++; } catch {}
        }
        lines.push("   已 git worktree remove " + removed + "/" + mergedStale.length + " 个" + (guarded > 0 ? "，保护 " + guarded + " 个有未提交改动的工作区" : ""));
      }
    }
  }
}

lines.push("------------------------");

process.stdout.write(lines.join("\n"));
