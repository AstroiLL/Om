#!/usr/bin/env bash
# Om installer: links the Om configs into $HOME (user level, reversible) and optionally installs
# packages, fonts, the GTK theme, agent skills and the coredump limit.
#
#   ./install.sh                 link configs + scripts + user units (no sudo)
#   ./install.sh --all           everything below as well
#   ./install.sh --packages      install packages with the distro package manager (sudo)
#   ./install.sh --fonts         Roboto Mono (terminal font) into ~/.local/share/fonts if missing
#   ./install.sh --gtk-theme     Tokyonight-Dark GTK theme + icons (git clone, user level)
#   ./install.sh --skills        agent skills -> ~/.hermes/skills/om and ~/.claude/skills (if present)
#   ./install.sh --coredump      /etc/systemd/user.conf.d/10-coredump.conf (sudo) for crash diagnosis
#   ./install.sh --dry-run ...   print what would be done, change nothing
#
# Every file that is replaced is moved to ~/.local/state/om/backups/<timestamp>/ first.
set -euo pipefail

REPO=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
OM=$HOME/.local/share/om
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/om
BACKUP=$STATE/backups/$(date +%Y%m%d-%H%M%S)
DRY=0; DO_PKG=0; DO_FONTS=0; DO_GTK=0; DO_SKILLS=0; DO_CORE=0

for a in "$@"; do
  case $a in
    --dry-run) DRY=1 ;;
    --packages) DO_PKG=1 ;;
    --fonts) DO_FONTS=1 ;;
    --gtk-theme) DO_GTK=1 ;;
    --skills) DO_SKILLS=1 ;;
    --coredump) DO_CORE=1 ;;
    --all) DO_PKG=1; DO_FONTS=1; DO_GTK=1; DO_SKILLS=1; DO_CORE=1 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a (see --help)" >&2; exit 2 ;;
  esac
done

c_ok=$'\e[32m'; c_warn=$'\e[33m'; c_off=$'\e[0m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '  %sok%s   %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '  %swarn%s %s\n' "$c_warn" "$c_off" "$*"; }
run()  { if ((DRY)); then printf '  [dry] %s\n' "$*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

backup() {  # move an existing path out of the way, keeping its relative location under $HOME
  local p=$1 rel
  rel=${p#"$HOME"/}
  run mkdir -p "$BACKUP/$(dirname "$rel")"
  run mv "$p" "$BACKUP/$rel"
  warn "backed up $p -> $BACKUP/$rel"
}

link() {  # link <target> <link-path>
  local src=$1 dst=$2
  if [[ -L $dst && $(readlink -f "$dst") == "$(readlink -f "$src")" ]]; then ok "$dst"; return; fi
  [[ -e $dst || -L $dst ]] && backup "$dst"
  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  ok "$dst -> $src"
}

ensure_line() {  # ensure_line <file> <exact line> <comment>
  local f=$1 line=$2 comment=$3
  if [[ -f $f ]] && grep -qxF "$line" "$f"; then ok "$f already sources Om"; return; fi
  if ((DRY)); then printf '  [dry] append to %s: %s\n' "$f" "$line"; return; fi
  printf '\n# %s\n%s\n' "$comment" "$line" >>"$f"
  ok "$f: added '$line'"
}

# ---------------------------------------------------------------- packages
install_packages() {
  say "== packages"
  local id like list mgr pkgs=() missing=() p
  # shellcheck disable=SC1091
  . /etc/os-release
  id=${ID:-}; like=${ID_LIKE:-}
  case " $id $like " in
    *" debian "*|*" ubuntu "*) list=debian; mgr=apt ;;
    *" arch "*)                list=arch;   mgr=pacman ;;
    *" fedora "*)              list=fedora; mgr=dnf ;;
    *) warn "unknown distro '$id' — install the packages from packages/*.txt by hand"; return ;;
  esac
  mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$REPO/packages/$list.txt" | awk '{print $1}')
  for p in "${pkgs[@]}"; do
    case $mgr in
      apt)    apt-cache show "$p" >/dev/null 2>&1 || missing+=("$p") ;;
      pacman) pacman -Si "$p" >/dev/null 2>&1 || pacman -Qi "$p" >/dev/null 2>&1 || missing+=("$p") ;;
      dnf)    dnf -q info "$p" >/dev/null 2>&1 || missing+=("$p") ;;
    esac
  done
  local avail=()
  for p in "${pkgs[@]}"; do [[ " ${missing[*]} " == *" $p "* ]] || avail+=("$p"); done
  ((${#missing[@]})) && warn "not in your repositories (see README, install by hand/AUR/COPR): ${missing[*]}"
  case $mgr in
    apt)    run sudo apt-get install -y --no-install-recommends "${avail[@]}" ;;
    pacman) run sudo pacman -S --needed --noconfirm "${avail[@]}" ;;
    dnf)    run sudo dnf install -y "${avail[@]}" ;;
  esac
}

