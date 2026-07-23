local config = dofile("/mjcore/core/config.lua")
local theme = dofile("/mjcore/core/theme.lua")
local ui = dofile("/mjcore/core/ui.lua")
local icons = dofile("/mjcore/core/icons.lua")
local logger = dofile("/mjcore/core/logger.lua")
local notificationsFactory = dofile("/mjcore/core/notifications.lua")
local appCore = dofile("/mjcore/core/app.lua")
local appsCore = dofile("/mjcore/core/apps.lua")
local miaDetector = dofile("/mjcore/core/mia_detector.lua")
local node = dofile("/mjcore/core/node.lua")

local function findMonitors(preferredName)
    local names = {}

    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then
            names[#names + 1] = name
        end
    end

    table.sort(names)

    if preferredName then
        for index, name in ipairs(names) do
            if name == preferredName then
                table.remove(names, index)
                table.insert(names, 1, name)
                break
            end
        end
    end

    local result = {}
    for _, name in ipairs(names) do
        local monitor = peripheral.wrap(name)
        if monitor then
            result[#result + 1] = {name = name, monitor = monitor}
        end
    end

    return result
end

local monitorEntries = findMonitors(config.monitorName)
if #monitorEntries == 0 then error("No hay monitor conectado", 0) end

local iconColours = {
    inventory = colors.orange,
    players = colors.lightBlue,
    todo = colors.lime,
    energy = colors.yellow,
    alarms = colors.red,
    settings = colors.lightGray,
    updater = colors.cyan,
    system = colors.white,
    logistics = colors.green
}

local function loadRegistry()
    local registry = appsCore.loadRegistry()

    if type(node.apps) == "table" then
        local allowed = {}
        for _, id in ipairs(node.apps) do allowed[id] = true end
        if node.role == "terminal" then allowed.logistics = true end

        local filtered = {}
        for _, entry in ipairs(registry) do
            if allowed[entry.id] then filtered[#filtered + 1] = entry end
        end
        registry = filtered
    end

    return registry
end

local function runDesktop(entry, desktopIndex, desktopCount)
    local monitor = entry.monitor
    local monitorName = entry.name
    local notifications = notificationsFactory.new(config, logger)
    local registry = loadRegistry()
    local buttons = {}
    local page = 1
    local pageSize = 8
    local redraw = true
    local running = true

    monitor.setTextScale(config.textScale)
    theme.apply(monitor)

    local context = {
        monitor = monitor,
        monitorName = monitorName,
        config = config,
        theme = theme,
        ui = ui,
        logger = logger,
        notifications = notifications,
        node = node,
        desktopIndex = desktopIndex,
        desktopCount = desktopCount
    }

    local function pages()
        return math.max(1, math.ceil(#registry / pageSize))
    end

    local function buildLayout()
        local w, h = monitor.getSize()
        buttons = {}

        local cols = w >= 44 and 4 or 2
        local rows = math.ceil(pageSize / cols)
        local top = 4
        local bottom = h - 2
        local gapX = 1
        local gapY = 1
        local marginX = 1
        local cellW = math.floor((w - marginX * 2 - (cols - 1) * gapX) / cols)
        local cellH = math.max(3, math.floor((bottom - top + 1 - (rows - 1) * gapY) / rows))
        local first = (page - 1) * pageSize + 1

        for slot = 1, pageSize do
            local appEntry = registry[first + slot - 1]
            if appEntry then
                local col = (slot - 1) % cols
                local row = math.floor((slot - 1) / cols)
                buttons[#buttons + 1] = {
                    id = "app",
                    entry = appEntry,
                    x = marginX + col * (cellW + gapX),
                    y = top + row * (cellH + gapY),
                    w = cellW,
                    h = cellH
                }
            end
        end

        buttons[#buttons + 1] = {id = "prev", x = 1, y = h, w = 8, h = 1}
        buttons[#buttons + 1] = {id = "next", x = w - 7, y = h, w = 8, h = 1}
    end

    local function drawCard(button)
        local appEntry = button.entry
        ui.fill(monitor, button.x, button.y, button.w, button.h, theme.panel)
        ui.border(monitor, button.x, button.y, button.w, button.h, theme.panelAlt, theme.panel)

        local icon = icons.get(appEntry.icon)
        if icon and button.w >= 9 and button.h >= 3 then
            local iconY = button.y + math.max(0, math.floor((button.h - 3) / 2))
            ui.drawPixelIcon(
                monitor,
                button.x + 1,
                iconY,
                icon,
                iconColours[appEntry.icon] or theme.accent,
                theme.panel
            )
            ui.write(
                monitor,
                button.x + 5,
                button.y + math.floor(button.h / 2),
                ui.clip(appEntry.name, button.w - 6),
                theme.text,
                theme.panel
            )
        else
            ui.centerInBox(
                monitor,
                button.x,
                button.y,
                button.w,
                button.h,
                ui.clip(appEntry.name, button.w - 2),
                theme.text,
                theme.panel
            )
        end
    end

    local function draw()
        local w, h = monitor.getSize()
        theme.apply(monitor)
        monitor.setBackgroundColor(theme.desktop)
        monitor.clear()

        ui.fill(monitor, 1, 1, w, 2, theme.topbar)
        ui.write(monitor, 2, 1, "M&J CORE", theme.text, theme.topbar)

        local clock = textutils.formatTime(os.time(), true)
        ui.write(monitor, w - #clock - 1, 1, clock, theme.text, theme.topbar)

        local desktopLabel = "ESCRITORIO " .. tostring(desktopIndex)
        if desktopCount > 1 then
            desktopLabel = desktopLabel .. "/" .. tostring(desktopCount)
        end
        ui.write(monitor, 2, 2, desktopLabel, theme.muted, theme.topbar)
        ui.write(monitor, w - #(monitorName) - 1, 2, ui.clip(monitorName, math.floor(w / 2)), theme.accent, theme.topbar)
        ui.write(monitor, 2, 3, "APLICACIONES", theme.muted, theme.desktop)

        for _, button in ipairs(buttons) do
            if button.id == "app" then drawCard(button) end
        end

        ui.footer(monitor, theme, "< ANT")
        ui.center(monitor, h, tostring(page) .. "/" .. tostring(pages()), theme.accent, theme.footer)
        ui.write(monitor, w - 6, h, "SIG >", theme.text, theme.footer)
        ui.notification(monitor, notifications.current, theme)
    end

    local function launch(appEntry)
        local app, err = appCore.load(appEntry.path, context)
        if not app then
            notifications.push("Error: " .. appEntry.name, "error")
            logger.log(err, "ERROR")
            redraw = true
            return
        end

        local ok, runErr = appCore.run(app, context)
        if not ok then
            notifications.push("App detenida", "error")
            logger.log(runErr, "ERROR")
        end

        monitor.setTextScale(config.textScale)
        theme.apply(monitor)
        buildLayout()
        redraw = true
    end

    buildLayout()
    notifications.push("Escritorio " .. tostring(desktopIndex) .. " listo", "success")
    local refreshTimer = os.startTimer(config.refreshSeconds)

    while running do
        if redraw then
            draw()
            redraw = false
        end

        local event, a, b, c = os.pullEvent()

        if event == "monitor_touch" and a == monitorName then
            local _, hit = ui.hit(buttons, b, c)
            if hit then
                if hit.id == "app" then
                    launch(hit.entry)
                elseif hit.id == "prev" then
                    page = page - 1
                    if page < 1 then page = pages() end
                    buildLayout()
                    redraw = true
                elseif hit.id == "next" then
                    page = page + 1
                    if page > pages() then page = 1 end
                    buildLayout()
                    redraw = true
                end
            end

        elseif event == "monitor_resize" and a == monitorName then
            monitor.setTextScale(config.textScale)
            buildLayout()
            redraw = true

        elseif event == "peripheral_detach" and a == monitorName then
            running = false

        elseif event == "timer" and a == refreshTimer then
            notifications.update()
            refreshTimer = os.startTimer(config.refreshSeconds)
            redraw = true
        end
    end
end

local function detectorWorker()
    miaDetector.reload()
    miaDetector.update(true)

    while true do
        sleep(config.refreshSeconds)
        miaDetector.update(false)
    end
end

local tasks = {detectorWorker}
for index, entry in ipairs(monitorEntries) do
    tasks[#tasks + 1] = function()
        runDesktop(entry, index, #monitorEntries)
    end
end

logger.log("Iniciando " .. tostring(#monitorEntries) .. " escritorios independientes")
parallel.waitForAll(table.unpack(tasks))
