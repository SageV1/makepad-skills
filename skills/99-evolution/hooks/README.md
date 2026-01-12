# Makepad Skills Hooks

This folder contains Claude Code hooks to enable automatic triggering of makepad-evolution features.

## Setup

Copy the hooks configuration to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/pre-tool.sh \"$TOOL_NAME\" \"$TOOL_INPUT\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/post-bash.sh \"$TOOL_OUTPUT\" \"$EXIT_CODE\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/session-end.sh"
          }
        ]
      }
    ]
  }
}
```

Replace `${SKILLS_DIR}` with the actual path to your `.claude/skills` directory.

## Hooks Overview

| Hook | Trigger | Purpose |
|------|---------|---------|
| `pre-tool.sh` | Before Bash/Write/Edit | Detect Makepad version, check project style |
| `pre-ui-edit.sh` | Before Write/Edit (UI code) | Remind AI to provide complete UI specifications |
| `post-bash.sh` | After Bash command | Detect compilation errors for self-correction |
| `session-end.sh` | Session ends | Prompt for evolution review |

## How It Works

1. **Version Detection** (`pre-tool.sh`): On first tool use, detects Makepad branch from Cargo.toml
2. **UI Specification Checker** (`pre-ui-edit.sh`): When modifying UI code, checks for complete layout specifications and reminds AI to include all necessary properties (padding, spacing, alignment)
3. **Error Detection** (`post-bash.sh`): Monitors `cargo build/run` output for errors
4. **Evolution Prompt** (`session-end.sh`): Reminds to capture learnings at session end
