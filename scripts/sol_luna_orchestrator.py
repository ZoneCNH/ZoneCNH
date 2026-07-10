#!/usr/bin/env python3
"""仅依赖 Python 标准库的 Sol/Luna 外层编排器。"""

from __future__ import annotations

import argparse
import datetime as _dt
import fnmatch
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence


SOL_MODEL = "gpt-5.6-sol"
LUNA_MODEL = "gpt-5.6-luna"
REASONING_EFFORT = "xhigh"
MIN_EXECUTORS = 3
MAX_EXECUTORS = 5
DEFAULT_GIT_TIMEOUT = 60
DEFAULT_CHEAP_CHECK_TIMEOUT = 900
DEFAULT_MODEL_TIMEOUT = 1800
MAX_CHEAP_CHECK_OUTPUT_BYTES = 2 * 1024 * 1024

_VERDICTS = {"accept": 0, "retry_luna": 10, "escalate_sol": 20}
_SHELL_META = set(";|&><`$(){}[]*!?\n\r\0")
_REASONING_KEYS = {
    "reasoning_efforts",
    "supported_reasoning_efforts",
    "supported_reasoning_effort",
    "supported_reasoning_levels",
    "reasoning_effort",
    "efforts",
}
_SAFE_RUNNERS = {"test", "check", "lint", "typecheck", "build"}
_SAFE_GIT_DIFF_FLAGS = {
    "--cached",
    "--check",
    "--exit-code",
    "--name-only",
    "--no-ext-diff",
    "--quiet",
    "--stat",
}
_SAFE_GIT_STATUS_FLAGS = {
    "--branch",
    "--porcelain",
    "--porcelain=v1",
    "--porcelain=v2",
    "--short",
    "--untracked-files=all",
    "--untracked-files=no",
    "--untracked-files=normal",
    "-b",
    "-s",
}
_PYTEST_UNSAFE_FLAGS = ("-p", "-o", "--override-ini")
_GO_UNSAFE_FLAGS = (
    "-exec",
    "-toolexec",
    "-vettool",
    "--exec",
    "--toolexec",
    "--vettool",
)
_NODE_UNSAFE_FLAGS = (
    "--eval",
    "--experimental-loader",
    "--import",
    "--loader",
    "--require",
    "--test-reporter",
    "--test-reporter-destination",
    "--test-global-setup",
    "-e",
    "-r",
)
_MATRIX_EDGE_RE = re.compile(r"^M-[A-Za-z0-9][A-Za-z0-9_.-]*$")
_JSONL_LOCK = threading.Lock()
_PROTECTED_PATH_PATTERNS = (
    "docs/governance/scoring/RUBRIC-*.md",
    "docs/governance/STRUCTURAL-SCORING.md",
    "docs/governance/scoring/ARBITER-PROTOCOL.md",
    ".claude/agents/**",
    ".codex/agents/**",
    ".copilot/agents/**",
    ".claude/commands/spec-code-pipeline.md",
    ".codex/skills/spec-code-pipeline/**",
    ".copilot/commands/spec-code-pipeline.md",
    ".omc/state/outer-metrics/**",
    ".omx/state/outer-metrics/**",
    ".copilot/state/outer-metrics/**",
    "CONSTITUTION.md",
)


class GateDecision(str):
    """兼容字符串比较和旧调用方读取 ``decision`` 字段。"""

    @property
    def decision(self) -> str:
        return str(self)

    def __getitem__(self, key: Any) -> Any:
        if key == "decision":
            return str(self)
        return super().__getitem__(key)


class BlockedError(ValueError):
    """运行环境不满足治理前置条件。"""


def _compact(value: Any, limit: int = 12000) -> Any:
    if not isinstance(value, str) or len(value) <= limit:
        return value
    return value[:limit] + "\n...[输出已截断]"


def _write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _append_jsonl(path: Path, value: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with _JSONL_LOCK:
        with path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(value, ensure_ascii=False, sort_keys=True) + "\n")


