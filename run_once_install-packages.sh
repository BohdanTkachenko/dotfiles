#!/usr/bin/env bash
set -eu

FONTS_DIR="$HOME/.local/share/fonts"

BREW_APPS=(
  "bat"
  "direnv"
  "eza"
  "fd"
  "gemini-cli"
  "gh"
  "glab"
  "micro"
  "ripgrep"
  "tealdeer"
  "trash-cli"
  "ugrep"
  "yq"
  "zoxide"
)

declare -A FLATPAK_APPS
FLATPAK_APPS["org.gnome.Platform/x86_64/47"]=""
FLATPAK_APPS["it.mijorus.gearlever"]="https://github.com/BohdanTkachenko/gearlever/releases/download/cli-update-url/it.mijorus.gearlever.flatpak"

declare -A APPIMAGE_APPS
APPIMAGE_APPS["Beeper"]="https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop" 

GNOME_EXTENSIONS=(
  "dash-to-dock@micxgx.gmail.com"
  "search-light@icedman.github.com"
)

declare -A NERD_FONTS
NERD_FONTS["DroidSansMono"]="DroidSansMNerdFontMono-Regular.otf"
NERD_FONTS["Hack/Regular"]="HackNerdFont-Regular.ttf HackNerdFontMono-Regular.ttf HackNerdFontPropo-Regular.ttf"
NERD_FONTS["RobotoMono/Regular"]="RobotoMonoNerdFont-Regular.ttf RobotoMonoNerdFontMono-Regular.ttf RobotoMonoNerdFontPropo-Regular.ttf"

get_os() {
  case "$(uname -s)" in
    Linux)
      if [ -f /etc/os-release ]; then
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

install_brew_apps() {
  echo "🧩  Installing Brew apps..."

  local installed=$(brew list -1 --installed-on-request)
  for app in "${BREW_APPS[@]}"; do
    if echo "${installed}" | /usr/sbin/grep -q "^${app}$"; then
      echo "✅  ${app} is already installed."
    else
      echo "🟡  ${app} is not installed."
      brew install "${app}"
    fi
  done
}

install_gnome_ext() {
  local uuid="$1"; shift
  local gnome_version="$1"; shift

  echo "Installing GNOME extension '${uuid}'..."

  local ext_info=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=${uuid}")
  local ext_version=$(echo "${ext_info}" \
    | jq -r ".shell_version_map | to_entries[] | select(.key == \"${gnome_version}\") | .value.pk")
  if [[ "${ext_version}" -eq "" ]]; then
    echo "Warning: Extension ${uuid} does not have a version published for GNOME ${gnome_version}. Falling back to the last available extension version."
    ext_version=$(echo "${ext_info}" \
      | jq -r '[.shell_version_map[]] | max_by(.version).pk')
  fi

  local download_url="https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?version_tag=${ext_version}"
  local temp_file="/tmp/${uuid}.shell-extension.zip"
  if ! curl -sL "$download_url" -o "$temp_file"; then
      echo "Failed to download extension"
      return 1
  fi

  if ! gnome-extensions install --force "$temp_file" 2>/dev/null; then
      echo "Failed to install extension"
      rm -f "$temp_file"
      return 1
  fi

  # Enable extension
  if ! gnome-extensions enable "${uuid}" 2>/dev/null; then
      echo "Failed to enable extension"
      rm -f "$temp_file"
      return 1
  fi

  rm -f "$temp_file"
  echo "✅ Successfully installed and enabled ${uuid}"
  return 0  
}

install_gnome_extensions() {
  echo "🧩  Installing GNOME extensions..."

  local gnome_version
  gnome_version=$(gnome-shell --version | awk -F'[ .]' '{print $3}')

  local enabled_extensions=$(gnome-extensions list --enabled)
  for uuid in "${GNOME_EXTENSIONS[@]}"; do
    if echo "${enabled_extensions}" | grep -q "^${uuid}$"; then
      echo "✅  ${uuid} is installed and enabled."
    else
      echo "🟡  ${uuid} is not enabled or not installed."
      install_gnome_ext "${uuid}" "${gnome_version}"
    fi
  done
}

