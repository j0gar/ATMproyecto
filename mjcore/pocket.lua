local network = dofile("/mjcore/core/network.lua")
local node = dofile("/mjcore/core/node.lua")
local config = dofile("/mjcore/core/config.lua")

local function clear(title)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.cyan)
    print("M&J POCKET " .. tostring(config.version))
    term.setTextColor(colors.lightGray)
    print(title or "")
    print(string.rep("-", math.max(1, select(1, term.getSize()))))
    term.setTextColor(colors.white)
end

local function pause(message)
    print("")
    term.setTextColor(colors.gray)
    print(message or "Pulsa ENTER para continuar")
    term.setTextColor(colors.white)
    read()
end

local function prompt(label)
    term.setTextColor(colors.yellow)
    write(label)
    term.setTextColor(colors.white)
    return read()
end

local function request(kind, payload, timeout)
    term.setTextColor(colors.gray)
    print("Conectando con servidor " .. tostring(node.serverId) .. "...")
    term.setTextColor(colors.white)
    local result, err = network.request(kind, payload or {}, timeout or 5)
    if not result then
        term.setTextColor(colors.red)
        print("ERROR: " .. tostring(err or "Sin respuesta"))
        term.setTextColor(colors.white)
    end
    return result, err
end

local function chooseProfile()
    clear("TAREAS")
    print("1. J0GAR")
    print("2. MIA")
    print("0. Atras")
    local choice = prompt("> ")
    if choice == "1" then return "j0gar" end
    if choice == "2" then return "mia" end
    return nil
end

local function printTasks(data)
    local tasks = data and data.tasks or {}
    if #tasks == 0 then
        print("No hay tareas.")
        return
    end
    for index, task in ipairs(tasks) do
        local mark = task.done and "[X]" or "[ ]"
        print(tostring(index) .. ". " .. mark .. " " .. tostring(task.text or ""))
    end
end

local function taskProfile(profile)
    while true do
        clear("TAREAS " .. string.upper(profile))
        local data = request("tasks_get", {profile = profile})
        if data then printTasks(data) end
        print("")
        print("1. Anadir tarea")
        print("2. Marcar/desmarcar")
        print("3. Eliminar tarea")
        print("4. Recargar")
        print("0. Atras")
        local choice = prompt("> ")

        if choice == "0" then
            return
        elseif choice == "1" then
            clear("NUEVA TAREA " .. string.upper(profile))
            local text = prompt("Texto: ")
            text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" then
                local result = request("tasks_add", {profile = profile, text = text})
                if result then
                    term.setTextColor(colors.lime)
                    print("Tarea anadida.")
                    term.setTextColor(colors.white)
                end
            end
            pause()
        elseif choice == "2" then
            local index = tonumber(prompt("Numero: "))
            if index then
                local result = request("tasks_toggle", {profile = profile, index = index})
                if result then print("Tarea actualizada.") end
            else
                printError("Numero invalido")
            end
            pause()
        elseif choice == "3" then
            local index = tonumber(prompt("Numero: "))
            if index then
                local confirm = string.lower(prompt("Eliminar? (s/n): "))
                if confirm == "s" or confirm == "si" then
                    local result = request("tasks_remove", {profile = profile, index = index})
                    if result then print("Tarea eliminada.") end
                end
            else
                printError("Numero invalido")
            end
            pause()
        end
    end
end

local function tasksMenu()
    while true do
        local profile = chooseProfile()
        if not profile then return end
        taskProfile(profile)
    end
end

local function inventoryMenu()
    while true do
        clear("INVENTARIO")
        local query = prompt("Buscar (vacio=atras): ")
        query = string.lower(tostring(query or ""))
        if query == "" then return end

        local data = request("inventory_scan", {})
        if not data then pause(); return end
        local matches = {}
        for _, item in ipairs(data.items or {}) do
            local name = string.lower(tostring(item.name or ""))
            local display = string.lower(tostring(item.displayName or ""))
            if name:find(query, 1, true) or display:find(query, 1, true) then
                matches[#matches + 1] = item
            end
        end
        table.sort(matches, function(a, b) return (tonumber(a.count) or 0) > (tonumber(b.count) or 0) end)

        clear("RESULTADOS: " .. query)
        if #matches == 0 then
            print("No se encontraron objetos.")
            pause()
        else
            local shown = math.min(9, #matches)
            for i = 1, shown do
                local item = matches[i]
                print(tostring(i) .. ". " .. tostring(item.displayName or item.name) .. " x" .. tostring(item.count or 0))
            end
            print("0. Nueva busqueda")
            local selected = tonumber(prompt("Objeto: "))
            if selected and selected >= 1 and selected <= shown then
                local count = tonumber(prompt("Cantidad (1-64): ")) or 1
                count = math.max(1, math.min(64, math.floor(count)))
                local item = matches[selected]
                local result = request("inventory_deliver", {
                    player = node.player,
                    item = item.name,
                    count = count
                })
                if result then
                    term.setTextColor(colors.lime)
                    print("Entregados: " .. tostring(result.moved or 0))
                    term.setTextColor(colors.white)
                end
                pause()
            end
        end
    end
end

local function networkMenu()
    clear("RED")
    local result = request("ping", {}, 5)
    if result then
        term.setTextColor(colors.lime)
        print("Servidor conectado")
        term.setTextColor(colors.white)
        print("ID servidor: " .. tostring(result.server or node.serverId))
        print("Canal: " .. tostring(node.channel))
        print("Modem: " .. tostring(network.getModemName() or "automatico"))
        print("Jugador: " .. tostring(node.player))
    end
    pause()
end

local ok, modem = network.open()
if not ok then
    clear("ERROR DE RED")
    printError(tostring(modem))
    pause("Pulsa ENTER para salir")
    return
end

while true do
    clear("MENU PRINCIPAL")
    print("1. Tareas")
    print("2. Inventario")
    print("3. Estado de red")
    print("4. Reiniciar Pocket")
    print("0. Salir a consola")
    local choice = prompt("> ")

    if choice == "1" then
        tasksMenu()
    elseif choice == "2" then
        inventoryMenu()
    elseif choice == "3" then
        networkMenu()
    elseif choice == "4" then
        os.reboot()
    elseif choice == "0" then
        clear("CONSOLA")
        print("M&J Pocket cerrado.")
        return
    end
end
