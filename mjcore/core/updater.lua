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
    if not file then
        return false, err or ("No se pudo escribir " .. path)
    end

    file.write(content)
    file.close()
    return true
end

local function backup(path)
    if not fs.exists(path) or fs.isDir(path) then
        return true
    end

    local backupPath = "/mjcore_backup" .. path
    ensureParent(backupPath)

    if fs.exists(backupPath) then
        fs.delete(backupPath)
    end

    fs.copy(path, backupPath)
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
    if not http then
        return nil, "La API HTTP no esta disponible."
    end

    local remote, err = github.getJSON(config, "version.json")
    if not remote then
        return nil, err
    end

    return {
        current = config.version,
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
        return false, "El manifiesto remoto no contiene archivos."
    end

    local downloaded = {}

    for index, path in ipairs(manifest.files) do
        if onProgress then
            onProgress(index, #manifest.files, path)
        end

        local content, downloadErr = github.get(config, path)
        if not content then
            return false, downloadErr
        end

        table.insert(downloaded, {
            path = path,
            content = content
        })
    end

    if fs.exists("/mjcore_backup") then
        fs.delete("/mjcore_backup")
    end

    for _, item in ipairs(downloaded) do
        backup("/" .. item.path)
    end

    for _, item in ipairs(downloaded) do
        local ok, writeErr = writeFile("/" .. item.path, item.content)
        if not ok then
            return false, writeErr
        end
    end

    return true, manifest.version
end

function updater.runInteractive()
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.cyan)
    print("M&J CORE - ACTUALIZADOR")
    term.setTextColor(colors.white)
    print("Version instalada: " .. config.version)
    print("")

    write("Buscando actualizaciones... ")
    local status, err = updater.check()

    if not status then
        printError("ERROR")
        printError(err)
        return
    end

    term.setTextColor(colors.lime)
    print("OK")
    term.setTextColor(colors.white)
    print("Version disponible: " .. status.latest)

    if not status.available then
        term.setTextColor(colors.lime)
        print("El sistema ya esta actualizado.")
        term.setTextColor(colors.white)
        return
    end

    write("Instalar ahora? [s/N]: ")
    local answer = read():lower()
    if answer ~= "s" and answer ~= "si" then
        print("Actualizacion cancelada.")
        return
    end

    local ok, result = updater.install(function(index, total, path)
        print(("[%d/%d] %s"):format(index, total, path))
    end)

    if not ok then
        term.setTextColor(colors.red)
        print("Actualizacion fallida:")
        printError(result)
        print("La copia anterior esta en /mjcore_backup")
        return
    end

    term.setTextColor(colors.lime)
    print("Actualizado a la version " .. tostring(result))
    term.setTextColor(colors.white)
    print("Reiniciando...")
    sleep(2)
    os.reboot()
end

return updater