def _text_output(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return str(value)


def _run(
    argv: Sequence[str],
    cwd: Path | None = None,
    input_text: str | None = None,
    timeout: float = DEFAULT_GIT_TIMEOUT,
    stdin_devnull: bool = False,
) -> subprocess.CompletedProcess[str]:
    """所有外部命令统一走 argv，禁止 shell。"""
    command = [str(item) for item in argv]
    try:
        run_kwargs: dict[str, Any] = {
            "cwd": str(cwd) if cwd is not None else None,
            "capture_output": True,
            "text": True,
            "errors": "replace",
            "shell": False,
            "check": False,
            "timeout": timeout,
        }
        if input_text is not None:
            run_kwargs["input"] = input_text
        elif stdin_devnull:
            run_kwargs["stdin"] = subprocess.DEVNULL
        return subprocess.run(command, **run_kwargs)
    except subprocess.TimeoutExpired as error:
        stdout = _text_output(getattr(error, "stdout", None) or getattr(error, "output", None))
        stderr = _text_output(getattr(error, "stderr", None))
        timeout_message = f"command timed out after {timeout:g}s"
        stderr = f"{stderr.rstrip()}\n{timeout_message}".lstrip()
        return subprocess.CompletedProcess(command, 124, stdout=stdout, stderr=stderr)


def normalize_scope(path: str) -> str:
    """规范化工作区相对路径，拒绝从工作区逃逸。"""
    if not isinstance(path, str):
        raise ValueError("scope 必须是字符串")
    if path != path.strip():
        raise ValueError("scope 禁止首尾空白")
    if "\\" in path:
        raise ValueError("scope 禁止反斜杠，POSIX Git 路径必须保持精确")
    raw = path
    if not raw or "\0" in raw:
        raise ValueError("scope 不能为空")
    if raw.startswith("/") or re.match(r"^[A-Za-z]:/", raw):
        raise ValueError(f"scope 不能是绝对路径: {path}")

    parts: list[str] = []
    trailing_slash = raw.endswith("/")
    for item in raw.split("/"):
        if item in ("", "."):
            continue
        if item == "..":
            raise ValueError(f"scope 含有 parent 越界段: {path}")
        parts.append(item)
    normalized = "/".join(parts) or "."
    if trailing_slash and normalized != ".":
        return normalized + "/"
    return normalized


def _as_scopes(scopes: str | Iterable[str]) -> list[str]:
    if isinstance(scopes, str):
        scopes = [scopes]
    return [normalize_scope(item) for item in scopes]


def _scope_covers_protected_path(scope: str) -> bool:
    """Return whether a scope can write any constitution §14.1 path."""
    normalized = normalize_scope(scope).rstrip("/")
    if normalized == ".":
        return True
    has_glob = any(char in normalized for char in "*?[")
    for protected in _PROTECTED_PATH_PATTERNS:
        protected = protected.rstrip("/")
        if normalized == protected or protected.startswith(normalized + "/"):
            return True
        if fnmatch.fnmatchcase(normalized, protected) or fnmatch.fnmatchcase(
            protected, normalized
        ):
            return True
        if has_glob:
            literal_prefix = re.split(r"[*?\[]", normalized, maxsplit=1)[0].rstrip("/")
            if not literal_prefix or protected.startswith(literal_prefix + "/"):
                return True
    return False


def _validate_write_scope(scope: str) -> str:
    normalized = normalize_scope(scope)
    if any(char in normalized for char in "*?["):
        raise ValueError(f"write_scope 禁止通配符/glob: {scope}")
    git_scope = normalized.rstrip("/")
    if ".git" in Path(git_scope).parts:
        raise ValueError(f"write_scope 禁止 Git 元数据路径: {scope}")
    if _scope_covers_protected_path(normalized):
        raise ValueError(f"write_scope 覆盖宪法 §14.1 受保护路径: {scope}")
    return normalized


def path_in_scope(path: str, scopes: str | Iterable[str]) -> bool:
    normalized_path = normalize_scope(path).rstrip("/")
    for scope in _as_scopes(scopes):
        base_scope = scope.rstrip("/")
        if any(char in base_scope for char in "*?["):
            continue
        if base_scope == "." or normalized_path == base_scope:
            return True
        if normalized_path.startswith(base_scope + "/"):
            return True
    return False


def scopes_overlap(left: str | Iterable[str], right: str | Iterable[str]) -> bool:
    left_scopes = _as_scopes(left)
    right_scopes = _as_scopes(right)
    for left_scope in left_scopes:
        for right_scope in right_scopes:
            left_scope = left_scope.rstrip("/")
            right_scope = right_scope.rstrip("/")
            if any(char in left_scope + right_scope for char in "*?["):
                continue
            if (
                left_scope == "."
                or right_scope == "."
                or left_scope == right_scope
                or left_scope.startswith(right_scope + "/")
                or right_scope.startswith(left_scope + "/")
            ):
                return True
    return False


def _token_has_unsafe_path(token: str) -> bool:
    if not isinstance(token, str) or not token:
        return True
    if any(char in _SHELL_META for char in token):
        return True
    normalized = token.replace("\\", "/")
    pending = [normalized]
    while pending:
        candidate = pending.pop()
        if os.path.isabs(candidate) or re.match(r"^[A-Za-z]:/", candidate):
            return True
        if any(part == ".." for part in candidate.split("/")):
            return True
        if "=" in candidate:
            pending.extend(candidate.split("=", 1)[1:])
    return False


def _has_compact_flag(argv: Sequence[str], flag: str) -> bool:
    for token in argv:
        if token == flag or token.startswith(flag + "="):
            return True
        if token.startswith(flag) and len(token) > len(flag):
            return True
    return False


def is_safe_check(argv: Sequence[str]) -> bool:
    """判断计划中的检查是否属于固定 allowlist 且没有越界参数。"""
    try:
        if not isinstance(argv, (list, tuple)):
            return False
        argv = list(argv)
        if not argv or not all(isinstance(item, str) and item for item in argv):
            return False
        if any(_token_has_unsafe_path(item) for item in argv):
            return False

        command = argv[0]
        if command == "git":
            if len(argv) < 2 or argv[1] not in {"diff", "status"}:
                return False
            args = list(argv[2:])
            if args.count("--") > 1:
                return False
            if "--" in args:
                separator = args.index("--")
                flags = args[:separator]
                paths = args[separator + 1 :]
                if any(_token_has_unsafe_path(path) for path in paths):
                    return False
            else:
                flags = args
            allowed_flags = (
                _SAFE_GIT_DIFF_FLAGS
                if argv[1] == "diff"
                else _SAFE_GIT_STATUS_FLAGS
            )
            return all(flag in allowed_flags for flag in flags)
        if command in {"python", "python3"}:
            if len(argv) < 3 or argv[1:3] != ["-m", "pytest"]:
                return False
            return not any(
                _has_compact_flag(argv[3:], flag) for flag in _PYTEST_UNSAFE_FLAGS
            )
        if command == "pytest":
            return not any(
                _has_compact_flag(argv[1:], flag) for flag in _PYTEST_UNSAFE_FLAGS
            )
        if command == "go":
            if len(argv) < 2 or argv[1] not in {"test", "vet"}:
                return False
            return not any(
                _has_compact_flag(argv[2:], flag) for flag in _GO_UNSAFE_FLAGS
            )
        if command == "node":
            return len(argv) >= 2 and argv[1] == "--test" and not any(
                _has_compact_flag(argv[2:], flag) for flag in _NODE_UNSAFE_FLAGS
            )
        if command == "npm":
            return len(argv) >= 2 and (
                argv[1] == "test"
                or (len(argv) >= 3 and argv[1] == "run" and argv[2] in _SAFE_RUNNERS)
            )
        if command == "cargo":
            return len(argv) >= 2 and argv[1] in {"test", "check", "clippy"}
        if command == "make":
            return len(argv) >= 2 and argv[1] in {"test", "check", "lint"}
        return False
    except Exception:
        return False


def model_supports(catalog: Any, slug: str, effort: str) -> bool:
    """从 debug models 的 JSON 或文本目录中确认模型支持指定 effort。"""
    if isinstance(catalog, str):
        try:
            catalog = json.loads(catalog)
        except json.JSONDecodeError:
            lines = [line for line in catalog.splitlines() if slug in line]
            return any(effort in line for line in lines)

    found = False

    def visit(value: Any) -> None:
        nonlocal found
        if found:
            return
        if isinstance(value, list):
            for item in value:
                visit(item)
            return
        if not isinstance(value, dict):
            return

        names = [value.get(key) for key in ("slug", "id", "model", "name")]
        matches = any(item == slug for item in names)
        if matches:
            for key, item in value.items():
                if str(key).lower() in _REASONING_KEYS or (
                    "reason" in str(key).lower() and "effort" in str(key).lower()
                ):
                    if isinstance(item, str) and item == effort:
                        found = True
                    elif isinstance(item, list):
                        values = []
                        for entry in item:
                            if isinstance(entry, str):
                                values.append(entry)
                            elif isinstance(entry, dict):
                                values.extend(str(k) for k in entry)
                                values.extend(str(v) for v in entry.values())
                        if effort in values:
                            found = True
                    elif isinstance(item, dict) and effort in item:
                        found = True
            if value.get("supports_" + effort) is True:
                found = True
            if value.get("supports_reasoning_" + effort) is True:
                found = True
        for item in value.values():
            visit(item)

    visit(catalog)
    return found


def build_codex_command(
    model: str,
    effort: str,
    workspace: str | os.PathLike[str],
    prompt_file_or_dash: str,
    output_schema: str | os.PathLike[str] | None = None,
    output_last_message: str | os.PathLike[str] | None = None,
    sandbox: str = "read-only",
) -> list[str]:
    """构造 Codex exec argv；调用方通过 stdin 提供 ``-`` 的 prompt。"""
    if not model or not effort:
        raise ValueError("model 和 reasoning effort 不能为空")
    if sandbox not in {"read-only", "workspace-write", "danger-full-access"}:
        raise ValueError(f"不支持的 sandbox: {sandbox}")
    if prompt_file_or_dash != "-" and not prompt_file_or_dash:
        raise ValueError("prompt_file_or_dash 不能为空")
    command = [
        "codex",
        "-a",
        "never",
        "exec",
        "--ephemeral",
        "-m",
        model,
        "-c",
        f'model_reasoning_effort="{effort}"',
        "--cd",
        str(workspace),
        "--sandbox",
        sandbox,
    ]
    if output_schema is not None:
        command.extend(["--output-schema", str(output_schema)])
    if output_last_message is not None:
        command.extend(["--output-last-message", str(output_last_message)])
    command.append(prompt_file_or_dash)
    return command


def validate_plan(plan: Any, requested_workers: int) -> dict[str, Any]:
    """校验并规范 Sol 计划；失败抛出 ValueError。"""
    if requested_workers < MIN_EXECUTORS or requested_workers > MAX_EXECUTORS:
        raise ValueError("executor 数必须在 3 到 5 之间")
    if not isinstance(plan, dict) or not isinstance(plan.get("tasks"), list):
        raise ValueError("Sol 计划必须是含 tasks 数组的 JSON 对象")
    tasks = plan["tasks"]
    if len(tasks) != requested_workers or not (
        MIN_EXECUTORS <= len(tasks) <= MAX_EXECUTORS
    ):
        raise ValueError(f"Sol 计划必须恰好包含 {requested_workers} 个 task")

    identifiers: set[str] = set()
    normalized_tasks: list[dict[str, Any]] = []
    for index, task in enumerate(tasks, start=1):
        if not isinstance(task, dict):
            raise ValueError(f"第 {index} 个 task 不是对象")
        task = dict(task)
        if "write_scope" not in task and "scope" in task:
            # 兼容旧 manifest；Sol 新计划仍由 schema 强制使用 write_scope。
            task["write_scope"] = task["scope"]
            task.setdefault("instructions", "完成该 task 的实现")
            task.setdefault("acceptance", "task 变更可验证")
            task.setdefault("checks", [["git", "status", "--short"]])
        required = {"id", "instructions", "write_scope", "acceptance", "checks"}
        missing = sorted(required - set(task))
        if missing:
            raise ValueError(f"task {index} 缺少字段: {', '.join(missing)}")
        task_id = task["id"]
        if not isinstance(task_id, str) or not re.fullmatch(r"[A-Za-z0-9_.-]+", task_id):
            raise ValueError(f"task id 不安全: {task_id!r}")
        if task_id in identifiers:
            raise ValueError(f"task id 重复: {task_id}")
        identifiers.add(task_id)
        if not isinstance(task["instructions"], str) or not task["instructions"].strip():
            raise ValueError(f"task {task_id} 的 instructions 不能为空")
        if not isinstance(task["acceptance"], (str, list, dict)) or not task["acceptance"]:
            raise ValueError(f"task {task_id} 的 acceptance 不能为空")

        raw_scopes = task["write_scope"]
        if isinstance(raw_scopes, str):
            raw_scopes = [raw_scopes]
        if not isinstance(raw_scopes, list) or not raw_scopes:
            raise ValueError(f"task {task_id} 的 write_scope 必须是非空数组")
        scopes = [_validate_write_scope(item) for item in raw_scopes]
        if len(set(scopes)) != len(scopes):
            scopes = list(dict.fromkeys(scopes))
        if not isinstance(task["checks"], list) or not task["checks"]:
            raise ValueError(f"task {task_id} 必须至少有一个 check")
        checks: list[list[str]] = []
        for check in task["checks"]:
            if not is_safe_check(check):
                raise ValueError(f"task {task_id} 含不安全 check: {check!r}")
            checks.append(list(check))
        normalized_tasks.append(
            {
                **task,
                "id": task_id,
                "write_scope": scopes,
                "checks": checks,
            }
        )

    for index, left in enumerate(normalized_tasks):
        for right in normalized_tasks[index + 1 :]:
            if scopes_overlap(left["write_scope"], right["write_scope"]):
                raise ValueError(
                    f"task scope 重叠: {left['id']} 与 {right['id']}"
                )
    return {**plan, "tasks": normalized_tasks}


def _is_path_within(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def _resolved_scope_target(workspace: Path, scope: str) -> Path:
    candidate = workspace / scope.rstrip("/")
    cursor = candidate
    missing: list[str] = []
    while not cursor.exists() and not cursor.is_symlink():
        if cursor == workspace:
            break
        missing.append(cursor.name)
        cursor = cursor.parent
    try:
        resolved = cursor.resolve(strict=True)
    except OSError as error:
        raise ValueError(f"write_scope 无法安全解析: {scope}") from error
    for name in reversed(missing):
        resolved /= name
    return resolved


def _validate_plan_scope_targets(
    workspace: Path, plan: Mapping[str, Any]
) -> dict[str, Any]:
    """Reject symlink aliases, workspace escapes, and resolved Git metadata."""
    workspace_root = workspace.resolve(strict=True)
    git_dir_process = _run(["git", "rev-parse", "--absolute-git-dir"], cwd=workspace_root)
    common_process = _run(
        ["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
        cwd=workspace_root,
    )
    if (
        git_dir_process.returncode != 0
        or common_process.returncode != 0
        or not git_dir_process.stdout.strip()
        or not common_process.stdout.strip()
    ):
        raise BlockedError("无法解析 write_scope 的 Git 元数据边界")
    git_roots = {
        Path(git_dir_process.stdout.strip()).resolve(strict=True),
        Path(common_process.stdout.strip()).resolve(strict=True),
    }
    for task in plan.get("tasks", []):
        for scope in task.get("write_scope", []):
            resolved = _resolved_scope_target(workspace_root, scope)
            if not _is_path_within(resolved, workspace_root):
                raise ValueError(f"write_scope 经 symlink 越出 workspace: {scope}")
            if any(
                _is_path_within(resolved, git_root)
                or _is_path_within(git_root, resolved)
                for git_root in git_roots
            ):
                raise ValueError(f"write_scope 解析到 Git 元数据: {scope}")
            candidate = workspace_root / scope.rstrip("/")
            if candidate.is_symlink():
                raise ValueError(f"write_scope 不得是 symlink: {scope}")
            if candidate.is_dir():
                for descendant in candidate.rglob("*"):
                    if descendant.is_symlink():
                        raise ValueError(
                            f"write_scope 内含 symlink，无法证明写边界: {scope}"
                        )
    return dict(plan)


def _result_items(results: Any) -> list[dict[str, Any]]:
    if isinstance(results, dict):
        if isinstance(results.get("results"), list):
            results = results["results"]
        else:
            results = [dict(value, task_id=key) for key, value in results.items()]
    if not isinstance(results, list):
        return []
    return [item for item in results if isinstance(item, dict)]


def _batch_details(plan: Any, results: Any) -> tuple[GateDecision, list[str], list[str]]:
    if not isinstance(plan, dict) or not isinstance(plan.get("tasks"), list):
        return GateDecision("escalate_sol"), ["计划证据缺失"], []
    expected = [task.get("id") for task in plan["tasks"] if isinstance(task, dict)]
    items = _result_items(results)
    seen: dict[str, int] = {}
    for item in items:
        task_id = item.get("task_id") or item.get("id")
        if isinstance(task_id, str):
            seen[task_id] = seen.get(task_id, 0) + 1
    if set(seen) != set(expected) or any(count != 1 for count in seen.values()):
        return GateDecision("escalate_sol"), ["task 输出缺失或冲突"], []

    reasons: list[str] = []
    retry_tasks: list[str] = []
    changed_owners: dict[str, str] = {}
    for item in items:
        task_id = item.get("task_id") or item.get("id")
        if item.get("scope_ok") is False or item.get("scope_violation"):
            reasons.append(f"{task_id}: 越界编辑")
        if item.get("conflict") or item.get("overlap") or item.get("conflicts"):
            reasons.append(f"{task_id}: 输出冲突或重叠编辑")
        if item.get("uncertainties"):
            reasons.append(f"{task_id}: 存在未解决不确定性")
        if "evidence_complete" in item:
            evidence_complete = item.get("evidence_complete") is True
        else:
            evidence = item.get("evidence")
            evidence_complete = isinstance(evidence, list) and bool(evidence)
        if not evidence_complete:
            reasons.append(f"{task_id}: 证据缺失")
        for path in item.get("changed_files", []) or []:
            if not isinstance(path, str):
                reasons.append(f"{task_id}: changed_files 无效")
                continue
            try:
                normalized = normalize_scope(path)
            except ValueError:
                reasons.append(f"{task_id}: changed_files 越界")
                continue
            previous = changed_owners.get(normalized)
            if previous is not None and previous != task_id:
                reasons.append(f"{previous} 与 {task_id}: 实际编辑重叠")
            changed_owners[normalized] = str(task_id)

        mechanical_failed = bool(item.get("test_failed"))
        if item.get("mechanical_check") in {"failed", "fail"}:
            mechanical_failed = True
        if item.get("checks_ok") is False:
            mechanical_failed = True
        if mechanical_failed:
            retry_count = item.get("retry_count", 0)
            max_retries = item.get("max_retries", plan.get("max_retries"))
            exhausted = item.get("attempts_exhausted") or (
                isinstance(max_retries, int)
                and isinstance(retry_count, int)
                and retry_count >= max_retries
            )
            if item.get("attempts_remaining") or not exhausted:
                retry_tasks.append(str(task_id))
            else:
                reasons.append(f"{task_id}: 测试失败且重试耗尽")

    if reasons:
        return GateDecision("escalate_sol"), reasons, retry_tasks
    if retry_tasks:
        return GateDecision("retry_luna"), [f"等待 Luna 修复: {', '.join(retry_tasks)}"], retry_tasks
    if any(item.get("status") not in {"pass", "accepted", "passed"} for item in items):
        return GateDecision("escalate_sol"), ["task 输出状态冲突"], []
    return GateDecision("accept"), [], []


def evaluate_batch(plan: Any, results: Any) -> str:
    """cheap gate 的公开接口，只返回三种门禁 verdict。"""
    return _batch_details(plan, results)[0]


def _parse_json(value: str) -> Any:
    text = value.strip()
    if not text:
        raise ValueError("模型没有输出 JSON")
    candidates = [text]
    if text.startswith("```"):
        candidates.append(re.sub(r"^```(?:json)?\s*|\s*```$", "", text, flags=re.S))
    for line in reversed(text.splitlines()):
        if line.strip().startswith(("{", "[")):
            candidates.append(line.strip())
    first_object = text.find("{")
    last_object = text.rfind("}")
    if first_object >= 0 and last_object > first_object:
        candidates.append(text[first_object : last_object + 1])
    for candidate in candidates:
        try:
            return json.loads(candidate)
        except json.JSONDecodeError:
            continue
    raise ValueError("模型输出不是有效 JSON")


def _token_count(value: Any) -> int | None:
    if isinstance(value, dict):
        for key in ("total_tokens", "totalTokens", "tokens"):
            if isinstance(value.get(key), int):
                return value[key]
        for item in value.values():
            count = _token_count(item)
            if count is not None:
                return count
    elif isinstance(value, list):
        for item in value:
            count = _token_count(item)
            if count is not None:
                return count
    return None


def _token_count_from_stderr(value: str) -> int | None:
    """Extract the CLI's final ``tokens used`` counter when JSON omits usage."""
    if not isinstance(value, str):
        return None
    matches = re.findall(
        r"tokens\s+used\s*(?:\r?\n|:\s*)\s*([0-9][0-9,]*)",
        value,
        flags=re.IGNORECASE,
    )
    if not matches:
        return None
    try:
        return int(matches[-1].replace(",", ""))
    except ValueError:
        return None


def _model_failure_class(stderr: str) -> str:
    text = stderr.lower() if isinstance(stderr, str) else ""
    if "usage limit" in text or "insufficient_quota" in text or "out of credits" in text:
        return "usage_limit"
    if "invalid_api_key" in text or "unauthorized" in text or "authentication" in text:
        return "authentication"
    if "rate_limit_exceeded" in text or "retry-after" in text:
        return "rate_limit"
    if "model_not_found" in text or "does not have access" in text:
        return "model_access"
    return "model_call_failed"


def _call_codex(
    model: str,
    prompt: str,
    workspace: Path,
    run_dir: Path,
    call_log: Path,
    kind: str,
    output_schema: Path | None = None,
    output_last_message: Path | None = None,
    sandbox: str = "read-only",
    timeout: float = DEFAULT_MODEL_TIMEOUT,
) -> tuple[subprocess.CompletedProcess[str], str]:
    if output_last_message is None:
        output_last_message = run_dir / "responses" / f"{kind}-{uuid.uuid4().hex[:8]}.txt"
    output_last_message.parent.mkdir(parents=True, exist_ok=True)
    command = build_codex_command(
        model,
        REASONING_EFFORT,
        workspace,
        "-",
        output_schema=output_schema,
        output_last_message=output_last_message,
        sandbox=sandbox,
    )
    started = _dt.datetime.now(_dt.timezone.utc).isoformat()
    process = _run(command, cwd=workspace, input_text=prompt, timeout=timeout)
    raw = ""
    if output_last_message.exists():
        raw = output_last_message.read_text(encoding="utf-8", errors="replace")
    if not raw.strip():
        raw = process.stdout
    try:
        decoded = _parse_json(raw)
        tokens = _token_count(decoded)
    except ValueError:
        tokens = None
    if tokens is None:
        tokens = _token_count_from_stderr(process.stderr)
    _append_jsonl(
        call_log,
        {
            "kind": kind,
            "model": model,
            "effort": REASONING_EFFORT,
            "returncode": process.returncode,
            "tokens": tokens,
            "started_at": started,
            "command": command,
            "stdout": _compact(process.stdout),
            "stderr": _compact(process.stderr),
            "response_file": str(output_last_message),
        },
    )
    return process, raw


def _has_rename_or_copy_status(status_code: str) -> bool:
    return len(status_code) == 2 and any(char in {"R", "C"} for char in status_code)


def _porcelain_v1_z_records(raw: str, label: str) -> list[tuple[str, str, str | None]]:
    records: list[tuple[str, str, str | None]] = []
    entries = raw.split("\0")
    index = 0
    while index < len(entries):
        entry = entries[index]
        if not entry:
            index += 1
            continue
        if len(entry) < 4 or entry[2] != " ":
            raise BlockedError(f"{label}格式异常: {entry!r}")
        status_code = entry[:2]
        path = entry[3:]
        if not path:
            raise BlockedError(f"{label}缺少路径")
        source: str | None = None
        if _has_rename_or_copy_status(status_code):
            index += 1
            if index >= len(entries) or not entries[index]:
                raise BlockedError(f"{label}缺少重命名源路径")
            source = entries[index]
        records.append((status_code, path, source))
        index += 1
    return records


def _ignored_paths(worktree: Path) -> set[str]:
    """Read the ignored-file baseline; any git/status anomaly is fatal."""
    process = _run(
        [
            "git",
            "status",
            "--ignored",
            "--porcelain=v1",
            "--untracked-files=all",
            "-z",
        ],
        cwd=worktree,
    )
    if process.returncode != 0:
        raise BlockedError(
            f"无法读取 ignored 文件状态: {process.stderr or process.stdout}"
        )
    return {
        path
        for status_code, path, _source in _porcelain_v1_z_records(
            process.stdout, "ignored 文件状态"
        )
        if status_code == "!!"
    }


def _run_dir_prefix(workspace: Path, run_dir: Path) -> str | None:
    """Return the current run's workspace-relative path, never an external path."""
    try:
        workspace_root = workspace.resolve()
        resolved_run_dir = run_dir.resolve()
        relative = resolved_run_dir.relative_to(workspace_root)
    except (OSError, ValueError):
        return None
    if relative == Path("."):
        return None
    return relative.as_posix().rstrip("/")


def _unexpected_ignored_paths(
    workspace: Path,
    run_dir: Path,
    ignored_before: set[str],
    ignored_after: set[str],
) -> list[str]:
    """Exclude only artifacts owned by this run inside the same workspace."""
    new_ignored = ignored_after - ignored_before
    run_prefix = _run_dir_prefix(workspace, run_dir)
    if run_prefix is not None:
        new_ignored = {
            path
            for path in new_ignored
            if path != run_prefix and not path.startswith(run_prefix + "/")
        }
    return sorted(new_ignored)


def _guarded_model_call(
    model: str,
    prompt: str,
    workspace: Path,
    run_dir: Path,
    call_log: Path,
    kind: str,
    output_schema: Path | None,
    output_last_message: Path,
    sandbox: str,
) -> tuple[subprocess.CompletedProcess[str], str, list[str]]:
    """Run one model call with an ignored-file baseline and post-call diff."""
    ignored_before = _ignored_paths(workspace)
    if sandbox == "workspace-write" and ignored_before:
        raise BlockedError(
            "executor worktree 在模型调用前已有 ignored 文件，无法证明内容未被篡改: "
            + ", ".join(sorted(ignored_before))
        )
    process, raw = _call_codex(
        model,
        prompt,
        workspace,
        run_dir,
        call_log,
        kind,
        output_schema=output_schema,
        output_last_message=output_last_message,
        sandbox=sandbox,
    )
    ignored_after = _ignored_paths(workspace)
    unexpected = _unexpected_ignored_paths(
        workspace, run_dir, ignored_before, ignored_after
    )
    _append_jsonl(
        call_log,
        {
            "kind": "ignored-audit",
            "call_kind": kind,
            "checked": True,
            "before_count": len(ignored_before),
            "after_count": len(ignored_after),
            "new_ignored": sorted(ignored_after - ignored_before),
            "unexpected_ignored": unexpected,
            "owned_run_prefix": _run_dir_prefix(workspace, run_dir),
        },
    )
    return process, raw, unexpected


def _status_paths(worktree: Path) -> tuple[list[str], str, str]:
    status = _run(
        ["git", "status", "--porcelain=v1", "--untracked-files=all", "-z"],
        cwd=worktree,
    )
    diff_names = _run(["git", "diff", "--name-only", "-z", "HEAD", "--"], cwd=worktree)
    if status.returncode != 0:
        raise BlockedError(f"无法读取工作区状态: {status.stderr or status.stdout}")
    if diff_names.returncode != 0:
        raise BlockedError(
            f"无法读取工作区 diff 状态: {diff_names.stderr or diff_names.stdout}"
        )
    changed: list[str] = []
    for _status_code, path, source in _porcelain_v1_z_records(
        status.stdout, "工作区状态"
    ):
        changed.append(path)
        if source is not None:
            changed.append(source)
    changed.extend(item for item in diff_names.stdout.split("\0") if item)
    return sorted(set(changed)), status.stdout, diff_names.stdout


def _capture_patch(worktree: Path, patch_path: Path) -> tuple[list[str], str, str]:
    changed, status_raw, _ = _status_paths(worktree)
    untracked: list[str] = []
    for status_code, path, _source in _porcelain_v1_z_records(
        status_raw, "捕获 patch 状态"
    ):
        if status_code == "??":
            untracked.append(path)
    if untracked:
        add = _run(["git", "add", "-N", "--", *untracked], cwd=worktree)
        if add.returncode != 0:
            patch_path.write_text("", encoding="utf-8")
            return changed, status_raw, add.stderr or add.stdout
    diff = _run(["git", "diff", "--binary", "--no-ext-diff", "HEAD", "--"], cwd=worktree)
    diff_error = diff.stderr or diff.stdout if diff.returncode != 0 else ""
    if untracked:
        reset = _run(["git", "reset", "--", *untracked], cwd=worktree)
        if reset.returncode != 0:
            patch_path.write_text("", encoding="utf-8")
            return changed, status_raw, reset.stderr or reset.stdout
    patch_path.parent.mkdir(parents=True, exist_ok=True)
    patch_path.write_text(diff.stdout if not diff_error else "", encoding="utf-8")
    return changed, status_raw, diff_error


def _path_diff_fingerprint(worktree: Path, path: str) -> str:
    normalized = normalize_scope(path)
    diff = _run(
        ["git", "diff", "--binary", "--no-ext-diff", "HEAD", "--", normalized],
        cwd=worktree,
    )
    if diff.returncode != 0:
        raise BlockedError(f"无法计算 changed path 指纹: {normalized}")
    digest = hashlib.sha256(diff.stdout.encode("utf-8", errors="surrogatepass"))
    candidate = worktree / normalized
    if candidate.is_symlink():
        digest.update(b"\0symlink\0" + os.readlink(candidate).encode("utf-8", errors="surrogatepass"))
    elif candidate.is_file():
        digest.update(b"\0file\0")
        with candidate.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    elif candidate.exists():
        digest.update(b"\0other\0")
    else:
        digest.update(b"\0missing\0")
    return digest.hexdigest()


def _check_sandbox_binary() -> str:
    binary = shutil.which("bwrap")
    if not binary:
        raise BlockedError("cheap check 需要可用的 bubblewrap (bwrap) 沙箱")
    return binary


def _resource_limiter_binary() -> str:
    binary = shutil.which("prlimit")
    if not binary:
        raise BlockedError("cheap check 需要可用的 prlimit 资源限制器")
    return binary


def _sandbox_mount_args(source: Path, read_only: bool = True) -> list[str]:
    resolved = source.resolve()
    operation = "--ro-bind" if read_only else "--bind"
    return ["--dir", str(resolved), operation, str(resolved), str(resolved)]


def _cheap_check_command(worktree: Path, argv: Sequence[str]) -> list[str]:
    """Build a networkless, clean-environment bubblewrap command for tests."""
    workspace = worktree.resolve(strict=True)
    git_entry = workspace / ".git"
    if not git_entry.exists():
        raise BlockedError(f"cheap check workspace 缺少 .git: {workspace}")
    common = _run(
        ["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
        cwd=workspace,
    )
    if common.returncode != 0 or not common.stdout.strip():
        raise BlockedError(
            f"无法定位 cheap check Git common-dir: {common.stderr or common.stdout}"
        )
    common_git = Path(common.stdout.strip()).resolve(strict=True)
    git_dir_process = _run(["git", "rev-parse", "--absolute-git-dir"], cwd=workspace)
    if git_dir_process.returncode != 0 or not git_dir_process.stdout.strip():
        raise BlockedError(
            f"无法定位 cheap check Git dir: {git_dir_process.stderr or git_dir_process.stdout}"
        )
    git_dir = Path(git_dir_process.stdout.strip()).resolve(strict=True)

    command = [
        _resource_limiter_binary(),
        "--as=4294967296",
        "--cpu=600",
        "--fsize=16777216",
        "--nofile=1024",
        "--nproc=2048",
        "--core=0",
        "--",
        _check_sandbox_binary(),
        "--die-with-parent",
        "--new-session",
        "--unshare-all",
        "--cap-drop",
        "ALL",
        "--size",
        "67108864",
        "--tmpfs",
        "/",
        "--size",
        "536870912",
        "--tmpfs",
        "/tmp",
    ]
    command.extend(_sandbox_mount_args(Path("/usr"), read_only=True))
    command.extend(
        [
            "--symlink",
            "usr/bin",
            "/bin",
            "--symlink",
            "usr/sbin",
            "/sbin",
            "--symlink",
            "usr/lib",
            "/lib",
            "--symlink",
            "usr/lib64",
            "/lib64",
        ]
    )
    python_venv = Path("/opt/python_venv")
    if python_venv.exists():
        command.extend(_sandbox_mount_args(python_venv, read_only=True))

    host_home = Path.home().resolve()
    cache_mounts = [
        host_home / ".cargo",
        host_home / ".rustup",
        host_home / "go" / "pkg" / "mod",
    ]
    for cache in cache_mounts:
        if cache.exists():
            command.extend(_sandbox_mount_args(cache, read_only=True))

    command.extend(_sandbox_mount_args(workspace, read_only=True))
    command.extend(_sandbox_mount_args(common_git, read_only=True))
    command.extend(_sandbox_mount_args(git_dir, read_only=True))
    command.extend(
        [
            "--ro-bind",
            str(git_entry),
            str(git_entry),
            "--proc",
            "/proc",
            "--dev",
            "/dev",
            "--dir",
            "/tmp/home",
            "--clearenv",
        ]
    )
    safe_environment = {
        "HOME": "/tmp/home",
        "TMPDIR": "/tmp",
        "XDG_CACHE_HOME": "/tmp/cache",
        "GOCACHE": "/tmp/go-build",
        "NPM_CONFIG_CACHE": "/tmp/npm-cache",
        "PYTHONPYCACHEPREFIX": "/tmp/pycache",
        "CARGO_TARGET_DIR": "/tmp/cargo-target",
        "COVERAGE_FILE": "/tmp/.coverage",
        "CI": "1",
    }
    for name in ("PATH", "LANG", "LC_ALL", "LC_CTYPE", "TZ", "TERM", "USER", "LOGNAME"):
        value = os.environ.get(name)
        if value:
            safe_environment[name] = value
    cargo_home = host_home / ".cargo"
    rustup_home = host_home / ".rustup"
    module_cache = host_home / "go" / "pkg" / "mod"
    if cargo_home.exists():
        safe_environment["CARGO_HOME"] = str(cargo_home)
    if rustup_home.exists():
        safe_environment["RUSTUP_HOME"] = str(rustup_home)
    if module_cache.exists():
        safe_environment["GOMODCACHE"] = str(module_cache)
    for name, value in sorted(safe_environment.items()):
        command.extend(["--setenv", name, value])
    command.extend(["--chdir", str(workspace), "--", *map(str, argv)])
    return command


def _run_cheap_check(
    worktree: Path,
    argv: Sequence[str],
    timeout: float = DEFAULT_CHEAP_CHECK_TIMEOUT,
) -> subprocess.CompletedProcess[str]:
    command = _cheap_check_command(worktree, argv)
    with tempfile.TemporaryFile() as stdout_file, tempfile.TemporaryFile() as stderr_file:
        try:
            process = subprocess.run(
                command,
                cwd=str(worktree),
                stdin=subprocess.DEVNULL,
                stdout=stdout_file,
                stderr=stderr_file,
                shell=False,
                check=False,
                timeout=timeout,
            )
            returncode = process.returncode
            timed_out = False
        except subprocess.TimeoutExpired:
            returncode = 124
            timed_out = True

        def read_limited(handle: Any) -> str:
            handle.seek(0, os.SEEK_END)
            size = handle.tell()
            handle.seek(0)
            data = handle.read(MAX_CHEAP_CHECK_OUTPUT_BYTES)
            text = data.decode("utf-8", errors="replace")
            if size > MAX_CHEAP_CHECK_OUTPUT_BYTES:
                text += (
                    f"\n...[cheap check 输出已截断: {size} bytes, "
                    f"保留 {MAX_CHEAP_CHECK_OUTPUT_BYTES} bytes]"
                )
            return text

        stdout = read_limited(stdout_file)
        stderr = read_limited(stderr_file)
        if timed_out:
            timeout_message = f"command timed out after {timeout:g}s"
            stderr = f"{stderr.rstrip()}\n{timeout_message}".lstrip()
        return subprocess.CompletedProcess(
            command, returncode, stdout=stdout, stderr=stderr
        )


def _snapshot_and_checks(
    worktree: Path,
    checks: Sequence[Sequence[str]],
    patch_path: Path,
    check_log_path: Path,
) -> dict[str, Any]:
    if not checks:
        raise ValueError("cheap check 列表不能为空")
    check_results: list[dict[str, Any]] = []
    for index, check in enumerate(checks, start=1):
        process = _run_cheap_check(
            worktree, check, timeout=DEFAULT_CHEAP_CHECK_TIMEOUT
        )
        check_results.append(
            {
                "index": index,
                "argv": list(check),
                "returncode": process.returncode,
                "stdout": _compact(process.stdout),
                "stderr": _compact(process.stderr),
            }
        )
    _write_json(check_log_path, check_results)
    changed, status_raw, diff_names = _status_paths(worktree)
    captured_changed, _, patch_error = _capture_patch(worktree, patch_path)
    if captured_changed:
        changed = sorted(set(changed) | set(captured_changed))
    return {
        "changed_files": changed,
        "status_raw": status_raw,
        "diff_names": diff_names,
        "patch_error": patch_error,
        "check_results": check_results,
        "checks_ok": bool(check_results) and all(
            item["returncode"] == 0 for item in check_results
        ),
    }


def _validate_luna_output(value: Any) -> tuple[bool, str]:
    if not isinstance(value, dict):
        return False, "Luna 输出不是对象"
    if value.get("status") not in {"pass", "accepted", "fail", "failed"}:
        return False, "Luna 输出缺少有效 status"
    if not isinstance(value.get("summary"), str) or not value["summary"].strip():
        return False, "Luna 输出缺少 summary"
    if not isinstance(value.get("changed_files"), list):
        return False, "Luna 输出缺少 changed_files"
    return True, ""


def _luna_output_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "additionalProperties": False,
        "required": ["status", "summary", "changed_files"],
        "properties": {
            "status": {
                "type": "string",
                "enum": ["pass", "accepted", "fail", "failed"],
            },
            "summary": {"type": "string"},
            "changed_files": {"type": "array", "items": {"type": "string"}},
        },
    }


def _sol_plan_output_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "additionalProperties": False,
        "required": ["tasks"],
        "properties": {
            "tasks": {
                "type": "array",
                "minItems": MIN_EXECUTORS,
                "maxItems": MAX_EXECUTORS,
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": [
                        "id",
                        "instructions",
                        "write_scope",
                        "acceptance",
                        "checks",
                    ],
                    "properties": {
                        "id": {"type": "string"},
                        "instructions": {"type": "string"},
                        "write_scope": {
                            "type": "array",
                            "minItems": 1,
                            "items": {"type": "string"},
                        },
                        "acceptance": {"type": "string"},
                        "checks": {
                            "type": "array",
                            "minItems": 1,
                            "items": {
                                "type": "array",
                                "items": {"type": "string"},
                            },
                        },
                    },
                },
            }
        },
    }


