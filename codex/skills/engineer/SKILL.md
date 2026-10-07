---
name: engineer
description: Start, inspect, pause or resume the persistent personal Jira-to-draft-PR engineering runtime.
---

Use the installed `engineer` CLI. Default invocation: `engineer start --host codex`.
It is a persistent process; keep it running in a terminal or install its supervisor
service with `engineer install-service --host codex`. Use `engineer status` to report
actual progress. Forward pause/resume/cancel requests to the corresponding command.

The canonical workflow is `~/.local/share/engineer/PLAYBOOK.md` (source:
`engineer/PLAYBOOK.md` in dotfiles). Read it for engineering decisions, and the
adjacent README for installation or troubleshooting. Do not replace the runtime
with a prompt loop or claim completion from a worker response.
