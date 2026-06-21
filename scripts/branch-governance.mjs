#!/usr/bin/env node
/**
 * branch-governance.mjs — scan local branches and GitHub PRs for governance actions.
 *
 * Read-only by default. It classifies:
 * - merge candidates: open, non-draft, mergeable PRs
 * - fix candidates: open PRs that are draft or not mergeable
 * - delete candidates: local branches that are fully merged into main and not attached to a worktree
 * - worktree path violations: non-root branch-attached worktrees not under .worktree/workspaces/<branch-name>
 *
 * Usage:
 *   node scripts/branch-governance.mjs [--json]
 */

import { execFileSync } from "child_process";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
import {
  canonicalWorktreePath,
  describeBranchWorktreePath,
  parseWorktreePorcelain,
} from "./worktree-policy.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "..");

const defaultRun = (cmd, args, opts = {}) => {
  try {
    return execFileSync(cmd, args, {
      cwd: projectRoot,
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "pipe"],
      timeout: 10000,
      ...opts,
    }).trim();
  } catch (error) {
    return "";
  }
};

const splitLines = (text) => text.split(/\r?\n/);

export function buildScan({ run = defaultRun, now = () => new Date() } = {}) {
  const getGitRoot = run("git", ["rev-parse", "--show-toplevel"]);
  const hasGh = !!run("gh", ["--version"]);
  const timestamp = now().toISOString();

  const worktreeState = getGitRoot
    ? parseWorktreePorcelain(run("git", ["worktree", "list", "--porcelain"]))
    : { branchToPath: new Map() };

  const openPrs = hasGh
    ? JSON.parse(
        run("gh", [
          "pr",
          "list",
          "--state",
          "open",
          "--limit",
          "100",
          "--json",
          "number,title,headRefName,baseRefName,mergeable,isDraft,url,updatedAt,author",
        ]) || "[]",
      )
    : [];

  const branchNames = splitLines(
    run("git", ["for-each-ref", "--format=%(refname:short)", "refs/heads"]),
  )
    .map((name) => name.trim())
    .filter((name) => Boolean(name) && name !== "main");

  const openPrByHead = new Map(openPrs.map((pr) => [pr.headRefName, pr]));

  const mergeCandidates = [];
  const fixCandidates = [];
  const closeCandidates = [];
  const deleteCandidates = [];
  const unpublishedBranches = [];
  const worktreePathViolations = [];
  const branchInventory = [];

  for (const branch of branchNames) {
    const branchTracked = worktreeState.branchToPath.has(branch);
    const branchPath = worktreeState.branchToPath.get(branch) || null;
    const worktreePathStatus = branchTracked
      ? describeBranchWorktreePath({ root: getGitRoot, branchName: branch, actualPath: branchPath })
      : { expectedPath: getGitRoot ? canonicalWorktreePath(getGitRoot, branch) : null, isRootCheckout: false, compliant: null };
    const { expectedPath: expectedWorktreePath, isRootCheckout, compliant: worktreePathCompliant } = worktreePathStatus;
    const upstreamCount = run("git", ["rev-list", "--left-right", "--count", `main...${branch}`]);
    const [aheadMain, aheadBranch] = upstreamCount
      ? upstreamCount.split(/\s+/).map((n) => Number(n) || 0)
      : [0, 0];
    const isMergedIntoMain = aheadBranch === 0;
    const pr = openPrByHead.get(branch) || null;

    const branchEntry = {
      branch,
      aheadMain,
      aheadBranch,
      mergedIntoMain: isMergedIntoMain,
      worktreePath: branchPath,
      expectedWorktreePath,
      rootCheckout: isRootCheckout,
      worktreePathCompliant,
      hasOpenPr: !!pr,
      prNumber: pr ? pr.number : null,
      prDraft: pr ? !!pr.isDraft : null,
      prMergeable: pr ? pr.mergeable : null,
    };
    branchInventory.push(branchEntry);

    if (branchTracked && !isRootCheckout && branchPath !== expectedWorktreePath) {
      worktreePathViolations.push({
        branch,
        actualPath: branchPath,
        expectedPath: expectedWorktreePath,
        reason: "branch-attached worktree path is not canonical",
      });
    }

    if (isMergedIntoMain && !branchTracked) {
      deleteCandidates.push({
        branch,
        reason: "fully merged into main and not attached to a worktree",
      });
    }

    if (!pr) {
      if (!isMergedIntoMain && aheadBranch > 0) {
        unpublishedBranches.push({
          branch,
          reason: "local branch has outstanding commits but no open PR",
        });
      }
      continue;
    }

    if (!pr.isDraft && pr.mergeable === "MERGEABLE") {
      mergeCandidates.push({
        number: pr.number,
        branch,
        title: pr.title,
        url: pr.url,
      });
    } else {
      const reason = pr.isDraft
        ? "draft PR"
        : `mergeable=${pr.mergeable || "UNKNOWN"}`;
      fixCandidates.push({
        number: pr.number,
        branch,
        title: pr.title,
        url: pr.url,
        reason,
      });
    }
  }

  // Open PRs whose branch no longer exists locally are usually close/follow-up candidates.
  for (const pr of openPrs) {
    if (branchNames.includes(pr.headRefName)) continue;
    closeCandidates.push({
      number: pr.number,
      branch: pr.headRefName,
      title: pr.title,
      url: pr.url,
      reason: "open PR head branch is not present locally",
    });
  }

  const mainSyncCounts = run("git", ["rev-list", "--left-right", "--count", "origin/main...main"]);
  const [originAheadMain, mainAheadOrigin] = mainSyncCounts
    ? mainSyncCounts.split(/\s+/).map((n) => Number(n) || 0)
    : [0, 0];
  const repoStatus = run("git", ["status", "--short"]);

  return {
    scanId: `branch-governance-${new Date(timestamp).getTime()}`,
    timestamp,
    context: {
      gitRoot: getGitRoot || "n/a",
      currentBranch: run("git", ["rev-parse", "--abbrev-ref", "HEAD"]) || "n/a",
      mainSynced: originAheadMain === 0 && mainAheadOrigin === 0,
      mainSyncCounts: {
        originAheadMain,
        mainAheadOrigin,
      },
      repoClean: repoStatus.length === 0,
      dirtyEntries: repoStatus ? splitLines(repoStatus).filter(Boolean).length : 0,
      ghAvailable: hasGh,
    },
    summary: {
      openPrs: openPrs.length,
      mergeCandidates: mergeCandidates.length,
      fixCandidates: fixCandidates.length,
      deleteCandidates: deleteCandidates.length,
      closeCandidates: closeCandidates.length,
      unpublishedBranches: unpublishedBranches.length,
      branchesScanned: branchInventory.length,
      worktreePathViolations: worktreePathViolations.length,
    },
    mergeCandidates,
    fixCandidates,
    deleteCandidates,
    closeCandidates,
    unpublishedBranches,
    worktreePathViolations,
    branchInventory,
    openPrs,
  };
}