def _sol_escalation_schema() -> dict[str, Any]:
    return {
        "type": "object",
        "additionalProperties": False,
        "required": ["decision", "reason", "missing_evidence"],
        "properties": {
            "decision": {
                "type": "string",
                "enum": ["blocked", "escalate_sol"],
            },
            "reason": {"type": "string"},
            "missing_evidence": {"type": "array", "items": {"type": "string"}},
        },
    }


def _schema_file(run_dir: Path, name: str, schema: Mapping[str, Any]) -> Path:
    path = run_dir / "schemas" / name
    if not path.exists():
        _write_json(path, schema)
    return path


def _traceability_fields(
    spec_ref: str, matrix_edges: Sequence[str]
) -> tuple[str, list[str]]:
    if not isinstance(spec_ref, str) or not spec_ref.strip() or "\0" in spec_ref:
        raise ValueError("spec-ref 必须是非空字符串")
    normalized_spec = normalize_scope(spec_ref)
    if any(char in normalized_spec for char in "*?["):
        raise ValueError("spec-ref 禁止通配符/glob")
    if Path(normalized_spec).name != "SPEC.md":
        raise ValueError("spec-ref 必须引用 SPEC.md")
    if isinstance(matrix_edges, str):
        matrix_edges = [matrix_edges]
    if not isinstance(matrix_edges, (list, tuple)):
        raise ValueError("matrix-edge 必须是数组")
    normalized_edges: list[str] = []
    for edge in matrix_edges:
        if not isinstance(edge, str) or not edge.strip() or "\0" in edge:
            raise ValueError("matrix-edge 必须至少包含一个非空字符串")
        normalized_edge = edge.strip()
        if not _MATRIX_EDGE_RE.fullmatch(normalized_edge):
            raise ValueError(f"matrix-edge 不是有效的 M-* 标识: {edge}")
        if normalized_edge not in normalized_edges:
            normalized_edges.append(normalized_edge)
    if not normalized_edges:
        raise ValueError("matrix-edge 必须至少指定一个")
    return normalized_spec, normalized_edges


