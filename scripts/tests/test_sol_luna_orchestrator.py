"""TDD contract tests for ``scripts/sol_luna_orchestrator.py``.

The implementation is intentionally not imported through a fallback or a
skip: while the implementation is absent, collection must fail with the
missing module path rather than silently turning this contract green.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
from types import SimpleNamespace
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts" / "sol_luna_orchestrator.py"


def _load_orchestrator():
    spec = importlib.util.spec_from_file_location("sol_luna_orchestrator", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise AssertionError(f"cannot load orchestrator module from {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


orchestrator = _load_orchestrator()


def _error_types():
    custom_error = getattr(orchestrator, "OrchestrationError", None)
    if isinstance(custom_error, type) and issubclass(custom_error, BaseException):
        return (ValueError, custom_error)
    return (ValueError,)


def _catalog():
    return {
        "models": [
            {
                "slug": orchestrator.SOL_MODEL,
                "supported_reasoning_efforts": ["high", "xhigh"],
            },
            {
                "slug": orchestrator.LUNA_MODEL,
                "supported_reasoning_efforts": ["high", "xhigh"],
            },
        ]
    }


def _plan(task_count: int, workers: int | None = None) -> dict:
    return {
        "tasks": [
            {
                "id": f"task-{index}",
                "scope": f"src/task-{index}.py",
            }
            for index in range(task_count)
        ],
        "workers": workers if workers is not None else task_count,
        "max_retries": 1,
    }


def _batch_results(plan: dict) -> list[dict]:
    return [
        {
            "task_id": task["id"],
            "status": "passed",
            "mechanical_check": "passed",
            "evidence": [f"evidence for {task['id']}"],
            "uncertainties": [],
            "conflicts": [],
            "scope_violation": False,
            "changed_files": [task["scope"]],
            "retry_count": 0,
        }
        for task in plan["tasks"]
    ]


def _decision(evaluation):
    """Read both permitted result shapes without weakening the decision check."""
    if hasattr(evaluation, "decision"):
        return evaluation.decision
    return evaluation["decision"]


def test_public_constants_define_the_sol_luna_contract():
    assert orchestrator.SOL_MODEL == "gpt-5.6-sol"
    assert orchestrator.LUNA_MODEL == "gpt-5.6-luna"
    assert orchestrator.REASONING_EFFORT == "xhigh"
    assert orchestrator.MIN_EXECUTORS == 3
    assert orchestrator.MAX_EXECUTORS == 5


def test_model_supports_sol_and_luna_at_xhigh_but_not_luna_at_ultra():
    catalog = _catalog()

    assert orchestrator.model_supports(catalog, orchestrator.SOL_MODEL, "xhigh") is True
    assert orchestrator.model_supports(catalog, orchestrator.LUNA_MODEL, "xhigh") is True
    assert orchestrator.model_supports(catalog, orchestrator.LUNA_MODEL, "ultra") is False


@pytest.mark.parametrize("model", [orchestrator.SOL_MODEL, orchestrator.LUNA_MODEL])
def test_build_codex_command_uses_model_and_xhigh_as_argv_tokens(model):
    prompt = "/tmp/prompt with spaces.md"

    command = orchestrator.build_codex_command(
        model=model,
        effort=orchestrator.REASONING_EFFORT,
        workspace="/workspace/project",
        prompt_file_or_dash=prompt,
        sandbox="read-only",
    )

    assert isinstance(command, list)
    assert all(isinstance(token, str) for token in command)
    assert command.count("-m") == 1
    assert command[command.index("-m") + 1] == model
    assert command[:4] == ["codex", "-a", "never", "exec"]
    assert "--ephemeral" in command
    assert command.count("-c") == 1
    assert command[command.index("-c") + 1] == 'model_reasoning_effort="xhigh"'
    assert command[command.index("--sandbox") + 1] == "read-only"
    assert command[-1] == prompt
    assert not any(token.startswith("'") or token.startswith('"') for token in command)


@pytest.mark.parametrize(
    "invalid_path",
    [
        "",
        "/tmp/project/file.py",
        "../outside.py",
        "src/../outside.py",
        " src/file.py",
        "src/file.py ",
        "src\\file.py",
    ],
)
def test_normalize_scope_rejects_empty_absolute_and_parent_paths(invalid_path):
    with pytest.raises(_error_types()):
        orchestrator.normalize_scope(invalid_path)


def test_normalize_scope_preserves_directory_prefix_and_normalizes_file_scope():
    assert orchestrator.normalize_scope("src/task.py") == "src/task.py"
    assert orchestrator.normalize_scope("src/") == "src/"


@pytest.mark.parametrize(
    ("path", "scopes", "expected"),
    [
        ("src/task.py", ["src/task.py"], True),
        ("src/task.py.bak", ["src/task.py"], False),
        ("src/lib/task.py", ["src/"], True),
        ("src/task.py", ["src/*.py"], False),
        ("src/task.txt", ["src/*.py"], False),
        ("src-extra/task.py", ["src/"], False),
        ("docs/README.md", ["src/", "docs/README.md"], True),
    ],
)
def test_path_in_scope_distinguishes_exact_files_directory_prefixes_and_similar_prefixes(
    path, scopes, expected
):
    assert orchestrator.path_in_scope(path, scopes) is expected


@pytest.mark.parametrize(
    ("left", "right", "expected"),
    [
        ("src/task.py", "src/task.py", True),
        ("src/task.py", "src/", True),
        ("src/", "src/lib/", True),
        ("src/", "src-extra/", False),
        ("src/task.py", "src/task.py.bak", False),
        ("src/*.py", "src/task.py", False),
        ("src/*.py", "docs/*.py", False),
    ],
)
def test_scopes_overlap_uses_path_boundaries(left, right, expected):
    assert orchestrator.scopes_overlap(left, right) is expected


@pytest.mark.parametrize(
    "argv",
    [
        ["git", "diff", "--check"],
        ["git", "diff", "--check", "--", "src/task.py"],
        ["git", "diff", "--name-only", "--", "src/task.py"],
        ["git", "diff", "--stat", "--"],
        ["git", "diff", "--exit-code"],
        ["git", "diff", "--quiet", "--cached"],
        ["git", "diff", "--no-ext-diff"],
        ["git", "status", "--short"],
        ["git", "status", "-s"],
        ["git", "status", "--porcelain"],
        ["git", "status", "--porcelain=v1"],
        ["git", "status", "--porcelain=v2"],
        ["git", "status", "--branch"],
        ["git", "status", "-b"],
        ["git", "status", "--untracked-files=all"],
        ["git", "status", "--untracked-files=normal"],
        ["git", "status", "--untracked-files=no"],
        ["git", "status", "--porcelain=v1", "--untracked-files=all", "--", "src/"],
        ["python", "-m", "pytest", "-q"],
        ["pytest", "-q", "tests"],
        ["go", "test", "./..."],
    ],
)
def test_is_safe_check_allows_only_explicit_read_only_checks(argv):
    assert orchestrator.is_safe_check(argv) is True


@pytest.mark.parametrize(
    "argv",
    [
        ["git", "diff", "--check; touch /tmp/pwned"],
        ["git", "diff", "--check|cat"],
        ["git", "diff", "--check&&cat"],
        ["git", "diff", "$(id)"],
        ["git", "diff", "`id`"],
        ["git", "reset", "--hard"],
        ["git", "clean", "-fd"],
        ["git", "push"],
        ["git", "diff", "--output", "owned.txt"],
        ["git", "diff", "--output=owned.txt"],
        ["git", "diff", "--ext-diff"],
        ["git", "diff", "--textconv"],
        ["git", "diff", "--unknown-flag"],
        ["git", "status", "--unknown-flag"],
        ["git", "status", "--porcelain=v3"],
        ["git", "status", "--untracked-files=maybe"],
        ["echo", "not-an-allowlisted-check"],
        ["python", "arbitrary_script.py"],
        ["python3", "arbitrary_script.py"],
        ["python", "-c", "print('arbitrary code')"],
        ["pytest", "-p", "plugin"],
        ["pytest", "-pplugin"],
        ["pytest", "-p=plugin"],
        ["python3", "-m", "pytest", "-p", "plugin"],
        ["python3", "-m", "pytest", "-pplugin"],
        ["python3", "-m", "pytest", "-p=plugin"],
        ["go", "test", "-exec", "sh -c"],
        ["go", "test", "-execsh"],
        ["go", "test", "-exec=/bin/sh"],
        ["go", "test", "-toolexec=./evil"],
        ["go", "vet", "-vettool=./evil"],
        ["go", "test", "--exec=./evil"],
        ["go", "test", "--toolexec=./evil"],
        ["go", "vet", "--vettool=./evil"],
        ["node", "--test", "--test-reporter=./evil.mjs"],
        ["node", "--test", "--import=./evil.mjs"],
        ["node", "--test", "--test-global-setup=./evil.mjs"],
        ["pytest", "-o", "addopts=-p evil"],
        ["python3", "-m", "pytest", "--override-ini=addopts=-p evil"],
        ["pytest", "--rootdir=/tmp/project"],
        ["go", "test", "-modfile=build=/tmp/go.mod"],
    ],
)
def test_is_safe_check_rejects_shell_injection_mutation_git_writes_and_scripts(argv):
    assert orchestrator.is_safe_check(argv) is False


def test_snapshot_runs_checks_before_final_status_and_patch_and_tracks_scope_violation(
    tmp_path, monkeypatch
):
    events = []
    out_of_scope = "generated/check-output.txt"

    def fake_run(_worktree, argv, **kwargs):
        events.append("check")
        assert kwargs["timeout"] == orchestrator.DEFAULT_CHEAP_CHECK_TIMEOUT
        output = tmp_path / out_of_scope
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text("created by check\n", encoding="utf-8")
        return subprocess.CompletedProcess(argv, 0, stdout="ok", stderr="")

    def fake_status(_worktree):
        events.append("status")
        return [out_of_scope], f" M {out_of_scope}\0", out_of_scope

    def fake_capture(_worktree, patch_path):
        events.append("capture")
        patch_path.write_text(f"diff --git a/{out_of_scope} b/{out_of_scope}\n", encoding="utf-8")
        return [out_of_scope], f" M {out_of_scope}\0", ""

    monkeypatch.setattr(orchestrator, "_run_cheap_check", fake_run)
    monkeypatch.setattr(orchestrator, "_status_paths", fake_status)
    monkeypatch.setattr(orchestrator, "_capture_patch", fake_capture)

    snapshot = orchestrator._snapshot_and_checks(
        tmp_path,
        [["python3", "-m", "pytest"]],
        tmp_path / "attempt.patch",
        tmp_path / "checks.json",
    )

    assert events == ["check", "status", "capture"]
    assert snapshot["changed_files"] == [out_of_scope]
    assert out_of_scope in (tmp_path / "attempt.patch").read_text(encoding="utf-8")
    assert orchestrator.path_in_scope(out_of_scope, ["src/"]) is False
    assert snapshot["check_results"][0]["returncode"] == 0


@pytest.mark.parametrize(
    "scope",
    [
        ".",
        "docs/governance",
        "docs/governance/scoring",
        "docs/governance/scoring/*",
        "docs/**",
        ".claude/agents/",
        ".codex/skills/spec-code-pipeline/",
        ".omx/state/outer-metrics/**",
        "CONSTITUTION.md",
        ".git",
        ".git/config",
        "nested/.git/config",
        "docs/governance/scoring/RUBRIC-*.md",
        "src/*.py",
        "scripts/**",
    ],
)
def test_validate_plan_rejects_protected_paths_ancestors_and_wildcards(scope):
    plan = _plan(3, 3)
    plan["tasks"][0]["scope"] = scope

    with pytest.raises(_error_types()):
        orchestrator.validate_plan(plan, 3)


def test_resolved_write_scope_rejects_symlink_alias_to_git_metadata(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    (tmp_path / "tracked.txt").write_text("tracked\n", encoding="utf-8")
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )
    (tmp_path / "gitmeta").symlink_to(".git", target_is_directory=True)
    plan = _plan(3, 3)
    plan["tasks"][0]["scope"] = "gitmeta"
    normalized = orchestrator.validate_plan(plan, 3)

    with pytest.raises(_error_types()):
        orchestrator._validate_plan_scope_targets(tmp_path, normalized)


def test_run_rejects_empty_global_checks_and_missing_traceability(tmp_path):
    args = _orchestration_args(tmp_path)
    args.check = []
    with pytest.raises(_error_types()):
        orchestrator._run_orchestration(args)


@pytest.mark.parametrize(
    ("spec_ref", "matrix_edges"),
    [
        ("/etc/passwd", ["M-001"]),
        ("../SPEC.md", ["M-001"]),
        ("SPEC.md", ["not-an-edge"]),
        ("SPEC.md", ["FR-002"]),
    ],
)
def test_traceability_fields_reject_unsafe_spec_refs_and_non_matrix_ids(
    spec_ref, matrix_edges
):
    with pytest.raises(_error_types()):
        orchestrator._traceability_fields(spec_ref, matrix_edges)


def test_spec_reference_must_resolve_to_a_file_inside_workspace(tmp_path):
    spec = tmp_path / "module" / "demo" / "spec" / "SPEC.md"
    spec.parent.mkdir(parents=True)
    spec.write_text("# Spec\n\nFR-001\n", encoding="utf-8")

    assert orchestrator._validate_spec_reference(
        tmp_path, "module/demo/spec/SPEC.md"
    ) == "module/demo/spec/SPEC.md"
    with pytest.raises(_error_types()):
        orchestrator._validate_spec_reference(tmp_path, "missing/SPEC.md")
    with pytest.raises(_error_types()):
        orchestrator._validate_spec_reference(tmp_path, "/etc/passwd")

    args = _orchestration_args(tmp_path)
    args.spec_ref = ""
    with pytest.raises(_error_types()):
        orchestrator._run_orchestration(args)


def test_matrix_edges_must_exist_in_canonical_matrix_for_spec(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    spec_ref = "module/demo/spec/SPEC.md"
    matrix_ref = "module/demo/matrix/TRACEABILITY.md"
    spec = tmp_path / spec_ref
    matrix = tmp_path / matrix_ref
    spec.parent.mkdir(parents=True)
    matrix.parent.mkdir(parents=True)
    spec.write_text("# Spec\n\n- FR-001\n", encoding="utf-8")
    matrix.write_text(
        "| Edge ID | FR |\n|---|---|\n| M-001 | FR-001 |\n\n"
        "```markdown\n| M-GHOST | FR-404 |\n```\n",
        encoding="utf-8",
    )
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )

    assert orchestrator._validate_traceability_references(
        tmp_path, spec_ref, matrix_ref, ["M-001"]
    ) == (spec_ref, matrix_ref, ["M-001"])
    with pytest.raises(_error_types()):
        orchestrator._validate_traceability_references(
            tmp_path, spec_ref, matrix_ref, ["M-999"]
        )
    with pytest.raises(_error_types()):
        orchestrator._validate_traceability_references(
            tmp_path, spec_ref, matrix_ref, ["M-GHOST"]
        )

    unrelated = tmp_path / "unrelated" / "matrix" / "TRACEABILITY.md"
    unrelated.parent.mkdir(parents=True)
    unrelated.write_text("| M-001 | FR-001 |\n", encoding="utf-8")
    with pytest.raises(_error_types()):
        orchestrator._validate_traceability_references(
            tmp_path,
            spec_ref,
            "unrelated/matrix/TRACEABILITY.md",
            ["M-001"],
        )


def test_traceability_refs_must_be_tracked_in_current_head(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    (tmp_path / ".gitignore").write_text("ignored/\n", encoding="utf-8")
    subprocess.run(["git", "add", ".gitignore"], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )
    spec_ref = "ignored/SPEC.md"
    matrix_ref = "ignored/matrix/TRACEABILITY.md"
    spec = tmp_path / spec_ref
    matrix = tmp_path / matrix_ref
    spec.parent.mkdir()
    matrix.parent.mkdir()
    spec.write_text("FR-001\n", encoding="utf-8")
    matrix.write_text(
        "| Edge ID | FR |\n|---|---|\n| M-EPHEMERAL | FR-001 |\n",
        encoding="utf-8",
    )

    with pytest.raises(_error_types()):
        orchestrator._validate_traceability_references(
            tmp_path, spec_ref, matrix_ref, ["M-EPHEMERAL"]
        )

    args = _orchestration_args(tmp_path)
    args.matrix_edge = []
    with pytest.raises(_error_types()):
        orchestrator._run_orchestration(args)


def test_prompt_families_carry_spec_ref_and_matrix_edges(tmp_path, monkeypatch):
    spec_ref = "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md"
    matrix_ref = "docs/governance/improvements/20260710-sol_luna_orchestration/matrix/TRACEABILITY.md"
    edges = ["M-001", "M-002"]
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }

    task_prompt = orchestrator._task_prompt("请求", task, 1, spec_ref, edges)
    integration_prompt = orchestrator._integration_prompt(
        "请求", [task], task["checks"], spec_ref, edges, None, 1
    )
    assert spec_ref in task_prompt and spec_ref in integration_prompt
    assert matrix_ref in task_prompt and matrix_ref in integration_prompt
    for edge in edges:
        assert edge in task_prompt and edge in integration_prompt

    seen = {}

    def fake_call(*args, **kwargs):
        seen["prompt"] = args[1]
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), ""

    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: set())
    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)
    orchestrator._sol_escalation(
        "证据缺失",
        {},
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        spec_ref,
        edges,
    )
    assert spec_ref in seen["prompt"]
    assert matrix_ref in seen["prompt"]
    assert all(edge in seen["prompt"] for edge in edges)


@pytest.mark.parametrize(
    ("task_count", "requested_workers"),
    [(3, 3), (5, 5)],
)
def test_validate_plan_accepts_executor_boundaries(task_count, requested_workers):
    orchestrator.validate_plan(_plan(task_count, requested_workers), requested_workers)


@pytest.mark.parametrize("requested_workers", [2, 6])
def test_validate_plan_rejects_workers_outside_executor_bounds(requested_workers):
    with pytest.raises(_error_types()):
        orchestrator.validate_plan(_plan(3, requested_workers), requested_workers)


def test_validate_plan_rejects_duplicate_task_ids():
    plan = _plan(3, 3)
    plan["tasks"][1]["id"] = plan["tasks"][0]["id"]

    with pytest.raises(_error_types()):
        orchestrator.validate_plan(plan, 3)


def test_validate_plan_rejects_overlapping_task_scopes():
    plan = _plan(3, 3)
    plan["tasks"][0]["scope"] = "src/"
    plan["tasks"][1]["scope"] = "src/task-1.py"

    with pytest.raises(_error_types()):
        orchestrator.validate_plan(plan, 3)


@pytest.mark.parametrize("scope", ["/etc/passwd", "src/../outside.py"])
def test_validate_plan_rejects_unsafe_task_scopes(scope):
    plan = _plan(3, 3)
    plan["tasks"][0]["scope"] = scope

    with pytest.raises(_error_types()):
        orchestrator.validate_plan(plan, 3)


def test_evaluate_batch_accepts_when_every_task_passes_with_evidence():
    plan = _plan(3, 3)
    results = _batch_results(plan)

    assert _decision(orchestrator.evaluate_batch(plan, results)) == "accept"


def test_evaluate_batch_retries_luna_for_a_mechanical_check_failure():
    plan = _plan(3, 3)
    results = _batch_results(plan)
    results[0]["mechanical_check"] = "failed"

    assert _decision(orchestrator.evaluate_batch(plan, results)) == "retry_luna"


@pytest.mark.parametrize(
    "mutation",
    [
        pytest.param(lambda result: result.update(evidence=[]), id="missing-evidence"),
        pytest.param(lambda result: result.update(evidence="not_run"), id="evidence-not-run"),
        pytest.param(lambda result: result.update(uncertainties=["unresolved assumption"]), id="uncertainty"),
        pytest.param(lambda result: result.update(conflicts=["task result conflict"]), id="conflict"),
        pytest.param(lambda result: result.update(scope_violation=True), id="scope-violation"),
        pytest.param(
            lambda result: result.update(changed_files=["src/shared.py"]),
            id="overlapping-actual-changed-files",
        ),
    ],
)
def test_evaluate_batch_escalates_for_incomplete_or_conflicting_evidence(mutation):
    plan = _plan(3, 3)
    results = _batch_results(plan)
    mutation(results[0])
    if results[0]["changed_files"] == ["src/shared.py"]:
        results[1]["changed_files"] = ["src/shared.py"]

    assert _decision(orchestrator.evaluate_batch(plan, results)) == "escalate_sol"


def test_evaluate_batch_escalates_when_luna_retry_budget_is_exhausted():
    plan = _plan(3, 3)
    results = _batch_results(plan)
    results[0]["mechanical_check"] = "failed"
    results[0]["retry_count"] = plan["max_retries"]

    assert _decision(orchestrator.evaluate_batch(plan, results)) == "escalate_sol"


def test_probe_cli_fails_closed_before_subprocess_when_fake_catalog_lacks_xhigh(tmp_path, monkeypatch):
    """A catalog probe must reject unsupported required models before any model call."""
    catalog_path = tmp_path / "catalog.json"
    catalog_path.write_text(
        json.dumps(
            {
                "models": [
                    {"slug": orchestrator.SOL_MODEL, "supported_reasoning_efforts": ["high"]},
                    {"slug": orchestrator.LUNA_MODEL, "supported_reasoning_efforts": ["ultra"]},
                ]
            }
        ),
        encoding="utf-8",
    )

    calls = []

    def forbidden_subprocess(*args, **kwargs):
        calls.append((args, kwargs))
        raise AssertionError("model subprocess must not run after a failed catalog probe")

    monkeypatch.setattr(subprocess, "run", forbidden_subprocess)
    monkeypatch.setattr(
        sys,
        "argv",
        ["sol_luna_orchestrator.py", "probe", "--catalog", str(catalog_path)],
    )

    try:
        return_code = orchestrator.main()
    except SystemExit as exc:
        return_code = exc.code

    assert return_code not in (None, 0)
    assert calls == []


def test_primary_worktree_root_is_the_first_registered_worktree(tmp_path, monkeypatch):
    primary = tmp_path / "primary"
    nested = primary / ".worktree" / "workspaces" / "feat" / "current"
    primary.mkdir(parents=True)
    nested.mkdir(parents=True)

    def fake_run(argv, **kwargs):
        assert argv == ["git", "worktree", "list", "--porcelain"]
        return subprocess.CompletedProcess(
            argv,
            0,
            stdout=(
                f"worktree {primary}\nHEAD abc\nbranch refs/heads/main\n\n"
                f"worktree {nested}\nHEAD def\nbranch refs/heads/feat/current\n"
            ),
            stderr="",
        )

    monkeypatch.setattr(orchestrator, "_run", fake_run)

    assert orchestrator._primary_worktree_root(nested) == primary.resolve()
    assert orchestrator._runtime_worktree_path(primary, "run-1", "task-1") == (
        primary / ".worktree" / "workspaces" / "runtime" / "sol_luna" / "run-1" / "task-1"
    )


def test_run_converts_timeout_to_returncode_124_and_keeps_stderr(monkeypatch, tmp_path):
    def timed_out(*args, **kwargs):
        assert kwargs["timeout"] == orchestrator.DEFAULT_GIT_TIMEOUT
        raise subprocess.TimeoutExpired(
            kwargs.get("args", args[0] if args else ["git"]),
            kwargs["timeout"],
            output="partial stdout",
            stderr="partial stderr",
        )

    monkeypatch.setattr(subprocess, "run", timed_out)

    result = orchestrator._run(["git", "status"], cwd=tmp_path)

    assert result.returncode == 124
    assert "partial stdout" in result.stdout
    assert "partial stderr" in result.stderr
    assert "timed out" in result.stderr.lower()


def test_status_paths_fails_closed_on_git_status_failure(monkeypatch, tmp_path):
    def failed_run(argv, **kwargs):
        return subprocess.CompletedProcess(argv, 1, stdout="", stderr="git failed")

    monkeypatch.setattr(orchestrator, "_run", failed_run)
    with pytest.raises(_error_types()):
        orchestrator._status_paths(tmp_path)


def test_status_paths_reports_both_rename_source_and_target(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    source = tmp_path / ".claude" / "agents" / "executor.toml"
    source.parent.mkdir(parents=True)
    source.write_text("model = 'unsafe'\n", encoding="utf-8")
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )
    target = tmp_path / "safe" / "executor.toml"
    target.parent.mkdir()
    subprocess.run(
        ["git", "mv", ".claude/agents/executor.toml", "safe/executor.toml"],
        cwd=tmp_path,
        check=True,
    )

    changed, _, _ = orchestrator._status_paths(tmp_path)

    assert changed == [".claude/agents/executor.toml", "safe/executor.toml"]


def test_status_and_ignored_parsers_handle_rename_with_worktree_modification(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    (tmp_path / ".gitignore").write_text("*.secret\n", encoding="utf-8")
    source = tmp_path / "safe" / "source.txt"
    source.parent.mkdir()
    source.write_text("before\n", encoding="utf-8")
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )
    subprocess.run(
        ["git", "mv", "safe/source.txt", "safe/target.txt"],
        cwd=tmp_path,
        check=True,
    )
    (tmp_path / "safe" / "target.txt").write_text("after\n", encoding="utf-8")
    (tmp_path / "ignored.secret").write_text("ignored\n", encoding="utf-8")

    changed, status_raw, _ = orchestrator._status_paths(tmp_path)

    assert "RM safe/target.txt\0safe/source.txt\0" in status_raw
    assert changed == ["safe/source.txt", "safe/target.txt"]
    assert orchestrator._ignored_paths(tmp_path) == {"ignored.secret"}


def test_posix_git_paths_with_backslashes_cannot_alias_scoped_paths(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    safe = tmp_path / "src" / "file.txt"
    alias = tmp_path / "src\\file.txt"
    safe.parent.mkdir()
    safe.write_text("before\n", encoding="utf-8")
    alias.write_text("before\n", encoding="utf-8")
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )
    safe.write_text("after\n", encoding="utf-8")
    alias.write_text("after\n", encoding="utf-8")

    changed, _, _ = orchestrator._status_paths(tmp_path)

    assert changed == ["src/file.txt", "src\\file.txt"]
    assert orchestrator.path_in_scope("src/file.txt", ["src/"]) is True
    with pytest.raises(_error_types()):
        orchestrator.path_in_scope("src\\file.txt", ["src/"])


def test_capture_patch_does_not_treat_rename_source_as_untracked_status(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    source = tmp_path / "?? decoy"
    source.write_text("before\n", encoding="utf-8")
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )
    subprocess.run(["git", "mv", "?? decoy", "renamed.txt"], cwd=tmp_path, check=True)
    (tmp_path / "renamed.txt").write_text("after\n", encoding="utf-8")
    patch = tmp_path / "rename.patch"

    changed, _, error = orchestrator._capture_patch(tmp_path, patch)

    assert error == ""
    assert changed == ["?? decoy", "renamed.txt"]
    assert "renamed.txt" in patch.read_text(encoding="utf-8")


def test_cheap_check_sandbox_blocks_host_git_metadata_and_secret_env(tmp_path, monkeypatch):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    tracked = tmp_path / "tracked.txt"
    tracked.write_text("tracked\n", encoding="utf-8")
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )
    outside = tmp_path.parent / f"{tmp_path.name}-escape.txt"
    git_config = tmp_path / ".git" / "config"
    config_before = git_config.read_bytes()
    monkeypatch.setenv("OPENAI_API_KEY", "test-only-secret")
    program = f"""
