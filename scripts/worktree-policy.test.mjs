import assert from "node:assert/strict";
import test from "node:test";

import {
  WORKTREE_PATH_RULE,
  canonicalWorktreePath,
  describeBranchWorktreePath,
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
