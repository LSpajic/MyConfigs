#!/usr/bin/env bash
# myconfigs installer
#   - checks that the programs each config needs are installed (and offers to install them)
#   - backs up any existing real files that would be overwritten
#   - links everything into $HOME with GNU stow
#
# Usage:
#   ./install.sh                 # everything
#   ./install.sh zsh i3 polybar  # only these packages
#   ./install.sh --check         # only report what's missing / linked, change nothing
#   ./install.sh -y              # don't ask, install missing deps automatically
#   ./install.sh --unstow [pkg]  # remove the symlinks again
#   ./install.sh --list          # list packages

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"
BACKUP="$HOME/.myconfigs-backup/$(date +%Y%m%d-%H%M%S)"

# ---------------------------------------------------------------- packages
# package -> commands it needs ("cmd" or "cmd:aptpkg:brewpkg")
declare -A DEPS=(
  [zsh]="zsh git curl"
  [bash]="bash"
  [git]="git gh"
  [i3]="i3 dex xss-lock i3lock nm-applet:network-manager-gnome feh setxkbmap:x11-xkb-utils xinput pactl:pulseaudio-utils brightnessctl rofi polybar"
  [polybar]="polybar xrandr:x11-xserver-utils jq i3-msg:i3 pactl:pulseaudio-utils wpctl:wireplumber brightnessctl"
  [rofi]="rofi"
  [ronema]="rofi nmcli:network-manager qrencode"
  [x11]="feh"
  [wallpaper]=""
  [vscode]="code"
  [gh]="gh"
  [glow]="glow::glow"
  [scripts]="nmcli:network-manager"
)
# apt has no package for these -> brew only (or manual)
declare -A NO_APT=([glow]=1 [code]=1)
# commands that need a manual install
declare -A MANUAL=(
  [code]="VS Code: https://code.visualstudio.com/  (or: sudo snap install code --classic)"
)

# ---------------------------------------------------------------- output
if [ -t 1 ]; then R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[1;34m'; N=$'\e[0m'; else R= G= Y= B= N=; fi
info() { printf '%s==>%s %s\n' "$B" "$N" "$*"; }
ok()   { printf '  %s✔%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
err()  { printf '  %s✘%s %s\n' "$R" "$N" "$*"; }

# ---------------------------------------------------------------- args
CHECK=0 YES=0 UNSTOW=0 PKGS=()
for a in "$@"; do
  case "$a" in
    --check|-c) CHECK=1 ;;
    -y|--yes)   YES=1 ;;
    --unstow|-D) UNSTOW=1 ;;
    --list|-l)  printf '%s\n' "${!DEPS[@]}" | sort; exit 0 ;;
    -h|--help)  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option $a"; exit 1 ;;
    *)  [[ -n "${DEPS[$a]+x}" ]] || { echo "unknown package: $a (see --list)"; exit 1; }
        PKGS+=("$a") ;;
  esac
