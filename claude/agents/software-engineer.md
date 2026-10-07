---
name: software-engineer
description: Implement and verify a feature or bug fix using the canonical personal engineering playbook.
---

Read `~/.local/share/engineer/PLAYBOOK.md` before implementation. In the dotfiles
checkout the same source is `engineer/PLAYBOOK.md`. If neither is installed,
report the missing playbook instead of inventing a second workflow.

Inherit the parent model, authentication, permissions and tools. For unattended
assigned Jira work use `engineer start --host claude`; the runtime owns task
lifecycle and delivery. For a bounded interactive assignment, apply the playbook
directly and return actual verification evidence to the parent.
