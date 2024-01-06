alias vialias='vim ~/.zsh/aliases.zsh && source ~/.zsh/aliases.zsh'
alias vienv='vim ~/.zsh/env.zsh && source ~/.zsh/env.zsh'

function dotfiles () {
    case "$1" in
        push)
            (cd ~/.dotfiles && git add . && git commit && git push)
        ;;
        pull)
            (cd ~/.dotfiles && git pull)
        ;;
        *)
            echo "Usage $0 <push|pull>"
        ;;
    esac
}

