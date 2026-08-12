---
name: agent-workspace-linux
description: Drive an isolated hidden Linux desktop and workspace-owned browser.
disable-model-invocation: true
---

# Agent Workspace Linux

Drive GUI apps through the `agent-workspace-linux` MCP server inside its hidden
Xvfb desktop. Keep all input, screenshots, clipboard access, and browser control
inside that workspace rather than the host Hyprland session.

## Boundaries

- Use the hidden workspace only. Never target the host desktop, host Chrome,
  keyboard, pointer, or focus.
- Call `mcp_permissions` before the first mutation.
- Obtain explicit approval for purchases, messages, account changes, or other
  consequential external actions.
- Require the user's hidden-workspace acknowledgement before starting one.
- Stop workspaces created for a completed task unless the user asks to keep them.

## Workflow

1. Orient with `mcp_agent_context`, `mcp_session_brief`, `mcp_permissions`,
   `workspace_doctor`, `workspace_list`, and `workspace_status`.
2. Start or reuse a workspace only after the acknowledgement gate is satisfied.
3. Prefer semantic browser or accessibility actions. Use screenshots and
   coordinate input only as a fallback.
4. Observe after every meaningful action and verify the intended result.
5. Collect requested artifacts, then stop the workspace.

Load only the MCP tool schemas needed for the current phase. Do not enumerate
the entire server up front.
