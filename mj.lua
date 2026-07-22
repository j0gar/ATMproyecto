local args = {...}
local command = (args[1] or "help"):lower()

local function help()
    print("M&J Core")
    print("")
    print("mj start     Inicia el sistema")
    print("mj update    Busca e instala actualizaciones")
    print("mj version   Muestra la version instalada")
    print("mj logs      Muestra el registro del sistema")
    print("mj task list [j0gar|mia]")
    print("mj task add [j0gar|mia] <texto>")
    print("mj task done [j0gar|mia] <numero>")
    print("mj task remove [j0gar|mia] <numero>")
    print("mj setup server|terminal|pocket [lado] [jugador] [serverId] [origen]")
    print("mj help      Muestra esta ayuda")
end

local function loadNode()
    local ok, node = pcall(dofile, "/mjcore/data/node.lua")
    if ok and type(node) == "table" then return node end
    return { role = "server" }
end

local taskFiles = {
    j0gar = "/mjcore/data/t-J0gar.lua",
    mia = "/mjcore/data/t-Mia.lua"
}

local function normalizeProfile(value)
    local profile = string.lower(tostring(value or "j0gar"))
    if not taskFiles[profile] then return nil end
    return profile
end

local function loadLocalTasks(profile)
    local ok, data = pcall(dofile, taskFiles[profile])
    if not ok or type(data) ~= "table" then return nil, "No se pudieron cargar las tareas" end
    data.tasks = data.tasks or {}
    return data
end

local function saveLocalTasks(profile, data)
    local file = fs.open(taskFiles[profile], "w")
    if not file then return false, "No se pudieron guardar las tareas" end
    file.write("return " .. textutils.serialize(data))
    file.close()
    return true
end

local function remoteTask(kind, payload)
    local network = dofile("/mjcore/core/network.lua")
    local result, err = network.request(kind, payload, 4)
    if not result then return nil, err or "Servidor sin respuesta" end
    return result
end

local function taskCommand()
    local action = string.lower(tostring(args[2] or "list"))
    local profile = normalizeProfile(args[3])
    if not profile then
        printError("Perfil invalido. Usa j0gar o mia.")
        return
    end

    local node = loadNode()
    local data, err

    if action == "list" then
        if node.role == "terminal" then data, err = remoteTask("tasks_get", { profile = profile })
        else data, err = loadLocalTasks(profile) end

    elseif action == "add" then
        local text = table.concat(args, " ", 4):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then printError("Uso: mj task add [j0gar|mia] <texto>"); return end
        if node.role == "terminal" then data, err = remoteTask("tasks_add", { profile = profile, text = text })
        else
            data, err = loadLocalTasks(profile)
            if data then
                table.insert(data.tasks, { text = text, done = false })
                local ok; ok, err = saveLocalTasks(profile, data)
                if not ok then data = nil end
            end
        end

    elseif action == "done" then
        local index = tonumber(args[4])
        if not index then printError("Uso: mj task done [j0gar|mia] <numero>"); return end
        if node.role == "terminal" then data, err = remoteTask("tasks_toggle", { profile = profile, index = index })
        else
            data, err = loadLocalTasks(profile)
            if data and data.tasks[index] then
                data.tasks[index].done = not data.tasks[index].done
                local ok; ok, err = saveLocalTasks(profile, data)
                if not ok then data = nil end
            else data = nil; err = "Tarea inexistente" end
        end

    elseif action == "remove" then
        local index = tonumber(args[4])
        if not index then printError("Uso: mj task remove [j0gar|mia] <numero>"); return end
        if node.role == "terminal" then data, err = remoteTask("tasks_remove", { profile = profile, index = index })
        else
            data, err = loadLocalTasks(profile)
            if data and data.tasks[index] then
                table.remove(data.tasks, index)
                local ok; ok, err = saveLocalTasks(profile, data)
                if not ok then data = nil end
            else data = nil; err = "Tarea inexistente" end
        end

    else
        printError("Accion invalida. Usa list, add, done o remove.")
        return
    end

    if not data then printError(tostring(err or "Operacion fallida")); return end
    print("Tareas " .. string.upper(profile) .. ":")
    if #data.tasks == 0 then print("  No hay tareas") end
    for index, task in ipairs(data.tasks) do
        print(string.format("%d. %s %s", index, task.done and "[X]" or "[ ]", tostring(task.text or "")))
    end
end

if command == "start" then
    shell.run("/mjcore/boot.lua")
elseif command == "update" then
    local updater = dofile("/mjcore/core/updater.lua")
    updater.runInteractive()
elseif command == "task" then
    taskCommand()
elseif command == "setup" then
    local role=(args[2] or ""):lower()
    if role~="server" and role~="terminal" and role~="pocket" then printError("Uso: mj setup server|terminal|pocket [lado] [jugador] [serverId] [origen]"); return end
    local cfg={role=role,modemSide=args[3] or "left",channel=321,serverId=tonumber(args[5]) or 2,player=args[4] or "j0gar",inventorySource=args[6] or "right",apps=(role=="terminal" or role=="pocket") and {"inventory","todo"} or nil}
    local f=fs.open("/mjcore/data/node.lua","w"); f.write("return "..textutils.serialize(cfg)); f.close()
    print("Nodo configurado como "..role..". Reinicia con reboot.")
elseif command == "version" then
    local config = dofile("/mjcore/core/config.lua")
    print("M&J Core " .. tostring(config.version))
    print(tostring(config.codename or ""))
elseif command == "logs" then
    if fs.exists("/mjcore/logs/system.log") then shell.run("type", "/mjcore/logs/system.log")
    else print("Todavia no hay registros.") end
else
    help()
end
