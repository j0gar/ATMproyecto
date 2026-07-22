local config = dofile("/mjcore/core/config.lua")
local theme = dofile("/mjcore/core/theme.lua")
local ui = dofile("/mjcore/core/ui.lua")
local logger = dofile("/mjcore/core/logger.lua")
local logo = dofile("/mjcore/assets/logo.lua")
local node = dofile("/mjcore/core/node.lua")
local network = dofile("/mjcore/core/network.lua")

local BOOT_DURATION = 2.7
local BAR_STEPS = 27

local monitor, monitorName = ui.findMonitor(config.monitorName)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

if not monitor then
    term.setTextColor(colors.red)
    print("M&J Core no encuentra ningun monitor.")
    logger.log("No se encontro monitor", "ERROR")
    return
end

local networkOk, networkInfo = network.open()
if networkOk then
    logger.log("Modem wireless abierto: " .. tostring(networkInfo))
else
    logger.log("No se pudo abrir la red: " .. tostring(networkInfo), "WARNING")
end

monitor.setTextScale(config.textScale)
monitor.setBackgroundColor(theme.background)
monitor.setTextColor(theme.text)
monitor.clear()

local function drawPixelLogo(target)
    local screenW, screenH = target.getSize()
    local pixelW = logo.pixelWidth or 1
    local pixelH = logo.pixelHeight or 1
    local logoW = #logo.pixels[1] * pixelW
    local logoH = #logo.pixels * pixelH
    local startX = math.max(1, math.floor((screenW - logoW) / 2) + 1)
    local startY = math.max(2, math.floor((screenH - logoH) / 2) - 4)
    local palette = {H = colors.gray, M = colors.lightGray, J = colors.cyan, C = colors.blue}

    for row, line in ipairs(logo.pixels) do
        for column = 1, #line do
            local color = palette[line:sub(column, column)]
            if color then
                ui.fill(target, startX + (column - 1) * pixelW, startY + (row - 1) * pixelH, pixelW, pixelH, color)
            end
        end
    end

    return startY + logoH
end

local function drawLoadingBar(target, y, progress)
    local screenW = target.getSize()
    local barW = math.max(20, math.floor(screenW * 0.58))
    local x = math.floor((screenW - barW) / 2) + 1
    local filled = math.floor(barW * progress)
    ui.fill(target, x, y, barW, 1, theme.panel)
    if filled > 0 then ui.fill(target, x, y, filled, 1, theme.accent) end
end

local logoBottom = drawPixelLogo(monitor)
local screenW, screenH = monitor.getSize()
local titleY = math.min(screenH - 6, logoBottom + 1)
local barY = math.min(screenH - 3, titleY + 3)

ui.center(monitor, titleY, "M&J CORE", theme.accent, theme.background)
ui.center(monitor, titleY + 1, "STABLE v" .. config.version, theme.muted, theme.background)

for step = 0, BAR_STEPS do
    local progress = step / BAR_STEPS
    drawLoadingBar(monitor, barY, progress)

    local status
    if progress < 0.30 then
        status = "INICIANDO NUCLEO"
    elseif progress < 0.62 then
        status = "ABRIENDO RED"
    elseif progress < 0.90 then
        status = "PREPARANDO ESCRITORIO"
    else
        status = "SISTEMA LISTO"
    end

    local statusY = math.min(screenH - 1, barY + 2)
    ui.fill(monitor, 1, statusY, screenW, 1, theme.background)
    ui.center(monitor, statusY, status, theme.text, theme.background)
    sleep(BOOT_DURATION / BAR_STEPS)
end

logger.log("Arranque completado en " .. monitorName .. " como " .. tostring(node.role))

if node.role == "server" then
    parallel.waitForAny(
        function() shell.run("/mjcore/desktop.lua") end,
        function() shell.run("/mjcore/server.lua") end
    )
else
    shell.run("/mjcore/desktop.lua")
end
