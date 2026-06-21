import assert from "node:assert/strict";
import test from "node:test";

import { buildScan, formatHumanReport } from "./branch-governance.mjs";

test("classifies merge, fix, delete, close, and publish candidates", () => {
  const calls = [];
  const responses = new Map([
    ["git rev-parse --show-toplevel", "/repo"],
    ["gh --version", "gh version 2.0.0"],
    [
      "git worktree list --porcelain",
      [
        "worktree /repo",
        "HEAD 0123456",
        "branch refs/heads/main",
        "",
        "worktree /repo/.worktree/feature-fix",
        "HEAD 1111111",
        "branch refs/heads/feature-fix",
        "",
      ].join("\n"),
    ],
    [
      "gh pr list --state open --limit 100 --json number,title,headRefName,baseRefName,mergeable,isDraft,url,updatedAt,author",
      JSON.stringify([
        {
          number: 11,
          title: "mergeable change",
          headRefName: "feature-merge",
          baseRefName: "main",
          mergeable: "MERGEABLE",
          isDraft: false,
          url: "https://example.test/pr/11",
          updatedAt: "2026-06-21T00:00:00Z",
          author: { login: "alice" },
        },
        {
          number: 12,
          title: "needs fixes",
          headRefName: "feature-fix",
          baseRefName: "main",
          mergeable: "CONFLICTING",
          isDraft: true,
          url: "https://example.test/pr/12",
          updatedAt: "2026-06-21T00:00:00Z",
          author: { login: "bob" },
        },
        {
          number: 13,
          title: "missing head branch",
          headRefName: "stale-branch",
          baseRefName: "main",
          mergeable: "UNKNOWN",
          isDraft: false,
          url: "https://example.test/pr/13",
          updatedAt: "2026-06-21T00:00:00Z",
          author: { login: "carol" },
        },
      ]),
    ],
    ["git for-each-ref --format=%(refname:short) refs/heads", ["main", "feature-merge", "feature-fix", "local-unpublished", "merged-local"].join("\n")],
    ["git rev-list --left-right --count main...feature-merge", "0 2"],
    ["git rev-list --left-right --count main...feature-fix", "3 1"],
    ["git rev-list --left-right --count main...local-unpublished", "1 1"],
    ["git rev-list --left-right --count main...merged-local", "4 0"],
    ["git rev-parse --abbrev-ref HEAD", "feature-merge"],
    ["git rev-list --left-right --count origin/main...main", "0 0"],
    ["git status --short", ""],
  ]);

  const run = (cmd, args) => {
    const key = `${cmd} ${args.join(" ")}`;
    calls.push(key);
    return responses.get(key) || "";
  };

  const scan = buildScan({ run, now: () => new Date("2026-06-21T08:00:00Z") });

  assert.equal(scan.context.gitRoot, "/repo");
  assert.equal(scan.context.ghAvailable, true);
  assert.equal(scan.summary.openPrs, 3);
  assert.equal(scan.summary.mergeCandidates, 1);
  assert.equal(scan.summary.fixCandidates, 1);
  assert.equal(scan.summary.deleteCandidates, 1);
  assert.equal(scan.summary.closeCandidates, 1);
  assert.equal(scan.summary.unpublishedBranches, 1);
  assert.equal(scan.summary.worktreePathViolations, 1);
  assert.equal(scan.summary.branchesScanned, 4);
  assert.equal(scan.context.mainSynced, true);
  assert.equal(scan.context.repoClean, true);
  assert.deepEqual(scan.context.mainSyncCounts, { originAheadMain: 0, mainAheadOrigin: 0 });

  assert.deepEqual(scan.mergeCandidates, [
    {
      number: 11,
      branch: "feature-merge",
      title: "mergeable change",
      url: "https://example.test/pr/11",
    },
  ]);
  assert.equal(scan.fixCandidates[0].number, 12);
  assert.equal(scan.fixCandidates[0].reason, "draft PR");
  assert.equal(scan.deleteCandidates[0].branch, "merged-local");
  assert.equal(scan.closeCandidates[0].branch, "stale-branch");
  assert.equal(scan.unpublishedBranches[0].branch, "local-unpublished");
  assert.deepEqual(scan.worktreePathViolations, [
    {
      branch: "feature-fix",
      actualPath: "/repo/.worktree/feature-fix",
      expectedPath: "/repo/.worktree/workspaces/feature-fix",
      reason: "branch-attached worktree path is not canonical",
    },
  ]);

  const featureFix = scan.branchInventory.find((entry) => entry.branch === "feature-fix");
  assert.ok(featureFix);
  assert.equal(featureFix.worktreePathCompliant, false);
  assert.equal(featureFix.expectedWorktreePath, "/repo/.worktree/workspaces/feature-fix");

  const report = formatHumanReport(scan);
  assert.match(report, /Worktree path violations: 1/);
  assert.match(report, /\[WORKTREE\] feature-fix/);
  assert.match(report, /\[MERGE\] #11 feature-merge/);
  assert.match(report, /\[FIX\]   #12 feature-fix/);
  assert.match(report, /\[DELETE\] merged-local/);
  assert.match(report, /\[CLOSE\] #13 stale-branch/);
  assert.match(report, /\[PUBLISH\] local-unpublished/);
  assert.ok(calls.includes("git worktree list --porcelain"));
});