def _validate_spec_reference(workspace: Path, spec_ref: str) -> str:
    """Require a real SPEC.md file whose resolved target stays in workspace."""
    normalized_spec, _ = _traceability_fields(spec_ref, ["M-VALIDATE"])
    try:
        workspace_root = workspace.resolve(strict=True)
        resolved_spec = (workspace_root / normalized_spec).resolve(strict=True)
        resolved_spec.relative_to(workspace_root)
    except (OSError, ValueError) as error:
        raise ValueError(f"spec-ref 不存在或越出 workspace: {spec_ref}") from error
    if not resolved_spec.is_file():
        raise ValueError(f"spec-ref 不是文件: {spec_ref}")
    return normalized_spec


def _canonical_matrix_ref(spec_ref: str) -> str:
    spec_path = Path(spec_ref)
    module_root = spec_path.parent.parent if spec_path.parent.name == "spec" else spec_path.parent
    return (module_root / "matrix" / "TRACEABILITY.md").as_posix()


def _require_head_tracked_file(workspace: Path, relative_path: str) -> None:
    tracked = _run(
        ["git", "ls-files", "--error-unmatch", "--", relative_path], cwd=workspace
    )
    head_tree = _run(
        ["git", "ls-tree", "-r", "--name-only", "-z", "HEAD", "--", relative_path],
        cwd=workspace,
    )
    unchanged = _run(["git", "diff", "--quiet", "HEAD", "--", relative_path], cwd=workspace)
    head_paths = {item for item in head_tree.stdout.split("\0") if item}
    if (
        tracked.returncode != 0
        or head_tree.returncode != 0
        or unchanged.returncode != 0
        or relative_path not in head_paths
    ):
        raise ValueError(f"追溯引用必须由当前 HEAD 跟踪: {relative_path}")