done
[ ${#PKGS[@]} -eq 0 ] && mapfile -t PKGS < <(printf '%s\n' "${!DEPS[@]}" | sort)

confirm() { [ $YES -eq 1 ] && return 0; read -rp "  $1 [Y/n] " r; [[ -z "$r" || "$r" =~ ^[Yy] ]]; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- package manager
install_pkgs() { # args: list of "cmd:apt:brew" specs
  local apt=() brew=() manual=() spec cmd ap bp
  for spec in "$@"; do
    IFS=: read -r cmd ap bp <<<"$spec"
    ap=${ap:-$cmd}; bp=${bp:-$cmd}
    if [[ -n "${MANUAL[$cmd]+x}" ]]; then manual+=("$cmd")
    elif have apt-get && [[ -z "${NO_APT[$cmd]+x}" ]] && sudo -v 2>/dev/null; then apt+=("$ap")
    elif have brew; then brew+=("$bp")
    else manual+=("$cmd"); fi
  done
  if [ ${#apt[@]} -gt 0 ]; then
    info "apt install ${apt[*]}"
    sudo apt-get update -qq && sudo apt-get install -y "${apt[@]}" || err "apt install failed"
  fi
  if [ ${#brew[@]} -gt 0 ]; then
    info "brew install ${brew[*]}"
    brew install "${brew[@]}" || err "brew install failed"
  fi
  for cmd in "${manual[@]}"; do warn "install manually: ${MANUAL[$cmd]:-$cmd}"; done
}

# ---------------------------------------------------------------- 1. dependencies
info "Checking dependencies"
declare -A SEEN=(); MISSING=()
for spec in stow:stow:stow $(for p in "${PKGS[@]}"; do echo "${DEPS[$p]}"; done); do
  cmd=${spec%%:*}
  [[ -n "${SEEN[$cmd]+x}" ]] && continue; SEEN[$cmd]=1
  if have "$cmd"; then ok "$cmd"; else err "$cmd  (missing)"; MISSING+=("$spec"); fi
done

# things that aren't a single command
EXTRA_MISSING=()
if [[ " ${PKGS[*]} " == *" zsh "* ]]; then
  if [ -d "$HOME/.oh-my-zsh" ]; then ok "oh-my-zsh"; else err "oh-my-zsh  (missing)"; EXTRA_MISSING+=(ohmyzsh); fi
  for opt in "$HOME/.sdkman:sdkman" "$HOME/.nvm:nvm" "/home/linuxbrew/.linuxbrew:homebrew"; do
    [ -e "${opt%%:*}" ] && ok "${opt##*:} (optional)" || warn "${opt##*:} not installed (optional, .zshrc skips it)"
  done
fi
if [[ " ${PKGS[*]} " == *" rofi "* ]]; then
  if have fc-list && fc-list | grep -qi 'FiraCode Nerd'; then ok "FiraCode Nerd Font"
  else err "FiraCode Nerd Font  (missing)"; EXTRA_MISSING+=(font); fi
fi
if [[ " ${PKGS[*]} " == *" ronema "* ]]; then
  have ronema && ok "ronema" || warn "ronema not found - install it manually (config is linked anyway)"
fi

if [ $CHECK -eq 0 ] && [ $UNSTOW -eq 0 ]; then
  if [ ${#MISSING[@]} -gt 0 ] && confirm "Install ${#MISSING[@]} missing program(s)?"; then
    install_pkgs "${MISSING[@]}"
  fi
  for x in "${EXTRA_MISSING[@]}"; do
    case $x in
      ohmyzsh) confirm "Install oh-my-zsh?" && \
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ;;
      font) if confirm "Download FiraCode Nerd Font to ~/.local/share/fonts?"; then
          tmp=$(mktemp -d)
          curl -fL -o "$tmp/f.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip \
            && mkdir -p "$HOME/.local/share/fonts/FiraCode" \
            && unzip -oq "$tmp/f.zip" -d "$HOME/.local/share/fonts/FiraCode" && fc-cache -f >/dev/null \
            && ok "font installed" || err "font install failed"
          rm -rf "$tmp"
        fi ;;
    esac
  done
  if have zsh && [ "$(basename "${SHELL:-}")" != zsh ] && [[ " ${PKGS[*]} " == *" zsh "* ]]; then
    confirm "Make zsh your login shell?" && chsh -s "$(command -v zsh)"
  fi
fi

have stow || { err "GNU stow is required. Install it (sudo apt install stow / brew install stow) and rerun."; exit 1; }

# ---------------------------------------------------------------- 2. unstow
if [ $UNSTOW -eq 1 ]; then
  info "Removing links"
  for p in "${PKGS[@]}"; do stow -D --no-folding -d "$REPO" -t "$TARGET" "$p" && ok "$p unlinked"; done
  exit 0
fi

# ---------------------------------------------------------------- 3. link
info "Linking configs into $TARGET"
for p in "${PKGS[@]}"; do
  [ -d "$REPO/$p" ] || { warn "$p: no folder, skipping"; continue; }
  # every file the package would create
  while IFS= read -r -d '' f; do
    rel=${f#"$REPO/$p/"}; dest="$TARGET/$rel"
    if [ -L "$dest" ]; then
      [ "$(readlink -f "$dest")" = "$(readlink -f "$f")" ] && continue
      [ $CHECK -eq 1 ] && { warn "$rel -> links elsewhere ($(readlink "$dest"))"; continue; }
      mkdir -p "$BACKUP/$(dirname "$rel")"; mv "$dest" "$BACKUP/$rel"; warn "moved old link $rel to backup"
    elif [ -e "$dest" ]; then
      [ $CHECK -eq 1 ] && { warn "$rel exists as a real file (would be backed up)"; continue; }
      mkdir -p "$BACKUP/$(dirname "$rel")"; mv "$dest" "$BACKUP/$rel"; warn "backed up $rel"
    elif [ $CHECK -eq 1 ]; then
      warn "$rel not linked yet"
    fi
  done < <(find "$REPO/$p" -type f -print0)

  [ $CHECK -eq 1 ] && continue
  if stow --no-folding -R -d "$REPO" -t "$TARGET" "$p"; then ok "$p"; else err "$p failed"; fi
done

[ -d "$BACKUP" ] && info "Old files were saved to $BACKUP"
[ $CHECK -eq 1 ] && info "Check done (nothing was changed)" || info "Done. Restart your shell / reload i3 (Mod4+Shift+r)."
