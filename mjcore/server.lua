local network = dofile("/mjcore/core/network.lua")
local logistics = dofile("/mjcore/core/logistics.lua")
local logger = dofile("/mjcore/core/logger.lua")

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
        elseif msg.kind=="tasks_get" then result,err=loadTasks((msg.payload or {}).profile); ok=result~=nil
        elseif msg.kind=="tasks_toggle" then
            local p=msg.payload or {}; local data,path=loadTasks(p.profile)
            if data and data.tasks[tonumber(p.index) or 0] then data.tasks[tonumber(p.index)].done=not data.tasks[tonumber(p.index)].done; ok=saveTable(path,data); result=data; if not ok then err="No se pudieron guardar tareas" end else ok=false; err="Tarea inexistente" end
        else ok=false; err="Peticion desconocida: "..tostring(msg.kind) end
        network.reply(msg,ok,result or err)
    end
end
