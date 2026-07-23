local network = dofile("/mjcore/core/network.lua")
local logistics = dofile("/mjcore/core/logistics.lua")
local logger = dofile("/mjcore/core/logger.lua")
local machineConfig = dofile("/mjcore/core/machine_config.lua")

local profiles = {j0gar="/mjcore/data/t-J0gar.lua",mia="/mjcore/data/t-Mia.lua"}
local function loadTasks(id)
    local path=profiles[string.lower(tostring(id or ""))]; if not path then return nil,"Perfil desconocido" end
    local ok,data=pcall(dofile,path); if not ok or type(data)~="table" then return nil,"No se pudieron cargar tareas" end
    data.tasks=data.tasks or {}; return data,path
end
local function saveTable(path,data)
    local f=fs.open(path,"w"); if not f then return false end; f.write("return "..textutils.serialize(data)); f.close(); return true
end

while true do
    local msg, err = network.receive()
    if not msg then logger.log(err,"ERROR"); sleep(1)
    else
        local ok, result
        if msg.kind=="ping" then ok,result=true,{server=os.getComputerID()}
        elseif msg.kind=="inventory_scan" then result,err=logistics.scan(); ok=result~=nil
        elseif msg.kind=="inventory_deliver" then local p=msg.payload or {}; result,err=logistics.deliver(p.player,p.item,p.count); ok=result~=nil
        elseif msg.kind=="inventory_store_known" then local p=msg.payload or {}; result,err=logistics.storeKnown(p.player); ok=result~=nil
        elseif msg.kind=="logistics_status" then
            local statusPath="/mjcore/data/logistics_state.lua"
            if fs.exists(statusPath) then local statusOk,status=pcall(dofile,statusPath); if statusOk then ok,result=true,status else ok=false; err=tostring(status) end
            else ok=false; err="Servicio de logistica sin estado" end
        elseif msg.kind=="logistics_set_config" then
            local p=msg.payload or {}
            local machinePath="/mjcore/machines/"..tostring(p.id or "")..".lua"
            if not fs.exists(machinePath) then ok=false; err="Maquina desconocida"
            else
                local machineOk,machine=pcall(dofile,machinePath)
                if not machineOk or type(machine)~="table" then ok=false; err="Definicion de maquina invalida"
                else
                    local setting
                    for _,entry in ipairs(machine.settings or {}) do if entry.key==p.key then setting=entry break end end
                    if not setting then ok=false; err="Ajuste desconocido"
                    else
                        local value=tonumber(p.value)
                        if not value then ok=false; err="Valor invalido"
                        else
                            value=math.max(tonumber(setting.min) or value,math.min(tonumber(setting.max) or value,value))
                            result,err=machineConfig.set(machine,p.key,value); ok=result~=nil
                        end
                    end
                end
            end
        elseif msg.kind=="tasks_get" then result,err=loadTasks((msg.payload or {}).profile); ok=result~=nil
        elseif msg.kind=="tasks_toggle" then
            local p=msg.payload or {}; local data,path=loadTasks(p.profile)
            local index=tonumber(p.index) or 0
            if data and data.tasks[index] then
                data.tasks[index].done=not data.tasks[index].done
                ok=saveTable(path,data); result=data
                if not ok then err="No se pudieron guardar tareas" end
            else ok=false; err="Tarea inexistente" end
        elseif msg.kind=="tasks_add" then
            local p=msg.payload or {}; local data,path=loadTasks(p.profile)
            local text=tostring(p.text or ""):gsub("^%s+",""):gsub("%s+$","")
            if not data then ok=false
            elseif text=="" then ok=false; err="El texto de la tarea esta vacio"
            else
                table.insert(data.tasks,{text=text,done=false})
                ok=saveTable(path,data); result=data
                if not ok then err="No se pudieron guardar tareas" end
            end
        elseif msg.kind=="tasks_remove" then
            local p=msg.payload or {}; local data,path=loadTasks(p.profile)
            local index=tonumber(p.index) or 0
            if data and data.tasks[index] then
                table.remove(data.tasks,index)
                ok=saveTable(path,data); result=data
                if not ok then err="No se pudieron guardar tareas" end
            else ok=false; err="Tarea inexistente" end
        else ok=false; err="Peticion desconocida: "..tostring(msg.kind) end
        network.reply(msg,ok,result or err)
    end
end
