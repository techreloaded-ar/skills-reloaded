#!/usr/bin/env bash
set -euo pipefail

# ─── Skills Reloaded Installer ────────────────────────────────────────────────
# Installs skills-reloaded commands for Claude Code, Codex, Gemini CLI, OpenCode
# Usage: curl -fsSL https://raw.githubusercontent.com/Smarello/skills-reloaded/main/install.sh | bash
# ──────────────────────────────────────────────────────────────────────────────

REPO_BASE="https://raw.githubusercontent.com/Smarello/skills-reloaded/main/skills-reloaded"
FILES=("explore-context.md" "create-skills.md" "create-agents.md" "update-skills.md")

# ─── Colors ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Tool definitions ────────────────────────────────────────────────────────
TOOL_NAMES=("Claude Code" "Codex" "Gemini CLI" "OpenCode")
TOOL_PATHS=("$HOME/.claude/commands" "$HOME/.codex/prompts" "$HOME/.gemini/commands" "$HOME/.config/opencode/commands")
TOOL_COUNT=${#TOOL_NAMES[@]}

# ─── Cleanup ──────────────────────────────────────────────────────────────────
TMPDIR_INSTALL=""
cleanup() {
  [[ -n "$TMPDIR_INSTALL" && -d "$TMPDIR_INSTALL" ]] && rm -rf "$TMPDIR_INSTALL"
}
trap cleanup EXIT

# ─── Frontmatter parser ──────────────────────────────────────────────────────
# Sets: FM_NAME, FM_DESC, FM_BODY
parse_frontmatter() {
  local file="$1"
  FM_NAME=""
  FM_DESC=""
  FM_BODY=""

  local first_line
  first_line=$(head -n 1 "$file")

  if [[ "$first_line" == "---" ]]; then
    # Has frontmatter — use awk to split header and body
    local header
    header=$(awk 'NR==1{next} /^---$/{exit} {print}' "$file")
    FM_BODY=$(awk 'BEGIN{found=0} /^---$/{found++; if(found==2){skip=1; next}} skip{print}' "$file")

    while IFS= read -r line; do
      if [[ "$line" =~ ^name:[[:space:]]*(.*) ]]; then
        FM_NAME="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^description:[[:space:]]*(.*) ]]; then
        FM_DESC="${BASH_REMATCH[1]}"
      fi
    done <<< "$header"
  else
    # No frontmatter — derive name from filename, description from first heading
    FM_NAME=$(basename "$file" .md)

    while IFS= read -r line; do
      if [[ "$line" =~ ^#[[:space:]]+(.*) ]]; then
        FM_DESC="${BASH_REMATCH[1]}"
        break
      fi
    done < "$file"

    FM_BODY=$(<"$file")
  fi
}

# ─── TOML converter ──────────────────────────────────────────────────────────
to_toml() {
  local desc="$1"
  local body="$2"

  # Escape backslashes and triple quotes in body
  body="${body//\\/\\\\}"
  body="${body//\"\"\"/\"\"\\\"}"

  # Escape backslashes in description, then escape double quotes
  desc="${desc//\\/\\\\}"
  desc="${desc//\"/\\\"}"

  printf 'description = "%s"\n\nprompt = """\n%s\n"""\n' "$desc" "$body"
}

# ─── Install for a specific tool ─────────────────────────────────────────────
install_for_tool() {
  local tool_index="$1"
  local tool_name="${TOOL_NAMES[$tool_index]}"
  local tool_path="${TOOL_PATHS[$tool_index]}"

  mkdir -p "$tool_path"

  local installed=()

  for file in "${FILES[@]}"; do
    local src="$TMPDIR_INSTALL/$file"
    local cmd_name
    cmd_name=$(basename "$file" .md)

    parse_frontmatter "$src"

    case "$tool_index" in
      0) # Claude Code — copy verbatim
        cp "$src" "$tool_path/$file"
        installed+=("$file")
        ;;
      1|3) # Codex / OpenCode — strip frontmatter, write body as .md
        printf '%s\n' "$FM_BODY" > "$tool_path/$file"
        installed+=("$file")
        ;;
      2) # Gemini CLI — convert to .toml
        local toml_file="${cmd_name}.toml"
        to_toml "$FM_DESC" "$FM_BODY" > "$tool_path/$toml_file"
        installed+=("$toml_file")
        ;;
    esac
  done

  echo ""
  printf "  ${GREEN}✓${RESET} ${BOLD}%s${RESET} ${DIM}→ %s${RESET}\n" "$tool_name" "$tool_path"
  for f in "${installed[@]}"; do
    printf "    ${DIM}%s${RESET}\n" "$f"
  done
}

