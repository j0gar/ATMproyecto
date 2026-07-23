local storage = dofile("/mjcore/core/storage.lua")
local machineConfig = dofile("/mjcore/core/machine_config.lua")
local logger = dofile("/mjcore/core/logger.lua")
local STATE_PATH = "/mjcore/data/logistics_state.lua"
local CYCLE_SECONDS = 2

local function save(state)
    local file = fs.open(STATE_PATH, "w")
    if file then file.write("return " .. textutils.serialize(state)); file.close() end
end

local function loadMachines()
    local machines = {}
    local dir = "/mjcore/machines"
    if not fs.exists(dir) then return machines end
    for _, file in ipairs(fs.list(dir)) do
        if file:sub(-4) == ".lua" then
            local ok, machine = pcall(dofile, fs.combine(dir, file))
            if ok and type(machine) == "table" and machine.id and machine.peripheral and machine.slots then
                machines[#machines+1] = machine
            else logger.log("Maquina invalida: " .. file, "ERROR") end
        end
    end
    table.sort(machines, function(a,b) return a.id < b.id end)
    return machines
end

local function firstStack(inv, slots)
    local listed = inv.list() or {}
    for _, slot in ipairs(slots or {}) do if listed[slot] then return listed[slot], slot end end
end

local function findStorageItem(predicate)
    local listed = storage.list()
    if not listed then return nil end
    for slot, stack in pairs(listed) do
        local detail = storage.getDetail(slot)
        if predicate(detail or stack) then return slot, detail or stack end
    end
end

local function process(machine)
    local cfg = machineConfig.load(machine)
    local status = {id=machine.id,name=machine.name or machine.id,connected=false,enabled=cfg.enabled~=false,job="En espera",queue=0,fuel=0,config=cfg,settings=machine.settings or {}}
    if cfg.enabled == false then status.job = "Desactivada"; return status end
    if not peripheral.isPresent(machine.peripheral) then return status end
    local inv = peripheral.wrap(machine.peripheral)
    if not inv or type(inv.list) ~= "function" then return status end
    status.connected = true

    for _, slot in ipairs(machine.slots.outputs or {}) do storage.pull(machine.peripheral, slot) end

    local fuelStack = firstStack(inv, machine.slots.fuel)
    status.fuel = fuelStack and fuelStack.count or 0
    local fuelTarget = math.max(0, tonumber(cfg.fuelTarget) or 0)
    if machine.fuel and status.fuel < fuelTarget then
        local slot = findStorageItem(function(detail) return detail and detail.name == machine.fuel.name end)
        if slot then storage.push(machine.peripheral, slot, fuelTarget - status.fuel, machine.slots.fuel[1]) end
        fuelStack = firstStack(inv, machine.slots.fuel); status.fuel = fuelStack and fuelStack.count or 0
    end

    local inputStack, inputSlot = firstStack(inv, machine.slots.inputs)
    if inputStack then
        local detail = inv.getItemDetail and inv.getItemDetail(inputSlot) or inputStack
        status.job = (detail and detail.displayName) or inputStack.name
    else
        local slot, detail = findStorageItem(machine.accepts)
        if slot then
            local moved = storage.push(machine.peripheral, slot, tonumber(cfg.inputBatch) or 64, machine.slots.inputs[1])
            if moved and moved > 0 then status.job = (detail and detail.displayName) or detail.name end
        end
    end
    return status
end

local machines = loadMachines()
logger.log("Servicio de logistica iniciado con " .. tostring(#machines) .. " maquina(s)")
while true do
    local controller, controllerName = storage.find()
    local state = {active=true,storageConnected=controller~=nil,storageName=controllerName,machines={},queue=0,updated=os.epoch and os.epoch("utc") or 0}
    for _, machine in ipairs(machines) do
        local ok, result = pcall(process, machine)
        if ok then state.machines[#state.machines+1] = result
        else state.machines[#state.machines+1] = {id=machine.id,name=machine.name or machine.id,connected=false,job="Error",fuel=0,error=tostring(result)} end
    end
    save(state)
    sleep(CYCLE_SECONDS)
end
