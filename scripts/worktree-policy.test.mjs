import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  WORKTREE_PATH_RULE,
  canonicalWorktreePath,
  describeBranchWorktreePath,
  findNestedRegisteredWorktrees,
  findUnregisteredWorktreeDirs,
  parseWorktreePorcelain,
} from "./worktree-policy.mjs";

test("describes canonical worktree paths and root checkout exceptions", () => {
  assert.equal(WORKTREE_PATH_RULE, "/home/{module}/.worktree/workspaces/<branch-name>");
  assert.equal(canonicalWorktreePath("/repo", "feature-x"), "/repo/.worktree/workspaces/feature-x");

  const parsed = parseWorktreePorcelain([
    "worktree /repo",
    "HEAD 1111111",
    "branch refs/heads/feature-merge",
    "",
    "worktree /repo/.worktree/feature-fix",
    "HEAD 2222222",
    "branch refs/heads/feature-fix",
    "",
  ].join("\n"));

  assert.equal(parsed.branchToPath.get("feature-merge"), "/repo");
  assert.equal(parsed.branchToPath.get("feature-fix"), "/repo/.worktree/feature-fix");
  assert.equal(parsed.pathToBranch.get("/repo"), "feature-merge");

  assert.deepEqual(
    describeBranchWorktreePath({
      root: "/repo",
      branchName: "feature-merge",
      actualPath: "/repo",
    }),
    {
      expectedPath: "/repo/.worktree/workspaces/feature-merge",
      isRootCheckout: true,
      compliant: true,
    },
  );

  assert.deepEqual(
    describeBranchWorktreePath({
      root: "/repo",
      branchName: "feature-fix",
      actualPath: "/repo/.worktree/feature-fix",
    }),
    {
      expectedPath: "/repo/.worktree/workspaces/feature-fix",
      isRootCheckout: false,
      compliant: false,
    },
  );
});

test("parseWorktreePorcelain 收录 detached HEAD worktree 路径", () => {
  const parsed = parseWorktreePorcelain([
    "worktree /repo",
    "HEAD 1111111",
    "branch refs/heads/main",
    "",
    "worktree /repo/.worktree/omx-team/run-a/worker-1",
    "HEAD 2222222",
    "detached",
    "",
    "worktree /repo/.worktree/workspaces/feature-x",
    "HEAD 3333333",
    "branch refs/heads/feature-x",
    "",
  ].join("\n"));

  // detached worktree 不进 pathToBranch/branchToPath，但进 detachedPaths
  assert.equal(parsed.pathToBranch.has("/repo/.worktree/omx-team/run-a/worker-1"), false);
  assert.equal(parsed.branchToPath.has("detached"), false);
  assert.ok(parsed.detachedPaths.has("/repo/.worktree/omx-team/run-a/worker-1"));
  // 非 detached 的 worktree 不在 detachedPaths
  assert.equal(parsed.detachedPaths.has("/repo"), false);
  assert.equal(parsed.detachedPaths.has("/repo/.worktree/workspaces/feature-x"), false);
});

test("findUnregisteredWorktreeDirs 按工作区根报告未被 Git 注册的 .worktree 目录", () => {
  const root = mkdtempSync(join(tmpdir(), "worktree-policy-"));
  const registeredWorktree = join(root, ".worktree", "workspaces", "feat", "real");
  const staleWorktree = join(root, ".worktree", "workspaces", "fix", "stale");
  const staleOmxRun = join(root, ".worktree", "omx-team", "run-a");

  try {
    mkdirSync(join(registeredWorktree, "docs"), { recursive: true });
    mkdirSync(join(staleWorktree, ".omx", "state"), { recursive: true });
    mkdirSync(staleOmxRun, { recursive: true });

    const porcelain = [
      `worktree ${root}`,
      "HEAD 1111111",
      "branch refs/heads/main",
      "",
      `worktree ${registeredWorktree}`,
      "HEAD 2222222",
      "branch refs/heads/feat/real",
      "",
    ].join("\n");

    assert.deepEqual(findUnregisteredWorktreeDirs({ root, porcelain }), [
      staleOmxRun,
      staleWorktree,
    ].sort());
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("findNestedRegisteredWorktrees 报告非根 worktree 下的注册 worktree", () => {
  const porcelain = [
    "worktree /repo",
    "HEAD 1111111",
    "branch refs/heads/main",
    "",
    "worktree /repo/.worktree/workspaces/feat/real",
    "HEAD 2222222",
    "branch refs/heads/feat/real",
    "",
    "worktree /repo/.worktree/workspaces/feat/real/.worktree/omx-team/run-a/worker-1",
    "HEAD 3333333",
    "detached",
    "",
  ].join("\n");

  assert.deepEqual(findNestedRegisteredWorktrees({ root: "/repo", porcelain }), [
    {
      path: "/repo/.worktree/workspaces/feat/real/.worktree/omx-team/run-a/worker-1",
      parentPath: "/repo/.worktree/workspaces/feat/real",
    },
  ]);
});
