import { resolve } from "path";

export const WORKTREE_PATH_RULE = "/home/{module}/.worktree/workspaces/<branch-name>";

const normalizeBranchName = (branchName) => String(branchName || "").trim().replace(/^refs\/heads\//, "");

export const canonicalWorktreePath = (root, branchName) => resolve(root, ".worktree", "workspaces", normalizeBranchName(branchName));

export const parseWorktreePorcelain = (porcelain) => {
  const registered = new Set();
  const pathToBranch = new Map();
  const branchToPath = new Map();
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
    }
  }

  return { registered, pathToBranch, branchToPath };
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