def _matrix_edge_rows(matrix_text: str) -> dict[str, set[str]]:
    lines: list[str] = []
    in_fence = False
    for line in matrix_text.splitlines():
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence:
            lines.append(line)
    for index, line in enumerate(lines):
        if not line.lstrip().startswith("|"):
            continue
        headers = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(headers) < 2 or headers[0] != "Edge ID" or headers[1] != "FR":
            continue
        if index + 1 >= len(lines) or not re.match(
            r"^\s*\|(?:\s*:?-+:?\s*\|)+\s*$", lines[index + 1]
        ):
            raise ValueError("Matrix Edge 表缺少合法分隔行")
        rows: dict[str, set[str]] = {}
        for row_line in lines[index + 2 :]:
            if not row_line.lstrip().startswith("|"):
                break
            cells = [cell.strip() for cell in row_line.strip().strip("|").split("|")]
            if len(cells) < 2 or not _MATRIX_EDGE_RE.fullmatch(cells[0]):
                raise ValueError(f"Matrix Edge 表含无效行: {row_line}")
            if cells[0] in rows:
                raise ValueError(f"Matrix Edge ID 重复: {cells[0]}")
            fr_ids = set(re.findall(r"\bFR-[0-9]+\b", cells[1]))
            if not fr_ids:
                raise ValueError(f"Matrix Edge 缺少 FR 引用: {cells[0]}")
            rows[cells[0]] = fr_ids
        if not rows:
            raise ValueError("Matrix Edge 表不能为空")
        return rows
    raise ValueError("Matrix 缺少以 Edge ID/FR 开头的追溯表")


def _validate_traceability_references(
    workspace: Path,
    spec_ref: str,
    matrix_ref: str,
    matrix_edges: Sequence[str],
) -> tuple[str, str, list[str]]:
    """Bind requested M-edges to the canonical Matrix adjacent to the SPEC."""
    normalized_spec = _validate_spec_reference(workspace, spec_ref)
    _, normalized_edges = _traceability_fields(normalized_spec, matrix_edges)
    if not isinstance(matrix_ref, str) or not matrix_ref.strip() or "\0" in matrix_ref:
        raise ValueError("matrix-ref 必须是非空字符串")
    normalized_matrix = normalize_scope(matrix_ref)
    if any(char in normalized_matrix for char in "*?["):
        raise ValueError("matrix-ref 禁止通配符/glob")
    if Path(normalized_matrix).name != "TRACEABILITY.md":
        raise ValueError("matrix-ref 必须引用 TRACEABILITY.md")

    expected_matrix = _canonical_matrix_ref(normalized_spec)
    if normalized_matrix != expected_matrix:
        raise ValueError(
            f"matrix-ref 不是 SPEC 的 canonical Matrix: expected {expected_matrix}"
        )
    try:
        workspace_root = workspace.resolve(strict=True)
        resolved_spec = (workspace_root / normalized_spec).resolve(strict=True)
        resolved_matrix = (workspace_root / normalized_matrix).resolve(strict=True)
        resolved_matrix.relative_to(workspace_root)
    except (OSError, ValueError) as error:
        raise ValueError(
            f"matrix-ref 不存在或越出 workspace: {matrix_ref}"
        ) from error
    if not resolved_matrix.is_file():
        raise ValueError(f"matrix-ref 不是文件: {matrix_ref}")
    _require_head_tracked_file(workspace_root, normalized_spec)
    _require_head_tracked_file(workspace_root, normalized_matrix)

    spec_text = resolved_spec.read_text(encoding="utf-8")
    matrix_text = resolved_matrix.read_text(encoding="utf-8")
    spec_fr_ids = set(re.findall(r"\bFR-[0-9]+\b", spec_text))
    if not spec_fr_ids:
        raise ValueError("SPEC 缺少 FR-* 标识")
    edge_rows = _matrix_edge_rows(matrix_text)
    unknown_fr = sorted(
        {fr_id for fr_ids in edge_rows.values() for fr_id in fr_ids} - spec_fr_ids
    )
    if unknown_fr:
        raise ValueError(f"Matrix 引用了 SPEC 中不存在的 FR: {', '.join(unknown_fr)}")
    available_edges = set(edge_rows)
    missing_edges = [edge for edge in normalized_edges if edge not in available_edges]
    if missing_edges:
        raise ValueError(
            f"matrix-edge 不存在于 canonical Matrix: {', '.join(missing_edges)}"
        )
    return normalized_spec, normalized_matrix, normalized_edges


def _task_prompt(
    request: str,
    task: Mapping[str, Any],
    attempt: int,
    spec_ref: str,
    matrix_edges: Sequence[str],
    previous: Mapping[str, Any] | None = None,
) -> str:
    spec_ref, matrix_edges = _traceability_fields(spec_ref, matrix_edges)
    previous_text = json.dumps(previous, ensure_ascii=False, indent=2) if previous else "无"
    return f"""你是 Luna Executor。只在当前 detached worktree 中工作，不创建或委派子 Agent。
请求：{request}
spec-ref: {spec_ref}
matrix-ref: {_canonical_matrix_ref(spec_ref)}
matrix-edge: {json.dumps(matrix_edges, ensure_ascii=False)}
任务 ID：{task['id']}
第 {attempt} 次尝试
写入范围：{json.dumps(task['write_scope'], ensure_ascii=False)}
任务说明：{task['instructions']}
验收标准：{json.dumps(task['acceptance'], ensure_ascii=False)}
允许检查：{json.dumps(task['checks'], ensure_ascii=False)}
上一次机械结果：{previous_text}

请完成实现并运行允许的检查。只能编辑写入范围内的文件。最后只输出结构化 JSON，至少包含：
{{"status":"pass 或 fail","summary":"...","changed_files":["相对路径"]}}
"""


def _run_task(
    request: str,
    task: Mapping[str, Any],
    workspace: Path,
    task_worktree: Path,
    run_dir: Path,
    call_log: Path,
    max_attempts: int,
    spec_ref: str,
    matrix_edges: Sequence[str],
) -> dict[str, Any]:
    task_id = str(task["id"])
    task_dir = run_dir / "tasks" / task_id
    output_schema = _schema_file(
        task_dir, "output-schema.json", _luna_output_schema()
    )
    result: dict[str, Any] = {
        "task_id": task_id,
        "write_scope": task["write_scope"],
        "attempts": [],
        "status": "evidence_missing",
        "scope_ok": False,
        "evidence_complete": False,
        "test_failed": False,
        "attempts_remaining": False,
    }
    previous: dict[str, Any] | None = None
    for attempt in range(1, max_attempts + 1):
        try:
            prompt = _task_prompt(
                request, task, attempt, spec_ref, matrix_edges, previous
            )
        except Exception as error:
            result["reason"] = f"Luna 执行前状态或追溯校验失败: {error}"
            result["status"] = "evidence_missing"
            break
        prompt_path = task_dir / f"attempt-{attempt}.prompt.md"
        prompt_path.parent.mkdir(parents=True, exist_ok=True)
        prompt_path.write_text(prompt, encoding="utf-8")
        output_path = task_dir / f"attempt-{attempt}.json"
        try:
            process, raw, new_ignored = _guarded_model_call(
                LUNA_MODEL,
                prompt,
                task_worktree,
                run_dir,
                call_log,
                f"luna-{task_id}-attempt-{attempt}",
                output_schema=output_schema,
                output_last_message=output_path,
                sandbox="workspace-write",
            )
        except Exception as error:
            result["reason"] = f"Luna 执行或 ignored 状态检测失败: {error}"
            result["status"] = "evidence_missing"
            break
        if new_ignored:
            result.update(
                {
                    "status": "evidence_missing",
                    "reason": "模型新增 ignored 文件，拒绝进入 cheap check",
                    "ignored_files": new_ignored,
                    "attempts_exhausted": True,
                }
            )
            break
        try:
            parsed = _parse_json(raw)
            valid_output, output_error = _validate_luna_output(parsed)
        except ValueError as error:
            parsed = None
            valid_output = False
            output_error = str(error)
        _write_json(task_dir / f"attempt-{attempt}-model.json", parsed or {"raw": raw})

        try:
            snapshot = _snapshot_and_checks(
                task_worktree,
                task["checks"],
                task_dir / f"attempt-{attempt}.patch",
                task_dir / f"attempt-{attempt}-checks.json",
            )
        except Exception as error:
            result.update(
                {
                    "status": "evidence_missing",
                    "reason": f"cheap check 或状态检查异常: {error}",
                    "attempts_exhausted": True,
                }
            )
            break
        outside: list[str] = []
        actual_changed_files: list[str] = []
        for path in snapshot["changed_files"]:
            try:
                normalized_path = normalize_scope(path)
                actual_changed_files.append(normalized_path)
                if not path_in_scope(normalized_path, task["write_scope"]):
                    outside.append(path)
            except ValueError:
                outside.append(path)
        declared_outside: list[str] = []
        declared_changed_files: list[str] = []
        if valid_output and isinstance(parsed, dict):
            for path in parsed.get("changed_files", []):
                try:
                    normalized_path = normalize_scope(path)
                    declared_changed_files.append(normalized_path)
                    if not path_in_scope(normalized_path, task["write_scope"]):
                        declared_outside.append(path)
                except ValueError:
                    declared_outside.append(str(path))
        scope_ok = not outside and not declared_outside
        evidence_conflict = (
            valid_output
            and scope_ok
            and set(declared_changed_files) != set(actual_changed_files)
        )
        model_failed = valid_output and isinstance(parsed, dict) and parsed.get("status") in {
            "fail",
            "failed",
        }
        test_failed = not snapshot["checks_ok"] or model_failed
        evidence_complete = (
            process.returncode == 0
            and valid_output
            and not snapshot["patch_error"]
            and bool(snapshot["status_raw"] is not None)
            and not evidence_conflict
        )
        attempt_record = {
            "attempt": attempt,
            "returncode": process.returncode,
            "output_valid": valid_output,
            "output_error": output_error,
            "scope_ok": scope_ok,
            "outside_files": outside,
            "declared_outside_files": declared_outside,
            "declared_changed_files": declared_changed_files,
            "changed_files": snapshot["changed_files"],
            "evidence_conflict": evidence_conflict,
            "checks_ok": snapshot["checks_ok"],
            "model_status": parsed.get("status") if isinstance(parsed, dict) else None,
            "model_failed": model_failed,
            "check_results": snapshot["check_results"],
            "patch_file": str(task_dir / f"attempt-{attempt}.patch"),
        }
        result["attempts"].append(attempt_record)
        previous = {
            **attempt_record,
            "model_result": parsed,
        }
        result.update(
            {
                "changed_files": snapshot["changed_files"],
                "scope_ok": scope_ok,
                "evidence_complete": evidence_complete,
                "conflict": evidence_conflict,
                "test_failed": test_failed,
                "patch_file": str(task_dir / f"attempt-{attempt}.patch"),
                "model_result": parsed,
                "model_returncode": process.returncode,
            }
        )
        if not valid_output or process.returncode != 0:
            result["reason"] = output_error or "Luna 调用失败，证据缺失"
            break
        if not scope_ok:
            result["reason"] = "越界或重叠编辑"
            break
        if evidence_conflict:
            result.update(
                {
                    "status": "evidence_conflict",
                    "reason": "Luna changed_files 与机械 diff 冲突",
                    "evidence_complete": False,
                }
            )
            break
        if snapshot["checks_ok"] and parsed.get("status") in {"pass", "accepted"}:
            result.update({"status": "pass", "evidence_complete": True, "reason": ""})
            break
        if test_failed and attempt < max_attempts:
            continue
        result["status"] = "test_failure" if test_failed else "evidence_missing"
        result["attempts_exhausted"] = test_failed and attempt >= max_attempts
        if model_failed and snapshot["checks_ok"]:
            result["reason"] = "Luna 明确报告失败且重试耗尽"
        elif test_failed:
            result["reason"] = "测试失败且重试耗尽"
        else:
            result["reason"] = "Luna 输出状态冲突"
        break
    result["attempts_remaining"] = False
    result["test_failed"] = result.get("status") == "test_failure"
    result["evidence_complete"] = bool(result.get("evidence_complete"))
    return result


def _workspace_info(workspace_arg: str) -> tuple[Path, str, str]:
    workspace = Path(workspace_arg).expanduser().resolve()
    if not workspace.is_dir():
        raise BlockedError(f"workspace 不存在: {workspace}")
    root = _run(["git", "rev-parse", "--show-toplevel"], cwd=workspace)
    if root.returncode != 0:
        raise BlockedError("workspace 不是 Git 仓库")
    actual_root = Path(root.stdout.strip()).resolve()
    if actual_root != workspace:
        raise BlockedError(f"workspace 必须是 Git 根目录: {actual_root}")
    branch = _run(["git", "symbolic-ref", "--quiet", "--short", "HEAD"], cwd=workspace)
    branch_name = branch.stdout.strip()
    if branch.returncode != 0 or not branch_name:
        raise BlockedError("必须在 feature branch 上运行，detached HEAD 被拒绝")
    if branch_name in {"main", "master"}:
        raise BlockedError("禁止在 main/master 直接运行")
    status = _run(
        ["git", "status", "--porcelain", "--untracked-files=all"], cwd=workspace
    )
    if status.returncode != 0:
        raise BlockedError("无法读取 workspace 状态")
    if status.stdout.strip():
        raise BlockedError("workspace 必须 clean")
    head = _run(["git", "rev-parse", "HEAD"], cwd=workspace)
    if head.returncode != 0 or not head.stdout.strip():
        raise BlockedError("无法读取当前 HEAD")
    return workspace, branch_name, head.stdout.strip()


