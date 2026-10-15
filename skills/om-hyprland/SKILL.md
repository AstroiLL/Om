---
name: om-hyprland
description: "Use when customizing an Om (Omarchy-like) Hyprland desktop."
version: 1.0.0
license: MIT
author: Om (adapted from omacom/omarchy default/agents/skills/omarchy, MIT)
metadata:
  hermes:
    tags: [hyprland, wayland, waybar, desktop, omarchy, om, lua, tmux, foot]
    related_skills: [om-diagnose-crash]
---

# Om Hyprland desktop

End-user customization of a Hyprland desktop installed from the Om repo (https://github.com/AstroiLL/Om). Om ports Omarchy ideas to any distro; Omarchy's `omarchy-*` CLI does NOT exist here — use `hyprctl`, systemd user units, plain files and the `om-*` scripts.

## When to Use

**Before editing anything in `~/.config/hypr`, `~/.config/waybar`, `~/.config/foot`, `~/.config/gtk-*`, `~/.tmux.conf`, mc skins or `om-*` scripts — use this skill.** Covers keybindings, monitors, window rules, gaps/borders/blur, bar, launcher, notifications, idle/lock, screenshots/OCR, keyboard layouts, theme colours, tmux.

## Layout

The repo lives anywhere; `install.sh` links it to `~/.local/share/om` (use this path, not the clone path).

| What | Path (relative to `~/.local/share/om`) | Linked as |
|---|---|---|
| Hyprland (Lua) | `configs/hypr/hyprland.lua`, `bindings.lua` | `~/.config/hypr` |
| Machine-only settings | `configs/hypr/local.lua` (git-ignored; template `local.lua.example`) | — |
| Runtime toggles | `~/.local/state/om/hypr/{no-gaps,workspace-layouts}.lua` | loaded last |
| Waybar | `configs/waybar/{config.jsonc,style.css}` | `~/.config/waybar` |
| foot | `configs/foot/{foot.ini,tokyo-night.ini}` | `~/.config/foot` |
| tmux | `configs/tmux/{tmux.conf,tokyo-night.conf}` | sourced from `~/.tmux.conf` |
| bash helpers | `configs/bash/om.bash` | sourced from `~/.bashrc` |
| mc skins | `configs/mc/skins/` | `~/.local/share/mc/skins` |
| GTK overrides | `configs/gtk/` | `~/.config/gtk-3.0/gtk.css`, `~/.config/gtk-4.0/gtk*.css` |
| systemd user units | `configs/systemd-user/` (+ `dropins/hyprland-only.conf`) | `~/.config/systemd/user/` |
| Scripts | `scripts/om-*` | `~/.local/bin/om-*` |

Never edit package-owned files (`/usr/share/hypr/*`, `/usr/lib/systemd/user/*`, `/etc/xdg/*`); override with user files and drop-ins. Put machine-specific changes (monitor modes, GPU quirks, extra binds) into `local.lua`, not into the shared files.

## Talking to the running session from an agent shell

```bash
source ~/.local/share/om/scripts/om-env   # exports HYPRLAND_INSTANCE_SIGNATURE, WAYLAND_DISPLAY
```

## Safe change procedure

1. Read the file; `git -C ~/.local/share/om status` must be clean or understood.
2. Edit (Hyprland auto-reloads on save).
3. Validate: `Hyprland --verify-config` → `config ok`, then `hyprctl reload` and `hyprctl configerrors` (empty = good).
4. Commit in the repo; for anything visual take a screenshot (`grim -g "x,y wxh" shot.png`, geometry from `hyprctl clients -j`) and look at it.

Rollback = `git checkout -- <file>` / `git revert`.

## Hyprland >= 0.55 Lua specifics

- `hyprctl dispatch` takes a **Lua expression**: `hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'`. Old `hyprctl dispatch workspace 3` fails. Translate any `.conf`-era snippet.
- `hyprctl keyword` does not work with Lua; one-off runtime change: `hyprctl eval '<lua>'` (not persisted).
- Binds go through the local `bind(keys, description, dispatcher)` helper in `bindings.lua`; **every bind needs a description** (it feeds the Super+K cheatsheet `om-keybinds`). Check `hyprctl binds` before rebinding and tell the user what the key did before.
- Monitors: `hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })` in `local.lua`; list modes with `hyprctl monitors all`.
- Window rules change between releases — read the wiki for the installed version before writing one; never rely on memorized syntax.
- Launch apps through uwsm: `uwsm app -- <cmd>`.
- Waybar must be new enough to send Lua dispatch (git >= e17c0d9f, 2026-04-29); older Waybar workspace buttons silently do nothing.

## Autostart rules

- waybar, mako, hyprpaper, hypridle, hyprpolkitagent, hyprsunset run as systemd user units under `graphical-session.target`. **Do not also `exec` them in `hyprland.lua`** → duplicate bars/daemons.
- Each has the drop-in `hyprland-only.conf` (`ConditionEnvironment=XDG_CURRENT_DESKTOP=Hyprland`) so other desktop sessions on the same machine are unaffected. Add it to any new Hyprland-only unit.
- With `Linger=yes` the user manager outlives sessions: `hyprland.lua` restarts `xdg-desktop-portal` on start so screen sharing works.
- Restart a component: `systemctl --user restart waybar|mako|hyprpaper|hypridle`.

## Scripts

| Script | Key | Omarchy origin |
|---|---|---|
| `om-keybinds [--print]` | Super+K | keybindings menu |
| `om-power-menu` | Super+Esc | system menu (no suspend; confirms reboot/poweroff) |
| `om-ocr [--hermes]` | Super+Ctrl+PrtSc / Super+Alt+PrtSc | capture-text (tesseract rus+eng) |
| `om-nightlight` | Super+Ctrl+N | toggle-nightlight (hyprsunset) |
| `om-window-pop` | Super+O | window-pop |
| `om-window-transparency` | Super+Backspace | transparency toggle |
| `om-toggle-gaps` | Super+Shift+Backspace | window-gaps-toggle |
| `om-layout-toggle` | Super+L | workspace layout dwindle↔scrolling |
| `om-close-all` | Ctrl+Alt+Del | close-all (+ confirmation) |
| `om-launch-or-focus <class-re> <cmd>` | Super+Shift+B/T/O/E | launch-or-focus |
| `om-crash-watch` (unit `om-crash-watch.service`) | — | crash-watch: notification → «Разобрать с Hermes» |
| `om-crash-diagnose <pid>` | — | agent-crash: Hermes + skill `om-diagnose-crash` |
| `om-chrome-theme` | — | Chrome colour theme per profile (Chrome must be closed) |
| `om-hypr-check` | — | session health report |

## Theme (Tokyo Night everywhere)

Palette (Omarchy `themes/tokyo-night/colors.toml`): bg `#1a1b26`, fg `#a9b1d6`, blue `#7aa2f7`, cyan `#7dcfff`, yellow `#e0af68`, bright yellow `#ffc777` (selection), border `#3b4261`. When changing a colour, change it in every place: Hyprland borders, waybar CSS, foot, tmux, mc skins, GTK `selection.css`, gtksourceview `om-tokyo.xml`.

GTK theme: Fausto-Korpsvart/Tokyonight-GTK-Theme (`install.sh --gtk-theme`), set via `gsettings org.gnome.desktop.interface gtk-theme`. libadwaita apps ignore gtk-theme; they get colours only from `~/.config/gtk-4.0/gtk.css`.

## Diagnostics

- `om-hypr-check` — session, monitors, units, portal, recent errors.
- Hyprland log: `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log`; `journalctl --user -b -u 'wayland-wm@*'`.
- Black screen after login: switch to a TTY (Ctrl+Alt+F3), read logs, pick another session in the display manager.
- Crashes: skill `om-diagnose-crash`.

## Caution

System-level changes (packages, udev, /etc, display manager) need the user's approval: check state first, make reversible changes, verify. Never reboot or touch kernels/drivers on your own.
