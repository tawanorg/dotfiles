---
name: software-engineer
description: Implement and verify a feature or bug fix using the canonical personal engineering playbook.
---

Read `~/.local/share/dotagent/PLAYBOOK.md` before implementation. Its source is
`dotagent/PLAYBOOK.md` in the standalone `tawanorg/dotagent` repository. If neither is installed,
report the missing playbook instead of inventing a second workflow.

Inherit the parent model, authentication, permissions and tools. For unattended
assigned Jira work use `dotagent start --host claude`; the runtime owns task
lifecycle and delivery. For a bounded interactive assignment, apply the playbook
directly and return actual verification evidence to the parent.
