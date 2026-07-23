local network = dofile("/mjcore/core/network.lua")
local node = dofile("/mjcore/core/node.lua")
local config = dofile("/mjcore/core/config.lua")

local W, H = term.getSize()
local BG = colors.black
local FG = colors.white
local ACCENT = colors.cyan
local MUTED = colors.gray
local BUTTON = colors.gray
local ACTIVE = colors.blue
local GOOD = colors.lime
local BAD = colors.red

local function fill(y, bg, text, fg)
    term.setBackgroundColor(bg or BG)
    term.setTextColor(fg or FG)
    term.setCursorPos(1, y)
    term.write(string.rep(" ", W))
    if text then
        text = tostring(text)
        if #text > W - 2 then text = text:sub(1, W - 2) end
        term.setCursorPos(math.max(1, math.floor((W - #text) / 2) + 1), y)
        term.write(text)
    end
end

local function header(title)
    term.setBackgroundColor(BG)
    term.setTextColor(FG)
    term.clear()
    fill(1, ACCENT, "M&J POCKET " .. tostring(config.version), colors.black)
    fill(2, BG, title or "", ACCENT)
    fill(3, BG, string.rep("-", W), MUTED)
end

local function message(title, text, color)
    header(title)
    term.setTextColor(color or FG)
    term.setCursorPos(2, 5)
    print(tostring(text or ""))
    fill(H, BUTTON, "TOCA O ENTER", FG)
    while true do
        local e, a, b, c = os.pullEvent()
        if e == "mouse_click" or (e == "key" and (a == keys.enter or a == keys.space or a == keys.backspace)) then return end
    end
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function input(title, label, allowEmpty)
    header(title)
    term.setTextColor(colors.yellow)
    term.setCursorPos(1, 5)
    print(label or "Escribe y pulsa ENTER:")
    term.setTextColor(FG)
    term.setCursorPos(1, 7)
    local value = trim(read())
    if value == "" and not allowEmpty then return nil end
    return value
end

local function menu(title, items, options)
    options = options or {}
    local selected = 1
    local firstRow = 4
    local lastRow = H - 1
    local visible = math.max(1, lastRow - firstRow + 1)
    local offset = 0

    local function ensureVisible()
        if selected <= offset then offset = selected - 1 end
        if selected > offset + visible then offset = selected - visible end
        if offset < 0 then offset = 0 end
    end

    local function draw()
        header(title)
        for row = firstRow, lastRow do fill(row, BG, "", FG) end
        for row = 1, visible do
            local index = offset + row
            local item = items[index]
            if item then
                local bg = index == selected and ACTIVE or BUTTON
                local prefix = item.prefix or ""
                local label = prefix .. tostring(item.label or item.value or "")
                fill(firstRow + row - 1, bg, label, FG)
            end
        end
        local hint = options.hint or "TOCA / FLECHAS + ENTER"
        fill(H, BG, hint, MUTED)
    end

    if #items == 0 then return nil end
    while true do
        ensureVisible()
        draw()
        local e, a, b, c = os.pullEvent()
        if e == "mouse_click" then
            local y = c
            if y >= firstRow and y <= lastRow then
                local index = offset + (y - firstRow + 1)
                if items[index] then return items[index].value, index, items[index] end
            end
        elseif e == "mouse_scroll" then
            selected = math.max(1, math.min(#items, selected + (a > 0 and 1 or -1)))
        elseif e == "key" then
            if a == keys.up then selected = math.max(1, selected - 1)
            elseif a == keys.down then selected = math.min(#items, selected + 1)
            elseif a == keys.enter or a == keys.space then return items[selected].value, selected, items[selected]
            elseif a == keys.backspace or a == keys.escape then return options.backValue
            end
        elseif e == "char" then
            local number = tonumber(a)
            if number and number >= 1 and number <= #items then return items[number].value, number, items[number] end
            if a == "q" and options.backValue ~= nil then return options.backValue end
        end
    end
end

local function request(kind, payload, timeout, quiet)
    if not quiet then
        header("CONECTANDO")
        term.setCursorPos(2, 5)
        term.setTextColor(MUTED)
        print("Servidor " .. tostring(node.serverId) .. "...")
    end
    local result, err = network.request(kind, payload or {}, timeout or 5)
    if not result and not quiet then message("ERROR", tostring(err or "Sin respuesta"), BAD) end
    return result, err
end

local function chooseProfile()
    return menu("TAREAS", {
        {label = "J0GAR", value = "j0gar"},
        {label = "MIA", value = "mia"},
        {label = "ATRAS", value = false}
    }, {backValue = false})
end

local function taskAction(profile, task, index)
    local mark = task.done and "[X] " or "[ ] "
    local choice = menu("TAREA " .. tostring(index), {
        {label = mark .. tostring(task.text or "") , value = "none"},
        {label = task.done and "MARCAR PENDIENTE" or "MARCAR HECHA", value = "toggle"},
        {label = "ELIMINAR", value = "remove"},
        {label = "ATRAS", value = "back"}
    }, {backValue = "back"})

    if choice == "toggle" then
        local result = request("tasks_toggle", {profile = profile, index = index})
        if result then message("TAREAS", "Tarea actualizada.", GOOD) end
    elseif choice == "remove" then
        local confirm = menu("CONFIRMAR", {
            {label = "SI, ELIMINAR", value = true},
            {label = "NO", value = false}
        }, {backValue = false})
        if confirm then
            local result = request("tasks_remove", {profile = profile, index = index})
            if result then message("TAREAS", "Tarea eliminada.", GOOD) end
        end
    end
end

local function taskProfile(profile)
    while true do
        local data = request("tasks_get", {profile = profile})
        if not data then return end
        local items = {{label = "+ ANADIR TAREA", value = "add"}}
        for index, task in ipairs(data.tasks or {}) do
            items[#items + 1] = {
                label = (task.done and "[X] " or "[ ] ") .. tostring(task.text or ""),
                value = "task",
                task = task,
                taskIndex = index
            }
        end
        items[#items + 1] = {label = "RECARGAR", value = "reload"}
        items[#items + 1] = {label = "ATRAS", value = "back"}

        local choice, _, item = menu("TAREAS " .. string.upper(profile), items, {backValue = "back"})
        if choice == "back" then return
        elseif choice == "add" then
            local text = input("NUEVA TAREA", "Escribe la tarea y pulsa ENTER:")
            if text then
                local result = request("tasks_add", {profile = profile, text = text})
                if result then message("TAREAS", "Tarea anadida.", GOOD) end
            end
        elseif choice == "task" and item then
            taskAction(profile, item.task, item.taskIndex)
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

local function chooseAmount()
    local choice = menu("CANTIDAD", {
        {label = "1", value = 1},
        {label = "16", value = 16},
        {label = "32", value = 32},
        {label = "64", value = 64},
        {label = "OTRA (ESCRIBIR)", value = "custom"},
        {label = "ATRAS", value = false}
    }, {backValue = false})
    if choice == "custom" then
        local raw = input("CANTIDAD", "Escribe una cantidad (1-64):")
        local amount = tonumber(raw)
        if not amount then return nil end
        return math.max(1, math.min(64, math.floor(amount)))
    end
    return choice
end

local function inventoryMenu()
    while true do
        local action = menu("INVENTARIO", {
            {label = "BUSCAR OBJETO", value = "search"},
            {label = "GUARDAR TODO", value = "store"},
            {label = "ATRAS", value = "back"}
        }, {backValue = "back"})
        if action == "back" then return end
        if action == "store" then
            local result = request("inventory_store_known", {player = node.player}, 6)
            if result then
                message("INVENTARIO", "Guardados: " .. tostring(result.stored or 0) .. " | Dejados: " .. tostring(result.skipped or 0), GOOD)
            end
        else
        local query = input("INVENTARIO", "Buscar objeto (vacio = atras):", true)
        if query and query ~= "" then
        query = string.lower(query)

        local data = request("inventory_scan", {})
        if not data then return end
        local matches = {}
        for _, item in ipairs(data.items or {}) do
            local name = string.lower(tostring(item.name or ""))
            local display = string.lower(tostring(item.displayName or ""))
            if name:find(query, 1, true) or display:find(query, 1, true) then matches[#matches + 1] = item end
        end
        table.sort(matches, function(a, b) return (tonumber(a.count) or 0) > (tonumber(b.count) or 0) end)

        if #matches == 0 then
            message("INVENTARIO", "No se encontraron objetos.", colors.orange)
        else
            local items = {}
            for i = 1, math.min(#matches, 30) do
                local item = matches[i]
                items[#items + 1] = {
                    label = tostring(item.displayName or item.name) .. " x" .. tostring(item.count or 0),
                    value = "item",
                    item = item
                }
            end
            items[#items + 1] = {label = "NUEVA BUSQUEDA", value = "back"}
            local choice, _, selected = menu("RESULTADOS", items, {backValue = "back"})
            if choice == "item" and selected then
                local amount = chooseAmount()
                if amount then
                    local result = request("inventory_deliver", {
                        player = node.player,
                        item = selected.item.name,
                        count = amount
                    })
                    if result then message("INVENTARIO", "Entregados: " .. tostring(result.moved or 0), GOOD) end
                end
            end
        end
        end
        end
    end
end


local function logisticsMenu()
    local state = request("logistics_status", {}, 4)
    if not state then return end
    local machine = (state.machines or {})[1]
    header("LOGISTICA")
    term.setCursorPos(2, 4)
    term.setTextColor(state.active and GOOD or BAD)
    print("Estado: " .. (state.active and "ACTIVA" or "INACTIVA"))
    term.setTextColor(FG)
    print("Storage: " .. (state.storageConnected and "Conectado" or "Desconectado"))
    print("Maquina: " .. tostring(machine and machine.name or "Ninguna"))
    print("Trabajo: " .. tostring(machine and machine.job or "En espera"))
    print("Cola: " .. tostring(state.queue or 0))
    print("Combustible: " .. tostring(machine and machine.fuel or 0) .. " carbon")
    fill(H, BUTTON, "TOCA O ENTER", FG)
    while true do
        local e, a = os.pullEvent()
        if e == "mouse_click" or (e == "key" and (a == keys.enter or a == keys.backspace)) then return end
    end
end

local function networkMenu()
    local result, err = request("ping", {}, 5, true)
    if result then
        header("ESTADO DE RED")
        term.setCursorPos(2, 5)
        term.setTextColor(GOOD)
        print("Servidor conectado")
        term.setTextColor(FG)
        print("ID: " .. tostring(result.server or node.serverId))
        print("Canal: " .. tostring(node.channel))
        print("Modem: " .. tostring(network.getModemName() or "auto"))
        print("Jugador: " .. tostring(node.player))
        fill(H, BUTTON, "TOCA O ENTER", FG)
        while true do
            local e, a = os.pullEvent()
            if e == "mouse_click" or (e == "key" and (a == keys.enter or a == keys.backspace)) then return end
        end
    else
        message("RED", tostring(err or "Servidor sin respuesta"), BAD)
    end
end

local ok, modem = network.open()
if not ok then
    message("ERROR DE RED", tostring(modem), BAD)
    return
end

while true do
    local choice = menu("MENU PRINCIPAL", {
        {label = "TAREAS", value = "tasks"},
        {label = "INVENTARIO", value = "inventory"},
        {label = "LOGISTICA", value = "logistics"},
        {label = "ESTADO DE RED", value = "network"},
        {label = "REINICIAR POCKET", value = "reboot"},
        {label = "SALIR A CONSOLA", value = "exit"}
    }, {backValue = "exit"})

    if choice == "tasks" then tasksMenu()
    elseif choice == "inventory" then inventoryMenu()
    elseif choice == "logistics" then logisticsMenu()
    elseif choice == "network" then networkMenu()
    elseif choice == "reboot" then os.reboot()
    elseif choice == "exit" then
        header("CONSOLA")
        term.setCursorPos(1, 5)
        print("M&J Pocket cerrado.")
        return
    end
end
