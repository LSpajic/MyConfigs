# myconfigs

My Linux (Ubuntu + i3) dotfiles, managed with [GNU stow](https://www.gnu.org/software/stow/).

Each top-level folder is a **stow package** that mirrors `$HOME`:

| package     | what                                                  |
|-------------|-------------------------------------------------------|
| `zsh`       | `.zshrc`, `.zprofile` — gruvbox prompt, autosuggestions, syntax highlighting, fzf; also loads the Gruvbox gnome-terminal profile from `extras/` |
| `bash`      | `.bashrc`, `.profile`                                 |
| `git`       | `.gitconfig` (uses `gh` as credential helper)         |
| `i3`        | `~/.config/i3/config`                                 |
| `polybar`   | bar config, `launch.sh`, volume/brightness/workspace scripts |
| `rofi`      | rofi config + gruvbox theme (`themes/gruvbox.rasi`)   |
| `ronema`    | rofi network manager config, themes, icons            |
| `x11`       | `.fehbg`                                              |
| `wallpaper` | `~/Pictures/Wallpapers/wallpaper.jpg`                 |
| `vscode`    | VS Code `settings.json`                               |
| `gh`, `glow`| CLI configs                                           |
| `scripts`   | `~/.local/bin/eduroamCon.sh` (asks for credentials), `headphones` (BT headphone switching, bound in i3), `wifi-menu` (rofi Wi-Fi picker: polybar click / Mod4+n) |

## Install

```sh
git clone https://github.com/lspajic/myconfigs ~/myconfigs
cd ~/myconfigs
./install.sh            # check deps, install missing ones, back up old files, stow everything
```

Other options:

```sh
./install.sh --check        # only report missing programs / unlinked files
./install.sh zsh i3         # only some packages
./install.sh -y             # no prompts
./install.sh --unstow i3    # remove links
./install.sh --list
./install.sh --login        # login screen (see below)
```

Existing files that would be replaced are moved to `~/.myconfigs-backup/<timestamp>/`.
Missing programs are installed with `apt` (needs sudo) or, if that's not possible, Homebrew.

Since the files in `$HOME` are symlinks into this repo, editing e.g. `~/.config/i3/config`
edits the repo — just commit and push.

## Login screen

`./install.sh --login` (needs sudo) switches LightDM to `lightdm-gtk-greeter` with a custom
gruvbox theme (`system/lightdm/`) that matches the wallpaper and polybar, and makes **i3 the
default session**. Files are copied to `/usr/share/themes/MyConfigs-Greeter`,
`/usr/share/backgrounds/myconfigs` and `/etc/lightdm/` (the greeter user can't read `$HOME`),
so rerun it after changing the theme. Undo with `system/install-login.sh --uninstall`.

Locked out? `Ctrl+Alt+F3`, log in, `sudo rm /etc/lightdm/lightdm.conf.d/90-myconfigs.conf && sudo systemctl restart lightdm`.
