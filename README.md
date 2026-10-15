# Om

**Om** — оболочка в духе [Omarchy](https://omarchy.org) для любого дистрибутива Linux: Hyprland, waybar, foot, tmux, единая тема Tokyo Night и встроенная работа с ИИ-агентами. Ставится поверх существующей системы, не заменяя её.

> English: Om brings Omarchy's ideas (keyboard-driven Hyprland desktop, Tokyo Night everywhere, agent-friendly tooling) to any Linux distro as a user-level overlay. Tested on Debian 13; Arch/Fedora package lists are provided but untested. For AI agents: see [docs/INSTALL-AGENTS.md](docs/INSTALL-AGENTS.md).

## Что это и зачем

Omarchy от DHH — красивый и удобный десктоп, но это отдельный дистрибутив на Arch: ставится с нуля и живёт по своим правилам. Om берёт из него лучшие идеи и переносит их на ту систему, что у вас уже есть:

- **рядом с другим окружением**: GNOME, KDE или Cinnamon продолжают работать, Hyprland выбирается отдельной сессией на экране входа;
- **из обычных пакетов дистрибутива**, без своего репозитория;
- **конфиги — это симлинки на git-репозиторий**: любое изменение видно в `git diff` и откатывается одной командой;
- **рассчитано на ИИ-агентов**: в репо есть скиллы и инструкция, с которыми агент (Hermes, Claude Code и др.) может сам ставить, настраивать и чинить оболочку.

## Возможности

**Рабочий стол (Hyprland ≥ 0.55, Lua-конфиг)**
- Управление с клавиатуры, у каждой горячей клавиши есть описание. **Super+K** открывает шпаргалку по всем клавишам, в терминале то же самое даёт команда `hk`. Полный список: [docs/keybindings.md](docs/keybindings.md).
- **Перейти или запустить** (Super+Shift+B/T/O/E): если окно браузера, Telegram, Obsidian или редактора уже открыто, клавиша переключает на него, а не открывает второе.
- Окна: «выдернуть» окно поверх всех (Super+O), прозрачность (Super+Backspace), убрать зазоры и рамки (Super+Shift+Backspace), раскладка стола dwindle или scrolling (Super+L), закрыть все окна с подтверждением (Ctrl+Alt+Del).
- Меню питания без пункта сна (Super+Esc): подходит для десктопа на сервере.
- Скриншоты, история буфера обмена (Super+Shift+V), ночной свет (Super+Ctrl+N), экранные индикаторы громкости.
- **OCR**: выделяете область экрана — текст (русский и английский) попадает в буфер (Super+Ctrl+PrtSc) или сразу уходит ИИ-агенту (Super+Alt+PrtSc).
- Настройки конкретной машины (мониторы, особенности видеокарты, свои клавиши) лежат в `local.lua`. Этот файл не попадает в git.

**Панель waybar**: кнопка меню программ, рабочие столы 1–5, заголовок окна, часы, статус ИИ-агента Hermes, раскладка клавиатуры, звук, CPU, RAM, трей.

**ИИ-агенты**
- Раскладки tmux для работы с агентами: `tdl hermes` (редактор, агент и shell в одном окне), `tds` (сетка 2×2 с живым git diff), `tdlm` (по окну на каждый подпроект), `tsl 4 hermes` (несколько агентов рядом).
- **Разбор падений**: если программа упала, приходит уведомление с кнопкой «Разобрать с Hermes». Агент получает данные systemd-coredump и скилл `om-diagnose-crash`.
- Скиллы `om-hyprland` и `om-diagnose-crash` и инструкция [docs/INSTALL-AGENTS.md](docs/INSTALL-AGENTS.md): агент знает, где что лежит и как безопасно менять настройки.

**Терминал и shell**
- foot с темой Tokyo Night и шрифтом Roboto Mono 9. Выделение мышью — ярко-жёлтое с тёмным текстом.
- tmux: префикс **Ctrl+Space**, поэтому Ctrl+b остаётся свободным для tmux на удалённом сервере. **F12** передаёт все клавиши во вложенный tmux. Статусная строка наверху, активное окно светло-голубое.
- `ssh` внутри tmux называет окно именем сервера и возвращает обычное имя после выхода.
- Скины Tokyo Night для Midnight Commander: 256 цветов и truecolor.

**Единая тема Tokyo Night**: рамки окон, waybar, foot, tmux, mc, GTK3/GTK4 (тема Tokyonight-Dark и иконки), цветовая тема Chrome для выбранного профиля (`om-chrome-theme`).

## Чем отличается от Omarchy

| | Omarchy | Om |
|---|---|---|
| Что это | Отдельный дистрибутив (Arch), ставится на чистый диск | Набор конфигов и скриптов поверх вашего дистрибутива |
| Дистрибутивы | Только Arch | Debian 13 (проверено), Arch и Fedora (списки пакетов, без проверки) |
| Другие окружения | Только Omarchy | Работает рядом с GNOME, KDE и Cinnamon; юниты Hyprland не запускаются в других сессиях |
| Пакеты | pacman и свой репозиторий | Только пакеты дистрибутива; Roboto Mono и GTK-тема скачиваются с GitHub |
| Темы | 24 темы и переключатель | Одна тема, Tokyo Night, везде одинаковая |
| Утилиты | Около 470 команд `omarchy-*`, меню через walker | Около 15 скриптов `om-*`, меню и шпаргалка через fuzzel |
| Терминал и софт | Свой набор программ (Chromium, neovim, btop, lazygit и др.) | Только оболочка; программы на клавишах заменяются в `bindings.lua` |
| Сон | Есть | Нет: Om рассчитан и на десктоп на сервере |
| Агенты | Скиллы omarchy и diagnose-crash, внутренние инструменты | Скиллы `om-hyprland` и `om-diagnose-crash` для Hermes и Claude Code, инструкция для агентов, кнопка разбора падений |
| Языки | Английский | Русские подписи клавиш и меню; OCR на русском и английском |
| Откат | Переустановка или снапшоты | `git revert` и бэкапы заменённых файлов в `~/.local/state/om/backups/` |

Ещё в Om есть то, чего нет в Omarchy: переименование окон tmux при ssh, режим F12 для вложенного tmux, настройки машины в `local.lua`, юниты только для сессии Hyprland (`ConditionEnvironment`), цветовая тема Chrome только для одного профиля.

## Требования

- **Hyprland ≥ 0.55** с Lua-конфигом. В Debian 13 он есть в `trixie-backports`, в Arch — в основном репозитории, в Fedora — в COPR.
- **Waybar с Lua-dispatch** (git не старше коммита `e17c0d9f` от 2026-04-29). Со старым waybar кнопки рабочих столов не переключают столы. Что делать — в разделе [Waybar](#waybar).
- systemd (пользовательские юниты), uwsm, Wayland.

## Установка

```bash
git clone https://github.com/AstroiLL/Om.git ~/Om
cd ~/Om
./install.sh --dry-run --all   # посмотреть, что будет сделано
./install.sh --all             # пакеты (sudo), шрифт, GTK-тема, конфиги, скиллы, coredump
```

Части по отдельности:

| Ключ | Что делает | sudo |
|---|---|---|
| (без ключей) | Симлинки конфигов и скриптов, юниты пользователя, строки в `~/.bashrc` и `~/.tmux.conf` | нет |
| `--packages` | Пакеты из `packages/<дистрибутив>.txt`; недоступные перечисляет | да |
| `--fonts` | Шрифт Roboto Mono в `~/.local/share/fonts`, если его нет | нет |
| `--gtk-theme` | GTK-тема и иконки Tokyonight-Dark, настройки gsettings | нет |
| `--skills` | Скиллы в `~/.hermes/skills/om/` и `~/.claude/skills/` | нет |
| `--coredump` | `/etc/systemd/user.conf.d/10-coredump.conf`, чтобы разбор падений получал дампы | да |
| `--dry-run` | Только показать действия | — |

После установки выйдите из системы и на экране входа выберите сессию **Hyprland (uwsm-managed)**. Первым делом нажмите **Super+K**.

Все файлы, которые установщик заменяет, сначала переносятся в `~/.local/state/om/backups/<дата>/`. Повторный запуск ничего не ломает.

### Debian 13 (trixie)

```bash
echo 'deb http://deb.debian.org/debian trixie-backports main' | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt update
sudo apt install -t trixie-backports hyprland uwsm xdg-desktop-portal-hyprland hyprpaper hypridle hyprlock hyprpolkitagent hyprsunset
./install.sh --all
```

### Arch / Fedora

`./install.sh --packages` ставит то, что есть в репозиториях, и перечисляет недостающее. В Fedora сначала подключите COPR с Hyprland, например `sudo dnf copr enable solopasha/hyprland`. Установка на этих дистрибутивах не проверялась — пишите в issues.

### Waybar

В Debian 13 waybar версии 0.12, он слишком старый. Соберите из git:

```bash
git clone https://github.com/Alexays/Waybar ~/src/waybar && cd ~/src/waybar
sudo apt build-dep waybar      # в Debian 13 сначала: sudo apt install -t trixie-backports libxkbcommon-dev libxkbregistry-dev
meson setup build --prefix="$HOME/.local/opt/waybar-git" && ninja -C build && meson install -C build
```

Установщик сам найдёт `~/.local/opt/waybar-git/bin/waybar` и подключит его drop-in-файлом к `waybar.service`.

### Настройки своей машины

`configs/hypr/local.lua` создаётся из `local.lua.example` и в git не попадает. Здесь задаются мониторы, программный курсор (нужен для nouveau и некоторых виртуальных машин, если выделение мышью «съезжает»), блюр и тени для мощной видеокарты, другие раскладки клавиатуры и свои клавиши.

## Структура

```
configs/hypr/        hyprland.lua, bindings.lua, hypridle/hyprpaper/hyprsunset, local.lua.example
configs/waybar/      config.jsonc, style.css
configs/foot/        foot.ini, tokyo-night.ini
configs/tmux/        tmux.conf, tokyo-night.conf
configs/bash/        om.bash — tdl/tds/tdlm/tsl, алиасы, ssh → имя окна tmux
configs/mc/skins/    Tokyo Night для Midnight Commander
configs/gtk/         поверх темы GTK3/4: выделение, схема gtksourceview
configs/systemd-user/ om-crash-watch, swayosd, drop-ins hyprland-only
scripts/             om-* (см. om-hyprland/SKILL.md)
skills/              om-hyprland, om-diagnose-crash
packages/            списки пакетов debian/arch/fedora
docs/                keybindings.md, INSTALL-AGENTS.md
install.sh           установщик
```

## Удаление

```bash
systemctl --user disable --now om-crash-watch swayosd
rm ~/.config/hypr ~/.config/waybar ~/.config/foot ~/.local/share/om ~/.local/bin/om-*
# удалить строки "Om ..." из ~/.bashrc и ~/.tmux.conf; прежние файлы — в ~/.local/state/om/backups/
```

## Известные ограничения

- В GNOME Text Editor (libadwaita) выделение пока цвета акцента, а не жёлтое. В foot и tmux жёлтое работает.
- В Debian hyprpaper может падать при выключении и включении монитора (DPMS) на nouveau; systemd его перезапускает.
- Arch и Fedora не проверены.

## Лицензия и благодарности

MIT. Идеи, часть скриптов и скиллов адаптированы из [omacom/omarchy](https://github.com/omacom/omarchy) (MIT). Палитра — Tokyo Night. GTK-тема — [Fausto-Korpsvart/Tokyonight-GTK-Theme](https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme) (GPL-3.0, скачивается при установке и в репозиторий не входит). Шрифт Roboto Mono — Google Fonts, Apache 2.0.
