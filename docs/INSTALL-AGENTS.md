# Installing and maintaining Om — instructions for AI agents

For AI coding/ops agents (Hermes, Claude Code, Codex, OpenCode, …) asked to install, update, customize or debug **Om** on a user's machine. The user-facing description is in [README.md](../README.md) (Russian).

## Ground rules

1. **Ask before system changes.** Package installs, `/etc` edits, repository additions (backports, COPR, AUR), display-manager changes need explicit user approval. Linking configs into `$HOME` (`./install.sh` without flags) is user-level and reversible, but still tell the user what will be replaced.
2. **Dry run first.** Always run `./install.sh --dry-run [flags]` and show the user the summary before the real run.
3. **Never** reboot, change the default session, touch kernels/GPU drivers, or remove the user's other desktop environment.
4. **Verify, don't assume.** Every step below has a check; report real command output, not expectations.
5. **Machine specifics go to `configs/hypr/local.lua`** (git-ignored), never into shared files. Never commit host names, IPs, ssh aliases, personal paths, tokens or keys — the repo is public.

## Install procedure

```bash
# 0. Facts
. /etc/os-release; echo "$ID $VERSION_ID ($ID_LIKE)"
Hyprland --version 2>/dev/null | head -1      # need >= 0.55 (Lua config)
waybar --version 2>/dev/null                   # need Lua dispatch (git >= e17c0d9f), see README "Waybar"
echo "$XDG_SESSION_TYPE $XDG_CURRENT_DESKTOP"  # where you are running now

# 1. Get the repo
git clone https://github.com/AstroiLL/Om.git ~/Om && cd ~/Om

# 2. Plan (show to the user)
./install.sh --dry-run --all

# 3. Packages — only with approval. Debian 13 needs trixie-backports for Hyprland 0.55 (README).
./install.sh --packages

# 4. User-level parts
./install.sh --fonts --gtk-theme --skills
./install.sh                # configs, scripts, user units (idempotent)

# 5. Optional, sudo: core dumps for crash diagnosis
./install.sh --coredump

# 6. Optional: Hermes Agent (official installer, only if `hermes` is missing) + Hermes Desktop build.
#    Runs a remote install script and an Electron build (network, minutes) — ask the user first.
./install.sh --hermes-desktop
```

Hermes Desktop check: `ls ~/.hermes/hermes-agent/apps/desktop/release/linux*-unpacked/Hermes`, then in the session `om-hermes-desktop` and `hyprctl clients -j | jq -r '.[].class' | grep com.nousresearch.hermes`.

### Checks after install

```bash
ls -l ~/.local/share/om ~/.config/hypr ~/.config/waybar ~/.config/foot   # symlinks into the repo
Hyprland --verify-config | tail -1                                      # "config ok"
systemctl --user is-enabled om-crash-watch.service                      # enabled
bash -ic 'type -t tdl; alias hk'                                        # shell helpers loaded
grep -n 'om/configs/tmux' ~/.tmux.conf                                  # tmux config sourced
```

Inside a running Hyprland session (`source ~/.local/share/om/scripts/om-env` first when you are in a non-session shell):

```bash
hyprctl reload && hyprctl configerrors            # empty output = good
om-keybinds --print | head                        # cheatsheet comes from bind descriptions
systemctl --user is-active waybar mako om-crash-watch
grim -g "0,0 1920x30" /tmp/bar.png                 # then LOOK at the screenshot
```

If the user is not in a Hyprland session yet: tell them to log out and pick **Hyprland (uwsm-managed)**, then come back and run the in-session checks.

## Customizing

Load the skill `skills/om-hyprland/SKILL.md` (installed to `~/.hermes/skills/om/` and `~/.claude/skills/` by `--skills`). Key rules:

- Hyprland ≥ 0.55 uses **Lua**: `hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'`; `hyprctl keyword` does not work, use `hyprctl eval '<lua>'` for runtime-only changes.
- Every keybinding goes through `bind(keys, description, dispatcher)` in `configs/hypr/bindings.lua` and **must have a description** (Super+K cheatsheet). Check `hyprctl binds` and tell the user what a key did before rebinding. Regenerate `docs/keybindings.md` with `om-keybinds --print`.
- Theme colours live in several files (Hyprland borders, waybar CSS, foot, tmux, mc skins, GTK `selection.css`). Change all of them together.
- Validate → reload → screenshot → commit. Roll back with git.

## Debugging

- Crashes: skill `skills/om-diagnose-crash/SKILL.md` (read-only diagnosis, ask before fixing). `om-crash-diagnose <pid>` opens Hermes with it.
- Session health: `om-hypr-check`.
- Logs: `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log`, `journalctl --user -b -u 'wayland-wm@*'`, `journalctl --user -u waybar`.
- Workspace buttons do nothing → Waybar too old (no Lua dispatch).
- Mouse selection lands beside the pointer → hardware cursor offset (nouveau, some VMs): `hl.config({ cursor = { no_hardware_cursors = 1 } })` in `local.lua`.
- Duplicate bars/daemons → something `exec`s waybar/mako/hyprpaper in addition to their systemd units; Om starts them only as units.

## Updating

```bash
cd ~/.local/share/om && git pull && ./install.sh --dry-run && ./install.sh
```

Then in the session: `hyprctl reload`, `systemctl --user restart waybar`, `tmux source-file ~/.tmux.conf`.

## Uninstall

See README → «Удаление». Replaced files are in `~/.local/state/om/backups/<timestamp>/`.
