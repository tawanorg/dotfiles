---
name: worktree-cleanup
description: Remove finished Git worktrees to free local disk space, optionally including their Docker containers, volumes, networks and built images. Use when cleaning up worktrees while preserving selected active work.
---

# Worktree cleanup

Operate on the current repository's registered worktrees, wherever they live on disk. Keep the main checkout, selected active worktrees, their dependencies and unrelated projects intact.

## Resolve the scope

1. Read `git worktree list --porcelain` and identify the main checkout, current checkout and user-selected keep/remove paths. Match a supplied basename or branch only when it identifies one worktree uniquely. Resolve paths before acting.
2. Use the user's existing instructions: “keep only X” authorises removing the other linked worktrees; “remove X” authorises only X. With no selection, ask which worktrees to keep while completing read-only inventory. Do not infer that a worktree is finished from its age, clean status or branch name.
3. Treat Docker cleanup as optional: include it when requested, including “worktrees plus Docker” or “containers, volumes, etc.” Read [references/docker.md](references/docker.md) before planning that part. Worktree deletion alone does not authorise deleting databases.
4. If the current checkout is a removal target, move tool execution to the main checkout first. Retain local branches and commits unless branch deletion is separately requested.

## Inspect before removal

For every removal target, collect:

- Exact path and branch, lock status, and `git status --porcelain --untracked-files=all`.
- Ignored files that may hold unique work or data: local environment files, local databases, uploads and exports. Distinguish these from reproducible dependencies and build output.
- Approximate allocated size with `du -sk`, when practical. Label this as pre-deletion usage; shared files and Docker virtual disks can make it differ from space actually reclaimed.
- Running development processes and dependencies used by kept worktrees. Check symlink targets and shared local services, not just directory ownership.

Preserve targets containing unexpected application edits or unique untracked data until the user explicitly authorises discarding them or they are safely archived. “Done worktrees” alone does not establish that newly discovered edits are disposable. Continue removing other authorised targets while this is unresolved.

Small agent settings and notes may be archived outside every removal target, without another approval. Verify the archive and report its path. Keep secrets out of command output and use restrictive permissions for any archive containing sensitive files. Archiving small metadata must not become a large backup that defeats the cleanup.

Before mutation, give a short, concrete statement of what will be kept and removed, including data volumes if selected. Existing explicit authorisation is sufficient; ask again only for an unresolved keep selection, unexpected data loss or ambiguous shared dependency.

## Execute

1. Recheck target membership and status immediately before removal. If new edits appear, exclude that target and resolve them.
2. Stop only positively identified development servers/watchers serving removal targets, using graceful termination. Check PID, command and working directory together. A `node`/`npm` process or a working directory match alone is insufficient: preserve agent runtimes, MCP servers and shared tooling. Confirm stopped servers have exited before removing their files.
3. Perform authorised Docker cleanup using the reference, before removing Compose files needed to establish ownership.
4. Run `git worktree remove <exact-path>` from a retained checkout for each target. Use `--force` only for specifically authorised discarded changes or verified archived metadata; treat other failures as evidence to inspect. Keep locked worktrees unless their removal was explicitly authorised. Avoid recursive directory deletion as a fallback.
5. For already-missing worktree directories, inspect `git worktree prune --dry-run` and prune only when every affected entry is an authorised stale target.

Use argument arrays in scripts or correctly quoted literal paths. Never select deletion targets through broad directory globs. Cleanup does not require a repository commit or PR.

## Verify and report

Re-read `git worktree list --porcelain`; verify every removed path is absent and every kept path remains. Confirm kept changes and dependencies survived, accounting for edits made concurrently by the user or another agent. For Docker, verify the exact removed resources are absent and preserved resources remain.

Report removed worktree/resource counts, retained worktrees, any skipped targets and archive paths. Give measured or clearly qualified disk savings; do not add Docker image sizes as if layers were independent. Leave global caches and unrelated projects outside the cleanup scope.

Example invocation: `$worktree-cleanup keep only marketing-funding-review; remove the other worktrees and their Docker resources.`
