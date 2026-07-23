local storage = {}

local function isController(name)
    local ok, matches = pcall(peripheral.hasType, name, "functionalstorage:storage_controller")
    if ok and matches then return true end
    local types = {peripheral.getType(name)}
    for _, kind in ipairs(types) do
        if kind == "functionalstorage:storage_controller" then return true end
    end
    return false
end

function storage.find()
    local names = peripheral.getNames()
    table.sort(names)
    for _, name in ipairs(names) do
        if isController(name) then return peripheral.wrap(name), name end
    end
    if peripheral.isPresent("functionalstorage:storage_controller_0") then
        return peripheral.wrap("functionalstorage:storage_controller_0"), "functionalstorage:storage_controller_0"
    end
    return nil, nil
end

function storage.require()
    local controller, name = storage.find()
    if not controller then return nil, nil, "No se ha encontrado el Storage Controller" end
    return controller, name
end

function storage.list()
    local controller, name, err = storage.require()
    if not controller then return nil, err end
    local ok, items = pcall(controller.list)
    if not ok then return nil, tostring(items) end
    return items or {}, name
end

function storage.getDetail(slot)
    local controller, _, err = storage.require()
    if not controller then return nil, err end
    local ok, detail = pcall(controller.getItemDetail, slot)
    if not ok then return nil, tostring(detail) end
    return detail
end

function storage.contains(itemName, nbt)
    local items, err = storage.list()
    if not items then return false, err end
    for _, stack in pairs(items) do
        if stack.name == itemName then return true end
    end
    return false
end

function storage.push(toName, fromSlot, amount, toSlot)
    local controller, _, err = storage.require()
    if not controller then return nil, err end
    local ok, moved = pcall(controller.pushItems, toName, fromSlot, amount, toSlot)
    if not ok then return nil, tostring(moved) end
    return tonumber(moved) or 0
end

function storage.pull(fromName, fromSlot, amount, toSlot)
    local controller, _, err = storage.require()
    if not controller then return nil, err end
    local ok, moved = pcall(controller.pullItems, fromName, fromSlot, amount, toSlot)
    if not ok then return nil, tostring(moved) end
    return tonumber(moved) or 0
end

return storage
