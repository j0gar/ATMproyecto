local logger = {}
local path = "/mjcore/logs/system.log"

local function ensureDir()
    if not fs.exists("/mjcore/logs") then
        fs.makeDir("/mjcore/logs")
    end
end

local function timestamp()
    return textutils.formatTime(os.time(), true)
end

function logger.log(message, level)
    ensureDir()

    local file = fs.open(path, "a")
    if not file then return false end

    file.writeLine(
        ("[%s] [%s] %s"):format(
            timestamp(),
            tostring(level or "INFO"),
            tostring(message)
        )
    )
    file.close()
    return true
end

function logger.read()
    if not fs.exists(path) then return {} end

    local file = fs.open(path, "r")
    local lines = {}

    while true do
        local line = file.readLine()
        if not line then break end
        table.insert(lines, line)
    end

    file.close()
    return lines
end

return logger
