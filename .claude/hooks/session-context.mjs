import { execSync } from "child_process";
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

  const now = Date.now();
  const orphans = candidates
    .filter((c) => classify(c) === "ORPHAN")
    .filter((c) => !hasProtectedFile(c))
    .map((c) => ({ path: c, ageMs: now - statSync(c).mtimeMs }))
    .filter((o) => o.ageMs > TTL_MS)
    .sort((a, b) => b.ageMs - a.ageMs);

  if (orphans.length > 0) {
    lines.push("---");
    lines.push("🧹 Worktree 孤儿 GC（" + (cleanMode ? "✅ CLEAN 模式" : "dry-run，设 WORKTREE_GC_CLEAN=1 真删") + "）：发现 " + orphans.length + " 个 >24h 孤儿");
    for (const o of orphans.slice(0, 15)) {
      lines.push("   " + Math.floor(o.ageMs / 3600000) + "h  " + relative(projectRoot, o.path));
    }
    if (orphans.length > 15) lines.push("   ... 还有 " + (orphans.length - 15) + " 个");
    if (cleanMode) {
      let removed = 0;
      for (const o of orphans) {
        try { rmSync(o.path, { recursive: true, force: true }); removed++; } catch {}
      }
      lines.push("   已删除 " + removed + "/" + orphans.length + " 个");
    }
  }
}

lines.push("------------------------");

process.stdout.write(lines.join("\n"));
