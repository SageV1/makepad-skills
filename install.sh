#!/bin/bash
#
# Makepad Skills Installer
# https://github.com/ZhangHanDong/makepad-skills
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ZhangHanDong/makepad-skills/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/ZhangHanDong/makepad-skills/main/install.sh | bash -s -- --with-hooks
#   curl -fsSL https://raw.githubusercontent.com/ZhangHanDong/makepad-skills/main/install.sh | bash -s -- --target /path/to/project
#   curl -fsSL https://raw.githubusercontent.com/ZhangHanDong/makepad-skills/main/install.sh | bash -s -- --agent your_agent
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REPO_URL="https://github.com/ZhangHanDong/makepad-skills"
BRANCH="main"
TARGET_DIR=""
WITH_HOOKS=false
TARGET_AGENT="claude-code"
TEMP_DIR=""

# Print colored message
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Print banner
print_banner() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}      ${GREEN}Makepad Skills Installer v3.0.0${NC}         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}      Agent Skills for Makepad                ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --target DIR      Install to specific directory (default: current directory)"
    echo "  --with-hooks      Also install and configure hooks (Claude Code only)"
    echo "  --agent AGENT     Set agent (default: claude-code)"
    echo "  --list-agents     Show supported agents and exit"
    echo "  --branch BRANCH   Use specific branch (default: main)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Install to current project"
    echo "  $0"
    echo ""
    echo "  # Install with hooks enabled"
    echo "  $0 --with-hooks"
    echo ""
    echo "  # Install to specific project"
    echo "  $0 --target /path/to/my-makepad-project"
    echo ""
    echo "  # Install for a specific agent"
    echo "  $0 --agent your_agent"
    echo ""
}

list_agents() {
    echo "Supported agents:"
    echo "  - claude-code (default)"
    echo "  - codex"
    echo "  - gemini"
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target)
                TARGET_DIR="$2"
                shift 2
                ;;
            --with-hooks)
                WITH_HOOKS=true
                shift
                ;;
            --agent)
                if [[ -z "$2" ]]; then
                    error "Missing value for --agent (codex|claude-code|gemini)"
                fi
                TARGET_AGENT="$2"
                shift 2
                ;;
            --list-agents)
                list_agents
                exit 0
                ;;
            --codex)
                TARGET_AGENT="codex"
                shift
                ;;
            --claude|--claude-code)
                TARGET_AGENT="claude-code"
                shift
                ;;
            --branch)
                BRANCH="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

normalize_agent() {
    case "$TARGET_AGENT" in
        codex)
            ;;
        gemini)
            ;;
        claude|claude-code)
            TARGET_AGENT="claude-code"
            ;;
        *)
            error "Unknown agent: $TARGET_AGENT (expected codex, claude-code, or gemini)"
            ;;
    esac
}

agent_label() {
    if [[ "$TARGET_AGENT" == "codex" ]]; then
        echo "Codex"
    elif [[ "$TARGET_AGENT" == "gemini" ]]; then
        echo "Gemini CLI"
    else
        echo "Claude Code"
    fi
}

skills_base_dir() {
    if [[ "$TARGET_AGENT" == "codex" ]]; then
        echo "$TARGET_DIR/.codex"
    elif [[ "$TARGET_AGENT" == "gemini" ]]; then
        echo "$TARGET_DIR/.gemini"
    else
        echo "$TARGET_DIR/.claude"
    fi
}

skills_dir() {
    echo "$(skills_base_dir)/skills"
}

# Check dependencies
check_deps() {
    info "Checking dependencies..."

    # Need either curl or git
    if ! command -v curl &> /dev/null && ! command -v git &> /dev/null; then
        error "Either curl or git is required. Please install one of them first."
    fi

    # Need unzip if using curl
    if command -v curl &> /dev/null && ! command -v unzip &> /dev/null; then
        if ! command -v git &> /dev/null; then
            error "unzip is required when using curl. Please install unzip or git."
        fi
        warn "unzip not found, will use git instead"
    fi

    success "Dependencies OK"
}

