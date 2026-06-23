#!/usr/bin/env node
/**
 * gc-scan.mjs — Harness Starter GC 扫描器
 *
 * 确定性健康检查，不依赖 AI。外部验证门（Sniff 模式）。
 *
 * 用法: node scripts/gc-scan.mjs [--json] [--ci]
 */

import { readFileSync, existsSync, readdirSync, statSync, writeFileSync, mkdirSync } from "fs";
import { join, dirname, resolve, relative } from "path";
import { fileURLToPath } from "url";
import { execSync, execFileSync } from "child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "..");

const run = (cmd, opts = {}) => {
  try {
    return execSync(cmd, { cwd: projectRoot, encoding: "utf-8", timeout: 5000, ...opts }).trim();
  } catch { return ""; }
};

const findings = [];
const addFinding = (type, severity, file, line, message, detail) => {
  findings.push({ type, severity, file, line, message, detail, ts: new Date().toISOString() });
};

// 1. CLAUDE.md 完整性
const claudeMdPath = join(projectRoot, "CLAUDE.md");
if (!existsSync(claudeMdPath)) {
  addFinding("missing_file", "critical", "CLAUDE.md", 0, "CLAUDE.md 缺失", "项目根缺少 CLAUDE.md");
} else {
  const content = readFileSync(claudeMdPath, "utf-8");
  const lines = content.split("\n");
  for (const s of ["行为准则", "消除信息差", "Simplicity First", "Surgical Changes", "Goal-Driven"]) {
    if (!content.includes(s)) {
      addFinding("missing_section", "warning", "CLAUDE.md", 0, "缺少章节: " + s, "未找到 " + s);
    }
  }
  const todoLine = lines.findIndex(l => l.includes("【待填写"));
  if (todoLine !== -1) {
    addFinding("placeholder", "warning", "CLAUDE.md", todoLine + 1, "存在未占位符", lines[todoLine].trim());
  }
}

// 2. Git 状态
const gitRoot = run("git rev-parse --show-toplevel 2>/dev/null");
if (gitRoot) {
  const branch = run("git rev-parse --abbrev-ref HEAD");
  const uncommitted = run("git status --short");
  const uncommittedLines = uncommitted.split("\n").filter(Boolean);
  if (uncommittedLines.length > 10) {
    addFinding("many_uncommitted", "info", ".", 0, "大量未提交变更 (" + uncommittedLines.length + " 个文件)", "建议及时提交");
  }
  const diffContent = run("git diff --unified=0") + "\n" + run("git diff --cached --unified=0");
  if (/console\.\w+\s*\(/.test(diffContent)) {
    addFinding("debug_residue", "warning", "(diff)", 0, "调试残留: console.log", "变更中包含 console.log");
  }
  if (/\bdebugger\b/.test(diffContent)) {
    addFinding("debug_residue", "warning", "(diff)", 0, "调试残留: debugger", "变更中包含 debugger");
  }
}

// 3. TODO/FIXME 扫描 (排除自身)
const scanDir = (dir, depth = 0) => {
  if (depth > 4 || !existsSync(dir)) return;
  try {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(dir, entry.name);
      if (entry.name.startsWith(".") || entry.name === "node_modules" || entry.name === ".git") continue;
      if (entry.isDirectory()) { scanDir(fullPath, depth + 1); continue; }
      if (!/\.(mjs|js|ts|tsx|jsx|md|json|yaml|yml)$/i.test(entry.name)) continue;
      if (fullPath.endsWith("gc-scan.mjs")) continue; // 排除自身
      const content = readFileSync(fullPath, "utf-8");
      const total = (content.match(/\bTODO\b/g) || []).length + (content.match(/\bFIXME\b/g) || []).length;
      if (total > 5) {
        addFinding("todo_cluster", "info", relative(projectRoot, fullPath), 0, "TODO/FIXME 集中 (" + total + " 处)", total + " 处");
      }
    }
  } catch { /* skip */ }
};
scanDir(projectRoot);

