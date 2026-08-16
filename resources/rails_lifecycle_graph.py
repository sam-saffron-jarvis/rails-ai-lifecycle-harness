#!/usr/bin/env python3
"""Deterministically inventory Rails lifecycle declarations in the current repository.

Static application-source scanner only: no Rails boot, dependency source, evaluator data,
or task metadata. Output is JSON with stable, sorted fact rows plus an evidence schema.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path.cwd().resolve()
SCAN_ROOTS = ["app/models", "app/jobs", "app/controllers", "lib/rails_ext"]
OPTIONAL_FILES = ["db/schema.rb"]
OPTIONAL_ROOTS = ["db/migrate"]

DECLARATIONS = (
    "has_many_attached", "has_one_attached", "has_many", "has_one", "belongs_to",
    "delegated_type", "has_markdown",
)
CALLBACKS = (
    "before_destroy", "around_destroy", "after_destroy", "after_destroy_commit",
    "before_commit", "after_commit", "after_create_commit", "after_update_commit",
    "after_save_commit", "after_rollback", "after_update", "after_save", "before_save",
)


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def files_to_scan() -> list[Path]:
    found: set[Path] = set()
    for root in SCAN_ROOTS + OPTIONAL_ROOTS:
        p = ROOT / root
        if p.is_dir():
            found.update(x for x in p.rglob("*.rb") if x.is_file())
    for name in OPTIONAL_FILES:
        p = ROOT / name
        if p.is_file():
            found.add(p)
    return sorted(found, key=rel)


def source_digest(paths: list[Path]) -> str:
    h = hashlib.sha256()
    for path in paths:
        name = rel(path).encode()
        data = path.read_bytes()
        h.update(len(name).to_bytes(8, "big")); h.update(name)
        h.update(len(data).to_bytes(8, "big")); h.update(data)
    return h.hexdigest()


def symbol_at(lines: list[str], index: int) -> str:
    # Ruby model/concern files conventionally indent nested class/module declarations.
    # Track namespace declarations by indentation; inner method/block `end`s do not
    # accidentally erase the enclosing model symbol.
    stack: list[tuple[int, str]] = []
    for line in lines[: index + 1]:
        code = line.split("#", 1)[0]
        m = re.match(r"(\s*)(class|module)\s+([A-Z][A-Za-z0-9_:]*)", code)
        if not m:
            continue
        indent = len(m.group(1).expandtabs(2))
        name = m.group(3)
        stack = [(n, s) for n, s in stack if n < indent]
        if "::" in name:
            stack = [(indent, name)]
        else:
            stack.append((indent, name))
    return "::".join(name for _, name in stack) if stack else "(top-level)"


def statement(lines: list[str], i: int) -> str:
    parts = [lines[i].strip()]
    balance = parts[0].count("(") - parts[0].count(")") + parts[0].count("{") - parts[0].count("}")
    j = i
    while j + 1 < len(lines) and j - i < 12 and (balance > 0 or parts[-1].rstrip().endswith(",")):
        j += 1
        part = lines[j].strip()
        parts.append(part)
        balance += part.count("(") - part.count(")") + part.count("{") - part.count("}")
    return " ".join(parts)


def token_option(stmt: str, key: str) -> str | None:
    m = re.search(rf"\b{re.escape(key)}:\s*(?::([A-Za-z_][A-Za-z0-9_!?]*)|[\"']([^\"']+)[\"'])", stmt)
    return (m.group(1) or m.group(2)) if m else None


def target_name(stmt: str, macro: str) -> str:
    tail = stmt[stmt.find(macro) + len(macro):]
    m = re.search(r"\(?\s*(?::([A-Za-z_][A-Za-z0-9_!?]*)|[\"']([^\"']+)[\"'])", tail)
    return (m.group(1) or m.group(2)) if m else "(dynamic)"


def dependent_semantics(macro: str, dependent: str | None) -> tuple[str, str, str, str]:
    mode = dependent or "default/unspecified"
    if macro in ("has_one_attached", "has_many_attached"):
        if dependent is None:
            mode = "purge_later (Rails default)"
            return mode, "destroy attachment rows; attachment after_destroy_commit schedules blob purge", "yes (attachment destroy)", "blob row + stored file purged asynchronously after commit"
        if dependent == "purge_later":
            return mode, "destroy attachment rows; attachment after_destroy_commit schedules blob purge", "yes (attachment destroy)", "blob row + stored file purged asynchronously after commit"
        if dependent == "destroy":
            return mode, "destroy attachment rows only", "yes (attachment destroy)", "attachment removed; blob row + stored file are not purged by dependent callback"
        return mode, f"attachment association dependent={dependent}", "depends on Rails mode", "inspect attachment reflection and blob ownership"
    if dependent == "destroy":
        return mode, "instantiate and destroy associated records", "yes", "n/a"
    if dependent == "destroy_async":
        return mode, "enqueue associated-record destruction after owner commit", "yes, in async destroy", "n/a"
    if dependent in ("delete", "delete_all"):
        return mode, "direct SQL deletion of associated records", "no", "n/a"
    if dependent == "nullify":
        return mode, "direct foreign-key nullification", "no", "n/a"
    return mode, "Rails association default/declared behavior", "not guaranteed", "n/a"


def row(path: Path, line: int, symbol: str, kind: str, owns: str, dependent: str,
        mechanism: str, callbacks: str, attachment: str, declaration: str) -> dict:
    return {
        "source_symbol": symbol,
        "file": rel(path),
        "line": line,
        "kind": kind,
        "owns_or_association": owns,
        "dependent_mode": dependent,
        "deletion_mechanism": mechanism,
        "callbacks_expected": callbacks,
        "attachment_lifecycle": attachment,
        "declaration": re.sub(r"\s+", " ", declaration.strip())[:500],
    }


def scan_file(path: Path) -> list[dict]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    out: list[dict] = []
    for i, line in enumerate(lines):
        code = line.split("#", 1)[0]
        symbol = symbol_at(lines, i)
        stmt = statement(lines, i)

        dm = re.match(r"\s*(has_many_attached|has_one_attached|has_many|has_one|belongs_to|delegated_type|has_markdown)\b", code)
        if dm:
            macro = dm.group(1)
            name = target_name(stmt, macro)
            dep = token_option(stmt, "dependent")
            mode, mechanism, callbacks, attachment = dependent_semantics(macro, dep)
            flags = []
            if token_option(stmt, "polymorphic") == "true" or re.search(r"\bpolymorphic:\s*true", stmt): flags.append("polymorphic")
            as_name = token_option(stmt, "as")
            if as_name: flags.append(f"polymorphic-as:{as_name}")
            through = token_option(stmt, "through")
            if through: flags.append(f"through:{through}")
            owns = f"{macro} {name}" + (f" [{', '.join(flags)}]" if flags else "")
            out.append(row(path, i + 1, symbol, "declaration", owns, mode, mechanism, callbacks, attachment, stmt))

        cm = re.match(r"\s*(" + "|".join(CALLBACKS) + r")\b", code)
        if cm:
            cb = cm.group(1)
            event = "after outer transaction commit" if "commit" in cb else ("after transaction rollback" if "rollback" in cb else "record lifecycle")
            out.append(row(path, i + 1, symbol, "callback", cb, "n/a", event,
                           "yes when record lifecycle reaches callback; direct delete/delete_all bypass record callbacks",
                           "callback body may enqueue/purge; inspect declaration", stmt))

        # Direct/batch deletion calls. Exclude Hash/String #delete unless receiver strongly resembles AR lifecycle.
        for m in re.finditer(r"(?P<recv>[A-Za-z_@][A-Za-z0-9_@.:()!?]*(?:\.[A-Za-z_][A-Za-z0-9_!?]*(?:\([^)]*\))?)*)\.(?P<op>destroy!|destroy|destroy_all|delete_all|delete)\b", code):
            recv, op = m.group("recv"), m.group("op")
            if op == "delete" and any(x in recv for x in ("params", "cookies", "session", "options", "attributes")):
                continue
            callbacks = "yes" if op.startswith("destroy") else "no"
            mechanism = "instantiate/destroy each record" if op == "destroy_all" else ("record destroy" if op.startswith("destroy") else "direct SQL/record deletion")
            out.append(row(path, i + 1, symbol, "deletion_call", f"{recv}.{op}", "call-site", mechanism, callbacks, "follow downstream attachment callbacks only when destroy callbacks run", code))

        for m in re.finditer(r"(?P<job>[A-Z][A-Za-z0-9_:]*Job)(?:\.set\([^)]*\))?\.perform_later\b", code):
            out.append(row(path, i + 1, symbol, "job_enqueue", m.group("job"), "job class/config dependent", "perform_later", "n/a", "enqueue timing depends on Active Job transaction-commit policy", code))

        if re.search(r"\b(?:transaction|with_transaction_returning_status)\s+do\b", code):
            out.append(row(path, i + 1, symbol, "transaction", "transaction block", "n/a", "outer commit controls registered after_commit work", "after_commit runs only on commit; after_rollback only on rollback", "jobs/purges may be deferred or dropped according to policy", code))

        # Schema-level polymorphic ownership and foreign keys are facts, not inferred solutions.
        sm = re.search(r"\bt\.(?:references|belongs_to)\s+[:\"']([A-Za-z_][A-Za-z0-9_]*)[\"']?.*\bpolymorphic:\s*true", code)
        if sm:
            out.append(row(path, i + 1, symbol, "schema_edge", sm.group(1), "database reference", "type + id polymorphic reference", "n/a", "historical class names live in the type column", code))

    return out


def main() -> int:
    if any((ROOT / x).exists() for x in ("verification_test.rb", "solution.patch")):
        # Repository roots should not be evaluator/task directories.
        print("refusing evaluator/task directory as repository root", file=sys.stderr)
        return 2
    paths = files_to_scan()
    if not paths:
        print("no Rails application source found in allowed roots", file=sys.stderr)
        return 2
    rows = [r for p in paths for r in scan_file(p)]
    rows.sort(key=lambda r: (r["file"], r["line"], r["kind"], r["owns_or_association"]))
    packet = {
        "schema_version": "rails_lifecycle_graph/v1",
        "scan_policy": {
            "repository_root": ".",
            "included_roots": SCAN_ROOTS,
            "optional_roots": OPTIONAL_ROOTS,
            "optional_files": OPTIONAL_FILES,
            "excluded": ["test", "spec", "vendor", "gems", "evaluator", "task metadata", "solution artifacts"],
        },
        "source_manifest_sha256": source_digest(paths),
        "source_file_count": len(paths),
        "row_count": len(rows),
        "rows": rows,
        "required_solver_evidence_schema": {
            "direct_edges": [{"owner": "string", "resource": "string", "destroy_path": "string", "callbacks": "yes|no|conditional", "evidence": "file:line"}],
            "indirect_edges": [{"from": "string", "via": "string", "to": "string", "evidence": "file:line"}],
            "historical_edges": [{"current_owner": "string", "historical_owner": "string", "destroy_path": "string", "evidence": "file:line"}],
            "transaction_boundaries": [{"operation": "string", "commit_behavior": "string", "rollback_behavior": "string", "evidence": "file:line"}],
            "focused_existing_test": {"path": "string", "command": "string"},
            "minimal_patch_plan": [{"file": "string", "fact_addressed": "string"}],
        },
    }
    json.dump(packet, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
