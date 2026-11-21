# ~/.zshrc — gruvbox, matching i3 / polybar / login screen

# ═══════════════════════════════════════════════════════════════ oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""                       # prompt is defined below
# extra plugins are cloned into $ZSH/custom/plugins by ~/myconfigs/install.sh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  [[ -d $ZSH/custom/plugins/$p ]] || plugins=(${plugins:#$p})
done
# synchronous git info in the prompt (the async version often shows nothing)
zstyle ':omz:alpha:lib:git' async-prompt no
source $ZSH/oh-my-zsh.sh

# ═══════════════════════════════════════════════════════════════ colours
# true colour where the terminal supports it, nearest 256-colour otherwise
[[ $COLORTERM == (24bit|truecolor) ]] || zmodload zsh/nearcolor 2>/dev/null

typeset -gA GB=(
  bg1 '#3c3836' bg2 '#504945' bg3 '#665c54' fg '#ebdbb2' gray '#928374'
  red '#fb4934' green '#b8bb26' yellow '#fabd2f' blue '#83a598'
  purple '#d3869b' aqua '#8ec07c' orange '#fe8019' amber '#d79921'
)

# ═══════════════════════════════════════════════════════════════ prompt
#   ~/myconfigs on main ● ❯       (red ❯ when the last command failed)
ZSH_THEME_GIT_PROMPT_PREFIX=" %F{$GB[gray]}on%f %F{$GB[aqua]}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{$GB[orange]}●"
ZSH_THEME_GIT_PROMPT_CLEAN=""

_prompt_host() { [[ -n $SSH_CONNECTION ]] && print -n "%F{$GB[purple]}%n@%m%f " }
_prompt_venv() { [[ -n $VIRTUAL_ENV ]] && print -n "%F{$GB[gray]}(${VIRTUAL_ENV:t})%f " }
export VIRTUAL_ENV_DISABLE_PROMPT=1

PROMPT='$(_prompt_host)$(_prompt_venv)%B%F{$GB[amber]}%~%f%b$(git_prompt_info) %(?.%F{$GB[green]}.%F{$GB[red]})❯%f '
RPROMPT='%(?..%F{$GB[red]}✘ %?%f)'

# ═══════════════════════════════════════════════════════════════ plugins look
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$GB[bg3]"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]="fg=$GB[green]"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=$GB[green]"
ZSH_HIGHLIGHT_STYLES[alias]="fg=$GB[green]"
ZSH_HIGHLIGHT_STYLES[function]="fg=$GB[green]"
ZSH_HIGHLIGHT_STYLES[precommand]="fg=$GB[green],italic"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=$GB[red]"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=$GB[purple]"
ZSH_HIGHLIGHT_STYLES[path]="fg=$GB[fg],underline"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=$GB[yellow]"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=$GB[yellow]"
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=$GB[blue]"
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=$GB[blue]"
ZSH_HIGHLIGHT_STYLES[comment]="fg=$GB[gray]"
ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=$GB[orange]"

# fzf: Ctrl+R history, Ctrl+T files, Alt+C cd — gruvbox colours
if [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=rounded
    --color=bg+:$GB[bg1],bg:-1,spinner:$GB[aqua],hl:$GB[yellow]
    --color=fg:$GB[fg],header:$GB[gray],info:$GB[blue],pointer:$GB[amber]
    --color=marker:$GB[green],fg+:$GB[fg],prompt:$GB[amber],hl+:$GB[yellow],border:$GB[bg2]"
fi

# ═══════════════════════════════════════════════════════════════ history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks

# ═══════════════════════════════════════════════════════════════ PATH / tools
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

export FLYCTL_INSTALL="$HOME/.fly"
export ANDROID_HOME="$HOME/Android/Sdk"
path=(
  "$HOME/.local/bin"            # pipx, uv, antigravity, own scripts
  "$FLYCTL_INSTALL/bin"
  /snap/bin
  $path
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_HOME/cmdline-tools/latest/bin"
)
typeset -U path                 # drop duplicates

# nvm — lazy-loaded so it doesn't slow down every new shell; the default node
# version goes straight on PATH, so node/npm/npx work right away.
# nvm calls `command hash -r`, which in zsh only works with POSIX_BUILTINS set
# (that was the "nvm:867: command not found: hash" error) -> the wrapper sets it.
export NVM_DIR="$HOME/.nvm"
if [[ -s $NVM_DIR/nvm.sh ]]; then
  () {
    local want=${$(<$NVM_DIR/alias/default 2>/dev/null)#v}
    local -a v=( $NVM_DIR/versions/node/v${want}*(N/nOn) )
    (( $#v )) || v=( $NVM_DIR/versions/node/v*(N/nOn) )   # alias like lts/* -> newest
    (( $#v )) && path=( $v[1]/bin $path )
  }
  nvm() {
    unfunction nvm
    setopt local_options posix_builtins
    source $NVM_DIR/nvm.sh --no-use
    [[ -s $NVM_DIR/bash_completion ]] && source $NVM_DIR/bash_completion
    functions -c nvm _nvm_impl
    nvm() { setopt local_options posix_builtins; _nvm_impl "$@" }
    nvm "$@"
  }
fi

# ═══════════════════════════════════════════════════════════════ aliases
alias matlab='/usr/local/MATLAB/R2025b/bin/matlab'
alias weather='curl wttr.in'
(( $+commands[batcat] )) && ! (( $+commands[bat] )) && alias bat='batcat'
export BAT_THEME="gruvbox-dark"

# ═══════════════════════════════════════════════════════════════ sdkman
# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
