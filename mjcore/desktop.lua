local config = dofile("/mjcore/core/config.lua")
local theme = dofile("/mjcore/core/theme.lua")
local ui = dofile("/mjcore/core/ui.lua")
local logger = dofile("/mjcore/core/logger.lua")
local notificationsFactory = dofile("/mjcore/core/notifications.lua")
local appCore = dofile("/mjcore/core/app.lua")
local appsCore = dofile("/mjcore/core/apps.lua")

local monitor, monitorName = ui.findMonitor(config.monitorName)
if not monitor then error("No hay monitor conectado", 0) end

monitor.setTextScale(config.textScale)

local notifications = notificationsFactory.new(config, logger)
local registry = appsCore.loadRegistry()
local buttons = {}
local selected = 1
local redraw = true
local running = true

local context = {
    monitor = monitor,
    monitorName = monitorName,
    config = config,
    theme = theme,
    ui = ui,
    logger = logger,
    notifications = notifications
}

local function iconText(icon)
    local icons = {
        inventory = "[#]",
        players = "[O]",
        todo = "[=]",
        energy = "[*]",
        alarms = "[!]",
        settings = "[+]",
        updater = "[^]"
    }
    return icons[icon] or "[ ]"
end

local function buildLayout()
    local w, h = monitor.getSize()
    buttons = {}

    local columns = 3
    if w < 45 then columns = 2 end

    local rows = math.max(1, math.ceil(#registry / columns))
    local marginX = 2
    local gapX = 2
    local gapY = 1
    local contentTop = 4
    local contentBottom = h - 2

    local buttonW = math.floor((w - marginX * 2 - gapX * (columns - 1)) / columns)
    local buttonH = math.max(5, math.floor((contentBottom - contentTop + 1 - gapY * (rows - 1)) / rows))

    for i, entry in ipairs(registry) do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)

        table.insert(buttons, {
            x = marginX + col * (buttonW + gapX),
            y = contentTop + row * (buttonH + gapY),
            w = buttonW,
            h = buttonH,
            label = entry.name,
            subtitle = entry.subtitle,
            icon = iconText(entry.icon),
            entry = entry
        })
    end
end

local function drawTopbar()
    local w = monitor.getSize()
    ui.fill(monitor, 1, 1, w, 2, theme.topbar)
    ui.write(monitor, 2, 1, "M&J CORE", theme.text, theme.topbar)
    ui.write(monitor, 2, 2, "Foundation v" .. config.version, theme.muted, theme.topbar)

    local timeText = textutils.formatTime(os.time(), true)
    ui.write(monitor, w - #timeText, 1, timeText, theme.text, theme.topbar)
end

local function drawFooter()
    local w, h = monitor.getSize()
    ui.fill(monitor, 1, h, w, 1, theme.panel)
    ui.write(monitor, 2, h, "Toca una app | Flechas + Enter", theme.text, theme.panel)

    local status = "SISTEMA OK"
    ui.write(monitor, w - #status, h, status, theme.success, theme.panel)
end

local function draw()
    monitor.setBackgroundColor(theme.desktop)
    monitor.setTextColor(theme.text)
    monitor.clear()

    drawTopbar()

    for i, button in ipairs(buttons) do
        ui.button(monitor, button, i == selected, theme)
    end

    drawFooter()
    ui.notification(monitor, notifications.current, theme)
end

local function launch(index)
    local button = buttons[index]
    if not button then return end

    logger.log("Abriendo app: " .. button.entry.name)

    local app, err = appCore.load(button.entry.path, context)
    if not app then
        logger.log(err, "ERROR")
        notifications.push("Error al abrir " .. button.entry.name, "error")
        return
    end

    local ok, runErr = appCore.run(app, context)
    if not ok then
        logger.log(runErr, "ERROR")
        notifications.push("La app se ha detenido", "error")
    end

    monitor.setTextScale(config.textScale)
    redraw = true
end

buildLayout()
notifications.push("M&J Core iniciado", "success")
local timer = os.startTimer(config.refreshSeconds)

while running do
    if redraw then
        draw()
        redraw = false
    end

    local event, a, b, c = os.pullEvent()

    if event == "monitor_touch" and a == monitorName then
        local index = ui.hit(buttons, b, c)
        if index then
            selected = index
            draw()
            launch(index)
        end

    elseif event == "key" then
        local columns = 3
        local w = monitor.getSize()
        if w < 45 then columns = 2 end

        if a == keys.left and selected > 1 then
            selected = selected - 1
        elseif a == keys.right and selected < #buttons then
            selected = selected + 1
        elseif a == keys.up and selected - columns >= 1 then
            selected = selected - columns
        elseif a == keys.down and selected + columns <= #buttons then
            selected = selected + columns
        elseif a == keys.enter or a == keys.space then
            launch(selected)
        elseif a == keys.q then
            running = false
        end

        redraw = true

    elseif event == "monitor_resize" and a == monitorName then
        monitor.setTextScale(config.textScale)
        buildLayout()
        redraw = true

    elseif event == "timer" then
        if notifications.handleTimer(a) then
            redraw = true
        elseif a == timer then
            timer = os.startTimer(config.refreshSeconds)
            redraw = true
        end
    end
end

logger.log("Escritorio cerrado")
monitor.setBackgroundColor(colors.black)
monitor.clear()
