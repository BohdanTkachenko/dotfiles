#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/scripts/_common.sh"

NIX_CONFIG_FILE="$HOME_MANAGER_DIR/user-config.nix"

select_profile() {
  if [ -n "${HOME_MANAGER_PROFILE:-}" ]; then
    log item "Profile"
    log ok "Configuration profile already selected: '$HOME_MANAGER_PROFILE'. Skipping."
    return 0
  fi

  log item "Please choose the configuration profile you want to apply."

  local chosen_config=""
  while true; do
    for key in "${!PROFILES[@]}"; do
      local value="${PROFILES[$key]}"
      local display_text="${value#*;}"
      printf "      ${COLOR_BLUE}%s) %s${COLOR_RESET}\n" "${key}" "$display_text"
    done
    printf "⌨️  ${COLOR_BLUE}Choose a profile:${COLOR_RESET} "
    
    read -r -n 1 choice
    printf "\n\n"

    local lower_choice
    lower_choice=${choice,,}

    if [[ -v "PROFILES[$lower_choice]" ]]; then
      local value="${PROFILES[$lower_choice]}"
      chosen_config="${value%%;*}"
      log success "You have selected the '$chosen_config' configuration."
      break
    else
      log error "Invalid option '${choice}'. Please try again."
    fi
  done

  if [ -z "$chosen_config" ]; then
    log error "No configuration was chosen. Aborting."
    exit 1
  fi

  log item "Saving selection to '$HOME_MANAGER_PROFILE_FILE'..."
  echo "HOME_MANAGER_PROFILE=\"$chosen_config\"" >> "$ENV_FILE"
  log ok "Selection saved."

  export HOME_MANAGER_PROFILE="$chosen_config"
}

function write_config() {
  log item "$NIX_CONFIG_FILE"

  local formatted_profiles
  formatted_profiles=$(printf '"%s" ' "${profiles[@]}")

  cat > "$NIX_CONFIG_FILE" << EOF
{
  # Edit in ${BASH_SOURCE[0]}
  username = "$USER";
  homeDirectory = "$HOME";
  sourceDir = "$HOME_MANAGER_DIR";
  hosttypes = [${formatted_profiles}];
}
EOF

  log ok "Updated"
}

main() {
  log section "Configuration"

  select_profile
  write_config
}

main
