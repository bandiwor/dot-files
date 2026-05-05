#
# ~/.zshrc
#

# --- 1. Базовые настройки ZSH (обязательно для комфорта) ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY      # Добавлять в историю, а не перезаписывать
setopt SHARE_HISTORY       # Общая история между открытыми окнами kitty
setopt HIST_IGNORE_DUPS    # Не записывать дубликаты подряд


fpath=(/usr/share/zsh/site-functions $fpath)

autoload -Uz compinit
compinit

# --- 2. Переменные окружения ---
export TERMINAL=kitty
export MOZ_ENABLE_WAYLAND=1
export EDITOR=nvim
export VISUAL=nvim
export PATH="$PATH:/home/kira/.local/bin"

export BAT_THEME="Catppuccin Macchiato"

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# --- 3. Алиасы ---
alias grep='grep --color=auto'
alias v=$EDITOR

# Pacman
alias pacS='sudo pacman -S'
alias pacR='sudo pacman -R'
alias pacRn='sudo pacman -Rn'
alias pacRs='sudo pacman -Rs'
alias pacRns='sudo pacman -Rns'
alias pacUpdate='sudo pacman -Syu'

alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lla='eza -la --icons --group-directories-first'
alias tree='eza --tree --icons'

alias cat='bat -p'

eval "$(starship init zsh)"

take() {
    mkdir -p "$1" && cd "$1"
}

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

eval "$(zoxide init zsh)"


bindkey "^[[1;5C" forward-word       # Ctrl + Right
bindkey "^[[1;5D" backward-word      # Ctrl + Left

bindkey "^[[1;2C" forward-word       # Shift + Right
bindkey "^[[1;2D" backward-word      # Shift + Left
bindkey "^[[1;2A" up-line-or-history  # Shift + Up
bindkey "^[[1;2B" down-line-or-history # Shift + Down

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char

bindkey -v

export KEYTIMEOUT=1

bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#5b6078"

if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
fi

if [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
fi

eval "$(starship init zsh)"

# pnpm
export PNPM_HOME="/home/kira/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
