local updater = {}

local config = dofile("/mjcore/core/config.lua")
local github = dofile("/mjcore/core/github.lua")

local function ensureParent(path)
    local parent = fs.getDir(path)
    if parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end
end

local function writeFile(path, content)
    ensureParent(path)
    local file, err = fs.open(path, "w")
    if not file then return false, err end
    file.write(content)
    file.close()
    return true
end

local function versionParts(version)
    local parts = {}
    for number in tostring(version):gmatch("%d+") do
        table.insert(parts, tonumber(number))
    end
    return parts
end

local function compareVersions(a, b)
    local av = versionParts(a)
    local bv = versionParts(b)
    local length = math.max(#av, #bv)

    for i = 1, length do
        local left = av[i] or 0
        local right = bv[i] or 0
        if left < right then return -1 end
        if left > right then return 1 end
    end

    return 0
end

function updater.check()
    local remote, err = github.getJSON(config, "version.json")
    if not remote then return nil, err end

    return {
        current = config.version,
        latest = tostring(remote.version),
        available = compareVersions(config.version, remote.version) < 0
    }
end

function updater.install(onProgress)
    local manifest, err = github.getJSON(config, "manifest.json")
    if not manifest then return false, err end

    local downloaded = {}

    for index, path in ipairs(manifest.files or {}) do
        if onProgress then onProgress(index, #manifest.files, path) end

        local content, downloadErr = github.get(config, path)
        if not content then return false, downloadErr end

        table.insert(downloaded, {path = path, content = content})
    end

    if fs.exists("/mjcore_backup") then
        fs.delete("/mjcore_backup")
    end

    fs.makeDir("/mjcore_backup")

    for _, item in ipairs(downloaded) do
        local target = "/" .. item.path

        if fs.exists(target) and not fs.isDir(target) then
            local backup = "/mjcore_backup/" .. item.path
            ensureParent(backup)
            fs.copy(target, backup)
        end
    end

    for _, item in ipairs(downloaded) do
        local ok, writeErr = writeFile("/" .. item.path, item.content)
        if not ok then return false, writeErr end
    end

    return true, manifest.version
end

function updater.runInteractive()
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.cyan)
    print("M&J CORE - ACTUALIZADOR")
    term.setTextColor(colors.white)

    local status, err = updater.check()

    if not status then
        printError(err)
        return
    end

    print("Instalada: " .. status.current)
    print("Disponible: " .. status.latest)

    if not status.available then
        print("El sistema ya esta actualizado.")
        return
    end

    write("Instalar ahora? [s/N]: ")
    local answer = read():lower()

    if answer ~= "s" and answer ~= "si" then
        print("Cancelado.")
        return
    end

    local ok, result = updater.install(function(i, total, path)
        print(("[%d/%d] %s"):format(i, total, path))
    end)

    if not ok then
        printError(result)
        return
    end

    print("Actualizado a " .. tostring(result))
    sleep(2)
    os.reboot()
end

return updater