# ---------------------------------------------------------------- fonts
install_fonts() {
  say "== fonts"
  if fc-list : family 2>/dev/null | grep -qx 'Roboto Mono'; then ok "Roboto Mono present"; return; fi
  local d=$HOME/.local/share/fonts/RobotoMono base=https://github.com/google/fonts/raw/main/apache/robotomono
  run mkdir -p "$d"
  run curl -fsSL --retry 3 -o "$d/RobotoMono[wght].ttf" "$base/RobotoMono%5Bwght%5D.ttf"
  run curl -fsSL --retry 3 -o "$d/RobotoMono-Italic[wght].ttf" "$base/RobotoMono-Italic%5Bwght%5D.ttf"
  run fc-cache -f "$d"
  ok "Roboto Mono -> $d (Apache 2.0)"
}

# ---------------------------------------------------------------- GTK theme
install_gtk_theme() {
  say "== GTK theme Tokyonight-Dark"
  local src=${XDG_CACHE_HOME:-$HOME/.cache}/om/tokyonight-gtk
  if [[ -d $HOME/.themes/Tokyonight-Dark ]]; then ok "theme already in ~/.themes"; else
    have sassc || warn "sassc is required by the theme build (install it or use --packages)"
    [[ -d $src/.git ]] || run git clone --depth 1 https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git "$src"
    # -l links libadwaita (gtk-4.0) files; Om re-links its own gtk-4.0 css right after this step
    run bash -c "cd '$src/themes' && ./install.sh -c dark -l"
  fi
  if [[ ! -d $HOME/.local/share/icons/Tokyonight-Dark && -d $src/icons/Tokyonight-Dark ]]; then
    run mkdir -p "$HOME/.local/share/icons"; run cp -r "$src/icons/Tokyonight-Dark" "$HOME/.local/share/icons/"
  fi
  if have gsettings; then
    run gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'
    [[ -d $HOME/.local/share/icons/Tokyonight-Dark ]] && run gsettings set org.gnome.desktop.interface icon-theme 'Tokyonight-Dark'
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    ok "gsettings org.gnome.desktop.interface: Tokyonight-Dark, prefer-dark"
  fi
}

# ---------------------------------------------------------------- configs
link_configs() {
  say "== configs"
  link "$REPO" "$OM"
  link "$OM/configs/hypr"   "$CFG/hypr"
  link "$OM/configs/waybar" "$CFG/waybar"
  link "$OM/configs/foot"   "$CFG/foot"
  link "$OM/configs/mc/skins" "$HOME/.local/share/mc/skins"
  if [[ ! -e $REPO/configs/hypr/local.lua ]]; then
    run cp "$REPO/configs/hypr/local.lua.example" "$REPO/configs/hypr/local.lua"; ok "created hypr/local.lua from example"
  fi

  say "== GTK overrides"
  link "$OM/configs/gtk/gtk3.css"          "$CFG/gtk-3.0/gtk.css"
  link "$OM/configs/gtk/selection.css"     "$CFG/gtk-3.0/selection.css"
  link "$OM/configs/gtk/gtk4-gtk.css"      "$CFG/gtk-4.0/gtk.css"
  link "$OM/configs/gtk/gtk4-gtk-dark.css" "$CFG/gtk-4.0/gtk-dark.css"
  link "$OM/configs/gtk/selection.css"     "$CFG/gtk-4.0/selection.css"
  [[ -d $HOME/.themes/Tokyonight-Dark/gtk-4.0/assets ]] && link "$HOME/.themes/Tokyonight-Dark/gtk-4.0/assets" "$CFG/gtk-4.0/assets"
  link "$OM/configs/gtk/gtksourceview-5" "$HOME/.local/share/gtksourceview-5/styles"
  if have gsettings && gsettings list-keys org.gnome.TextEditor >/dev/null 2>&1; then
    run gsettings set org.gnome.TextEditor style-scheme 'om-tokyo'; ok "gnome-text-editor scheme om-tokyo"
  fi

  say "== shell"
  ensure_line "$HOME/.tmux.conf" "source-file ~/.local/share/om/configs/tmux/tmux.conf" "Om tmux config"
  ensure_line "$HOME/.bashrc" "[ -f ~/.local/share/om/configs/bash/om.bash ] && . ~/.local/share/om/configs/bash/om.bash" "Om shell helpers: tdl/tds/tdlm/tsl, aliases a/g/ih/hk, ssh->tmux window name"

  say "== scripts -> ~/.local/bin"
  local s
  for s in "$REPO"/scripts/om-*; do link "$OM/scripts/${s##*/}" "$HOME/.local/bin/${s##*/}"; done
  [[ :$PATH: == *":$HOME/.local/bin:"* ]] || warn "~/.local/bin is not in PATH (binds use full paths, terminal commands need PATH)"
}

