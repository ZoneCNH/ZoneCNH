import { existsSync, readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { execSync } from "child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, "..");

const run = (cmd) => {
  try {
    return execSync(cmd, { stdio: "pipe", timeout: 3000 }).toString().trim();
  } catch {
    return "";
  }
};

const checks = [];

// ── 核心文件检查 ──────────────────────────

const claudeOk = existsSync(join(projectRoot, "CLAUDE.md"));
checks.push({ name: "CLAUDE.md", ok: claudeOk, hint: claudeOk ? "" : "缺少 CLAUDE.md" });

const claudeDirOk = existsSync(join(projectRoot, ".claude"));
checks.push({ name: ".claude/ 目录", ok: claudeDirOk, hint: claudeDirOk ? "" : "缺少 .claude/ 目录" });

const settingsOk = existsSync(join(projectRoot, ".claude/settings.json"));
checks.push({ name: "settings.json", ok: settingsOk, hint: settingsOk ? "" : "缺少 settings.json，Hook 无法注册" });

// ── Hook 文件检查 ─────────────────────────

const hooks = ["pre-tool-check.mjs", "session-context.mjs", "session-review.mjs", "post-tool-check.mjs", "pre-compact.mjs"];
for (const h of hooks) {
  const ok = existsSync(join(projectRoot, ".claude/hooks", h));
  if (h === "post-tool-check.mjs" || h === "pre-compact.mjs") {
    checks.push({ name: "hooks/" + h, ok, hint: ok ? "" : h + " 缺失（可选，L3 升级用）" });
  } else {
    checks.push({ name: "hooks/" + h, ok, hint: ok ? "" : h + " 缺失" });
  }
}

// PostToolUse 注册检查
const settingsContent = settingsOk ? readFileSync(join(projectRoot, ".claude/settings.json"), "utf-8") : "";
const postToolUseRegistered = settingsContent.includes("PostToolUse") && !settingsContent.includes("// \"PostToolUse\"");
checks.push({ name: "PostToolUse 已注册", ok: postToolUseRegistered, hint: postToolUseRegistered ? "" : "未在 settings.json 中启用（可选，取消注释即可）" });

// ── 项目类型检测 ──────────────────────────

const hasPackageJson = existsSync(join(projectRoot, "package.json"));
const hasPyprojectToml = existsSync(join(projectRoot, "pyproject.toml"));
const hasGoMod = existsSync(join(projectRoot, "go.mod"));
const hasCargoToml = existsSync(join(projectRoot, "Cargo.toml"));
const hasGemfile = existsSync(join(projectRoot, "Gemfile"));

const detectedLanguages = [];
if (hasPackageJson) detectedLanguages.push("Node.js/TypeScript");
if (hasPyprojectToml) detectedLanguages.push("Python");
if (hasGoMod) detectedLanguages.push("Go");
if (hasCargoToml) detectedLanguages.push("Rust");
if (hasGemfile) detectedLanguages.push("Ruby");

const isDocProject = detectedLanguages.length === 0 && existsSync(join(projectRoot, "README.md"));

const langLabel = detectedLanguages.length > 0 ? detectedLanguages.join(", ") : (isDocProject ? "文档项目" : "未检测到");
checks.push({ name: isDocProject ? "检测项目语言（文档项目）" : "检测项目语言", ok: true, hint: "已识别: " + langLabel });

// ── LSP 配置 ──────────────────────────────

const lspOk = existsSync(join(projectRoot, ".lsp.json"));
checks.push({ name: isDocProject ? ".lsp.json（可选）" : ".lsp.json", ok: isDocProject || lspOk, hint: lspOk ? "" : (isDocProject ? "文档项目无需 LSP" : "缺少 .lsp.json") });

// ── 语言服务检查（按项目类型）────────────

if (hasPackageJson) {
  const hasTsLsp = !!run("typescript-language-server --version 2>/dev/null");
  checks.push({ name: "TypeScript LSP", ok: hasTsLsp, hint: hasTsLsp ? "" : "未安装，执行 npm install -g typescript-language-server" });
}

if (hasPyprojectToml) {
  const hasPyright = !!run("pyright-langserver --version 2>/dev/null || pyright --version 2>/dev/null");
  checks.push({ name: "Python LSP (pyright)", ok: hasPyright, hint: hasPyright ? "" : "未安装，执行 pip install pyright" });
}

if (hasGoMod) {
  const hasGopls = !!run("gopls version 2>/dev/null");
  checks.push({ name: "Go LSP (gopls)", ok: hasGopls, hint: hasGopls ? "" : "未安装，执行 go install golang.org/x/tools/gopls@latest" });
}

if (hasCargoToml) {
  const hasRustAnalyzer = !!run("rust-analyzer --version 2>/dev/null");
  checks.push({ name: "Rust LSP (rust-analyzer)", ok: hasRustAnalyzer, hint: hasRustAnalyzer ? "" : "未安装，参考 https://rust-analyzer.github.io/manual.html" });
}

// 未检测到项目类型时，可能是文档/配置类项目，跳过 LSP 检查
if (detectedLanguages.length === 0) {
  const hasMarkdownOnly = existsSync(join(projectRoot, "README.md")) &&
    !existsSync(join(projectRoot, "package.json")) &&
    !existsSync(join(projectRoot, "pyproject.toml")) &&
    !existsSync(join(projectRoot, "go.mod"));
  if (hasMarkdownOnly) {
    checks.push({ name: "LSP（文档项目，跳过）", ok: true, hint: "文档类项目无需语言服务器" });
  } else {
    const hasTsLsp = !!run("typescript-language-server --version 2>/dev/null");
    checks.push({ name: "TypeScript LSP（默认）", ok: hasTsLsp, hint: hasTsLsp ? "" : "未安装，执行 npm install -g typescript-language-server" });
  }
}

// ── Skills 检查 ──────────────────────────

const harnessInitOk = existsSync(join(projectRoot, ".claude/skills/harness-init/SKILL.md"));
checks.push({ name: "harness-init Skill", ok: harnessInitOk, hint: harnessInitOk ? "" : "缺少初始化 Skill" });

const harnessModeOk = existsSync(join(projectRoot, ".claude/skills/harness-mode/SKILL.md"));
checks.push({ name: "harness-mode Skill", ok: harnessModeOk, hint: harnessModeOk ? "" : "缺少模式切换 Skill" });

const harnessGcOk = existsSync(join(projectRoot, ".claude/skills/harness-gc/SKILL.md"));
checks.push({ name: "harness-gc Skill（可选）", ok: harnessGcOk, hint: harnessGcOk ? "" : "缺少 GC Agent Skill" });

// ── npm 分发 ────────────────────────────

const packageJsonOk = existsSync(join(projectRoot, "package.json"));
const initScriptOk = existsSync(join(projectRoot, "scripts/init.mjs"));
const npmPkgLabel = isDocProject ? "npm 分发 (package.json)（可选）" : "npm 分发 (package.json)";
const npmInitLabel = isDocProject ? "npm init 脚本（可选）" : "npm init 脚本";
checks.push({ name: npmPkgLabel, ok: packageJsonOk, hint: packageJsonOk ? "" : (isDocProject ? "非 npm 项目，无需" : "缺少 package.json") });
checks.push({ name: npmInitLabel, ok: initScriptOk, hint: initScriptOk ? "" : (isDocProject ? "非 npm 项目，无需" : "缺少 init.mjs") });

// ── CLAUDE.md 内容完整性 ─────────────────

const claudeMdPath = join(projectRoot, "CLAUDE.md");
if (existsSync(claudeMdPath)) {
  const content = readFileSync(claudeMdPath, "utf-8");
  // 模板仓库中有占位符是正常行为，不作为 CI 失败条件
  if (content.includes("【待填写")) {
    checks.push({ name: "CLAUDE.md 占位符（可选）", ok: false, hint: "还有占位符未替换，首次使用请对 AI 说「帮我初始化 Harness」" });
  }
}

// ── GC 扫描脚本检查 ──────────────────────

const gcScanOk = existsSync(join(projectRoot, "scripts/gc-scan.mjs"));
checks.push({ name: "gc-scan.mjs（可选）", ok: gcScanOk, hint: gcScanOk ? "" : "缺少 GC 扫描脚本" });

// ── 输出 ──────────────────────────────────

const okCount = checks.filter((c) => c.ok).length;
const criticalFails = checks.filter((c) => !c.ok && !c.name.includes("（可选）")).length;

console.log("\nHarness 健康检查: " + okCount + "/" + checks.length + " 通过\n");
for (const c of checks) {
  const icon = c.ok ? "✅" : "❌";
  console.log("  " + icon + " " + c.name + (c.hint ? " — " + c.hint : ""));
}
console.log("");

// CI 模式下，关键检查失败时退出非零
if (criticalFails > 0) {
  process.exit(1);
}
