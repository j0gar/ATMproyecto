local config = dofile("/mjcore/core/config.lua")
local theme = dofile("/mjcore/core/theme.lua")
local ui = dofile("/mjcore/core/ui.lua")
local logger = dofile("/mjcore/core/logger.lua")
local notificationsFactory = dofile("/mjcore/core/notifications.lua")
local appCore = dofile("/mjcore/core/app.lua")
local appsCore = dofile("/mjcore/core/apps.lua")
local miaDetector = dofile("/mjcore/core/mia_detector.lua")

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

local icons = {
    inventory = "[#]",
    players = "[O]",
    todo = "[=]",
    energy = "[*]",
    alarms = "[!]",
    settings = "[+]",
    updater = "[^]",
    system = "[S]",
    favorites = "[F]"
}

local function buildLayout()
    local w, h = monitor.getSize()
    buttons = {}

    local columns = 3
    local marginX = 2
    local gapX = 1
    local gapY = 1
    local contentTop = 4
    local footerTop = h - 5
    local availableHeight = footerTop - contentTop

    local rows = math.max(1, math.ceil(#registry / columns))
    local buttonW = math.floor((w - marginX * 2 - gapX * (columns - 1)) / columns)
    local buttonH = math.max(4, math.floor((availableHeight - gapY * (rows - 1)) / rows))
    buttonH = math.min(buttonH, 6)

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
            icon = icons[entry.icon] or "[ ]",
            entry = entry
        })
    end
end

local function drawBackground()
    local w, h = monitor.getSize()
    monitor.setBackgroundColor(theme.desktop)
    monitor.clear()

    for y = 3, h - 6, 2 do
        for x = 1, w, 4 do
            ui.write(monitor, x, y, ".", colors.gray, theme.desktop)
        end
    end
end

local function drawTopbar()
    local w = monitor.getSize()
    ui.fill(monitor, 1, 1, w, 2, theme.topbar)
    ui.write(monitor, 2, 1, "<> M&J CORE", theme.text, theme.topbar)
    ui.write(monitor, 2, 2, "TOUCH UI", theme.muted, theme.topbar)

    local version = "v" .. config.version
    local clock = textutils.formatTime(os.time(), true)
    ui.write(monitor, w - #clock - #version - 3, 1, clock, theme.text, theme.topbar)
    ui.write(monitor, w - #version, 1, version, theme.accent, theme.topbar)
end

local function drawCards()
    for i, button in ipairs(buttons) do
        local border = i == selected and theme.accent or theme.panelAlt
        ui.fill(monitor, button.x, button.y, button.w, button.h, theme.panel)
        ui.border(monitor, button.x, button.y, button.w, button.h, border, theme.panel)

        ui.write(monitor, button.x + 2, button.y + 1, button.icon, theme.accent, theme.panel)
        ui.write(
            monitor,
            button.x + 7,
            button.y + 1,
            ui.clip(button.label, button.w - 9),
            theme.text,
            theme.panel
        )

        if button.h >= 4 then
            ui.write(
                monitor,
                button.x + 2,
                button.y + 2,
                ui.clip(button.subtitle or "", button.w - 4),
                theme.muted,
                theme.panel
            )
        end
    end
end

local function drawStatus()
    local w, h = monitor.getSize()
    local y = h - 4

    ui.fill(monitor, 1, y, w, 4, theme.panel)
    ui.write(monitor, 2, y, "ESTADO", theme.accent, theme.panel)
    ui.write(monitor, 2, y + 1, "Sistema operativo", theme.text, theme.panel)

    local peripherals = #peripheral.getNames()
    ui.write(monitor, math.floor(w / 3), y, "PERIFERICOS", theme.accent, theme.panel)
    ui.write(monitor, math.floor(w / 3), y + 1, tostring(peripherals) .. " conectados", theme.text, theme.panel)

    ui.write(monitor, math.floor(w * 0.67), y, "CONTROL", theme.accent, theme.panel)
    ui.write(monitor, math.floor(w * 0.67), y + 1, "100% tactil", theme.text, theme.panel)

    ui.fill(monitor, 1, h, w, 1, theme.topbar)
    ui.write(monitor, 2, h, "Toca una tarjeta para abrir", theme.text, theme.topbar)
end

local function draw()
    drawBackground()
    drawTopbar()
    drawCards()
    drawStatus()
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
miaDetector.reload()
miaDetector.update(true)
notifications.push("Touch UI cargado", "success")
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
            sleep(0.08)
            launch(index)
        end

    elseif event == "key" then
        if a == keys.q then
            running = false
        end

    elseif event == "monitor_resize" and a == monitorName then
        monitor.setTextScale(config.textScale)
        buildLayout()
        redraw = true

    elseif event == "timer" then
        if notifications.handleTimer(a) then
            redraw = true
        elseif a == timer then
            miaDetector.update(false)
            timer = os.startTimer(config.refreshSeconds)
            redraw = true
        end
    end
end

logger.log("Escritorio cerrado")
monitor.setBackgroundColor(colors.black)
monitor.clear()
