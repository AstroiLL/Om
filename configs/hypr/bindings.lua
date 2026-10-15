-- Om keybindings (Omarchy-style). Every bind carries a description -> Super+K cheatsheet.
-- Scripts: <repo>/scripts, reached via the ~/.local/share/om symlink made by install.sh.
-- Adapted from omacom/omarchy default/hypr/bindings/*.lua (MIT)

local S           = os.getenv("HOME") .. "/.local/share/om/scripts/"
local terminal    = "uwsm app -- foot"
local fileManager = "uwsm app -- nemo"
local menu        = "pkill -x fuzzel || fuzzel --launch-prefix='uwsm app -- '"
local mainMod     = "SUPER"

local function bind(keys, desc, dsp, opts)
    opts = opts or {}
    opts.description = desc
    if type(dsp) == "string" then dsp = hl.dsp.exec_cmd(dsp) end
    hl.bind(keys, dsp, opts)
end

local function focus_or_launch(class_re, cmd)
    return S .. "om-launch-or-focus '" .. class_re .. "' '" .. cmd .. "'"
end

-------------------- Приложения --------------------
bind(mainMod .. " + RETURN",             "Терминал",                          terminal)
bind(mainMod .. " + Q",                  "Терминал",                          terminal)
bind(mainMod .. " + ALT + RETURN",       "Терминал с tmux (сессия Work)",     terminal .. " -e bash -lc 'tmux attach || tmux new -s Work'")
bind(mainMod .. " + SPACE",              "Меню программ",                     menu)
bind(mainMod .. " + R",                  "Меню программ",                     menu)
bind(mainMod .. " + E",                  "Файловый менеджер",                 fileManager)
bind(mainMod .. " + SHIFT + F",          "Файловый менеджер",                 fileManager)
bind(mainMod .. " + SHIFT + RETURN",     "Chrome: новое окно",                "uwsm app -- google-chrome")
bind(mainMod .. " + SHIFT + B",          "Chrome (перейти или запустить)",    focus_or_launch("google-chrome", "uwsm app -- google-chrome"))
bind(mainMod .. " + SHIFT + T",          "Telegram (перейти или запустить)",  focus_or_launch("org\\.telegram\\.desktop.*", "uwsm app -- sh -c \"command -v telegram-desktop >/dev/null && exec telegram-desktop || exec ~/Telegram/Telegram\""))
bind(mainMod .. " + SHIFT + O",          "Obsidian (перейти или запустить)",  focus_or_launch("obsidian", "uwsm app -- obsidian"))
bind(mainMod .. " + SHIFT + E",          "Текстовый редактор (перейти или запустить)", focus_or_launch("org\\.gnome\\.TextEditor", "uwsm app -- gnome-text-editor"))
bind(mainMod .. " + SHIFT + CTRL + A",   "Hermes (перейти или запустить)",    focus_or_launch("hermes", "uwsm app -- foot --app-id=hermes -T Hermes hermes"))

-------------------- Окна --------------------
bind(mainMod .. " + C",                  "Закрыть окно",                      hl.dsp.window.close())
bind(mainMod .. " + W",                  "Закрыть окно",                      hl.dsp.window.close())
bind("CTRL + ALT + DELETE",              "Закрыть все окна (с подтверждением)", S .. "om-close-all")
bind(mainMod .. " + V",                  "Плавающее / тайл",                  hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + T",                  "Плавающее / тайл",                  hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + P",                  "Псевдо-тайл",                       hl.dsp.window.pseudo())
bind(mainMod .. " + J",                  "Сменить направление разделения",    hl.dsp.layout("togglesplit"))
bind(mainMod .. " + F",                  "Полный экран",                      hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(mainMod .. " + ALT + F",            "Развернуть (с панелью)",            hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mainMod .. " + CTRL + F",           "Полный экран внутри плитки",        hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }))
bind(mainMod .. " + O",                  "Выдернуть окно: плавающее и поверх", S .. "om-window-pop")
bind(mainMod .. " + L",                  "Раскладка стола: dwindle / scrolling", S .. "om-layout-toggle")
bind(mainMod .. " + BACKSPACE",          "Прозрачность окна",                 S .. "om-window-transparency")
bind(mainMod .. " + SHIFT + BACKSPACE",  "Зазоры и рамки вкл/выкл",           S .. "om-toggle-gaps")

bind(mainMod .. " + left",               "Фокус влево",                       hl.dsp.focus({ direction = "left" }))
bind(mainMod .. " + right",              "Фокус вправо",                      hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + up",                 "Фокус вверх",                       hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + down",               "Фокус вниз",                        hl.dsp.focus({ direction = "down" }))
bind(mainMod .. " + SHIFT + left",       "Поменять окна: влево",              hl.dsp.window.swap({ direction = "l" }))
bind(mainMod .. " + SHIFT + right",      "Поменять окна: вправо",             hl.dsp.window.swap({ direction = "r" }))
bind(mainMod .. " + SHIFT + up",         "Поменять окна: вверх",              hl.dsp.window.swap({ direction = "u" }))
bind(mainMod .. " + SHIFT + down",       "Поменять окна: вниз",               hl.dsp.window.swap({ direction = "d" }))
bind("ALT + TAB",                        "Следующее окно",                    hl.dsp.window.cycle_next())
bind("ALT + TAB",                        "Следующее окно (наверх)",           hl.dsp.window.bring_to_top())
bind("ALT + SHIFT + TAB",                "Предыдущее окно",                   hl.dsp.window.cycle_next({ next = false }))
bind("ALT + SHIFT + TAB",                "Предыдущее окно (наверх)",          hl.dsp.window.bring_to_top())

bind(mainMod .. " + mouse:272",          "Перетащить окно",                   hl.dsp.window.drag(),   { mouse = true })
bind(mainMod .. " + mouse:273",          "Изменить размер окна",              hl.dsp.window.resize(), { mouse = true })

-------------------- Рабочие столы --------------------
for i = 1, 10 do
    local key = i % 10
    bind(mainMod .. " + " .. key,                 "Стол " .. i,                         hl.dsp.focus({ workspace = i }))
    bind(mainMod .. " + SHIFT + " .. key,         "Окно на стол " .. i,                 hl.dsp.window.move({ workspace = i }))
    bind(mainMod .. " + SHIFT + ALT + " .. key,   "Окно на стол " .. i .. " (остаться)", hl.dsp.window.move({ workspace = i, follow = false }))
end
bind(mainMod .. " + TAB",                "Следующий стол",                    hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + SHIFT + TAB",        "Предыдущий стол",                   hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + CTRL + TAB",         "Прошлый стол",                      hl.dsp.focus({ workspace = "previous" }))
bind(mainMod .. " + mouse_down",         "Следующий стол",                    hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up",           "Предыдущий стол",                   hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + S",                  "Scratchpad показать/скрыть",        hl.dsp.workspace.toggle_special("magic"))
bind(mainMod .. " + SHIFT + S",          "Окно в scratchpad",                 hl.dsp.window.move({ workspace = "special:magic" }))

-------------------- Система и меню --------------------
bind(mainMod .. " + K",                  "Шпаргалка горячих клавиш",          S .. "om-keybinds")
bind(mainMod .. " + ESCAPE",             "Меню питания",                      S .. "om-power-menu")
bind(mainMod .. " + CTRL + L",           "Блокировка экрана",                 "loginctl lock-session")
bind(mainMod .. " + M",                  "Выйти из Hyprland",                 "uwsm stop")
bind(mainMod .. " + SHIFT + V",          "История буфера обмена",             "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy")
bind(mainMod .. " + CTRL + N",           "Ночной свет вкл/выкл",              S .. "om-nightlight")

-------------------- Захват экрана --------------------
bind("Print",                            "Скриншот области в буфер",          "grim -g \"$(slurp)\" - | wl-copy")
bind("SHIFT + Print",                    "Скриншот экрана в ~/Pictures/Screenshots", "mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%F_%H-%M-%S).png")
bind(mainMod .. " + CTRL + Print",       "Текст с экрана (OCR) в буфер",      S .. "om-ocr")
bind(mainMod .. " + ALT + Print",        "Текст с экрана (OCR) в Hermes",     S .. "om-ocr --hermes")

-------------------- Звук (OSD swayosd) --------------------
bind("XF86AudioRaiseVolume", "Громкость +", "swayosd-client --output-volume raise",       { locked = true, repeating = true })
bind("XF86AudioLowerVolume", "Громкость -", "swayosd-client --output-volume lower",       { locked = true, repeating = true })
bind("XF86AudioMute",        "Звук вкл/выкл", "swayosd-client --output-volume mute-toggle", { locked = true })
bind("XF86AudioMicMute",     "Микрофон вкл/выкл", "swayosd-client --input-volume mute-toggle", { locked = true })
bind("XF86AudioNext",        "Следующий трек", "playerctl next",       { locked = true })
bind("XF86AudioPause",       "Пауза",          "playerctl play-pause", { locked = true })
bind("XF86AudioPlay",        "Воспроизведение","playerctl play-pause", { locked = true })
bind("XF86AudioPrev",        "Предыдущий трек","playerctl previous",   { locked = true })
