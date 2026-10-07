---
name: dotagent
description: Start, inspect, pause or resume the persistent personal Jira-to-draft-PR engineering runtime.
disable-model-invocation: true
---

Run `dotagent start --host claude` for assigned Jira work. This is a persistent
terminal process; `dotagent install-service --host claude` installs the optional
login/wake supervisor. Use `dotagent status`, `pause`, `resume`, or `cancel <task>`
for controls. Read `~/.local/share/dotagent/PLAYBOOK.md` for the canonical workflow
and the README in https://github.com/tawanorg/dotagent for setup/troubleshooting.
Select project state and brain from the current directory or use `--project NAME`. Never substitute a prompt-only
loop for the installed runtime.