import json
import os
import resource
import sys
from pathlib import Path

blocked = []
for target in (Path('inside.txt'), Path({str(outside)!r}), Path('.git/config')):
    try:
        target.write_text('escape\\n')
    except OSError:
        blocked.append(str(target))
print(json.dumps({{
    'blocked': blocked,
    'secret_visible': 'OPENAI_API_KEY' in os.environ,
    'stdin': sys.stdin.read(),
    'host_secret_visible': Path('/opt/binance/secrets/prod.env').exists(),
    'host_socket_visible': Path('/run/docker.sock').exists(),
    'rlimit_as': resource.getrlimit(resource.RLIMIT_AS)[0],
    'rlimit_fsize': resource.getrlimit(resource.RLIMIT_FSIZE)[0],
    'rlimit_nproc': resource.getrlimit(resource.RLIMIT_NPROC)[0],
}}))
"""

    process = orchestrator._run_cheap_check(
        tmp_path, ["python3", "-c", program]
    )

    assert process.returncode == 0, process.stderr
    assert (tmp_path / "inside.txt").exists() is False
    assert outside.exists() is False
    assert git_config.read_bytes() == config_before
    sandbox_result = json.loads(process.stdout)
    assert "inside.txt" in sandbox_result["blocked"]
    assert ".git/config" in sandbox_result["blocked"]
    assert sandbox_result["secret_visible"] is False
    assert sandbox_result["stdin"] == ""
    assert sandbox_result["host_secret_visible"] is False
    assert sandbox_result["host_socket_visible"] is False
    assert sandbox_result["rlimit_as"] == 4_294_967_296
    assert sandbox_result["rlimit_fsize"] == 16_777_216
    assert sandbox_result["rlimit_nproc"] == 2_048

    large_output = orchestrator._run_cheap_check(
        tmp_path,
        [
            "python3",
            "-c",
            f"import sys; sys.stdout.write('x' * {orchestrator.MAX_CHEAP_CHECK_OUTPUT_BYTES + 1024})",
        ],
    )
    assert large_output.returncode == 0
    assert "cheap check 输出已截断" in large_output.stdout
    assert len(large_output.stdout) < orchestrator.MAX_CHEAP_CHECK_OUTPUT_BYTES + 200


def _guarded_ignored_result(monkeypatch, workspace, run_dir, ignored_after):
    snapshots = iter([set(), set(ignored_after)])
    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: next(snapshots))
    monkeypatch.setattr(
        orchestrator,
        "_call_codex",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            "{}",
        ),
    )
    return orchestrator._guarded_model_call(
        orchestrator.SOL_MODEL,
        "Sol plan",
        workspace,
        run_dir,
        run_dir / "model-calls.jsonl",
        "sol-plan",
        None,
        run_dir / "output-last-message",
        "read-only",
    )[2]


def test_parent_sol_run_dir_ignored_files_are_exempted(tmp_path, monkeypatch):
    workspace = tmp_path / "parent-workspace"
    run_dir = workspace / ".omx" / "state" / "orchestration" / "run-1"

    assert _guarded_ignored_result(
        monkeypatch,
        workspace,
        run_dir,
        {
            ".omx/state/orchestration/run-1/output-last-message",
            ".omx/state/orchestration/run-1/model-calls.jsonl",
        },
    ) == []
    audit_records = [
        json.loads(line)
        for line in (run_dir / "model-calls.jsonl").read_text(encoding="utf-8").splitlines()
    ]
    assert audit_records[-1]["kind"] == "ignored-audit"
    assert audit_records[-1]["checked"] is True
    assert audit_records[-1]["unexpected_ignored"] == []


def test_parent_run_dir_filter_keeps_other_ignored_files(tmp_path, monkeypatch):
    workspace = tmp_path / "parent-workspace"
    run_dir = workspace / ".omx" / "state" / "orchestration" / "run-1"

    assert _guarded_ignored_result(
        monkeypatch,
        workspace,
        run_dir,
        {
            ".omx/state/orchestration/run-1/output-last-message",
            ".omx/state/orchestration/run-2/model-calls.jsonl",
            ".cache/foreign.bin",
        },
    ) == [
        ".cache/foreign.bin",
        ".omx/state/orchestration/run-2/model-calls.jsonl",
    ]


@pytest.mark.parametrize("worktree_kind", ["task-1", "integration"])
def test_task_and_integration_worktrees_do_not_exempt_external_run_dir(
    tmp_path, monkeypatch, worktree_kind
):
    primary = tmp_path / "primary-workspace"
    workspace = primary / ".worktree" / "workspaces" / "runtime" / worktree_kind
    run_dir = primary / ".omx" / "state" / "orchestration" / "run-1"
    ignored_path = ".omx/state/orchestration/run-1/output-last-message"

    assert _guarded_ignored_result(
        monkeypatch, workspace, run_dir, {ignored_path}
    ) == [ignored_path]


def test_workspace_write_model_rejects_preexisting_ignored_baseline(
    tmp_path, monkeypatch
):
    model_calls = []
    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: {"state.cfg"})
    monkeypatch.setattr(
        orchestrator,
        "_call_codex",
        lambda *args, **kwargs: model_calls.append((args, kwargs)),
    )

    with pytest.raises(_error_types()):
        orchestrator._guarded_model_call(
            orchestrator.LUNA_MODEL,
            "task",
            tmp_path,
            tmp_path / "external-run",
            tmp_path / "calls.jsonl",
            "luna-task",
            None,
            tmp_path / "output.json",
            "workspace-write",
        )

    assert model_calls == []


def test_call_codex_extracts_token_usage_from_stderr(tmp_path, monkeypatch):
    output = tmp_path / "response.json"
    output.write_text("{}", encoding="utf-8")
    monkeypatch.setattr(
        orchestrator,
        "_run",
        lambda *args, **kwargs: subprocess.CompletedProcess(
            ["codex"], 0, stdout="", stderr="tokens used\n97,509\n"
        ),
    )
    log = tmp_path / "model-calls.jsonl"

    orchestrator._call_codex(
        orchestrator.LUNA_MODEL,
        "prompt",
        tmp_path,
        tmp_path / "run",
        log,
        "luna-test",
        output_schema=None,
        output_last_message=output,
        sandbox="read-only",
    )

    record = json.loads(log.read_text(encoding="utf-8"))
    assert record["tokens"] == 97509


@pytest.mark.parametrize(
    ("stderr", "expected"),
    [
        ("You've hit your usage limit", "usage_limit"),
        ("insufficient_quota", "usage_limit"),
        ("invalid_api_key", "authentication"),
        ("rate_limit_exceeded", "rate_limit"),
        ("model_not_found", "model_access"),
        ("unexpected process failure", "model_call_failed"),
    ],
)
def test_model_failure_class_distinguishes_external_blockers(stderr, expected):
    assert orchestrator._model_failure_class(stderr) == expected


def test_escalation_digest_keeps_failures_and_compacts_passing_tasks(tmp_path):
    passed_patch = tmp_path / "passed.patch"
    passed_patch.write_text("pass patch\n", encoding="utf-8")
    failed_patch = tmp_path / "failed.patch"
    failed_patch.write_text("failed patch\n", encoding="utf-8")
    results = [
        {
            "task_id": "task-pass",
            "status": "pass",
            "evidence_complete": True,
            "scope_ok": True,
            "checks_ok": True,
            "changed_files": ["src/pass.py"],
            "patch_file": str(passed_patch),
            "model_result": {"huge": "x" * 20_000},
        },
        {
            "task_id": "task-fail",
            "status": "evidence_conflict",
            "reason": "diff conflict",
            "evidence_complete": False,
            "scope_ok": True,
            "checks_ok": True,
            "conflict": True,
            "changed_files": ["src/fail.py"],
            "patch_file": str(failed_patch),
            "attempts": [
                {
                    "declared_changed_files": [],
                    "check_results": [{"argv": ["pytest"], "returncode": 0}],
                }
            ],
        },
    ]

    digest = orchestrator._task_escalation_digest(results)

    assert digest["counts"] == {"failed": 1, "passed": 1}
    assert digest["failed_or_conflicting_tasks"][0]["task_id"] == "task-fail"
    assert digest["passed_task_receipts"][0]["task_id"] == "task-pass"
    assert len(digest["passed_task_receipts"][0]["patch_sha256"]) == 64
    assert "huge" not in json.dumps(digest)


def test_model_usage_summary_separates_sol_luna_and_unknown_tokens(tmp_path):
    log = tmp_path / "model-calls.jsonl"
    records = [
        {"kind": "sol-plan", "model": orchestrator.SOL_MODEL, "tokens": 100},
        {"kind": "luna-task", "model": orchestrator.LUNA_MODEL, "tokens": 250},
        {"kind": "luna-task", "model": orchestrator.LUNA_MODEL, "tokens": None},
        {"kind": "ignored-audit", "checked": True},
    ]
    log.write_text(
        "\n".join(json.dumps(record) for record in records) + "\nnot-json\n",
        encoding="utf-8",
    )

    assert orchestrator._model_usage_summary(log) == {
        "calls": 3,
        "sol_calls": 1,
        "luna_calls": 2,
        "sol_tokens": 100,
        "luna_tokens": 250,
        "total_tokens": 350,
        "unknown_token_calls": 1,
        "invalid_log_records": 1,
    }


def test_run_task_passes_a_structured_output_schema_to_luna(tmp_path, monkeypatch):
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }
    seen_schema = {}

    def fake_call(*args, **kwargs):
        schema_path = kwargs["output_schema"]
        assert schema_path is not None
        seen_schema.update(json.loads(Path(schema_path).read_text(encoding="utf-8")))
        output_path = kwargs["output_last_message"]
        output_path.write_text(
            json.dumps(
                {
                    "status": "pass",
                    "summary": "完成",
                    "changed_files": [],
                }
            ),
            encoding="utf-8",
        )
        raw = json.dumps(
            {"status": "pass", "summary": "完成", "changed_files": []}
        )
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: set())
    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)
    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: set())
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: {
            "changed_files": [],
            "status_raw": "",
            "diff_names": "",
            "patch_error": "",
            "check_results": [],
            "checks_ok": True,
        },
    )

    result = orchestrator._run_task(
        "请求",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        1,
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
    )

    assert result["status"] == "pass"
    assert seen_schema["required"] == ["status", "summary", "changed_files"]
    assert seen_schema["additionalProperties"] is False
    assert set(seen_schema["properties"]) == {"status", "summary", "changed_files"}


def test_run_task_escalates_when_declared_files_conflict_with_mechanical_diff(
    tmp_path, monkeypatch
):
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            json.dumps(
                {"status": "pass", "summary": "完成", "changed_files": []}
            ),
            [],
        ),
    )
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: {
            "changed_files": ["src/task-1.py"],
            "status_raw": " M src/task-1.py",
            "diff_names": "src/task-1.py",
            "patch_error": "",
            "check_results": [{"returncode": 0}],
            "checks_ok": True,
        },
    )

    result = orchestrator._run_task(
        "请求",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        1,
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
    )

    assert result["status"] == "evidence_conflict"
    assert result["conflict"] is True
    assert result["evidence_complete"] is False
    assert result["attempts"][0]["declared_changed_files"] == []
    assert result["attempts"][0]["changed_files"] == ["src/task-1.py"]


def test_run_task_retries_explicit_luna_failure_before_passing(tmp_path, monkeypatch):
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }
    responses = iter(
        [
            {"status": "fail", "summary": "首次失败", "changed_files": []},
            {"status": "pass", "summary": "重试通过", "changed_files": []},
        ]
    )
    calls = []

    def fake_call(*args, **kwargs):
        calls.append(kwargs["output_last_message"])
        raw = json.dumps(next(responses))
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)
    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: set())
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: {
            "changed_files": [],
            "status_raw": "",
            "diff_names": "",
            "patch_error": "",
            "check_results": [],
            "checks_ok": True,
        },
    )

    result = orchestrator._run_task(
        "请求",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        2,
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
    )

    assert len(calls) == 2
    assert [attempt["model_status"] for attempt in result["attempts"]] == ["fail", "pass"]
    assert result["status"] == "pass"
    assert result.get("attempts_exhausted") is not True


def test_run_task_fails_closed_on_new_ignored_file_before_cheap_check(tmp_path, monkeypatch):
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }
    check_calls = []

    def fake_call(*args, **kwargs):
        return (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            json.dumps({"status": "pass", "summary": "完成", "changed_files": []}),
        )

    ignored = iter([set(), {".cache/model-output.bin"}])
    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: next(ignored))
    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: check_calls.append(args) or {},
    )

    result = orchestrator._run_task(
        "请求",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        1,
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
    )

    assert result["status"] != "pass"
    assert result["ignored_files"] == [".cache/model-output.bin"]
    assert check_calls == []


def test_run_task_fails_closed_when_ignored_status_detection_raises(tmp_path, monkeypatch):
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }
    model_calls = []

    def fail_status(_path):
        raise RuntimeError("status unavailable")

    monkeypatch.setattr(orchestrator, "_ignored_paths", fail_status)
    monkeypatch.setattr(orchestrator, "_call_codex", lambda *args, **kwargs: model_calls.append(args))

    result = orchestrator._run_task(
        "请求",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        1,
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
    )

    assert result["status"] != "pass"
    assert "状态" in result["reason"]
    assert model_calls == []


def test_run_task_fails_closed_when_post_model_ignored_detection_raises(tmp_path, monkeypatch):
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }
    ignored_calls = 0
    check_calls = []

    def ignored_status(_path):
        nonlocal ignored_calls
        ignored_calls += 1
        if ignored_calls == 1:
            return set()
        raise RuntimeError("post-model status unavailable")

    monkeypatch.setattr(orchestrator, "_ignored_paths", ignored_status)
    monkeypatch.setattr(
        orchestrator,
        "_call_codex",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            json.dumps({"status": "pass", "summary": "完成", "changed_files": []}),
        ),
    )
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: check_calls.append(args) or {},
    )

    result = orchestrator._run_task(
        "请求",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        1,
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
    )

    assert result["status"] != "pass"
    assert "ignored" in result["reason"]
    assert check_calls == []


def test_sol_plan_output_schema_closes_task_shape_and_requires_string_acceptance():
    schema = orchestrator._sol_plan_output_schema()
    task_schema = schema["properties"]["tasks"]["items"]

    assert schema["additionalProperties"] is False
    assert task_schema["additionalProperties"] is False
    assert task_schema["properties"]["acceptance"] == {"type": "string"}
    assert set(task_schema["properties"]) == {
        "id",
        "instructions",
        "write_scope",
        "acceptance",
        "checks",
    }


def test_sol_escalation_passes_decision_schema_to_codex(tmp_path, monkeypatch):
    seen = {}

    def fake_call(*args, **kwargs):
        schema_path = kwargs["output_schema"]
        seen.update(json.loads(Path(schema_path).read_text(encoding="utf-8")))
        kwargs["output_last_message"].parent.mkdir(parents=True, exist_ok=True)
        kwargs["output_last_message"].write_text(
            json.dumps(
                {
                    "decision": "blocked",
                    "reason": "证据不足",
                    "missing_evidence": ["检查日志"],
                }
            ),
            encoding="utf-8",
        )
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), ""

    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: set())
    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)

    result = orchestrator._sol_escalation(
        "证据缺失",
        {"missing": True},
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
    )

    assert result["returncode"] == 0
    assert set(seen["required"]) >= {"decision", "reason", "missing_evidence"}


def test_integration_repair_uses_schema_only_after_initial_checks_fail(tmp_path, monkeypatch):
    plan = {
        "tasks": [
            {"id": f"task-{index}", "write_scope": [f"src/{index}.py"]}
            for index in range(3)
        ]
    }
    task_results = [
        {"task_id": f"task-{index}", "patch_file": str(tmp_path / f"{index}.patch")}
        for index in range(3)
    ]
    checks = iter([(False, [{"returncode": 1}]), (True, [{"returncode": 0}])])
    seen = {}

    monkeypatch.setattr(orchestrator, "_create_worktree", lambda _workspace, _path: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda _workspace, _patch: (True, ""))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _path: ([], "", ""))
    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: set())
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args, **kwargs: next(checks))
    monkeypatch.setattr(
        orchestrator,
        "_capture_patch",
        lambda _worktree, patch_path: ([], "", "")
        if patch_path.name == "combined.patch"
        else ([], "", ""),
    )

    def fake_call(*args, **kwargs):
        schema = kwargs["output_schema"]
        seen.update(json.loads(Path(schema).read_text(encoding="utf-8")))
        output_path = kwargs["output_last_message"]
        output_path.parent.mkdir(parents=True, exist_ok=True)
        raw = json.dumps(
            {"status": "pass", "summary": "修复完成", "changed_files": []}
        )
        output_path.write_text(raw, encoding="utf-8")
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)

    result = orchestrator._integration_repair(
        "请求",
        plan,
        task_results,
        tmp_path / "workspace",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        [["git", "status", "--short"]],
        1,
        [],
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
        runtime_base=tmp_path / "runtime" / "run",
    )

    assert result["status"] == "pass"
    assert seen["required"] == ["status", "summary", "changed_files"]
    assert seen["additionalProperties"] is False
    assert set(seen["properties"]) == {"status", "summary", "changed_files"}


def test_integration_repair_refreshes_scope_after_checks_before_capture(tmp_path, monkeypatch):
    plan = {
        "tasks": [
            {"id": f"task-{index}", "write_scope": [f"src/{index}.py"]}
            for index in range(3)
        ]
    }
    task_results = [
        {"task_id": f"task-{index}", "patch_file": str(tmp_path / f"{index}.patch")}
        for index in range(3)
    ]
    events = []
    status_results = iter(
        [
            ([], "", ""),
            ([], "", ""),
            ([], "", ""),
            (["outside.py"], "", ""),
        ]
    )
    capture_calls = []

    monkeypatch.setattr(orchestrator, "_create_worktree", lambda _workspace, _path: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda _workspace, _patch: (True, ""))
    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: set())
    monkeypatch.setattr(
        orchestrator,
        "_status_paths",
        lambda _path: events.append("status") or next(status_results),
    )
    checks = iter([(False, [{"returncode": 1}]), (True, [{"returncode": 0}])])
    monkeypatch.setattr(
        orchestrator,
        "_run_checks",
        lambda *args, **kwargs: events.append("checks") or next(checks),
    )
    monkeypatch.setattr(
        orchestrator,
        "_capture_patch",
        lambda *args: capture_calls.append(args) or ([], "", ""),
    )

    def fake_call(*args, **kwargs):
        raw = json.dumps({"status": "pass", "summary": "修复完成", "changed_files": []})
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)

    result = orchestrator._integration_repair(
        "请求",
        plan,
        task_results,
        tmp_path / "workspace",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        [["git", "status", "--short"]],
        1,
        [],
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
        runtime_base=tmp_path / "runtime" / "run",
    )

    assert result["status"] != "pass"
    assert result["outside_files"] == ["outside.py"]
    assert capture_calls == []
    assert events == ["checks", "status", "status", "status", "checks", "status"]


def test_integration_repair_escalates_declared_vs_mechanical_diff_conflict(
    tmp_path, monkeypatch
):
    plan = {
        "tasks": [
            {"id": f"task-{index}", "write_scope": [f"src/{index}.py"]}
            for index in range(3)
        ]
    }
    task_results = [
        {"task_id": f"task-{index}", "patch_file": str(tmp_path / f"{index}.patch")}
        for index in range(3)
    ]
    statuses = iter(
        [
            (["src/0.py"], "", ""),
            (["src/0.py"], "", ""),
            (["src/0.py", "src/1.py"], "", ""),
        ]
    )
    check_calls = []
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda *args: (True, ""))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _path: next(statuses))
    monkeypatch.setattr(
        orchestrator,
        "_path_diff_fingerprint",
        lambda _worktree, path: f"fingerprint:{path}",
    )
    monkeypatch.setattr(
        orchestrator,
        "_run_checks",
        lambda *args, **kwargs: check_calls.append(args) or (False, [{"returncode": 1}]),
    )
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            json.dumps({"status": "pass", "summary": "fixed", "changed_files": []}),
            [],
        ),
    )

    result = orchestrator._integration_repair(
        "请求",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        [["git", "status", "--short"]],
        1,
        [],
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
        runtime_base=tmp_path / "runtime",
    )

    assert result["status"] == "evidence_conflict"
    assert result["conflict"] is True
    assert result["attempts"][0]["repair_changed_files"] == ["src/1.py"]
    assert len(check_calls) == 1


def test_integration_repair_retries_explicit_luna_failure_before_passing(tmp_path, monkeypatch):
    plan = {
        "tasks": [
            {"id": f"task-{index}", "write_scope": [f"src/{index}.py"]}
            for index in range(3)
        ]
    }
    task_results = [
        {"task_id": f"task-{index}", "patch_file": str(tmp_path / f"{index}.patch")}
        for index in range(3)
    ]
    checks = iter(
        [
            (False, [{"returncode": 1}]),
            (True, [{"returncode": 0}]),
            (True, [{"returncode": 0}]),
        ]
    )
    responses = iter(
        [
            {"status": "failed", "summary": "首次失败", "changed_files": []},
            {"status": "pass", "summary": "重试通过", "changed_files": []},
        ]
    )
    calls = []

    monkeypatch.setattr(orchestrator, "_create_worktree", lambda _workspace, _path: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda _workspace, _patch: (True, ""))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _path: ([], "", ""))
    monkeypatch.setattr(orchestrator, "_ignored_paths", lambda _path: set())
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args, **kwargs: next(checks))
    monkeypatch.setattr(orchestrator, "_capture_patch", lambda *args: ([], "", ""))

    def fake_call(*args, **kwargs):
        calls.append(kwargs["output_last_message"])
        raw = json.dumps(next(responses))
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)

    result = orchestrator._integration_repair(
        "请求",
        plan,
        task_results,
        tmp_path / "workspace",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        [["git", "status", "--short"]],
        2,
        [],
        "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        ["M-001"],
        runtime_base=tmp_path / "runtime" / "run",
    )

    assert len(calls) == 2
    assert [attempt["model_status"] for attempt in result["attempts"]] == ["failed", "pass"]
    assert result["status"] == "pass"
    assert result.get("attempts_exhausted") is not True


def _orchestration_args(workspace: Path):
    return SimpleNamespace(
        request="请求",
        request_file=None,
        workspace=str(workspace),
        workers=3,
        max_luna_attempts=1,
        check=['["git", "status", "--short"]'],
        spec_ref="docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md",
        matrix_ref="docs/governance/improvements/20260710-sol_luna_orchestration/matrix/TRACEABILITY.md",
        matrix_edge=["M-001"],
    )


def test_run_parser_requires_spec_matrix_refs_and_matrix_edge():
    parser = orchestrator._parser()
    base = [
        "run",
        "--request",
        "请求",
        "--check",
        '["git", "status", "--short"]',
    ]
    with pytest.raises(SystemExit):
        parser.parse_args(base)
    with pytest.raises(SystemExit):
        parser.parse_args(base + ["--spec-ref", "SPEC.md"])

    parsed = parser.parse_args(
        base
        + [
            "--spec-ref",
            "SPEC.md",
            "--matrix-ref",
            "matrix/TRACEABILITY.md",
            "--matrix-edge",
            "M-001",
            "--matrix-edge",
            "M-002",
        ]
    )
    assert parsed.spec_ref == "SPEC.md"
    assert parsed.matrix_ref == "matrix/TRACEABILITY.md"
    assert parsed.matrix_edge == ["M-001", "M-002"]


def _patch_orchestration_dependencies(monkeypatch, workspace, integration_result, apply_calls):
    plan = {
        "tasks": [
            {
                "id": f"task-{index}",
                "instructions": "实现任务",
                "write_scope": [f"src/task-{index}.py"],
                "acceptance": "检查通过",
                "checks": [["git", "status", "--short"]],
            }
            for index in range(3)
        ],
        "workers": 3,
        "max_retries": 1,
    }
    primary = workspace / "primary"
    primary.mkdir(parents=True)
    spec = (
        workspace
        / "docs"
        / "governance"
        / "improvements"
        / "20260710-sol_luna_orchestration"
        / "SPEC.md"
    )
    spec.parent.mkdir(parents=True, exist_ok=True)
    spec.write_text("# Spec\n\nFR-001\n", encoding="utf-8")
    matrix = spec.parent / "matrix" / "TRACEABILITY.md"
    matrix.parent.mkdir(parents=True, exist_ok=True)
    matrix.write_text("| Edge ID | FR |\n|---|---|\n| M-001 | FR-001 |\n", encoding="utf-8")

    monkeypatch.setattr(orchestrator, "_workspace_info", lambda _: (workspace, "feat/test", "head"))
    monkeypatch.setattr(orchestrator, "_validate_plan_scope_targets", lambda _workspace, value: value)
    monkeypatch.setattr(orchestrator, "_primary_worktree_root", lambda _: primary)
    monkeypatch.setattr(
        orchestrator,
        "_probe_catalog",
        lambda: (subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), _catalog()),
    )
    def fake_plan_call(*args, **kwargs):
        prompt = args[1]
        assert f"spec-ref: {spec.relative_to(workspace).as_posix()}" in prompt
        assert f"matrix-ref: {matrix.relative_to(workspace).as_posix()}" in prompt
        assert "M-001" in prompt
        return (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            json.dumps(plan),
        )

    monkeypatch.setattr(orchestrator, "_call_codex", fake_plan_call)
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda _workspace, path: True)
    monkeypatch.setattr(
        orchestrator,
        "_run_task",
        lambda _request, task, *_args: {
            "task_id": task["id"],
            "status": "pass",
            "scope_ok": True,
            "evidence_complete": True,
            "test_failed": False,
            "changed_files": [],
            "patch_file": str(workspace / f"{task['id']}.patch"),
        },
    )
    monkeypatch.setattr(orchestrator, "_integration_repair", lambda *args, **kwargs: integration_result)
    monkeypatch.setattr(
        orchestrator,
        "_apply_patch",
        lambda target, patch: (apply_calls.append((target, patch)) or (True, "")),
    )
    def fake_run(argv, **kwargs):
        if argv[1:2] == ["ls-files"]:
            return subprocess.CompletedProcess(argv, 0, stdout=f"{argv[-1]}\n", stderr="")
        if argv[1:2] == ["ls-tree"]:
            return subprocess.CompletedProcess(argv, 0, stdout=f"{argv[-1]}\0", stderr="")
        stdout = "head\n" if argv == ["git", "rev-parse", "HEAD"] else ""
        return subprocess.CompletedProcess(argv, 0, stdout=stdout, stderr="")

    monkeypatch.setattr(orchestrator, "_run", fake_run)


def test_failed_integration_never_applies_a_patch_to_parent(tmp_path, monkeypatch):
    apply_calls = []
    _patch_orchestration_dependencies(
        monkeypatch,
        tmp_path / "workspace",
        {"status": "test_failure", "reason": "全局检查失败"},
        apply_calls,
    )
    workspace = tmp_path / "workspace"
    workspace.mkdir(exist_ok=True)

    code, summary = orchestrator._run_orchestration(_orchestration_args(workspace))

    assert code == 20
    assert summary["verdict"] == "escalate_sol"
    assert apply_calls == []


def test_parent_apply_happens_once_only_after_integration_checks_pass(tmp_path, monkeypatch):
    apply_calls = []
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    _patch_orchestration_dependencies(
        monkeypatch,
        workspace,
        {"status": "pass", "patch_file": str(workspace / "combined.patch")},
        apply_calls,
    )

    code, summary = orchestrator._run_orchestration(_orchestration_args(workspace))

    assert code == 0
    assert summary["verdict"] == "accept"
    assert len(apply_calls) == 1
    assert apply_calls[0][0] == workspace
