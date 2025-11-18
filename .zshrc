export ZSH_CONFIG=$HOME/.config/zsh

source <(fzf --zsh)
source "$ZSH_CONFIG/themes/robbyrussell.zsh"
source "$ZSH_CONFIG/plugins/wd/wd.plugin.zsh"

# ---  Completion ---
fpath=($ZSH_CONFIG/plugins/zsh-completions/src $fpath)
fpath=($ZSH_CONFIG/plugins/wd $fpath)
autoload -U compinit && compinit -C

source "$ZSH_CONFIG/plugins/fzf-tab/fzf-tab.plugin.zsh"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

## History file configuration
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000
[ "$SAVEHIST" -lt 10000 ] && SAVEHIST=10000

## History command configuration
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data
setopt inc_append_history
setopt append_history

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="mm/dd/yyyy"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim +setfiletype=sh'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"

#Set zsh to vi mode
bindkey -v

#Set bash to vi mode
set -o vi

# Bind vv to command line editor
bindkey vv edit-command-line

case "$OSTYPE" in
linux* | *bsd*)
  ;;
darwin*)
  export PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"
  export PATH=$PATH:$HOME/.spicetify
  export PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"

  source <(kubectl completion zsh)
  source <(kubectl-site completion zsh)
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  export FZF_BASE=$(brew --prefix)/opt/fzf

  # Calls mvnw if found in the current project, otherwise execute the original mvn
  mvn-or-mvnw() {
    [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && unset -f sdk && source "$HOME/.sdkman/bin/sdkman-init.sh"
    local dir="$PWD"
    while [[ ! -x "$dir/mvnw" && "$dir" != / ]]; do
      dir="${dir:h}"
    done
 
    if [[ -x "$dir/mvnw" ]]; then
      echo "Running \`$dir/mvnw\`..." >&2
      "$dir/mvnw" "$@"
      return $?
    fi

    command mvn "$@"
  }

  sdk() {
    unset -f sdk
    [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk "$@"
  }
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  source ~/.zprofile
  ;;
esac

# Reload alias
alias zshreload="source ~/.zshrc"
alias tmuxreload="tmux source-file ~/.tmux.conf"

# Config aliases

alias cat="bat -pp"
alias ls="eza --icons --color=always"
alias fzf-preview="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"
alias tmuxconfig="nvim ~/.tmux.conf"
alias vimconfig="nvim ~/.config/nvim/init.lua"
alias zshconfig="nvim ~/.zshrc"
alias git-commit-msg="git --no-pager diff HEAD~1 | ollama run tavernari/git-commit-message | awk 'NR==2'"
alias nvm="fnm"

alias gwt="git worktree"
alias gpu="git push -u origin HEAD"
alias gp="git push"
alias mvn="mvn-or-mvnw"
# Changing/making/removing directory
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus


alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias -- -='cd -'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

alias md='mkdir -p'
alias rd=rmdir

function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}
compdef _dirs d

# List directory contents
alias lsa='ls -lah'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'

# Config to Cpp build
alias cpp="clang++ -std=c++11 -stdlib=libc++"

export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Colorize man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Config FZF
export FZF_DEFAULT_COMMAND="rg --hidden --no-ignore --files"

# For compilers to find zlib you may need to set:
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/zlib/lib"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"

# For pkg-config to find zlib you may need to set:
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/php@7.2/bin:$PATH"
export PATH="/usr/local/opt/php@7.2/sbin:$PATH"

# Add Java HOME environment 
export JAVA_HOME="/Users/chinedumu/.sdkman/candidates/java/current"

# Add RUST bin to PATH
export PATH="$PATH:$HOME/.cargo/bin"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Add .local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Enable developer mode in Slack
export SLACK_DEVELOPER_MENU=true

# Git pretty log
alias lg1-specific="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'"
alias lg2-specific="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'"
alias lg3-specific="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'V"
alias lg="lg1"
alias lg2="lg1-specific --all"
alias lg2="lg2-specific --all"
alias lg3="lg3-specific --all"
# functions
decodeURL() { printf "%b\n" "$(sed 's/+/ /g; s/%\([0-9a-f][0-9a-f]\)/\\x\1/g;')"; }

getPastCommand() {
  history | fzf | sed -E 's/^ *([0-9]+).*/\!\1/g' | pbcopy
}

midpoint() {
  echo $(( ($1 + $2 ) / 2 ))
}

# wt() { 
#   local worktree_dir
#   if [ -z "$1" ]; then 
#     worktree_dir=$(git worktree list | fzf | awk '{ print $1 }') || return
#   else
#     worktree_dir=$(git worktree list | awk '{print $0 "|" $0}' | sed 's![^[:space:]]*/\([^[:space:]]*\).*|!\1 | !' | fzf --query="$1" --select-1 --exit-0 --delimiter='\|' --nth=1 | awk '{ print $3 }')
#   fi
#   cd -- "$worktree_dir"
# }


[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env


getProjectName() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    printf $(git rev-parse --git-common-dir --absolute-git-dir | tr '/' ' ' | awk ' {if (/main \.git$/) { print $(NF-2)} else if (/^ Users.*(\.git|\.bare)$/) {print $(NF-1)}}')
  else
    printf ${PWD:t}
  fi
}

# # Changing Tmux window names
cd() {
  builtin cd "$@" || return
  local name=$(getProjectName)
  [ -n "$TMUX" ] && tmux rename-window "$name"
}

# Open db rename-window
db() {
  if [ $(tmux list-sessions -F '#S' | grep -c "db") -gt 0 ]; then 
    tmux switch-client -t "db"  
  else
    tmuxinator start db
  fi
}

# Name tmux pane 
vim() {
  [ -n "$TMUX" ] && tmux select-pane -T "vim"
  nvim "$@" || return
}

ai() {
  [ -n "$TMUX" ] && tmux select-pane -T "✳"
  claude "$@" || return
}

mark() {
  if [ -n "$1" ]; then
    [ -n "$TMUX" ] && tmux select-pane -T "$1"
  else
    [ -n "$TMUX" ] && tmux select-pane -T "basic"
  fi
}

# Highlisth Commands Config
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[command]='fg=blue'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=blue'
ZSH_HIGHLIGHT_STYLES[alias]='fg=blue'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=green'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=green,bold'

export PATH=/opt/spotify-devex/bin:$PATH