# ---------------------------------------------------------------- systemd user units
link_units() {
  say "== systemd user units"
  local U=$CFG/systemd/user u
  link "$OM/configs/systemd-user/om-crash-watch.service" "$U/om-crash-watch.service"
  if have swayosd-server; then link "$OM/configs/systemd-user/swayosd.service" "$U/swayosd.service"; fi
  for u in waybar mako hyprpaper hypridle hyprpolkitagent hyprsunset; do
    link "$OM/configs/systemd-user/dropins/hyprland-only.conf" "$U/$u.service.d/hyprland-only.conf"
  done
  if [[ -x $HOME/.local/opt/waybar-git/bin/waybar ]]; then
    link "$OM/configs/systemd-user/dropins/waybar-git-build.conf" "$U/waybar.service.d/git-build.conf"
  fi
  run systemctl --user daemon-reload
  local en=(om-crash-watch.service)
  have swayosd-server && en+=(swayosd.service)
  for u in waybar mako hyprpaper hypridle hyprpolkitagent hyprsunset; do
    systemctl --user cat "$u.service" >/dev/null 2>&1 && en+=("$u.service")
  done
  run systemctl --user enable "${en[@]}" 2>/dev/null || warn "systemctl --user enable failed for some of: ${en[*]}"
  ok "enabled (start with the next Hyprland session): ${en[*]}"
}

# ---------------------------------------------------------------- agent skills
install_skills() {
  say "== agent skills"
  local s n
  for s in "$REPO"/skills/*/; do
    n=$(basename "$s")
    if [[ -d $HOME/.hermes ]]; then link "$OM/skills/$n" "$HOME/.hermes/skills/om/$n"; fi
    if [[ -d $HOME/.claude ]]; then link "$OM/skills/$n" "$HOME/.claude/skills/$n"; fi
  done
  [[ -d $HOME/.hermes || -d $HOME/.claude ]] || warn "no ~/.hermes or ~/.claude: point your agent at $OM/skills and $OM/AGENTS.md"
}

# ---------------------------------------------------------------- coredump
install_coredump() {
  say "== coredump limit"
  local f=/etc/systemd/user.conf.d/10-coredump.conf
  if [[ -f $f ]]; then ok "$f exists"; else
    run sudo mkdir -p /etc/systemd/user.conf.d
    if ((DRY)); then echo "  [dry] write $f"; else
      printf '# Om: let user processes dump core so om-crash-watch / om-diagnose-crash have evidence\n[Manager]\nDefaultLimitCORE=infinity\n' | sudo tee "$f" >/dev/null
    fi
    ok "$f (active after re-login)"
  fi
  have coredumpctl || warn "systemd-coredump is not installed (see packages/)"
}

# ---------------------------------------------------------------- checks
checks() {
  say "== checks"
  local v
  if have Hyprland; then
    v=$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ -n $v ]] && printf '%s\n0.55.0\n' "$v" | sort -V -C; then
      [[ $v == 0.55.0 ]] && ok "Hyprland $v" || warn "Hyprland $v < 0.55: Om uses the Lua config, upgrade Hyprland"
    else ok "Hyprland $v"; fi
    ((DRY)) || Hyprland --verify-config 2>&1 | tail -1 | sed 's/^/  /'
  else warn "Hyprland not installed (use --packages or see README)"; fi
  if have waybar && [[ ! -x $HOME/.local/opt/waybar-git/bin/waybar ]]; then
    v=$(waybar --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    warn "waybar $v: workspace clicks need Lua dispatch (Waybar git >= e17c0d9f). See README 'Waybar'."
  fi
  for v in uwsm foot fuzzel mako jq grim slurp wl-copy cliphist tmux; do have "$v" || warn "$v missing"; done
}

((DRY)) && say "DRY RUN: nothing will be changed"
((DO_PKG))    && install_packages
((DO_FONTS))  && install_fonts
((DO_GTK))    && install_gtk_theme
link_configs
link_units
((DO_SKILLS)) && install_skills
((DO_CORE))   && install_coredump
checks
say ""
say "Done. Log out and choose the 'Hyprland (uwsm-managed)' session. Super+K shows all hotkeys."
[[ -d $BACKUP ]] && say "Replaced files were saved to $BACKUP"
exit 0
