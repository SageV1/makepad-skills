# Makepad Skills Hooks

This folder contains Claude Code hooks to enable automatic triggering of makepad-evolution features.

## Prerequisites

- `jq` must be installed for JSON parsing

## Setup

Copy the hooks configuration to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|Update",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/skills/hooks/pre-ui-edit.sh"
          }
        ]
      }
    ]
  }
}
```

**Important**: Claude Code passes data via stdin as JSON, not command line arguments. Do not add `"$TOOL_NAME"` or `"$TOOL_INPUT"` to the command.

## Hooks Overview

| Hook | Trigger | Purpose |
|------|---------|---------|
| `pre-ui-edit.sh` | Before Write/Edit/Update | Check UI code completeness, block if missing critical properties |
| `post-bash.sh` | After Bash command | Detect compilation errors for self-correction |
| `session-end.sh` | Session ends | Prompt for evolution review |

## How It Works

### UI Specification Checker (`pre-ui-edit.sh`)

When modifying UI code (Button, Label, TextInput, RoundedView), the hook:

1. Reads JSON input from stdin
2. Extracts `tool_input.new_string` (for Edit) or `tool_input.content` (for Write)
3. Checks for 5 critical properties: width, height, padding, draw_text, wrap
4. If completeness < 3/5, outputs warning to stderr and exits with code 2 to block

**Input format** (from Claude Code via stdin):
```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "src/app.rs",
    "old_string": "...",
    "new_string": "<Button> { text: \"Click\" }"
  }
}
```

**Exit codes**:
- `0`: Allow tool execution
- `2`: Block tool execution and show message to Claude