# Determine target directory
determine_target() {
    if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$(pwd)"
    fi

    # Expand to absolute path
    TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || error "Target directory does not exist: $TARGET_DIR"

    info "Target directory: $TARGET_DIR"

    # Check if it looks like a project directory
    if [[ ! -f "$TARGET_DIR/Cargo.toml" ]]; then
        warn "No Cargo.toml found. This may not be a Rust/Makepad project."
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Clone or download repository
download_skills() {
    info "Downloading makepad-skills..."

    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Try ZIP download first (no git required)
    local ZIP_URL="https://github.com/ZhangHanDong/makepad-skills/archive/refs/heads/${BRANCH}.zip"

    if command -v curl &> /dev/null; then
        curl -fsSL "$ZIP_URL" -o "$TEMP_DIR/makepad-skills.zip" 2>/dev/null
        if [[ $? -eq 0 && -f "$TEMP_DIR/makepad-skills.zip" ]]; then
            unzip -q "$TEMP_DIR/makepad-skills.zip" -d "$TEMP_DIR" 2>/dev/null
            mv "$TEMP_DIR/makepad-skills-${BRANCH}" "$TEMP_DIR/makepad-skills"
            success "Downloaded via ZIP"
            return
        fi
    fi

    # Fallback to git clone
    if command -v git &> /dev/null; then
        git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/makepad-skills" 2>/dev/null && \
            success "Downloaded via git" && return
    fi

    error "Failed to download. Please check your internet connection."
}

# Install skills
install_skills() {
    local SKILLS_DIR
    SKILLS_DIR="$(skills_dir)"

    info "Installing skills for $(agent_label) to $SKILLS_DIR..."

    # Create base directory if needed
    mkdir -p "$(skills_base_dir)"

    # Backup existing skills if present
    if [[ -d "$SKILLS_DIR" ]]; then
        local BACKUP_DIR="$SKILLS_DIR.backup.$(date +%Y%m%d%H%M%S)"
        warn "Existing skills found. Backing up to $BACKUP_DIR"
        mv "$SKILLS_DIR" "$BACKUP_DIR"
    fi

    # Copy skills
    cp -r "$TEMP_DIR/makepad-skills/skills" "$SKILLS_DIR"

    success "Skills installed"
}

# Install hooks
install_hooks() {
    if [[ "$WITH_HOOKS" != true ]]; then
        return
    fi

    if [[ "$TARGET_AGENT" != "claude-code" ]]; then
        warn "Hooks are only supported in Claude Code. Skipping hook installation."
        return
    fi

    local BASE_DIR
    BASE_DIR="$(skills_base_dir)"
    local HOOKS_SRC="$TEMP_DIR/makepad-skills/.claude/hooks"
    local HOOKS_DST="$BASE_DIR/hooks"
    local SETTINGS_SRC="$TEMP_DIR/makepad-skills/.claude/settings.json"
    local SETTINGS_DST="$BASE_DIR/settings.json"

    info "Installing hooks to $HOOKS_DST..."

    # Create hooks directory
    mkdir -p "$HOOKS_DST"

    # Copy hook scripts
    if [[ -d "$HOOKS_SRC" ]]; then
        cp "$HOOKS_SRC"/*.sh "$HOOKS_DST/" 2>/dev/null || true
        chmod +x "$HOOKS_DST"/*.sh 2>/dev/null || true
        success "Hook scripts installed"
    else
        warn "Hook scripts source not found in .claude/hooks/, skipping"
    fi

    # Install settings.json (with UserPromptSubmit hook)
    if [[ -f "$SETTINGS_SRC" ]]; then
        if [[ -f "$SETTINGS_DST" ]]; then
            # Backup existing settings
            local BACKUP_SETTINGS="$SETTINGS_DST.backup.$(date +%Y%m%d%H%M%S)"
            warn "Existing settings.json found. Backing up to $BACKUP_SETTINGS"
            cp "$SETTINGS_DST" "$BACKUP_SETTINGS"
        fi
        cp "$SETTINGS_SRC" "$SETTINGS_DST"
        success "settings.json installed with UserPromptSubmit hook"
    else
        warn "settings.json source not found, creating default..."
        # Create default settings.json
        cat > "$SETTINGS_DST" << 'SETTINGS_EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/makepad-skill-router.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash|Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre-tool.sh"
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
            "command": "bash .claude/hooks/post-bash.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
        success "Default settings.json created"
    fi

    echo ""
    info "Hooks are now configured for auto-triggering!"
    echo "  - UserPromptSubmit: Routes queries to appropriate skills"
    echo "  - PreToolUse: Detects Makepad version"
    echo "  - PostToolUse: Self-correction on errors"
}

# Print summary
print_summary() {
    local SKILLS_DIR
    SKILLS_DIR="$(skills_dir)"

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Agent: $(agent_label)"
    echo "  Skills installed to: $SKILLS_DIR"
    echo ""
    echo "  Structure (19 Skills):"
    echo "  ├── # Core Skills (16)"
    echo "  ├── makepad-basics/          (App structure)"
    echo "  ├── makepad-dsl/             (DSL syntax)"
    echo "  ├── makepad-layout/          (Layout system)"
    echo "  ├── makepad-widgets/         (Widget components)"
    echo "  ├── makepad-event-action/    (Event handling)"
    echo "  ├── makepad-animation/       (Animation)"
    echo "  ├── makepad-shaders/         (Shaders & visual effects)"
    echo "  ├── makepad-platform/        (Platform support)"
    echo "  ├── makepad-font/            (Font, typography)"
    echo "  ├── makepad-splash/          (Splash scripting)"
    echo "  ├── robius-*/                (5 Robius patterns with _base/)"
    echo "  ├── molykit/                 (AI chat toolkit)"
    echo "  ├── # Extended Skills (3)"
    echo "  ├── makepad-deployment/      (Build & package)"
    echo "  ├── makepad-reference/       (Troubleshooting)"
    echo "  └── evolution/               (Self-improvement)"
    echo ""
    echo "  Quick Start:"
    if [[ "$TARGET_AGENT" == "codex" ]]; then
        echo "  1. Open your project with Codex"
        echo "  2. Ask: \"Create a simple Makepad counter app\""
    elif [[ "$TARGET_AGENT" == "gemini" ]]; then
        echo "  1. Open your project with Gemini CLI"
        echo "  2. Ask: \"Create a simple Makepad counter app\""
    else
        echo "  1. Open your project with Claude Code"
        echo "  2. Ask: \"Create a simple Makepad counter app\""
    fi
    echo ""
    if [[ "$TARGET_AGENT" != "claude-code" ]]; then
        if [[ "$WITH_HOOKS" == true ]]; then
            echo -e "  ${YELLOW}Hooks are only supported in Claude Code.${NC}"
            echo ""
        fi
    else
        if [[ "$WITH_HOOKS" == true ]]; then
            echo -e "  ${GREEN}Hooks are installed and auto-configured!${NC}"
            echo "  Skills will auto-trigger based on your questions."
            echo ""
        else
            echo "  To enable auto-triggering hooks, run:"
            echo "  curl -fsSL https://raw.githubusercontent.com/ZhangHanDong/makepad-skills/main/install.sh | bash -s -- --with-hooks --target $TARGET_DIR"
            echo ""
        fi
    fi
    echo "  Documentation: https://github.com/ZhangHanDong/makepad-skills"
    echo ""
}

# Main
main() {
    print_banner
    parse_args "$@"
    normalize_agent
    check_deps
    determine_target
    download_skills
    install_skills
    install_hooks
    print_summary
}

main "$@"
