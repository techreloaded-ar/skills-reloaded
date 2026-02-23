#!/usr/bin/env bash
set -euo pipefail

# ─── Skills Reloaded Installer ────────────────────────────────────────────────
# ─── Skills Reloaded Installer ────────────────────────────────────────────────
# Installs skills-reloaded skills for Claude Code, Codex, Gemini CLI, OpenCode, GitHub Copilot, Generic / Other
# Usage: curl -fsSL https://raw.githubusercontent.com/techreloaded-ar/skills-reloaded/main/install.sh | bash
# ──────────────────────────────────────────────────────────────────────────────

REPO_BASE="https://raw.githubusercontent.com/techreloaded-ar/skills-reloaded/main"
SKILL_NAMES=("explore-context" "create-skills" "create-agents")

# ─── Colors ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Tool definitions ────────────────────────────────────────────────────────
TOOL_NAMES=("Claude Code" "Codex" "Gemini CLI" "OpenCode" "GitHub Copilot" "Generic / Other")
TOOL_PATHS=(".claude/skills" ".agents/skills" ".gemini/skills" ".opencode/skills" ".github/skills" ".skills-reloaded/skills")
TOOL_COUNT=${#TOOL_NAMES[@]}

# ─── Legacy paths for cleanup ────────────────────────────────────────────────
OLD_TOOL_PATHS=(".claude/commands" ".codex/prompts" ".gemini/commands" ".config/opencode/commands" "" "")
OLD_EXTENSIONS=("md" "md" "toml" "md" "" "")
OLD_NAMES=("explore-context" "create-skills" "create-agents" "update-skills")

# ─── Cleanup ──────────────────────────────────────────────────────────────────
TMPDIR_INSTALL=""
cleanup() {
  [[ -n "$TMPDIR_INSTALL" && -d "$TMPDIR_INSTALL" ]] && rm -rf "$TMPDIR_INSTALL"
}
trap cleanup EXIT

# ─── Install for a specific tool ─────────────────────────────────────────────
install_for_tool() {
  local tool_index="$1"
  local tool_name="${TOOL_NAMES[$tool_index]}"
  local tool_path="${TOOL_PATHS[$tool_index]}"

  for skill_name in "${SKILL_NAMES[@]}"; do
    local dest_dir="$tool_path/$skill_name"
    mkdir -p "$dest_dir"
    cp "$TMPDIR_INSTALL/$skill_name/SKILL.md" "$dest_dir/SKILL.md"
  done

  echo ""
  printf "  ${GREEN}✓${RESET} ${BOLD}%s${RESET} ${DIM}→ %s${RESET}\n" "$tool_name" "$tool_path"
  for skill_name in "${SKILL_NAMES[@]}"; do
    printf "    ${DIM}%s/SKILL.md${RESET}\n" "$skill_name"
  done
}

# ─── Remove legacy files ─────────────────────────────────────────────────────
cleanup_legacy() {
  local tool_index="$1"
  local old_path="${OLD_TOOL_PATHS[$tool_index]}"
  
  # Skip se il path è vuoto (per nuove opzioni senza legacy)
  if [[ -z "$old_path" ]]; then
    return
  fi
  
  local ext="${OLD_EXTENSIONS[$tool_index]}"
  local removed=0

  for old_name in "${OLD_NAMES[@]}"; do
    local old_file="$old_path/$old_name.$ext"
    if [[ -f "$old_file" ]]; then
      rm "$old_file"
      ((removed++))
    fi
  done

  # Remove directory if empty (don't delete user's other files)
  if [[ -d "$old_path" ]] && [[ -z "$(ls -A "$old_path" 2>/dev/null)" ]]; then
    rmdir "$old_path"
  fi

  if [[ $removed -gt 0 ]]; then
    printf "  ${DIM}Cleaned up %d legacy file(s) from %s${RESET}\n" "$removed" "$old_path"
  fi
}

# ─── Interactive multi-select menu ────────────────────────────────────────────
interactive_menu() {
  local selected=()
  local cursor=0

  for ((i = 0; i < TOOL_COUNT; i++)); do
    selected+=(0) # all deselected by default
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
      printf "\033[%dA" "$TOOL_COUNT"
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
  printf "${DIM}  Install AI coding skills for your tools${RESET}\n"
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

  # Download skills
  printf "${DIM}  Downloading skills...${RESET}\n"
  local download_failed=0
  for skill_name in "${SKILL_NAMES[@]}"; do
    local url="$REPO_BASE/skills/$skill_name/SKILL.md"
    local dest_dir="$TMPDIR_INSTALL/$skill_name"
    mkdir -p "$dest_dir"
    local dest="$dest_dir/SKILL.md"

    if [[ "$downloader" == "curl" ]]; then
      if ! curl -fsSL "$url" -o "$dest" 2>/dev/null; then
        printf "  ${RED}✗${RESET} Failed to download %s\n" "$skill_name"
        download_failed=1
      fi
    else
      if ! wget -q "$url" -O "$dest" 2>/dev/null; then
        printf "  ${RED}✗${RESET} Failed to download %s\n" "$skill_name"
        download_failed=1
      fi
    fi
  done

  if [[ $download_failed -eq 1 ]]; then
    printf "\n${RED}  Some downloads failed. Please check your connection and try again.${RESET}\n"
    exit 1
  fi

  printf "  ${GREEN}✓${RESET} Downloaded %d skills\n" "${#SKILL_NAMES[@]}"
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
    cleanup_legacy "$tool_index"
  done

  # Summary
  echo ""
  printf "${GREEN}${BOLD}  Done!${RESET} Installed %d skills for %d tool(s).\n" "${#SKILL_NAMES[@]}" "${#SELECTED_TOOLS[@]}"
  echo ""
}

main "$@"
