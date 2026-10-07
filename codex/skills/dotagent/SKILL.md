---
name: dotagent
description: Start, inspect, pause or resume the persistent personal Jira-to-draft-PR engineering runtime.
---

Use the installed `dotagent` CLI. Default invocation: `dotagent start --host codex`.
It is a persistent process; keep it running in a terminal or install its supervisor
service with `dotagent install-service --host codex`. Use `dotagent status` to report
actual progress. Forward pause/resume/cancel requests to the corresponding command.

The canonical workflow is `~/.local/share/dotagent/PLAYBOOK.md`, sourced from
`dotagent/PLAYBOOK.md` in [tawanorg/dotagent](https://github.com/tawanorg/dotagent).
Read that repository's README for setup. Current-directory project configuration
selects isolated state and brain memory; `--project NAME` selects explicitly.
Do not replace the runtime with a prompt loop or claim completion from a worker response.
