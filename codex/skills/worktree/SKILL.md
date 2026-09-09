---
name: worktree
description: Create a Git worktree for the current project and continue a supplied task in its isolated checkout. Use for $worktree, a /worktree request delivered as text, or an explicit request to work in a separate Git worktree.
---

# Worktree

Create the checkout, verify it, and do any accompanying task there. A bare invocation creates a checkout and reports its location; it does not invent a coding task.

## Invocation

- `$worktree` — create a new worktree from the current committed HEAD.
- `$worktree fix the login redirect` — create a worktree and carry out that task there.
- Honor a supplied branch, base ref, destination, or request to include current changes.

This is an agent skill, not a registered native slash command. `$worktree` is the Codex CLI/IDE invocation; ChatGPT supports selecting skills with `@`. Treat `/worktree` as equivalent when the host delivers it as prompt text, but do not claim the skill adds a slash-menu entry.

## Inspect and choose

1. Read applicable repository instructions. Resolve the repository root with `git rev-parse --show-toplevel`, inspect `git status --short --branch`, and run `git worktree list --porcelain`. If there is no Git repository or no initial commit, explain the blocker without initializing or committing unrelated files.
2. Use the explicitly requested base, otherwise the current committed `HEAD`. Resolve the base to a commit before creation. Do not silently substitute `main`, pull, or rebase.
3. For a new branch, derive a short slug from the task. Follow repository branch conventions, otherwise use `codex/<slug>`; for a bare invocation use `codex/worktree-<timestamp>`. Validate with `git check-ref-format --branch` and avoid existing refs.
4. Honor a destination or established repository worktree convention. Otherwise use a sibling directory `<repo-name>-worktrees/<slug>` outside the source checkout. Avoid nesting in any existing checkout. Check for an existing path and Git registration; use a suffix for a generated-name collision. Never overwrite or repurpose an existing directory.
5. If an explicitly requested existing branch is already checked out elsewhere, use that checkout for the requested task when appropriate. Report its path and inspect its changes before editing. Do not force the same branch into two worktrees.

## Create and preserve

For a new branch, use the equivalent of:

```sh
git -C "$repo_root" worktree add -b "$branch_name" "$worktree_path" "$base_commit"
```

For a requested existing branch that is not checked out, omit `-b` and use that branch as the final argument. Use detached HEAD only when requested. Quote paths and pass task-derived text as arguments, never as executable shell text.

- Leave the source checkout's branch, index, tracked modifications, and untracked files intact. By default the new worktree contains committed files only; report this when the source is dirty.
- If the user explicitly wants current changes included, copy them without moving or stashing the source. Use a binary-capable Git diff against HEAD and `git apply --check` before applying in the destination; this transfers the net tracked changes without promising to preserve staging boundaries. Include deletions and separately copy relevant untracked files without overwriting destination files. If conflicts prevent transfer, retain both checkouts and report what remains unapplied.
- Do not reset, clean, force-checkout, auto-commit, or delete branches to make creation succeed. After a failure, inspect the actual state before retrying; do not force-remove a partially created checkout.

## Prepare and continue

Read the new checkout's instructions and setup documentation. Run the documented setup needed for an accompanying task. For a bare invocation, avoid expensive dependency installation unless the user or repository instructions request it. Do not start an extra server unnecessarily; when needed, use an available port.

Git-created worktrees do not automatically copy ignored configuration or execute Codex environment setup hooks. If `.worktreeinclude` exists, use it as the user's allowlist for ignored local setup files:

- Interpret patterns with Git-ignore semantics, including exclusions; do not approximate a complex file with shell globs.
- Copy only matching ignored files within the source repository; skip symlinks and never overwrite destination files or print secrets.
- If correct matching cannot be established, report the uncopied setup files instead of broadening the copy. Do not copy all ignored files, dependencies, or caches by default.
- Copy an ignored regular `AGENTS.override.md` from the repository root when present, without overwriting an existing destination file, to preserve local instructions.

Verify registration, the destination's branch and starting commit, and that the source checkout remains unchanged by your operations. Distinguish any transferred local changes from the starting commit.

Use the absolute worktree path as the working directory for every subsequent command and target edits there. A shell `cd` in one tool call does not retarget later calls. Continue the supplied task through its normal validation. Creating a worktree alone does not authorize pushing, opening a PR, merging, or deleting another checkout.

Report the path, branch, base, and any setup still needed. Do not claim to have switched the app's chat environment: a worktree created through Git is not automatically Codex-managed. For actual Local/Worktree chat Handoff, use the app's supported control when available or explain where it is; do not edit Codex's internal state to simulate it.

## Reference

For questions about managed worktrees, Handoff, or current UI behavior, consult [OpenAI's worktree documentation](https://learn.chatgpt.com/docs/environments/git-worktrees). This skill creates ordinary Git worktrees; the app's managed lifecycle and cleanup do not automatically apply.
