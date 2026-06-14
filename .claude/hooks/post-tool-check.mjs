import { execSync } from "child_process";
import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, "../..");

// PostToolUse — dirty-file guard
// 检测 Edit/Write 目标文件是否相对于 HEAD 有未暂存变更，
// 若有则表明工作树文件可能过期（working tree ≠ HEAD），
// 此时跳过后续处理以防止静默重写。

const input = readFileSync(0, "utf-8").trim();
if (!input) process.exit(0);

let call;
try {
  call = JSON.parse(input);
} catch {
  process.exit(0);
}

const tool = call.tool || "";
const args = call.input || {};
const filePath = args.file_path || args.path || "";

if ((tool === "Write" || tool === "Edit") && filePath) {
  const isStale = (() => {
    try {
      const diff = execSync(`git diff --name-only -- "${filePath}"`, {
        cwd: projectRoot, timeout: 3000, stdio: "pipe", encoding: "utf-8"
      }).trim();
      return diff !== "";
    } catch {
      return false;
    }
  })();

  if (isStale) {
    process.stderr.write(`[post-tool-check] 跳过：${filePath} 有未暂存变更（工作树可能过期）\n`);
    process.exit(0);
  }
}

process.exit(0);
