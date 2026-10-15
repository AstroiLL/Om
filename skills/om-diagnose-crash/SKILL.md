---
name: om-diagnose-crash
description: "Use when a program crashed or dumped core on Linux."
version: 1.1.0
license: MIT
author: Om (adapted from omacom/omarchy default/agents/skills/diagnose-crash, MIT)
metadata:
  hermes:
    tags: [crash, segfault, coredump, gdb, debuginfod, diagnosis]
    related_skills: [om-hyprland]
---

# Diagnosing a crash

## When to Use

Triggers: segfault, SIGSEGV, SIGABRT, core dump, "why did X crash / disappear", "X keeps crashing", "Hyprland/waybar died". Om's `om-crash-watch` notification opens this skill with the PID, binary and signal.

Work from evidence. The goal is an honest account of what happened, not a plausible story. **Diagnosis reads; it does not fix, tidy, or reconfigure.**

## Prerequisites (check, don't assume)

Stored cores need `systemd-coredump` + `gdb` (+ `elfutils` for `eu-stack`). Without them fall back to the journal (`journalctl -b -p warning`, `journalctl -k -b | grep -iE 'segfault|trap|oom'`). Installing them is a system change — ask first:

```bash
sudo apt install systemd-coredump gdb elfutils      # Debian/Ubuntu
sudo pacman -S --needed gdb elfutils                 # Arch (coredump is part of systemd)
sudo dnf install gdb elfutils                        # Fedora
```

A process that had `ulimit -c 0` leaves no core even with systemd-coredump. Om sets `DefaultLimitCORE=infinity` for the user manager (see README).

## Establish the facts

- `coredumpctl info <pid|name>` — backtrace and the **command line** (often the whole answer).
- `coredumpctl list` — one-off or pattern? Several programs dying together points elsewhere (GPU/driver, compositor, OOM).

## Rule out the boring causes first

`free -h`, `journalctl -k -b | grep -i oom`. An OOM-killed process is not a bug in that process. Check GPU driver messages (`journalctl -k -b | grep -iE 'nouveau|amdgpu|i915|xe|nvidia'`) for GPU-side crashes of Wayland apps; monitor hot-plug / DPMS events often kill wallpaper and bar daemons.

## Correlate against the timeline

Compare the crash timestamp with: filesystem mtimes (same second = likely trigger); the journal around that moment; recent package changes (`/var/log/dpkg.log`, `/var/log/pacman.log`, `dnf history`); recent commits in the Om repo (`git -C ~/.local/share/om log --since=...`).

## Read the whole core, not just frame 0

Other thread stacks show work in flight (loaders, IPC readers, GPU queues). Note third-party code in the address space (plugins, extensions, out-of-tree drivers) but don't blame it without evidence.

## Symbolize (debuginfod)

```bash
core=$(mktemp -t crash-XXXXXX.core); trap 'rm -f "$core"' EXIT
coredumpctl dump <pid> --output="$core"
# DEBUGINFOD_URLS: Debian https://debuginfod.debian.net, Arch https://debuginfod.archlinux.org,
# Fedora https://debuginfod.fedoraproject.org, Ubuntu https://debuginfod.ubuntu.com
DEBUGINFOD_URLS="<distro url>" gdb -q <executable> "$core" \
  -batch -ex 'set debuginfod enabled on' -ex 'thread apply all bt'
```

A core is a copy of process memory (passwords, tokens, documents): fresh `mktemp` path, delete when done, never leave it lying around, never paste raw memory into chat. Frames without debug info stay unresolved — say so, never invent function names; describe the shape (which library, signal handler vs main loop vs worker thread).

## Report

1. What crashed and what it was doing.
2. Most likely mechanism — separate what the evidence **proves** from what you **infer**.
3. Whether user data was lost and where to recover it (check trash / autosaves before concluding).
4. Will it recur; what would avoid or fix it.

If the cause is ambiguous, say so instead of assembling confidence from guesswork.

## Upstream

Most app crashes are upstream bugs of that app, not of the Om config. Hyprland crash → gather `hyprctl version`, `hyprctl systeminfo`, `$XDG_RUNTIME_DIR/hypr/*/hyprland.log`, `~/.cache/hyprland/hyprlandCrashReport*.txt`; name the right tracker (hyprwm/Hyprland, Alexays/Waybar, the distro bug tracker for packaging). File nothing without the user's go-ahead. Leave the system as you found it; the only cleanup is your own extracted core.

Mute repeated notifications for a known-flaky program: `touch ~/.local/state/om/crash-ignore/<name>`.
