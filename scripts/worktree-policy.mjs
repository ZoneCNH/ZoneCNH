import { existsSync, readdirSync } from "fs";
import { relative, resolve } from "path";

export const WORKTREE_PATH_RULE = "/home/{module}/.worktree/workspaces/<branch-name>";

const normalizeBranchName = (branchName) => String(branchName || "").trim().replace(/^refs\/heads\//, "");

export const canonicalWorktreePath = (root, branchName) => resolve(root, ".worktree", "workspaces", normalizeBranchName(branchName));

export const parseWorktreePorcelain = (porcelain) => {
  const registered = new Set();
  const pathToBranch = new Map();
  const branchToPath = new Map();
  const detachedPaths = new Set();
  let currentPath = null;

  for (const rawLine of String(porcelain || "").split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line) {
      currentPath = null;
      continue;
    }
    if (line.startsWith("worktree ")) {
      currentPath = line.slice("worktree ".length).trim();
      if (currentPath) registered.add(currentPath);
      continue;
    }
    if (line.startsWith("branch ") && currentPath) {
      const branchName = normalizeBranchName(line.slice("branch ".length).trim());
      if (!branchName) continue;
      pathToBranch.set(currentPath, branchName);
      if (!branchToPath.has(branchName)) branchToPath.set(branchName, currentPath);
      continue;
    }
    // detached HEAD worktree：porcelain 输出独立 "detached" 行而非 "branch " 行。
    // 收录其路径，供 GC 第三轨道判断是否已合入 main 后清理。
    if (line === "detached" && currentPath) {
      detachedPaths.add(currentPath);
    }
  }

  return { registered, pathToBranch, branchToPath, detachedPaths };
};

const readEntries = (dir) => {
  try {
    return readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }
};

const readSubdirs = (dir) => readEntries(dir)
  .filter((entry) => entry.isDirectory())
  .map((entry) => resolve(dir, entry.name));

const worktreeRootMarkers = new Set([".git", ".omx", ".claude", ".codex", "AGENTS.md", "CLAUDE.md", "CONSTITUTION.md", "README.md"]);

const hasWorktreeRootMarker = (dir) => readEntries(dir).some((entry) => worktreeRootMarkers.has(entry.name));

const collectUnregisteredCandidates = (dir, registeredPaths) => {
  const resolvedDir = resolve(dir);
  if (registeredPaths.has(resolvedDir)) return [];
  if (hasWorktreeRootMarker(resolvedDir)) return [resolvedDir];

  const subdirs = readSubdirs(resolvedDir);
  if (subdirs.length === 0) return [resolvedDir];

  return subdirs.flatMap((subdir) => collectUnregisteredCandidates(subdir, registeredPaths));
};

export const findUnregisteredWorktreeDirs = ({ root, porcelain }) => {
  if (!root) return [];

  const worktreeRoot = resolve(root, ".worktree");
  if (!existsSync(worktreeRoot)) return [];

  const { registered } = parseWorktreePorcelain(porcelain);
  const registeredPaths = new Set([...registered].map((path) => resolve(path)));
  const reservedTopLevelContainers = new Set(["omx-team", "workspaces"]);

  return readSubdirs(worktreeRoot)
    .flatMap((dir) => collectUnregisteredCandidates(dir, registeredPaths))
    .filter((dir) => {
      const relativePath = relative(worktreeRoot, dir);
      return !reservedTopLevelContainers.has(relativePath);
    })
    .sort();
};

export const findNestedRegisteredWorktrees = ({ root, porcelain }) => {
  if (!root) return [];

  const rootPath = resolve(root);
  const { registered } = parseWorktreePorcelain(porcelain);
  const registeredPaths = [...registered].map((path) => resolve(path)).sort((a, b) => a.length - b.length);

  return registeredPaths
    .flatMap((path) => {
      const parentPath = registeredPaths.find((candidate) => (
        candidate !== rootPath
        && candidate !== path
        && path.startsWith(`${candidate}/`)
      ));
      return parentPath ? [{ path, parentPath }] : [];
    })
    .sort((a, b) => a.path.localeCompare(b.path));
};

export const describeBranchWorktreePath = ({ root, branchName, actualPath = null }) => {
  const expectedPath = root ? canonicalWorktreePath(root, branchName) : null;
  const isRootCheckout = Boolean(root && actualPath === root);
  const compliant = actualPath ? isRootCheckout || actualPath === expectedPath : null;
  return {
    expectedPath,
    isRootCheckout,
    compliant,
  };
};