def _primary_worktree_root(workspace: Path) -> Path:
    """返回 git worktree 注册表中的第一个（primary）worktree 根目录。"""
    process = _run(["git", "worktree", "list", "--porcelain"], cwd=workspace)
    if process.returncode != 0:
        raise BlockedError("无法读取 primary worktree")
    for line in process.stdout.splitlines():
        if line.startswith("worktree "):
            root = Path(line.removeprefix("worktree ").strip()).expanduser().resolve()
            if not root.is_dir():
                raise BlockedError(f"primary worktree 不存在: {root}")
            return root
    raise BlockedError("git worktree 注册表没有 primary worktree")


def _runtime_worktree_path(primary_root: Path, run_id: str, leaf: str) -> Path:
    return (
        primary_root
        / ".worktree"
        / "workspaces"
        / "runtime"
        / "sol_luna"
        / run_id
        / leaf
    )


def _assert_parent_unchanged(workspace: Path, expected_head: str) -> None:
    status = _run(
        ["git", "status", "--porcelain", "--untracked-files=all"], cwd=workspace
    )
    if status.returncode != 0:
        raise BlockedError("无法在最终应用前读取父 workspace 状态")
    if status.stdout.strip():
        raise BlockedError("父 workspace 在运行期间发生变化，拒绝覆盖")
    head = _run(["git", "rev-parse", "HEAD"], cwd=workspace)
    if head.returncode != 0 or head.stdout.strip() != expected_head:
        raise BlockedError("父 workspace HEAD 在运行期间发生变化，拒绝覆盖")


def _create_worktree(workspace: Path, path: Path) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    process = _run(["git", "worktree", "add", "--detach", str(path), "HEAD"], cwd=workspace)
    return process.returncode == 0


def _apply_patch(workspace: Path, patch_path: Path) -> tuple[bool, str]:
    if not patch_path.exists() or not patch_path.read_text(encoding="utf-8").strip():
        return True, ""
    check = _run(
        ["git", "apply", "--check", "--whitespace=nowarn", str(patch_path)],
        cwd=workspace,
    )
    if check.returncode != 0:
        return False, check.stderr or check.stdout
    applied = _run(
        ["git", "apply", "--whitespace=nowarn", str(patch_path)], cwd=workspace
    )
    return applied.returncode == 0, applied.stderr or applied.stdout


def _run_checks(
    workspace: Path, checks: Sequence[Sequence[str]], log_path: Path
) -> tuple[bool, list[dict[str, Any]]]:
    if not checks:
        raise ValueError("全局 check 列表不能为空")
    records: list[dict[str, Any]] = []
    for index, check in enumerate(checks, start=1):
        process = _run_cheap_check(
            workspace, check, timeout=DEFAULT_CHEAP_CHECK_TIMEOUT
        )
        records.append(
            {
                "index": index,
                "argv": list(check),
                "returncode": process.returncode,
                "stdout": _compact(process.stdout),
                "stderr": _compact(process.stderr),
            }
        )
    _write_json(log_path, records)
    return bool(records) and all(item["returncode"] == 0 for item in records), records


def _integration_prompt(
    request: str,
    tasks: Sequence[Mapping[str, Any]],
    checks: Sequence[Sequence[str]],
    spec_ref: str,
    matrix_edges: Sequence[str],
    previous: Mapping[str, Any] | None,
    attempt: int,
) -> str:
    spec_ref, matrix_edges = _traceability_fields(spec_ref, matrix_edges)
    scopes = [scope for task in tasks for scope in task["write_scope"]]
    return f"""你是 Luna integration repair executor。不要创建或委派子 Agent。
请求：{request}
spec-ref: {spec_ref}
matrix-ref: {_canonical_matrix_ref(spec_ref)}
matrix-edge: {json.dumps(matrix_edges, ensure_ascii=False)}
第 {attempt} 次集成修复尝试
允许编辑范围：{json.dumps(scopes, ensure_ascii=False)}
全局检查：{json.dumps(checks, ensure_ascii=False)}
请检查当前已经合并的 task 改动，只修复全局检查失败原因，不要越出允许范围。
上一次结果：{json.dumps(previous or {}, ensure_ascii=False, indent=2)}
最后只输出 JSON：{{"status":"pass 或 fail","summary":"...","changed_files":[]}}
"""


def _integration_repair(
    request: str,
    plan: Mapping[str, Any],
    task_results: Sequence[Mapping[str, Any]],
    workspace: Path,
    run_dir: Path,
    call_log: Path,
    global_checks: Sequence[Sequence[str]],
    max_attempts: int,
    created_worktrees: list[Path],
    spec_ref: str,
    matrix_edges: Sequence[str],
    runtime_base: Path | None = None,
) -> dict[str, Any]:
    if runtime_base is None:
        primary_root = _primary_worktree_root(workspace)
        runtime_base = _runtime_worktree_path(primary_root, run_dir.name, "integration").parent
    integration_path = runtime_base / "integration"
    output_schema = _schema_file(
        run_dir, "luna-integration-output.json", _luna_output_schema()
    )
    result: dict[str, Any] = {"status": "evidence_missing", "attempts": []}
    try:
        spec_ref, matrix_edges = _traceability_fields(spec_ref, matrix_edges)
    except Exception as error:
        result["reason"] = f"集成修复追溯校验失败: {error}"
        return result
    if not _create_worktree(workspace, integration_path):
        result["reason"] = "无法创建 integration registered worktree"
        return result
    created_worktrees.append(integration_path)
    patch_paths = [Path(item["patch_file"]) for item in task_results]
    for patch_path in patch_paths:
        applied, message = _apply_patch(integration_path, patch_path)
        if not applied:
            result["reason"] = f"集成 patch 冲突: {message}"
            result["conflict"] = True
            return result

    scopes = [scope for task in plan["tasks"] for scope in task["write_scope"]]
    initial_checks_ok, initial_check_records = _run_checks(
        integration_path,
        global_checks,
        run_dir / "integration" / "initial-checks.json",
    )
    initial_changed, _, _ = _status_paths(integration_path)
    initial_outside = []
    for path in initial_changed:
        try:
            if not path_in_scope(path, scopes):
                initial_outside.append(path)
        except ValueError:
            initial_outside.append(path)
    result["initial_checks"] = initial_check_records
    result["changed_files"] = initial_changed
    result["scope_ok"] = not initial_outside
    if initial_outside:
        result.update(
            {
                "reason": "集成修复越界",
                "outside_files": initial_outside,
                "conflict": True,
            }
        )
        return result

    if initial_checks_ok:
        combined_patch = run_dir / "integration" / "combined.patch"
        changed, _, patch_error = _capture_patch(integration_path, combined_patch)
        capture_outside = []
        for path in changed:
            try:
                if not path_in_scope(path, scopes):
                    capture_outside.append(path)
            except ValueError:
                capture_outside.append(path)
        if patch_error:
            result.update(
                {
                    "reason": "无法捕获集成 combined patch",
                    "patch_error": patch_error,
                }
            )
            return result
        if capture_outside:
            result.update(
                {
                    "reason": "捕获 combined patch 时检测到越界编辑",
                    "outside_files": capture_outside,
                    "conflict": True,
                }
            )
            return result
        result.update(
            {
                "status": "pass",
                "reason": "集成 worktree 全局检查通过",
                "changed_files": changed,
                "patch_file": str(combined_patch),
                "evidence_complete": True,
                "checks_ok": True,
                "test_failed": False,
            }
        )
        return result

    previous: dict[str, Any] | None = None
    for attempt in range(1, max_attempts + 1):
        try:
            baseline_changed, _, _ = _status_paths(integration_path)
            baseline_fingerprints = {
                path: _path_diff_fingerprint(integration_path, path)
                for path in baseline_changed
            }
        except Exception as error:
            result["reason"] = f"集成修复前 diff 指纹失败: {error}"
            return result
        try:
            prompt = _integration_prompt(
                request,
                plan["tasks"],
                global_checks,
                spec_ref,
                matrix_edges,
                previous,
                attempt,
            )
        except Exception as error:
            result["reason"] = f"集成修复执行前状态或追溯校验失败: {error}"
            return result
        prompt_path = run_dir / "integration" / f"attempt-{attempt}.prompt.md"
        prompt_path.parent.mkdir(parents=True, exist_ok=True)
        prompt_path.write_text(prompt, encoding="utf-8")
        output_path = run_dir / "integration" / f"attempt-{attempt}.json"
        try:
            process, raw, new_ignored = _guarded_model_call(
                LUNA_MODEL,
                prompt,
                integration_path,
                run_dir,
                call_log,
                f"luna-integration-attempt-{attempt}",
                output_schema=output_schema,
                output_last_message=output_path,
                sandbox="workspace-write",
            )
        except Exception as error:
            result["reason"] = f"集成修复执行或 ignored 状态检测失败: {error}"
            return result
        if new_ignored:
            result.update(
                {
                    "status": "evidence_missing",
                    "reason": "模型新增 ignored 文件，拒绝进入 global cheap check",
                    "ignored_files": new_ignored,
                    "attempts_exhausted": True,
                }
            )
            return result
        try:
            parsed = _parse_json(raw)
            valid_output, output_error = _validate_luna_output(parsed)
        except ValueError as error:
            parsed = None
            valid_output = False
            output_error = str(error)
        _write_json(run_dir / "integration" / f"attempt-{attempt}-model.json", parsed or {"raw": raw})
        changed_before_checks, _, _ = _status_paths(integration_path)
        outside_before_checks = []
        for path in changed_before_checks:
            try:
                if not path_in_scope(path, scopes):
                    outside_before_checks.append(path)
            except ValueError:
                outside_before_checks.append(path)
        declared_changed_files: list[str] = []
        declared_outside_files: list[str] = []
        if valid_output and isinstance(parsed, dict):
            for path in parsed.get("changed_files", []):
                try:
                    normalized_path = normalize_scope(path)
                    declared_changed_files.append(normalized_path)
                    if not path_in_scope(normalized_path, scopes):
                        declared_outside_files.append(str(path))
                except ValueError:
                    declared_outside_files.append(str(path))
        if declared_outside_files:
            outside_before_checks = sorted(
                set(outside_before_checks) | set(declared_outside_files)
            )
        try:
            repair_changed_files: list[str] = []
            after_paths = set(changed_before_checks)
            for path in sorted(set(baseline_changed) | after_paths):
                if path not in baseline_fingerprints or _path_diff_fingerprint(
                    integration_path, path
                ) != baseline_fingerprints[path]:
                    repair_changed_files.append(path)
        except Exception as error:
            result["reason"] = f"集成修复后 diff 指纹失败: {error}"
            return result
        evidence_conflict = (
            valid_output
            and not outside_before_checks
            and not declared_outside_files
            and set(declared_changed_files) != set(repair_changed_files)
        )
        if evidence_conflict:
            attempt_result = {
                "attempt": attempt,
                "returncode": process.returncode,
                "output_valid": valid_output,
                "output_error": output_error,
                "changed_files": changed_before_checks,
                "repair_changed_files": repair_changed_files,
                "declared_changed_files": declared_changed_files,
                "declared_outside_files": declared_outside_files,
                "outside_files": outside_before_checks,
                "checks_ok": False,
                "check_results": [],
                "model_status": parsed.get("status") if isinstance(parsed, dict) else None,
                "evidence_conflict": True,
            }
            result["attempts"].append(attempt_result)
            result.update(
                {
                    "status": "evidence_conflict",
                    "reason": "integration Luna changed_files 与机械 diff 冲突",
                    "changed_files": changed_before_checks,
                    "conflict": True,
                    "evidence_complete": False,
                    "scope_ok": True,
                    "checks_ok": False,
                }
            )
            return result
        try:
            checks_ok, check_records = _run_checks(
                integration_path,
                global_checks,
                run_dir / "integration" / f"attempt-{attempt}-checks.json",
            )
            # Checks may create or modify files.  Only this refreshed snapshot
            # may authorize capturing the combined patch.
            changed, _, _ = _status_paths(integration_path)
        except Exception as error:
            result["reason"] = f"global check 或完成后状态检查异常: {error}"
            return result
        outside = []
        for path in changed:
            try:
                if not path_in_scope(path, scopes):
                    outside.append(path)
            except ValueError:
                outside.append(path)
        if outside_before_checks:
            outside = sorted(set(outside) | set(outside_before_checks))
        attempt_result = {
            "attempt": attempt,
            "returncode": process.returncode,
            "output_valid": valid_output,
            "output_error": output_error,
            "changed_files": changed,
            "repair_changed_files": repair_changed_files,
            "declared_changed_files": declared_changed_files,
            "declared_outside_files": declared_outside_files,
            "outside_files": outside,
            "patch_error": "",
            "checks_ok": checks_ok,
            "check_results": check_records,
            "model_status": parsed.get("status") if isinstance(parsed, dict) else None,
            "model_failed": valid_output
            and isinstance(parsed, dict)
            and parsed.get("status") in {"fail", "failed"},
        }
        model_failed = attempt_result["model_failed"]
        result["attempts"].append(attempt_result)
        previous = attempt_result
        result.update(
            {
                "changed_files": changed,
                "outside_files": outside,
                "evidence_complete": process.returncode == 0 and valid_output,
                "conflict": False,
                "scope_ok": not outside,
                "test_failed": not checks_ok or model_failed,
                "checks_ok": checks_ok,
                "final_check_results": check_records,
            }
        )
        if not valid_output or process.returncode != 0:
            result["reason"] = output_error or "集成修复证据缺失"
            return result
        if outside:
            result["reason"] = "集成修复越界"
            return result
        if checks_ok and parsed.get("status") in {"pass", "accepted"}:
            combined_patch = run_dir / "integration" / "combined.patch"
            captured_changed, _, patch_error = _capture_patch(
                integration_path, combined_patch
            )
            if patch_error:
                result.update(
                    {
                        "reason": "无法捕获集成 combined patch",
                        "patch_error": patch_error,
                    }
                )
                return result
            capture_outside = []
            for path in captured_changed:
                try:
                    if not path_in_scope(path, scopes):
                        capture_outside.append(path)
                except ValueError:
                    capture_outside.append(path)
            if capture_outside:
                result.update(
                    {
                        "reason": "捕获 combined patch 时检测到越界编辑",
                        "outside_files": capture_outside,
                        "conflict": True,
                    }
                )
                return result
            result.update(
                {
                    "status": "pass",
                    "reason": "集成修复后全局检查通过",
                    "patch_file": str(combined_patch),
                    "evidence_complete": True,
                    "checks_ok": True,
                }
            )
            return result
        if (not checks_ok or model_failed) and attempt < max_attempts:
            continue
        result["status"] = "test_failure"
        result["attempts_exhausted"] = attempt >= max_attempts
        result["reason"] = (
            "Luna 明确报告失败且重试耗尽"
            if model_failed and checks_ok
            else "全局检查失败且 Luna 重试耗尽"
        )
        return result
    result["reason"] = "集成修复没有产生结果"
    return result


