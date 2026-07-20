local function requireFile(path)
    if not fs.exists(path) then
        error("Falta el archivo: " .. path, 0)
    end
    return dofile(path)
end

local config = requireFile("/mjcore/core/config.lua")
local theme = requireFile("/mjcore/core/theme.lua")
local ui = requireFile("/mjcore/core/ui.lua")

local monitor = ui.findMonitor(config.monitorName)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

if not monitor then
    term.setTextColor(colors.red)
    print("M&J Core no encuentra ningun monitor.")
    return
end

monitor.setTextScale(config.textScale)
monitor.setBackgroundColor(theme.background)
monitor.setTextColor(theme.text)
monitor.clear()

local w, h = monitor.getSize()

local function center(y, text, color)
    monitor.setTextColor(color or theme.text)
    monitor.setCursorPos(math.max(1, math.floor((w - #text) / 2) + 1), y)
    monitor.write(text)
end

local function progress(y, percent)
    local width = math.max(10, math.min(w - 12, 40))
    local x = math.floor((w - width) / 2) + 1
    local filled = math.floor(width * percent)

    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(theme.panel)
    monitor.write(string.rep(" ", width))

    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(theme.accent)
    monitor.write(string.rep(" ", filled))
    monitor.setBackgroundColor(theme.background)
end

center(math.max(2, math.floor(h / 2) - 5), "M&J CORE", theme.accent)
center(math.max(3, math.floor(h / 2) - 3), "Sistema central de Mia + J0gar", theme.muted)

local steps = {
    "Detectando monitor",
    "Cargando interfaz",
    "Cargando aplicaciones",
    "Iniciando escritorio"
}

for i, label in ipairs(steps) do
    local y = math.max(5, math.floor(h / 2))
    monitor.setBackgroundColor(theme.background)
    monitor.setCursorPos(1, y)
    monitor.clearLine()
    center(y, label .. "...", theme.text)
    progress(y + 2, i / #steps)
    sleep(0.25)
end

shell.run("/mjcore/desktop.lua")
