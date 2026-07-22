local OWNER = "j0gar"
local REPO = "ATMproyecto"
local BRANCH = "main"

local PRESERVE_FILES = {
    ["mjcore/data/m-Mia.lua"] = true,
    ["mjcore/data/mia_detector.lua"] = true,
    ["mjcore/data/t-J0gar.lua"] = true,
    ["mjcore/data/t-Mia.lua"] = true,
    ["mjcore/data/node.lua"] = true
}

local BASE_URL =
    "https://raw.githubusercontent.com/" ..
    OWNER .. "/" .. REPO .. "/" .. BRANCH .. "/"

local function get(url)
    local response, err = http.get(url)
    if not response then
        return nil, err or "No se pudo conectar"
    end

    local body = response.readAll()
    response.close()
    return body
end

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
        return false, err or ("No se pudo abrir " .. path)
    end

    file.write(content)
    file.close()
    return true
end

local function download(path)
    local target = "/" .. path
    if PRESERVE_FILES[path] and fs.exists(target) then
        write("Conservando " .. path .. "... ")
        term.setTextColor(colors.yellow)
        print("PERSONALIZADO")
        term.setTextColor(colors.white)
        return true
    end

    write("Descargando " .. path .. "... ")
    local content, err = get(BASE_URL .. path)

    if not content then
        printError("ERROR")
        printError(err)
        return false
    end

    local ok, writeErr = writeFile("/" .. path, content)

    if not ok then
        printError("ERROR")
        printError(writeErr)
        return false
    end

    term.setTextColor(colors.lime)
    print("OK")
    term.setTextColor(colors.white)
    return true
end

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.cyan)
print("M&J CORE - INSTALADOR")
term.setTextColor(colors.white)
print("Repositorio: " .. OWNER .. "/" .. REPO)
print("")

if not http then
    printError("La API HTTP no esta disponible.")
    return
end

local manifestText, err = get(BASE_URL .. "manifest.json")
if not manifestText then
    printError("No se pudo descargar manifest.json")
    printError(err)
    return
end

local manifest = textutils.unserializeJSON(manifestText)
if not manifest or type(manifest.files) ~= "table" then
    printError("manifest.json no es valido.")
    return
end

local failed = {}

for _, path in ipairs(manifest.files) do
    if not download(path) then
        table.insert(failed, path)
    end
end

writeFile("/manifest.json", manifestText)

if #failed > 0 then
    term.setTextColor(colors.red)
    print("")
    print("Instalacion incompleta.")
    for _, path in ipairs(failed) do
        print("- " .. path)
    end
    return
end

term.setTextColor(colors.lime)
print("")
print("M&J Core " .. tostring(manifest.version) .. " instalado.")
term.setTextColor(colors.white)
print("Reiniciando...")
sleep(2)
os.reboot()
