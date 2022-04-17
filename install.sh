#!/bin/bash

# Determine the distro
# Here are some known OSes:
# - Darwin
# - FreeBSD
# - fedora
# - ubuntu
# - debian
# - raspbian
function get_distro () {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo $ID
  else
    uname
  fi
}

function install_debian () {
  sudo apt install -y curl stow vim
}

function install_macos () {
  brew install curl stow vim
}

install () {
  case $(get_distro) in
    debian)
      install_debian
      ;;
    ubuntu)
      install_debian
      ;;
    Darwin)
      install_macos
      ;;
  esac

  git submodule update --init

  curl -L git.io/antigen > zsh/.zsh/antigen.zsh

  stow zsh
  stow vim
}

install
