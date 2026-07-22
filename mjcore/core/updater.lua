local updater = {}

local config = dofile("/mjcore/core/config.lua")
local github = dofile("/mjcore/core/github.lua")

local PRESERVE_FILES = {
    ["mjcore/data/m-Mia.lua"] = true,
    ["mjcore/data/mia_detector.lua"] = true,
    ["mjcore/data/t-J0gar.lua"] = true,
    ["mjcore/data/t-Mia.lua"] = true,
    ["mjcore/data/node.lua"] = true
}

local function ensureParent(path)
    local parent = fs.getDir(path)
    if parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end
end

local function writeFile(path, content)
    ensureParent(path)
    local file, err = fs.open(path, "w")
    if not file then
        return false, err or ("No se pudo escribir " .. path)
    end

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
    local left = versionParts(a)
    local right = versionParts(b)
    local length = math.max(#left, #right)

    for i = 1, length do
        local l = left[i] or 0
        local r = right[i] or 0

        if l < r then return -1 end
        if l > r then return 1 end
    end

    return 0
end

function updater.check()
    local remote, err = github.getJSON(config, "version.json")
    if not remote then
        return nil, err
    end

    if not remote.version then
        return nil, "version.json no contiene una version"
    end

    return {
        current = tostring(config.version),
        latest = tostring(remote.version),
        available = compareVersions(config.version, remote.version) < 0
    }
end

function updater.install(onProgress)
    local manifest, err = github.getJSON(config, "manifest.json")
    if not manifest then
        return false, err
    end

    if type(manifest.files) ~= "table" then
        return false, "manifest.json no contiene una lista de archivos"
    end

    local downloaded = {}

    for index, path in ipairs(manifest.files) do
        if onProgress then
            onProgress(index, #manifest.files, path)
        end

        local content, downloadErr = github.get(config, path)
        if not content then
            return false, downloadErr or ("No se pudo descargar " .. path)
        end

        table.insert(downloaded, {
            path = path,
            content = content
        })
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
        local target = "/" .. item.path
        local preserve = PRESERVE_FILES[item.path] and fs.exists(target)

        if not preserve then
            local ok, writeErr = writeFile(target, item.content)

            if not ok then
                return false, writeErr
            end
        end
    end

    return true, tostring(manifest.version or "desconocida")
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
