#!/usr/bin/env bash
# Login screen: LightDM + lightdm-gtk-greeter with the MyConfigs-Greeter (gruvbox) theme,
# i3 as the default session.  Needs sudo.  Run via ./install.sh --login or directly.
#
#   system/install-login.sh            install / update
#   system/install-login.sh --uninstall  go back to the stock Ubuntu greeter
#
# If you ever end up without a working login screen:
#   Ctrl+Alt+F3, log in, then:  sudo rm /etc/lightdm/lightdm.conf.d/90-myconfigs.conf && sudo systemctl restart lightdm

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
SRC="$HERE/lightdm"

THEME_DIR=/usr/share/themes/MyConfigs-Greeter
BG_DIR=/usr/share/backgrounds/myconfigs
GREETER_CONF=/etc/lightdm/lightdm-gtk-greeter.conf
SEAT_CONF=/etc/lightdm/lightdm.conf.d/90-myconfigs.conf

info() { printf '\e[1;34m==>\e[0m %s\n' "$*"; }
ok()   { printf '  \e[32m✔\e[0m %s\n' "$*"; }
warn() { printf '  \e[33m!\e[0m %s\n' "$*"; }

if [ "${1:-}" = "--uninstall" ]; then
  info "Removing MyConfigs login screen"
  sudo rm -f "$SEAT_CONF"
  sudo rm -rf "$THEME_DIR" "$BG_DIR"
  [ -f "$GREETER_CONF.myconfigs-bak" ] && sudo mv "$GREETER_CONF.myconfigs-bak" "$GREETER_CONF"
  warn "lightdm-gtk-greeter is still installed and is LightDM's default once installed."
  warn "To get the Ubuntu greeter back:  sudo apt remove lightdm-gtk-greeter"
  exit 0
fi

info "Checking packages"
need=()
command -v lightdm >/dev/null || need+=(lightdm)
[ -x /usr/sbin/lightdm-gtk-greeter ] || need+=(lightdm-gtk-greeter)
fc-list | grep -qi '/usr/share/fonts.*JetBrains' || need+=(fonts-jetbrains-mono)
[ -d /usr/share/icons/DMZ-White ] || need+=(dmz-cursor-theme)
if [ ${#need[@]} -gt 0 ]; then
  info "sudo apt install ${need[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${need[@]}"
fi
[ -x /usr/sbin/lightdm-gtk-greeter ] || { echo "lightdm-gtk-greeter missing, aborting before touching the config"; exit 1; }
ok "lightdm, lightdm-gtk-greeter, JetBrains Mono, cursor theme"

info "Installing theme + wallpaper"
# copied, not symlinked: the greeter runs as the 'lightdm' user, which can't read your home
sudo install -d -m 755 "$THEME_DIR/gtk-3.0" "$BG_DIR"
sudo install -m 644 "$SRC/theme/MyConfigs-Greeter/gtk-3.0/gtk.css" "$THEME_DIR/gtk-3.0/gtk.css"
sudo install -m 644 "$REPO/wallpaper/Pictures/Wallpapers/wallpaper.jpg" "$BG_DIR/wallpaper.jpg"
ok "$THEME_DIR"
ok "$BG_DIR/wallpaper.jpg"

info "Installing LightDM config"
if [ -f "$GREETER_CONF" ] && [ ! -f "$GREETER_CONF.myconfigs-bak" ] && ! cmp -s "$GREETER_CONF" "$SRC/lightdm-gtk-greeter.conf"; then
  sudo cp -a "$GREETER_CONF" "$GREETER_CONF.myconfigs-bak"
  ok "backed up original to $GREETER_CONF.myconfigs-bak"
fi
sudo install -m 644 "$SRC/lightdm-gtk-greeter.conf" "$GREETER_CONF"
sudo install -d -m 755 "$(dirname "$SEAT_CONF")"
sudo install -m 644 "$SRC/90-myconfigs.conf" "$SEAT_CONF"
ok "$GREETER_CONF"
ok "$SEAT_CONF  (greeter = lightdm-gtk-greeter, default session = i3)"

# remember i3 as this user's last session too
if [ -f "$HOME/.dmrc" ]; then
  grep -q '^Session=i3$' "$HOME/.dmrc" || sed -i 's/^Session=.*/Session=i3/' "$HOME/.dmrc"
else
  printf '[Desktop]\nSession=i3\n' > "$HOME/.dmrc"
fi
ok "~/.dmrc -> Session=i3"

info "Done. The new login screen appears the next time you log out or reboot."
echo "   (Restarting lightdm now would end your current session, so it's left alone.)"