def _sol_escalation(
    reason: str,
    context: Any,
    workspace: Path,
    run_dir: Path,
    call_log: Path,
    spec_ref: str,
    matrix_edges: Sequence[str],
) -> dict[str, Any]:
    """只在 cheap gate 明确升级时调用 Sol 进行只读裁决。"""
    spec_ref, matrix_edges = _traceability_fields(spec_ref, matrix_edges)
    output_schema = _schema_file(
        run_dir, "sol-escalation-output.json", _sol_escalation_schema()
    )
    prompt = f"""你是 Sol escalation reviewer。不要修改文件，不要创建或委派子 Agent。
spec-ref: {spec_ref}
matrix-ref: {_canonical_matrix_ref(spec_ref)}
matrix-edge: {json.dumps(matrix_edges, ensure_ascii=False)}
升级原因：{reason}
当前证据：{json.dumps(context, ensure_ascii=False, indent=2, default=str)}
请给出简短的结构化 JSON，说明是否应 blocked/escalate_sol 以及缺失证据；不要提出未经证据支持的结论。
    """
    output_path = run_dir / "escalation" / f"sol-{uuid.uuid4().hex[:8]}.json"
    try:
        process, raw, new_ignored = _guarded_model_call(
            SOL_MODEL,
            prompt,
            workspace,
            run_dir,
            call_log,
            "sol-escalation",
            output_schema=output_schema,
            output_last_message=output_path,
            sandbox="read-only",
        )
    except Exception as error:
        return {
            "reason": f"Sol escalation 或 ignored 状态检测失败: {error}",
            "returncode": 20,
            "response_file": str(output_path),
        }
    if new_ignored:
        return {
            "reason": "Sol escalation 新增 ignored 文件，拒绝接受证据",
            "returncode": 20,
            "ignored_files": new_ignored,
            "response_file": str(output_path),
        }
    return {
        "reason": reason,
        "returncode": process.returncode,
        "response_file": str(output_path),
        "response": _compact(raw),
    }