install_flatpak_from_url() {
  local app_id="$1"; shift
  local url="$1"; shift

  echo "Installing Flatpak from ${url} ..."
  local tmp_file=$(mktemp --suffix=.flatpak)
  curl -L -o "${tmp_file}" "${url}"
  flatpak uninstall --user --assumeyes "${app_id}" || true
  flatpak install --user --assumeyes --noninteractive --reinstall "${tmp_file}"
  rm "${tmp_file}"
}

install_flatpak_apps() {
  echo "🧩  Installing Flatpak apps..."

  for app in "${!FLATPAK_APPS[@]}"; do
    if flatpak info "${app}" >/dev/null 2>&1; then
      echo "✅  Flatpak '${app}' is installed."
    else
      echo "🟡  Flatpak '${app}' is not installed."

      local url="${flatpak_apps[$app]}"
      if [ "${url}" -eq "" ]; then
        flatpak install --noninteractive --assumeyes "${app}"
      else      
        install_flatpak_from_url "${app}" "${url}"
      fi
    fi
  done
}

install_appimage() {
  local name="$1"; shift
  local url="$1"; shift

  echo "Installing AppImage from ${url} ..."
  local tmp_file=$(mktemp --suffix=.AppImage)
  curl -L -o "${tmp_file}" "${url}"
  flatpak run it.mijorus.gearlever \
    --integrate \
    --replace \
    --yes \
    --update-url "${url}" \
  "${tmp_file}"
}

install_appimages() {
  echo "🧩  Installing AppImages..."

  local installed_apps=$(flatpak run it.mijorus.gearlever --list-installed)

  for app in "${!APPIMAGE_APPS[@]}"; do
    if echo $installed_apps | grep -q "^${app}\s"; then
      echo "✅  ${app} is already installed."
    else
      echo "🟡  ${app} is not installed."
      install_appimage "${app}" "${APPIMAGE_APPS[$app]}" 
    fi
  done
}

install_nerd_font() {
  local prefix="$1"; shift
  local names="$1"; shift

  mkdir -p "${FONTS_DIR}"

  for name in ${names}; do
    local path="${FONTS_DIR}/${name}"
    local url="https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/${prefix}/${name}"

    if [ -f "${path}" ]; then
      echo "✅  Font ${name%%.*} is installed."
    else
      echo "🟡  Font ${name%%.*} is not installed."
      echo $url
      curl -fL -o "${path}" "${url}"
    fi
  done
}

install_fonts() {
  echo "🧩  Installing fonts..."

  for prefix in "${!NERD_FONTS[@]}"; do
    install_nerd_font "${prefix}" "${NERD_FONTS[$prefix]}"
  done

  fc-cache -f
}

configure_fish() {
  echo "🐟  Configuring fish..."

  local fish_plugins=$(cat $HOME/.config/fish/fish_plugins)

  if echo "${fish_plugins}" | grep -q "^jorgebucaran/fisher$"; then
    echo "✅  Fisher is already installed."
  else
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  fi

  if echo "${fish_plugins}" | grep -q "^ilancosman/tide@v6$"; then
    echo "✅  Tide is already installed."
  else
    fish -c "fisher install IlanCosman/tide@v6"
    fish -c "tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='One line' --prompt_spacing=Compact --icons='Many icons' --transient=Yes"
  fi
}

configure_tldr() {
  echo "📜  Configuring tldr..."

  tldr --update
}

install_bazzite_dx() {
  install_brew_apps
  install_flatpak_apps
  install_appimages

  install_gnome_extensions
  install_fonts

  configure_tldr
  configure_fish
}

install() {
  case "$(get_os)" in
    bazzite-dx-gnome|bazzite-dx-nvidia-gnome)
      install_bazzite_dx
      ;;
  esac
}

install