// 4. .gitignore
const gitignorePath = join(projectRoot, ".gitignore");
if (existsSync(gitignorePath)) {
  const giContent = readFileSync(gitignorePath, "utf-8");
  for (const entry of ["node_modules/", ".claude/reviews/", ".claude/loops/"]) {
    if (!giContent.includes(entry) && existsSync(join(projectRoot, entry.replace(/\/$/, "")))) {
      addFinding("gitignore_missing", "info", ".gitignore", 0, ".gitignore 缺少: " + entry, entry + " 存在但未被忽略");
    }
  }
} else {
  addFinding("missing_file", "warning", ".gitignore", 0, ".gitignore 缺失", "建议创建");
}

// 5. Hooks 状态
const hooksDir = join(projectRoot, ".claude/hooks");
if (existsSync(hooksDir)) {
  const hooksFiles = readdirSync(hooksDir).filter(f => f.endsWith(".mjs"));
  for (const h of ["pre-tool-check.mjs", "session-context.mjs", "session-review.mjs"]) {
    if (!hooksFiles.includes(h)) {
      addFinding("missing_hook", "critical", ".claude/hooks/", 0, "缺失 Hook: " + h, "必备安全/上下文 Hook");
    }
  }
  const settingsPath = join(projectRoot, ".claude/settings.json");
  if (existsSync(settingsPath)) {
    const sc = readFileSync(settingsPath, "utf-8");
    const map = { "pre-tool-check.mjs": "PreToolUse", "post-tool-check.mjs": "PostToolUse", "session-context.mjs": "SessionStart", "session-review.mjs": "Stop", "pre-compact.mjs": "PreCompact" };
    for (const h of hooksFiles) {
      const ev = map[h];
      if (!ev) continue;
      const isRegistered = sc.includes(ev) && sc.includes(h);
      const isCommented = sc.includes("// " + ev);
      if (!isRegistered) {
        addFinding("hook_not_registered", "warning", ".claude/settings.json", 0, "Hook 未注册: " + h + (isCommented ? " (被注释)" : ""), "请在 settings.json 中注册");
      }
    }
  }
} else {
  addFinding("missing_dir", "critical", ".claude/hooks/", 0, "Hooks 目录缺失");
}

// 6. Harness 状态
const statePath = join(projectRoot, ".claude/.harness-state");
if (existsSync(statePath)) {
  try {
    const state = JSON.parse(readFileSync(statePath, "utf-8"));
    if (!state.phase || !state.mode) {
      addFinding("harness_state_invalid", "warning", ".claude/.harness-state", 0, ".harness-state 缺少必要字段", "需要 phase 和 mode");
    }
  } catch {
    addFinding("harness_state_invalid", "warning", ".claude/.harness-state", 0, ".harness-state JSON 解析失败", "文件可能已损坏");
  }
} else {
  addFinding("missing_file", "info", ".claude/.harness-state", 0, ".harness-state 缺失", "初始化时自动创建");
}

// 7. TypeScript 类型检查
if (existsSync(join(projectRoot, "tsconfig.json"))) {
  const tscResult = run("npx tsc --noEmit 2>&1 || true");
  const errors = (tscResult.match(/error TS\d+/g) || []).length;
  if (errors > 0) {
    addFinding("tsc_errors", "warning", "(tsc --noEmit)", 0, "类型错误: " + errors + " 个", tscResult.split("\n").slice(0, 5).join("\n"));
  } else if (tscResult && !tscResult.includes("error TS")) {
    addFinding("tsc_pass", "info", "(tsc --noEmit)", 0, "TypeScript 类型检查通过", "无类型错误");
  }
}

// 8. LSP 配置
const lspPath = join(projectRoot, ".lsp.json");
if (existsSync(lspPath)) {
  if (!readFileSync(lspPath, "utf-8").includes("typescript-language-server")) {
    addFinding("lsp_config", "info", ".lsp.json", 0, "LSP 未配置 TypeScript", "其他语言服务");
  }
} else {
  addFinding("missing_file", "warning", ".lsp.json", 0, ".lsp.json 缺失", "LSP 不可用");
}