# ─── Interactive multi-select menu ────────────────────────────────────────────
interactive_menu() {
  local selected=()
  local cursor=0

  for ((i = 0; i < TOOL_COUNT; i++)); do
    selected+=(1) # all selected by default
  done

  # Reconnect stdin from tty for pipe mode (curl | bash)
  if [[ ! -t 0 ]]; then
    exec < /dev/tty
  fi

  # Check if we have a real terminal
  if [[ ! -t 0 ]]; then
    fallback_menu
    return
  fi

  # Hide cursor
  printf '\033[?25l'
  # Restore cursor on exit from this function
  trap 'printf "\033[?25h"' RETURN

  local draw_menu
  draw_menu() {
    # Move cursor up to redraw (except first draw)
    if [[ "${1:-}" == "redraw" ]]; then
      printf "\033[%dA" "$((TOOL_COUNT + 1))"
    fi

    for ((i = 0; i < TOOL_COUNT; i++)); do
      local checkbox
      if [[ ${selected[$i]} -eq 1 ]]; then
        checkbox="${GREEN}[x]${RESET}"
      else
        checkbox="[ ]"
      fi

      local line
      if [[ $i -eq $cursor ]]; then
        line="${CYAN}❯${RESET} ${checkbox} ${BOLD}${TOOL_NAMES[$i]}${RESET} ${DIM}(${TOOL_PATHS[$i]})${RESET}"
      else
        line="  ${checkbox} ${TOOL_NAMES[$i]} ${DIM}(${TOOL_PATHS[$i]})${RESET}"
      fi

      printf "\r\033[K%b\n" "$line"
    done
    printf "\r\033[K${DIM}  ↑↓ navigate  SPACE toggle  ENTER confirm${RESET}"
  }

  draw_menu "first"

  while true; do
    # Read single keypress
    IFS= read -rsn1 key

    case "$key" in
      $'\x1b') # Escape sequence
        read -rsn2 seq
        case "$seq" in
          '[A') # Up arrow
            ((cursor > 0)) && ((cursor--))
            ;;
          '[B') # Down arrow
            ((cursor < TOOL_COUNT - 1)) && ((cursor++))
            ;;
        esac
        ;;
      ' ') # Space — toggle
        if [[ ${selected[$cursor]} -eq 1 ]]; then
          selected[$cursor]=0
        else
          selected[$cursor]=1
        fi
        ;;
      '') # Enter — confirm
        printf "\n\n"
        # Return selected indices
        SELECTED_TOOLS=()
        for ((i = 0; i < TOOL_COUNT; i++)); do
          if [[ ${selected[$i]} -eq 1 ]]; then
            SELECTED_TOOLS+=("$i")
          fi
        done
        return
        ;;
    esac

    draw_menu "redraw"
  done
}

# ─── Fallback numbered menu for non-interactive terminals ─────────────────────
fallback_menu() {
  echo ""
  for ((i = 0; i < TOOL_COUNT; i++)); do
    printf "  %d) %s (%s)\n" "$((i + 1))" "${TOOL_NAMES[$i]}" "${TOOL_PATHS[$i]}"
  done
  echo ""
  printf "Enter tool numbers separated by spaces (e.g. 1 2 3), or 'all': "
  read -r choices

  SELECTED_TOOLS=()
  if [[ "$choices" == "all" ]]; then
    for ((i = 0; i < TOOL_COUNT; i++)); do
      SELECTED_TOOLS+=("$i")
    done
  else
    for choice in $choices; do
      local idx=$((choice - 1))
      if [[ $idx -ge 0 && $idx -lt $TOOL_COUNT ]]; then
        SELECTED_TOOLS+=("$idx")
      fi
    done
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo ""
  printf "${BOLD}${CYAN}  Skills Reloaded Installer${RESET}\n"
  printf "${DIM}  Install AI coding commands for your tools${RESET}\n"
  echo ""

  # Check for curl or wget
  local downloader=""
  if command -v curl &>/dev/null; then
    downloader="curl"
  elif command -v wget &>/dev/null; then
    downloader="wget"
  else
    printf "${RED}Error: curl or wget is required but neither was found.${RESET}\n"
    exit 1
  fi

  # Create temp directory
  TMPDIR_INSTALL=$(mktemp -d)

  # Download files
  printf "${DIM}  Downloading commands...${RESET}\n"
  local download_failed=0
  for file in "${FILES[@]}"; do
    local url="$REPO_BASE/$file"
    local dest="$TMPDIR_INSTALL/$file"

    if [[ "$downloader" == "curl" ]]; then
      if ! curl -fsSL "$url" -o "$dest" 2>/dev/null; then
        printf "  ${RED}✗${RESET} Failed to download %s\n" "$file"
        download_failed=1
      fi
    else
      if ! wget -q "$url" -O "$dest" 2>/dev/null; then
        printf "  ${RED}✗${RESET} Failed to download %s\n" "$file"
        download_failed=1
      fi
    fi
  done

  if [[ $download_failed -eq 1 ]]; then
    printf "\n${RED}  Some downloads failed. Please check your connection and try again.${RESET}\n"
    exit 1
  fi

  printf "  ${GREEN}✓${RESET} Downloaded %d commands\n" "${#FILES[@]}"
  echo ""

  # Tool selection
  printf "${BOLD}  Select tools to install for:${RESET}\n\n"
  interactive_menu

  if [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
    printf "${YELLOW}  No tools selected. Exiting.${RESET}\n"
    exit 0
  fi

  # Install
  printf "${BOLD}  Installing...${RESET}\n"
  for tool_index in "${SELECTED_TOOLS[@]}"; do
    install_for_tool "$tool_index"
  done

  # Summary
  echo ""
  printf "${GREEN}${BOLD}  Done!${RESET} Installed ${#FILES[@]} commands for ${#SELECTED_TOOLS[@]} tool(s).\n"
  echo ""
}

main "$@"