def _patch_sha256(path_value: Any) -> str | None:
    if not isinstance(path_value, str) or not path_value:
        return None
    path = Path(path_value)
    if not path.is_file():
        return None
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _task_escalation_digest(task_results: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    """Keep Sol context focused on failures; passing tasks become small receipts."""
    failed: list[dict[str, Any]] = []
    passed: list[dict[str, Any]] = []
    for item in task_results:
        task_id = item.get("task_id") or item.get("id")
        patch_hash = _patch_sha256(item.get("patch_file"))
        is_pass = (
            item.get("status") in {"pass", "accepted", "passed"}
            and item.get("evidence_complete") is True
            and item.get("scope_ok") is not False
            and item.get("checks_ok") is not False
            and not item.get("conflict")
        )
        if is_pass:
            passed.append(
                {
                    "task_id": task_id,
                    "status": item.get("status"),
                    "patch_sha256": patch_hash,
                    "changed_files": item.get("changed_files", []),
                }
            )
            continue
        attempts = item.get("attempts") if isinstance(item.get("attempts"), list) else []
        last_attempt = attempts[-1] if attempts and isinstance(attempts[-1], dict) else {}
        failed_checks = []
        for record in last_attempt.get("check_results", []) or []:
            if isinstance(record, dict) and record.get("returncode") != 0:
                failed_checks.append(
                    {
                        "argv": record.get("argv"),
                        "returncode": record.get("returncode"),
                        "stdout": _compact(record.get("stdout"), 2000),
                        "stderr": _compact(record.get("stderr"), 2000),
                    }
                )
        failed.append(
            {
                "task_id": task_id,
                "status": item.get("status"),
                "reason": item.get("reason"),
                "evidence_complete": item.get("evidence_complete"),
                "scope_ok": item.get("scope_ok"),
                "conflict": item.get("conflict"),
                "checks_ok": item.get("checks_ok"),
                "changed_files": item.get("changed_files", []),
                "declared_changed_files": last_attempt.get("declared_changed_files", []),
                "outside_files": last_attempt.get("outside_files", []),
                "ignored_files": item.get("ignored_files", []),
                "attempts_exhausted": item.get("attempts_exhausted"),
                "failed_checks": failed_checks,
                "patch_sha256": patch_hash,
            }
        )
    return {
        "failed_or_conflicting_tasks": failed,
        "passed_task_receipts": passed,
        "counts": {"failed": len(failed), "passed": len(passed)},
    }


def _model_usage_summary(call_log: Path) -> dict[str, int]:
    usage = {
        "calls": 0,
        "sol_calls": 0,
        "luna_calls": 0,
        "sol_tokens": 0,
        "luna_tokens": 0,
        "total_tokens": 0,
        "unknown_token_calls": 0,
        "invalid_log_records": 0,
    }
    if not call_log.exists():
        return usage
    for line in call_log.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            usage["invalid_log_records"] += 1
            continue
        model = record.get("model") if isinstance(record, dict) else None
        if model not in {SOL_MODEL, LUNA_MODEL}:
            continue
        usage["calls"] += 1
        family = "sol" if model == SOL_MODEL else "luna"
        usage[f"{family}_calls"] += 1
        tokens = record.get("tokens")
        if not isinstance(tokens, int) or isinstance(tokens, bool) or tokens < 0:
            usage["unknown_token_calls"] += 1
            continue
        usage[f"{family}_tokens"] += tokens
        usage["total_tokens"] += tokens
    return usage


def _probe_catalog(catalog_path: str | None = None) -> tuple[subprocess.CompletedProcess[str], Any]:
    if catalog_path:
        catalog_file = Path(catalog_path)
        raw = catalog_file.read_text(encoding="utf-8")
        catalog = _parse_json(raw)
        process = subprocess.CompletedProcess(
            ["catalog", str(catalog_file)], 0, stdout=raw, stderr=""
        )
        return process, catalog
    process = _run(["codex", "debug", "models", "--bundled"])
    raw = process.stdout if process.stdout.strip() else process.stderr
    try:
        catalog = _parse_json(raw)
    except ValueError:
        catalog = raw
    return process, catalog


def _exit_for(verdict: str) -> int:
    return _VERDICTS.get(verdict, 20)


def _print_json(value: Mapping[str, Any]) -> None:
    print(json.dumps(value, ensure_ascii=False, sort_keys=True))


def _cmd_probe(_: argparse.Namespace) -> int:
    process, catalog = _probe_catalog(_.catalog)
    supported = {
        SOL_MODEL: model_supports(catalog, SOL_MODEL, REASONING_EFFORT),
        LUNA_MODEL: model_supports(catalog, LUNA_MODEL, REASONING_EFFORT),
    }
    _print_json(
        {
            "command": "probe",
            "returncode": process.returncode,
            "effort": REASONING_EFFORT,
            "models": supported,
            "accepted": process.returncode == 0 and all(supported.values()),
            "stderr": _compact(process.stderr),
        }
    )
    return 0 if process.returncode == 0 and all(supported.values()) else 20


def _cmd_gate(args: argparse.Namespace) -> int:
    try:
        manifest_path = args.manifest or args.manifest_option
        if not manifest_path:
            raise ValueError("必须指定 manifest 路径")
        manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
        if isinstance(manifest, dict) and "plan" in manifest:
            plan = manifest["plan"]
            results = manifest.get("results", [])
        else:
            raise ValueError("manifest 必须包含 plan 和 results")
        verdict, reasons, retry_tasks = _batch_details(plan, results)
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(f"配置错误: {error}", file=sys.stderr)
        return 2
    print(verdict)
    return _exit_for(verdict)


def _read_request(args: argparse.Namespace) -> str:
    if bool(args.request) == bool(args.request_file):
        raise ValueError("必须且只能指定 --request 或 --request-file")
    if args.request_file:
        request = Path(args.request_file).read_text(encoding="utf-8")
    else:
        request = args.request
    if not isinstance(request, str) or not request.strip():
        raise ValueError("request 不能为空")
    return request.strip()


def _read_checks(raw_checks: Sequence[str]) -> list[list[str]]:
    if not isinstance(raw_checks, (list, tuple)):
        raise ValueError("--check 参数格式无效")
    checks: list[list[str]] = []
    for raw_check in raw_checks:
        try:
            parsed = json.loads(raw_check)
        except json.JSONDecodeError as error:
            raise ValueError(f"--check 必须是 JSON argv 数组: {raw_check!r}") from error
        if not isinstance(parsed, list) or not all(
            isinstance(item, str) and item for item in parsed
        ):
            raise ValueError(f"--check 必须是非空字符串数组: {raw_check!r}")
        checks.append(parsed)
    return checks


def _run_orchestration(args: argparse.Namespace) -> tuple[int, dict[str, Any]]:
    request = _read_request(args)
    spec_ref, matrix_edges = _traceability_fields(
        getattr(args, "spec_ref", None), getattr(args, "matrix_edge", None)
    )
    matrix_ref = getattr(args, "matrix_ref", None)
    if not MIN_EXECUTORS <= args.workers <= MAX_EXECUTORS:
        raise ValueError("--workers 必须在 3 到 5 之间")
    if args.max_luna_attempts < 1:
        raise ValueError("--max-luna-attempts 必须至少为 1")
    checks = _read_checks(args.check or [])
    if not checks:
        raise ValueError("run 必须至少配置一个非空全局 check")
    for check in checks:
        if not is_safe_check(check):
            raise ValueError(f"不安全的全局 check: {check!r}")
    workspace, branch, head = _workspace_info(args.workspace)
    spec_ref, matrix_ref, matrix_edges = _validate_traceability_references(
        workspace, spec_ref, matrix_ref, matrix_edges
    )
    check_sandbox = _check_sandbox_binary()
    primary_root = _primary_worktree_root(workspace)
    if primary_root == workspace:
        raise BlockedError("当前 workspace 不能同时作为 primary worktree")
    run_id = _dt.datetime.now(_dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    run_dir = workspace / ".omx" / "state" / "orchestration" / run_id
    run_dir.mkdir(parents=True, exist_ok=False)
    runtime_base = primary_root / ".worktree" / "workspaces" / "runtime" / "sol_luna" / run_id
    call_log = run_dir / "model-calls.jsonl"
    created_worktrees: list[Path] = []
    summary: dict[str, Any] = {
        "command": "run",
        "run_id": run_id,
        "verdict": "escalate_sol",
        "branch": branch,
        "head": head,
        "workspace": str(workspace),
        "models": {"orchestrator": SOL_MODEL, "executors": LUNA_MODEL},
        "effort": REASONING_EFFORT,
        "workers": args.workers,
        "max_luna_attempts": args.max_luna_attempts,
        "spec_ref": spec_ref,
        "matrix_ref": matrix_ref,
        "matrix_edges": matrix_edges,
        "check_sandbox": check_sandbox,
        "artifacts": str(run_dir),
    }

    try:
        probe_process, catalog = _probe_catalog()
        supported = {
            SOL_MODEL: model_supports(catalog, SOL_MODEL, REASONING_EFFORT),
            LUNA_MODEL: model_supports(catalog, LUNA_MODEL, REASONING_EFFORT),
        }
        summary["probe"] = {"returncode": probe_process.returncode, "models": supported}
        if probe_process.returncode != 0 or not all(supported.values()):
            summary.update(
                {
                    "verdict": "blocked",
                    "reason": "模型目录不支持要求的 xhigh 路由",
                }
            )
            return 20, summary

        schema = _sol_plan_output_schema()
        schema_path = run_dir / "plan-schema.json"
        _write_json(schema_path, schema)
        plan_prompt = f"""你是 Sol Orchestrator。不要写代码，不要创建或委派子 Agent。
用户请求：{request}
spec-ref: {spec_ref}
matrix-ref: {matrix_ref}
matrix-edge: {json.dumps(matrix_edges, ensure_ascii=False)}
请规划恰好 {args.workers} 个可并行、互不重叠的任务。每个 task 必须且只能包含 id、instructions、write_scope、acceptance、checks；acceptance 必须是字符串。
write_scope 必须是工作区相对路径数组，任务之间不得重叠。checks 只能使用 git diff/status、python3 -m pytest、pytest、go test/vet、node --test、npm test 或 npm run test/lint/typecheck/check/build、cargo test/check/clippy、make test/check/lint。
只输出符合 JSON schema 的计划。
        """
        prompt_path = run_dir / "sol-plan.prompt.md"
        prompt_path.write_text(plan_prompt, encoding="utf-8")
        plan_output_path = run_dir / "sol-plan.json"
        try:
            plan_process, plan_raw, new_ignored = _guarded_model_call(
                SOL_MODEL,
                plan_prompt,
                workspace,
                run_dir,
                call_log,
                "sol-plan",
                output_schema=schema_path,
                output_last_message=plan_output_path,
                sandbox="read-only",
            )
        except Exception as error:
            summary.update({"reason": f"Sol 规划或 ignored 状态检测失败: {error}"})
            return 20, summary
        if new_ignored:
            summary.update(
                {
                    "reason": "Sol 规划新增 ignored 文件，拒绝继续执行",
                    "ignored_files": new_ignored,
                }
            )
            return 20, summary
        if plan_process.returncode != 0:
            failure_class = _model_failure_class(plan_process.stderr)
            summary.update(
                {
                    "verdict": "blocked",
                    "reason": f"Sol 规划调用失败: {failure_class}",
                    "model_failure_class": failure_class,
                    "sol_returncode": plan_process.returncode,
                }
            )
            return 20, summary
        try:
            plan = validate_plan(_parse_json(plan_raw), args.workers)
            plan = _validate_plan_scope_targets(workspace, plan)
        except ValueError as error:
            summary.update({"reason": f"Sol 计划证据缺失或无效: {error}"})
            summary["sol_escalation"] = _sol_escalation(
                summary["reason"],
                {"raw_plan": _compact(plan_raw)},
                workspace,
                run_dir,
                call_log,
                spec_ref,
                matrix_edges,
            )
            return 20, summary
        _write_json(run_dir / "plan.normalized.json", plan)
        summary["plan"] = plan

        task_paths: dict[str, Path] = {}
        for task in plan["tasks"]:
            task_path = _runtime_worktree_path(primary_root, run_id, task["id"])
            if not _create_worktree(workspace, task_path):
                summary.update(
                    {
                        "verdict": "blocked",
                        "reason": f"无法创建 task worktree: {task['id']}",
                    }
                )
                return 20, summary
            created_worktrees.append(task_path)
            task_paths[task["id"]] = task_path

        task_results: list[dict[str, Any]] = []
        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            futures = {
                executor.submit(
                    _run_task,
                    request,
                    task,
                    workspace,
                    task_paths[task["id"]],
                    run_dir,
                    call_log,
                    args.max_luna_attempts,
                    spec_ref,
                    matrix_edges,
                ): task["id"]
                for task in plan["tasks"]
            }
            for future in as_completed(futures):
                task_results.append(future.result())
        task_results.sort(key=lambda item: item["task_id"])
        _write_json(run_dir / "task-results.json", task_results)
        gate_verdict, gate_reasons, _ = _batch_details(plan, task_results)
        summary["task_results"] = task_results
        summary["cheap_gate"] = {"verdict": gate_verdict, "reasons": gate_reasons}
        if gate_verdict != "accept":
            summary.update({"verdict": gate_verdict, "reason": "; ".join(gate_reasons)})
            if gate_verdict == "escalate_sol":
                summary["sol_escalation"] = _sol_escalation(
                    summary["reason"],
                    _task_escalation_digest(task_results),
                    workspace,
                    run_dir,
                    call_log,
                    spec_ref,
                    matrix_edges,
                )
            return _exit_for(gate_verdict), summary

        integration = _integration_repair(
            request,
            plan,
            task_results,
            workspace,
            run_dir,
            call_log,
            checks,
            args.max_luna_attempts,
            created_worktrees,
            spec_ref,
            matrix_edges,
            runtime_base=runtime_base,
        )
        _write_json(run_dir / "integration-result.json", integration)
        summary["integration_repair"] = integration
        summary["global_checks_initial"] = integration.get("initial_checks", [])
        summary["global_checks_final"] = integration.get(
            "final_check_results", integration.get("initial_checks", [])
        )
        if integration.get("status") != "pass":
            summary.update(
                {
                    "verdict": "escalate_sol",
                    "reason": integration.get("reason", "集成修复失败"),
                }
            )
            summary["sol_escalation"] = _sol_escalation(
                summary["reason"],
                integration,
                workspace,
                run_dir,
                call_log,
                spec_ref,
                matrix_edges,
            )
            return 20, summary
        try:
            _assert_parent_unchanged(workspace, head)
        except BlockedError as error:
            summary.update(
                {
                    "verdict": "blocked",
                    "reason": str(error),
                }
            )
            return 20, summary
        combined_patch = Path(integration.get("patch_file", ""))
        if not integration.get("patch_file"):
            summary.update({"verdict": "escalate_sol", "reason": "集成缺少 combined patch"})
            summary["sol_escalation"] = _sol_escalation(
                summary["reason"],
                integration,
                workspace,
                run_dir,
                call_log,
                spec_ref,
                matrix_edges,
            )
            return 20, summary
        applied, message = _apply_patch(workspace, combined_patch)
        if not applied:
            summary.update({"verdict": "escalate_sol", "reason": f"combined patch 冲突: {message}"})
            summary["sol_escalation"] = _sol_escalation(
                summary["reason"],
                integration,
                workspace,
                run_dir,
                call_log,
                spec_ref,
                matrix_edges,
            )
            return 20, summary
        summary.update({"verdict": "accept", "reason": "所有 cheap gate 和全局检查通过"})
        return 0, summary
    finally:
        cleanup: list[dict[str, Any]] = []
        for path in reversed(created_worktrees):
            process = _run(["git", "worktree", "remove", "--force", str(path)], cwd=workspace)
            cleanup.append(
                {"path": str(path), "returncode": process.returncode, "stderr": _compact(process.stderr)}
            )
        prune = _run(["git", "worktree", "prune", "--dry-run", "--verbose"], cwd=workspace)
        cleanup.append(
            {
                "prune_dry_run_returncode": prune.returncode,
                "prune_stdout": _compact(prune.stdout),
                "prune_stderr": _compact(prune.stderr),
            }
        )
        summary["cleanup"] = cleanup
        summary["model_usage"] = _model_usage_summary(call_log)
        _write_json(run_dir / "summary.json", summary)


def _cmd_run(args: argparse.Namespace) -> int:
    try:
        code, summary = _run_orchestration(args)
    except BlockedError as error:
        _print_json({"command": "run", "verdict": "blocked", "reason": str(error)})
        return 20
    except (OSError, ValueError) as error:
        _print_json({"command": "run", "verdict": "blocked", "reason": str(error)})
        return 2
    _print_json(summary)
    return code


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Sol/Luna 外层 Codex 编排器")
    subparsers = parser.add_subparsers(dest="command", required=True)
    probe = subparsers.add_parser("probe", help="检查 bundled 模型的 xhigh 支持")
    probe.add_argument("--catalog", help="测试用 JSON catalog；指定后不调用 codex")
    gate = subparsers.add_parser("gate", help="读取 manifest 并运行 cheap gate")
    gate.add_argument("manifest", nargs="?", help="JSON manifest 路径")
    gate.add_argument("--manifest", dest="manifest_option", help="JSON manifest 路径")
    run = subparsers.add_parser("run", help="规划、并行执行和验收 Luna tasks")
    request_group = run.add_mutually_exclusive_group(required=True)
    request_group.add_argument("--request", help="直接提供请求")
    request_group.add_argument("--request-file", help="请求文件")
    run.add_argument("--spec-ref", required=True, help="必填 SPEC 引用")
    run.add_argument("--matrix-ref", required=True, help="必填 canonical TRACEABILITY 引用")
    run.add_argument(
        "--matrix-edge",
        action="append",
        required=True,
        metavar="EDGE_ID",
        help="至少一个 Matrix edge ID，可重复指定",
    )
    run.add_argument("--workspace", default=".", help="feature branch 的 Git 根目录")
    run.add_argument("--workers", type=int, default=MIN_EXECUTORS, help="executor 数量，3 到 5")
    run.add_argument(
        "--check",
        action="append",
        default=[],
        metavar="JSON_ARGV",
        help='重复指定 JSON argv 数组，例如 --check \'["pytest", "-q"]\'',
    )
    run.add_argument(
        "--max-luna-attempts",
        type=int,
        default=2,
        help="每个 Luna task（含 repair）的最大尝试次数",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    if args.command == "probe":
        return _cmd_probe(args)
    if args.command == "gate":
        return _cmd_gate(args)
    if args.command == "run":
        return _cmd_run(args)
    parser.error("未知子命令")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
