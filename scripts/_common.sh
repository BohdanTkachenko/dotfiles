#!/usr/bin/env bash
set -eu

ENV_FILE="$HOME/.config/home-manager.env"

declare -A PROFILES=(
    [w]="workstation;🖥️  Workstation"
    [l]="lenovo-z16;💻 Lenovo Z16"
)

LOG_FILE=/tmp/chezmoi_scripts.log
LAST_COMMAND_LOG_FILE=/tmp/chezmoi_scripts_last_command.log

COLOR_RESET='\033[0m'
COLOR_BOLD_PURPLE='\033[1;35m'
COLOR_BOLD_CYAN='\033[1;36m'
# COLOR_BOLD='\033[1m'
COLOR_BOLD_RED='\033[1;31m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
# COLOR_CYAN='\033[0;36m'

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "❌ [ERROR] Environment file not found at '$ENV_FILE'. Please run the main install.sh script first." >&2
    exit 1
fi

# The env file should define this variable.
if [ -z "${HOME_MANAGER_DIR:-}" ]; then
    echo "❌ [ERROR] HOME_MANAGER_DIR is not set in '$ENV_FILE'. The file might be corrupt." >&2
    exit 1
fi

# A simple, unified logger.
# Usage:
#   log <type> <message>
# Example:
#   log section "Starting process..."
#   log item "Checking file..."
#   log ok "File is correct."
log() {
  local type="$1"; shift
  local text="$*"

  if [ -z "$type" ]; then
    echo "log ERROR: Missing required arguments. Usage: log <type> <text>" >&2
    return 1
  fi

  local icon=""
  local color=""
  local level=2
  case $type in
    section)  icon="⚙️ "; color="${COLOR_BOLD_PURPLE}"; level=0 ;;
    item)     icon="🔷";  color="${COLOR_BOLD_CYAN}"; level=1 ;;
    mismatch) icon="🟡";  color="${COLOR_YELLOW}" ;;
    ok)       icon="🟢";  color="${COLOR_GREEN}" ;;
    info)     icon="ℹ️ "; color="${COLOR_BLUE}" ;;
    success)  icon="✅";  color="${COLOR_GREEN}" ;;
    error)    icon="❌";  color="${COLOR_RED}" ;;
    warning)  icon="⚠️ "; color="${COLOR_YELLOW}" ;;
    critical) icon="‼️ "; color="${COLOR_BOLD_RED}" ;;
    skip)     icon="⏭️ ";  color="${COLOR_YELLOW}" ;;
    cancel)   icon="⏹️ "; color="${COLOR_RED}" ;;
    *)
      echo "log ERROR: Unknown log type: '${type}'" >&2
      return 1
      ;;
  esac

  

  local prefix=""
  case $level in
    0) prefix="\n${icon}" ;;
    1) prefix=" ╰─${icon}" ;;
    2) prefix="    ╰── ${icon}" ;;
  esac

  echo -e "${prefix} ${color}${text}${COLOR_RESET}" | tee -a ${LOG_FILE} >&2
}

ELEVATED_WARNED=false
warn_once_elevated() {
  if [ "$ELEVATED_WARNED" = false ]; then
    log warning "This script may require elevated permissions to run."
    ELEVATED_WARNED=true
  fi
}

get_os() {
  case "$(uname -s)" in
    Linux)
      if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [ -n "$VARIANT_ID" ]; then
          echo "$VARIANT_ID"
        else
          echo "$ID"
        fi
      else
        echo "linux"
      fi
      ;;
    *)
      echo "other"
      ;;
  esac
}

is_os_based_on_ostree() {
  if [ -f /run/ostree-booted ]; then
    return 0
  fi

  return 1
}

is_os_supports_nix() {
  is_os_based_on_ostree
}
