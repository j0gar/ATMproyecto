local nodeConfig = {}
local PATH = "/mjcore/data/node.lua"

function nodeConfig.save(data)
    if type(data) ~= "table" then return false, "Configuracion de nodo invalida" end

    local file = fs.open(PATH, "w")
    if not file then return false, "No se pudo guardar " .. PATH end

    file.write("return " .. textutils.serialize(data))
    file.close()
    return true
end

function nodeConfig.setPlayer(node, player)
    player = tostring(player or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if player == "" then return false, "Jugador invalido" end

    node.player = player
    node.identityConfigured = true
    return nodeConfig.save(node)
end

return nodeConfig
