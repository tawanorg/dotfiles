---
name: engineer
description: Start, inspect, pause or resume the persistent personal Jira-to-draft-PR engineering runtime.
disable-model-invocation: true
---

Run `engineer start --host claude` for assigned Jira work. This is a persistent
terminal process; `engineer install-service --host claude` installs the optional
login/wake supervisor. Use `engineer status`, `pause`, `resume`, or `cancel <task>`
for controls. Read `~/.local/share/engineer/PLAYBOOK.md` for the canonical workflow
and its adjacent README for setup/troubleshooting. Never substitute a prompt-only
loop for the installed runtime.
