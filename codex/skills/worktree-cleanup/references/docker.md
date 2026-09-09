# Docker resources belonging to removed worktrees

## Establish ownership and dependencies

Use the current Docker context; if it targets a remote daemon, establish that remote cleanup is intended before mutation. If Docker is unavailable, finish authorised filesystem cleanup and report Docker as skipped.

Inventory containers, including stopped containers, then inspect only the required fields:

- `com.docker.compose.project`
- `com.docker.compose.project.working_dir`
- `com.docker.compose.project.config_files`
- Volume and bind mounts, network membership, published ports and image IDs.

Map exact Compose project labels to registered worktree paths. Names alone are not proof of ownership. Inspect Compose labels on volumes and networks too; record exact resource IDs/names before deletion. Preserve unlabelled or ambiguous resources unless ownership can be established independently.

Check whether retained worktrees use a candidate stack through shared ports, environment configuration, Compose overrides, process configuration or symlinks. Emit only variable names, hostnames and ports when inspecting connection settings; redact credentials and tokens. Absence of a `.env` file or a dedicated stack does not by itself prove independence.

A shared Compose project may contain containers launched from several worktrees. Preserve any required shared service and its data, even if its labels refer to a removed worktree. When ownership or continued use remains ambiguous, keep the resource and ask a focused question while continuing independent cleanup.

## Remove the established targets

1. Build an exact allowlist of removable containers, volumes and networks. Before stopping anything, inspect all containers, including stopped ones, for volume references; inspect network membership. Exclude resources used by containers outside the allowlist.
2. Gracefully stop allowlisted containers, then remove them. Explicit `docker stop` and `docker rm` calls avoid requiring Compose files or environment values. `docker compose down` is suitable only when the entire resolved project is authorised for removal and no kept service shares it.
3. Delete only allowlisted volumes after their references are removed. Volume removal permanently discards their data; it must be within the user's authorised scope. Preserve host bind-mount directories except where they are already authorised worktree deletion targets.
4. Remove allowlisted networks once empty. Keep resources that acquire new external references during execution; inspect the changed state instead of forcing deletion.
5. If the user included images or broad project Docker cleanup, remove exact image tags/IDs proven to belong to the removed project builds and unused by retained containers. Recheck all containers. Use `docker image rm` without force; preserve shared base images and ambiguous untagged images. A project-name prefix is a discovery hint, not sufficient ownership evidence.

Use scoped resource removal, never global `docker system prune`, `docker volume prune`, `docker image prune` or builder-cache pruning as a shortcut. Cache cleanup requires separate scope and evidence; Docker build caches often span projects.

Verify exact target absence and retained container state. `docker system df` before/after can describe Docker's reported usage; it does not prove that the host has reclaimed the same amount from its virtual disk.
