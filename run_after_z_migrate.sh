#!/usr/bin/env bash
set -eu

rm -rf ~/.config/home-manager
rm -rf ~/.config/nix
git clone https://github.com/BohdanTkachenko/dotfiles.git ~/.config/home-manager 

cd ~/.config/home-manager
git submodule update

chezmoi purge

./scripts/install.sh