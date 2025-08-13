# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
export FZF_BASE=$(brew --prefix)/opt/fzf

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  fzf
  fzf-tab
  gcloud
  git
  git-escape-magic
  jsontools
  kubectl
  mvn
  tmux
  wd
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

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

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#

#Set zsh to vi mode
bindkey -v

#Set bash to vi mode
set -o vi

# Bind jk to <esc> key
bindkey jk vi-cmd-mode

# Bind vv to command line editor
bindkey vv edit-command-line

# Reload alias
alias zshreload="source ~/.zshrc"
alias tmuxreload="tmux source-file ~/.tmux.conf"

# Config aliases

alias cat="bat -pp"
alias ls="eza --icons --color=always"
alias fzf-preview="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"
alias tmuxconfig="nvim ~/.tmux.conf"
alias vimconfig="nvim ~/.config/nvim/init.vim"
alias zshconfig="nvim ~/.zshrc"
alias git-commit-msg="git --no-pager diff HEAD~1 | ollama run tavernari/git-commit-message | awk 'NR==2'"

# Config to Cpp build
alias cpp="clang++ -std=c++11 -stdlib=libc++"

export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Colorize man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Config FZF
export FZF_DEFAULT_COMMAND="rg --hidden --no-ignore --files"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# Automate node switch
# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path"  ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A"  ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version"  ];
    then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default
    version"
    nvm use default
  fi
}

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

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

source "$HOME/.sdkman/bin/sdkman-init.sh"

[ -f "/Users/chinedumu/.ghcup/env" ] && source "/Users/chinedumu/.ghcup/env" # ghcup-env

source ~/.zprofile

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

getProjectName() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    printf $(git rev-parse --git-common-dir --absolute-git-dir | tr '/' ' ' | awk ' {if (/main \.git$/) { print $(NF-2)} else if (/^ Users.*(\.git|\.bare)$/) {print $(NF-1)}}')
  else
    printf ${PWD:t}
  fi
}

# # Changing Tmux window names
# cd() {
#   builtin cd "$@" || return
#   local name=$(getProjectName)
#   [ -n "$TMUX" ] && tmux rename-window "$name"
# }

# Open db rename-window
db() {
  if [ $(tmux list-sessions -F '#S' | grep -c "db") -gt 0 ]; then 
    tmux switch-client -t "db"  
  else
    tmuxinator start db
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
export PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"

export PATH=$PATH:/Users/chinedumu/.spicetify
export PATH=/opt/spotify-devex/bin:$PATH