export function formatHumanReport(result) {
  const lines = [];
  lines.push(`\n=== Branch Governance Scan: ${result.scanId} ===`);
  lines.push(`  Branch: ${result.context.currentBranch}`);
  lines.push(`  Open PRs: ${result.summary.openPrs}`);
  lines.push(`  Merge candidates: ${result.summary.mergeCandidates}`);
  lines.push(`  Fix candidates: ${result.summary.fixCandidates}`);
  lines.push(`  Delete candidates: ${result.summary.deleteCandidates}`);
  lines.push(`  Close candidates: ${result.summary.closeCandidates}`);
  lines.push(`  Unpublished branches: ${result.summary.unpublishedBranches}`);
  lines.push(`  Worktree path violations: ${result.summary.worktreePathViolations}`);
  lines.push("");
  for (const item of result.worktreePathViolations) {
    lines.push(`[WORKTREE] ${item.branch} — actual ${item.actualPath} (expected ${item.expectedPath})`);
  }
  for (const item of result.mergeCandidates) {
    lines.push(`[MERGE] #${item.number} ${item.branch} — ${item.title}`);
    lines.push(`        ${item.url}`);
  }
  for (const item of result.fixCandidates) {
    lines.push(`[FIX]   #${item.number} ${item.branch} — ${item.title} (${item.reason})`);
    lines.push(`        ${item.url}`);
  }
  for (const item of result.deleteCandidates) {
    lines.push(`[DELETE] ${item.branch} — ${item.reason}`);
  }
  for (const item of result.closeCandidates) {
    const label = item.number ? `#${item.number} ${item.branch}` : item.branch;
    lines.push(`[CLOSE] ${label} — ${item.reason}`);
  }
  for (const item of result.unpublishedBranches) {
    lines.push(`[PUBLISH] ${item.branch} — ${item.reason}`);
  }
  return `${lines.join("\n")}\n`;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const isJson = process.argv.includes("--json");
  const result = buildScan();
  if (isJson) {
    process.stdout.write(JSON.stringify(result, null, 2));
  } else {
    process.stdout.write(formatHumanReport(result));
  }
}
