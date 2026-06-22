import { resolve } from "path";

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
