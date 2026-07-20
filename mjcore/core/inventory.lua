local inventory = {}

local preferredTypes = {
    "functionalstorage:storage_controller",
    "inventory"
}

local function findController()
    local names = peripheral.getNames()
    table.sort(names)

    for _, name in ipairs(names) do
        local types = { peripheral.getType(name) }
        local isInventory = false
        local isController = false

        for _, typeName in ipairs(types) do
            if typeName == "inventory" then
                isInventory = true
            elseif typeName == "functionalstorage:storage_controller" then
                isController = true
            end
        end

        if isController then
            return peripheral.wrap(name), name
        end

        if isInventory and name:find("functional_storage") then
            return peripheral.wrap(name), name
        end
    end

    for _, name in ipairs(names) do
        local wrapped = peripheral.wrap(name)
        if wrapped and type(wrapped.list) == "function" then
            return wrapped, name
        end
    end

    return nil, nil
end

local function displayName(item)
    if item.displayName and item.displayName ~= "" then
        return item.displayName
    end

    local name = tostring(item.name or "desconocido")
    local clean = name:gsub("^.-:", ""):gsub("_", " ")
    return clean
end

function inventory.scan()
    local controller, name = findController()

    if not controller then
        return nil, "No se ha encontrado el Storage Controller"
    end

    local ok, slots = pcall(controller.list)
    if not ok then
        return nil, tostring(slots)
    end

    local merged = {}
    local totalItems = 0

    for slot, stack in pairs(slots or {}) do
        if stack and stack.name then
            local key = tostring(stack.name) .. "|" .. tostring(stack.nbt or "")
            local entry = merged[key]

            if not entry then
                entry = {
                    key = key,
                    name = stack.name,
                    displayName = displayName(stack),
                    count = 0,
                    nbt = stack.nbt,
                    mod = tostring(stack.name):match("^(.-):") or "minecraft"
                }
                merged[key] = entry
            end

            entry.count = entry.count + (tonumber(stack.count) or 0)
            totalItems = totalItems + (tonumber(stack.count) or 0)
        end
    end

    local items = {}
    for _, entry in pairs(merged) do
        table.insert(items, entry)
    end

    return {
        controllerName = name,
        items = items,
        totalTypes = #items,
        totalItems = totalItems
    }
end

return inventory