// 9. Worktree 残留巡检（P3：让确定性扫描器独立发现 worktree 孤儿/已合入残留，
//    弥补 GC 仅在 Claude SessionStart 触发的局限。只报告，不删除）
if (gitRoot) {
  const isAncestor = (br) => {
    try {
      execFileSync("git", ["merge-base", "--is-ancestor", br, "main"], { stdio: "ignore", timeout: 3000 });
      return true; // exit 0 = br 是 main 祖先（已合入）
    } catch { return false; }
  };

  const worktreeBase = join(projectRoot, ".worktree");
  if (existsSync(worktreeBase)) {
    // ORPHAN：.worktree/ 下不在 git worktree list 的目录（与 session-context.mjs 轨道 A 同源）
    const registered = new Set(
      run("git worktree list --porcelain 2>/dev/null")
        .split("\n")
        .filter(l => l.startsWith("worktree "))
        .map(l => l.slice("worktree ".length).trim())
    );
    const regSub = new Set([...registered].filter(r => r !== projectRoot));
    const candidates = [];
    for (const top of readdirSync(worktreeBase, { withFileTypes: true })) {
      if (!top.isDirectory()) continue;
      const tp = join(worktreeBase, top.name);
      candidates.push(tp);
      try {
        for (const sub of readdirSync(tp, { withFileTypes: true })) {
          if (sub.isDirectory()) candidates.push(join(tp, sub.name));
        }
      } catch {}
    }
    const orphanCands = candidates.filter((c) => {
      if (registered.has(c)) return false;
      for (const r of regSub) {
        if (c === r || c.startsWith(r + "/") || r.startsWith(c + "/")) return false;
      }
      return true;
    });
    // 只报叶子孤儿：排除是其他孤儿父目录的容器（如 .worktree/workspaces 容器 → 只报其下叶子）
    for (const c of orphanCands) {
      if (orphanCands.some((other) => other.startsWith(c + "/"))) continue;
      addFinding("worktree_orphan", "info", relative(projectRoot, c), 0,
        "Worktree 孤儿目录（不在 git worktree list）", relative(projectRoot, c));
    }
  }

  // 已合入可清理：在 git worktree list 但分支已合入 main（与 session-context.mjs 轨道 B 同源）
  let curPath = null;
  const pathToBranch = new Map();
  for (const line of run("git worktree list --porcelain 2>/dev/null").split("\n")) {
    if (line.startsWith("worktree ")) curPath = line.slice("worktree ".length).trim();
    else if (line.startsWith("branch ") && curPath) pathToBranch.set(curPath, line.slice("branch ".length).trim().replace(/^refs\/heads\//, ""));
    else if (line === "") curPath = null;
  }
  for (const [wtPath, wtBranch] of pathToBranch) {
    if (wtPath === projectRoot) continue;
    if (isAncestor(wtBranch)) {
      addFinding("worktree_merged", "info", relative(projectRoot, wtPath), 0,
        "已合入 main 的 worktree 可清理: " + wtBranch, relative(projectRoot, wtPath));
    }
  }
}

// 10. Stash GC — auto-safety stash 超限与过期检测
if (gitRoot) {
  const stashLines = (run("git stash list 2>/dev/null") || "").split("\n").filter(Boolean);
  const totalStashes = stashLines.length;
  const autoSafetyStashes = stashLines.filter(l => l.includes("auto-safety")).length;
  const STASH_LIMIT = 30;
  const STASH_TTL_DAYS = 3;

  if (totalStashes > STASH_LIMIT) {
    addFinding("stash_overflow", "warning", "", 0,
      `Stash 超限: ${totalStashes}/${STASH_LIMIT}（auto-safety ${autoSafetyStashes} 个）`,
      "运行 scripts/gc-cleanup.sh 或手动 git stash drop 过期条目");
  }

  if (autoSafetyStashes > 10) {
    addFinding("stash_autosafety", "info", "", 0,
      `Auto-safety stash 积累: ${autoSafetyStashes} 个（TTL ${STASH_TTL_DAYS} 天）`,
      "SessionStart hook 会自动扫描过期条目；超过 STASH_LIMIT 时 oldest-first 清理");
  }

  // 检测过期 auto-safety stash
  const cutoffSec = Date.now() / 1000 - STASH_TTL_DAYS * 86400;
  let expiredCount = 0;
  for (const stashLine of stashLines) {
    if (!stashLine.includes("auto-safety")) continue;
    const refMatch = stashLine.match(/stash@\{(\d+)\}/);
    if (!refMatch) continue;
    const stashRef = `stash@{${refMatch[1]}}`;
    const dateStr = run(`git log -1 --format="%at" ${stashRef} 2>/dev/null`);
    if (!dateStr || parseInt(dateStr) < cutoffSec) expiredCount++;
  }
  if (expiredCount > 0) {
    addFinding("stash_expired", "warning", "", 0,
      `过期 auto-safety stash: ${expiredCount} 个（> ${STASH_TTL_DAYS} 天）`,
      "运行 scripts/gc-cleanup.sh 自动清理");
  }
}

// 11. 已合并分支清理检测
if (gitRoot) {
  const localBranches = (run("git branch --list 'docs/*' --format='%(refname:short)' 2>/dev/null") || "")
    .split("\n").filter(Boolean);
  const mergedToDelete = [];
  for (const b of localBranches) {
    if (run(`git merge-base --is-ancestor ${b} main && echo yes || echo no 2>/dev/null`) === "yes") {
      mergedToDelete.push(b);
    }
  }
  if (mergedToDelete.length > 0) {
    addFinding("branch_merged", "info", "", 0,
      `已合入 main 的 docs 分支: ${mergedToDelete.length} 个 (${mergedToDelete.slice(0, 3).join(", ")}${mergedToDelete.length > 3 ? "..." : ""})`,
      mergedToDelete.length > 3
        ? `运行 git branch -D ${mergedToDelete.join(" ")} 清理`
        : `运行 git branch -D ${mergedToDelete[0]} 清理`);
  }
}

// ── 汇总 ──────────────────────────────────

const bySeverity = { critical: [], warning: [], info: [] };
for (const f of findings) bySeverity[f.severity].push(f);

const result = {
  scanId: "gc-" + Date.now(),
  timestamp: new Date().toISOString(),
  summary: {
    total: findings.length,
    critical: bySeverity.critical.length,
    warning: bySeverity.warning.length,
    info: bySeverity.info.length,
  },
  context: {
    branch: gitRoot ? run("git rev-parse --abbrev-ref HEAD") : "n/a",
    lastCommit: gitRoot ? run("git log -1 --oneline") : "n/a",
  },
  findings,
};

// ── 输出 ──────────────────────────────────

const isJson = process.argv.includes("--json");
const isCi = process.argv.includes("--ci");

if (isJson) {
  process.stdout.write(JSON.stringify(result, null, 2));
} else {
  console.log("\n=== GC Scan: " + result.scanId + " ===");
  console.log("  分支: " + result.context.branch + "  提交: " + result.context.lastCommit);
  console.log("  总计: " + result.summary.total + "  (" + result.summary.critical + " critical, " + result.summary.warning + " warning, " + result.summary.info + " info)");
  console.log("");
  for (const f of findings) {
    const icon = f.severity === "critical" ? "[CRIT]" : f.severity === "warning" ? "[WARN]" : "[INFO]";
    console.log("  " + icon + " " + f.message);
    if (f.file) console.log("      文件: " + f.file + (f.line ? ":" + f.line : ""));
    if (f.detail) console.log("      " + f.detail.slice(0, 120));
    console.log("");
  }
}

// 持久化到 LOG.md (追加模式)
const loopsDir = join(projectRoot, ".claude/loops");
if (!existsSync(loopsDir)) mkdirSync(loopsDir, { recursive: true });
const logPath = join(loopsDir, "LOG.md");
let logContent = existsSync(logPath) ? readFileSync(logPath, "utf-8") : "";
const logLine = "| " + result.timestamp + " | auto | " + result.summary.total + " (" + result.summary.critical + "c " + result.summary.warning + "w " + result.summary.info + "i) | — |";
// 如果只有表头则追加，否则续在最后
if (logContent.trim().split("\n").filter(l => l.includes("|")).length <= 2) {
  logContent += "\n" + logLine;
} else {
  logContent = logContent.trimEnd() + "\n" + logLine;
}
writeFileSync(logPath, logContent + "\n", "utf-8");

if (isCi && result.summary.critical > 0) process.exit(1);
