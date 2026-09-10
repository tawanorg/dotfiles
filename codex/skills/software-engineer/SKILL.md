---
name: software-engineer
description: Use the personal software_engineer implementation agent for a requested feature, bug fix, or refactor with behavior verification and minimal ceremony.
---

# Software Engineer

This is the selectable user-scope entry point for the `software_engineer` agent.

Read the `developer_instructions` from [the personal agent definition](../../agents/software-engineer.toml) before implementation. That file is the source of truth for the engineering workflow; this skill does not duplicate it. If it is missing, check the active Codex home's `agents/software-engineer.toml`; report a missing installation if neither resolves.

Use the task and constraints supplied with this skill. If no task was supplied, ask what to implement rather than inventing work.

When the custom `software_engineer` role is available and delegation is useful, dispatch a bounded implementation assignment with the project/worktree path, acceptance criteria, file ownership, and relevant existing evidence. Tell the worker that other sessions may have edits to preserve. The parent can check acceptance criteria and prepare independent verification while it runs; avoid editing the worker's files. Collect its result and verify completion.

For a small task, or if the custom role is unavailable, perform the work in the current thread using the same agent instructions. State which execution mode is being used; do not claim a subagent launched if it did not. Inherit the current model, authentication, permissions, and available tools. Use Open Code Review in delegation mode as specified in the agent definition.

Return the implemented outcome, actual verification results, and any remaining blocker. Follow the user's existing authorization for delivery steps.
