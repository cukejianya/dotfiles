# --- robbyrussell, no-OMZ version ---

# 1) Git status via vcs_info (fast & built-in)
autoload -Uz vcs_info

# Show git info like: " git:(branch)" and add a yellow ✗ if dirty
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr ' '       # (we just want the dirty marker once)
zstyle ':vcs_info:git:*' unstagedstr ' %F{yellow}✗%f'
# Formats:
# - branch name in red, wrapped as " git:(<branch>)" with blue parens/prefix/suffix
zstyle ':vcs_info:git:*' formats ' %F{blue}git:(%F{red}%b%F{blue})%f%u'
zstyle ':vcs_info:git:*' actionformats ' %F{blue}git:(%F{red}%b*%a%F{blue})%f%u'

# Refresh vcs_info before each prompt
precmd() { vcs_info }

# 2) Prompt: green ➜ on success, red ➜ on failure; cyan cwd; then git info
# Original OMZ theme (reference):
# PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)"
# Recreated with %F colors and ${vcs_info_msg_0_}
PROMPT='%(?:%F{green}➜:%F{red}➜) %F{cyan}%c%f${vcs_info_msg_0_} '

# Optional: right prompt with time (comment out if you don’t want it)
# RPROMPT='%F{242}%*%f'

# 3) Nice-to-haves
setopt prompt_subst         # allow ${...} in PROMPT
autoload -Uz colors && colors
