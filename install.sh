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
  sudo apt install -y zsh curl stow vim
}

function install_macos () {
  brew install zsh curl stow vim
}

install () {
  case $(get_distro) in
    debian | ubuntu | pop)
      install_debian
      ;;
    Darwin)
      install_macos
      ;;
  esac

  sudo chsh -s $(which zsh) $USER

  git submodule update --init

  curl -L git.io/antigen > zsh/.zsh/antigen.zsh

  stow bin
  stow zsh
  stow vim
}

install
