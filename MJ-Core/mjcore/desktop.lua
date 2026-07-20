local config = dofile("/mjcore/core/config.lua")
local theme = dofile("/mjcore/core/theme.lua")
local ui = dofile("/mjcore/core/ui.lua")
local apps = dofile("/mjcore/core/apps.lua")

local monitor, monitorName = ui.findMonitor(config.monitorName)
if not monitor then error("No hay monitor conectado", 0) end

monitor.setTextScale(config.textScale)

local selected = 1
local buttons = {}
local running = true
local redraw = true

local function buildLayout()
    local w, h = monitor.getSize()
    buttons = {}

    local columns = 2
    local rows = math.ceil(#apps / columns)
    local gapX = 3
    local gapY = 1
    local marginX = 3
    local contentTop = 4
    local contentBottom = h - 2

    local availableW = w - (marginX * 2) - gapX
    local availableH = contentBottom - contentTop + 1 - ((rows - 1) * gapY)

    local buttonW = math.floor(availableW / columns)
    local buttonH = math.max(3, math.floor(availableH / rows))

    for i, app in ipairs(apps) do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)

        table.insert(buttons, {
            x = marginX + col * (buttonW + gapX),
            y = contentTop + row * (buttonH + gapY),
            w = buttonW,
            h = buttonH,
            label = app.label,
            subtitle = app.subtitle,
            app = app
        })
    end
end

local function draw()
    local w, h = monitor.getSize()
    monitor.setBackgroundColor(theme.background)
    monitor.setTextColor(theme.text)
    monitor.clear()

    local timeText = textutils.formatTime(os.time(), true)
    ui.header(monitor, config.title, timeText, theme)

    for i, button in ipairs(buttons) do
        ui.button(monitor, button, i == selected, theme)
    end

    ui.footer(
        monitor,
        "Toca una app | Flechas + Enter",
        "SISTEMA OK",
        theme
    )
end

local function showMessage(title, message, color)
    local w, h = monitor.getSize()
    local boxW = math.min(w - 6, 48)
    local boxH = 7
    local x = math.floor((w - boxW) / 2) + 1
    local y = math.floor((h - boxH) / 2) + 1

    ui.fill(monitor, x, y, boxW, boxH, theme.panel)
    ui.center(monitor, y + 1, title, color or theme.accent, theme.panel)

    local line = ui.clip(message, boxW - 4)
    ui.write(monitor, x + 2, y + 3, line, theme.text, theme.panel)
    ui.write(monitor, x + 2, y + 5, "Toca o pulsa una tecla", theme.muted, theme.panel)

    os.pullEvent()
    redraw = true
end

local function launch(index)
    local app = apps[index]
    if not app then return end

    if not fs.exists(app.path) then
        showMessage(app.label, "Aplicacion no instalada todavia.", theme.warning)
        return
    end

    local ok, result = pcall(function()
        return dofile(app.path)({
            monitor = monitor,
            monitorName = monitorName,
            ui = ui,
            theme = theme,
            config = config
        })
    end)

    if not ok then
        showMessage("ERROR EN " .. app.label, tostring(result), theme.danger)
    end

    monitor.setTextScale(config.textScale)
    buildLayout()
    redraw = true
end

buildLayout()
draw()

local timer = os.startTimer(config.refreshSeconds)

while running do
    local event, a, b, c = os.pullEvent()

    if event == "monitor_touch" and a == monitorName then
        local index = ui.hit(buttons, b, c)
        if index then
            selected = index
            draw()
            launch(index)
        end

    elseif event == "key" then
        local key = a
        local columns = 2

        if key == keys.left and selected > 1 then
            selected = selected - 1
            redraw = true
        elseif key == keys.right and selected < #apps then
            selected = selected + 1
            redraw = true
        elseif key == keys.up and selected - columns >= 1 then
            selected = selected - columns
            redraw = true
        elseif key == keys.down and selected + columns <= #apps then
            selected = selected + columns
            redraw = true
        elseif key == keys.enter or key == keys.space then
            launch(selected)
        elseif key == keys.q then
            running = false
        end

    elseif event == "monitor_resize" and a == monitorName then
        monitor.setTextScale(config.textScale)
        buildLayout()
        redraw = true

    elseif event == "timer" and a == timer then
        redraw = true
        timer = os.startTimer(config.refreshSeconds)
    end

    if redraw then
        draw()
        redraw = false
    end
end

monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()
monitor.setCursorPos(1, 1)
