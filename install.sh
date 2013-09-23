#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
    platform='linux'
elif [[ "$unamestr" == 'FreeBSD' ]]; then
    platform='linux'
elif [[ "$unamestr" == 'Darwin' ]]; then
    platform='mac'
fi

if [[ $platform == 'linux' ]]; then
    echo "Installing required packages..."
    sudo apt-get install zsh mc wget curl vim
    echo ""
fi

echo "Fetching GIT submodules recursively..."
git submodule update --init
git submodule foreach git submodule update --init

if [[ $platform == 'linux' ]]; then
    mkdir -p .config
fi
echo ""

echo "Removing old symlinks..."
rm -rf $HOME/.vim
rm $HOME/.vimrc
rm -rf $HOME/.oh-my-zsh
rm .zshrc
rm .gitconfig

if [[ $platform == 'linux' ]]; then
    rm -v $HOME/.Xdefaults
    rm -vrf $HOME/.i3
    rm -vrf $HOME/.config/sublime-text-3
elif [[ $platform == 'mac' ]]; then
    rm -vrf $HOME/Library/Application\ Support/Sublime\ Text\ 3
fi
echo ""

echo "Create new symlinks"
ln -sv $DIR/vimfiles $HOME/.vim
ln -sv $DIR/vimfiles/vimrc $HOME/.vimrc
ln -sv $DIR/zshrc $HOME/.zshrc
ln -sv $DIR/oh-my-zsh $HOME/.oh-my-zsh
ln -sv $DIR/gitconfig $HOME/.gitconfig

if [[ $platform == 'linux' ]]; then
    ln -sv $DIR/Xdefaults $HOME/.Xdefaults
    ln -sv $DIR/i3 $HOME/.i3
    ln -sv $DIR/sublime $HOME/.config/sublime-text-3

    for file in $DIR/fonts/*.otf ; do
        ln -svf $file $HOME/.fonts
    done
elif [[ $platform == 'mac' ]]; then
    ln -sv $DIR/sublime $HOME/Library/Application\ Support/Sublime\ Text\ 3

    for file in $DIR/fonts/*.otf ; do
        ln -svf $file $HOME/Library/Fonts
    done
fi
echo ""

if [[ $platform == 'linux' ]]; then
    echo "Reload font cache..."
    fc-cache -rv ~/.fonts
    echo ""
fi

if [[ $SHELL != '/bin/zsh' ]]; then
    chsh -s /bin/zsh
fi

git config --global push.default simple

echo "Don't forget to run :BundleInstall inside vim!"

