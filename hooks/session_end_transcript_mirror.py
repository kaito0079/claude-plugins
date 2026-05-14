#!/usr/bin/env python3
"""Stop hook: mirror worktree-scoped transcripts into the main worktree's project dir.

Claude Code writes session transcripts to ~/.claude/projects/<encoded-cwd>/<session>.jsonl,
where <encoded-cwd> is the absolute cwd with `/` and `.` replaced by `-`. When the user
works in git worktrees, every worktree gets its own project dir and transcripts get
scattered across them.

This hook copies (or refreshes) the current session's transcript to the **main
worktree's project dir** every time the Stop hook fires (per assistant turn), so
tools that scan one project dir — e.g., the bundled `/fewer-permission-prompts`
skill — can see the full history of the repository across all worktrees.

Idempotency: we skip the copy when the target mtime is not older than the source.
This makes the per-turn cost a single stat() call for unchanged transcripts.

Safety:
- Exits silently if cwd is not a git repo, if main worktree resolution fails, or
  if cwd already equals the main worktree (nothing to mirror).
- Never raises into Claude Code. All exceptions are swallowed and exit 0.
- Atomic write via tempfile + os.replace, so a concurrent reader never sees a
  half-written jsonl.
"""
from __future__ import annotations

import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile


PROJECTS_ROOT = pathlib.Path.home() / ".claude" / "projects"


def encode_cwd(path: str) -> str:
    """Match Claude Code's encoding: replace `/` and `.` with `-`."""
    return path.replace("/", "-").replace(".", "-")


def main_worktree_for(cwd: str) -> str | None:
    """Return the main worktree's absolute path for the repo containing `cwd`.

    The main worktree is the first `worktree` entry in `git worktree list --porcelain`,
    which is also the repository's primary checkout. Linked worktrees come after.
    """
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "worktree", "list", "--porcelain"],
            capture_output=True, text=True, timeout=2,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    for line in out.stdout.splitlines():
        if line.startswith("worktree "):
            return line[len("worktree "):].strip() or None
    return None


def mirror(src: pathlib.Path, dst: pathlib.Path) -> bool:
    """Copy src to dst if dst is missing or older. Returns True when a copy happened."""
    try:
        src_mtime = src.stat().st_mtime
    except OSError:
        return False
    if dst.exists():
        try:
            if dst.stat().st_mtime >= src_mtime:
                return False
        except OSError:
            pass
    dst.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(
        prefix=f".{dst.name}.", suffix=".tmp", dir=str(dst.parent)
    )
    os.close(fd)
    try:
        shutil.copy2(src, tmp_path)
        os.replace(tmp_path, dst)
    except Exception:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise
    return True


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    cwd = payload.get("cwd") or ""
    transcript = payload.get("transcript_path") or ""
    session_id = payload.get("session_id") or ""

    if not cwd or not transcript or not session_id:
        return 0
    if not os.path.isdir(cwd):
        return 0
    src = pathlib.Path(transcript)
    if not src.exists():
        return 0

    main_wt = main_worktree_for(cwd)
    if not main_wt:
        return 0
    if os.path.realpath(cwd) == os.path.realpath(main_wt):
        return 0  # already in the main worktree, nothing to mirror

    dst = PROJECTS_ROOT / encode_cwd(main_wt) / f"{session_id}.jsonl"
    try:
        mirror(src, dst)
    except Exception:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
