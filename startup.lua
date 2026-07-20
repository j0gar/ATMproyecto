--[[
    Detector de bienvenida para MiaWRaW
    Mods:
      - CC: Tweaked
      - Advanced Peripherals

    Archivo: startup.lua
--]]

-- =========================================================
-- CONFIGURACIÓN
-- =========================================================

local JUGADOR = "MiaWRaW"
local RADIO = 20

local MENSAJE_ENTRADA = "¡Hola, Mia! Bienvenida a la base."
local MENSAJE_SALIDA = "MiaWRaW ha salido de la zona."

local PREFIJO_CHAT = "Base"
local COMPROBAR_CADA = 1

local SONIDO_ENTRADA = "minecraft:block.note_block.bell"
local VOLUMEN = 1
local TONO = 1.2

-- Si está activado, Mia recibirá otro mensaje cuando salga.
local AVISAR_AL_SALIR = false

-- =========================================================
-- BÚSQUEDA DE PERIFÉRICOS
-- =========================================================

local detector =
    peripheral.find("player_detector")
    or peripheral.find("playerDetector")

if not detector then
    error("No se ha encontrado el Player Detector.", 0)
end

local chatBoxes = {
    peripheral.find("chat_box")
}

-- Compatibilidad con versiones anteriores.
if #chatBoxes == 0 then
    chatBoxes = {
        peripheral.find("chatBox")
    }
end

if #chatBoxes == 0 then
    error("No se ha encontrado ninguna Chat Box.", 0)
end

local monitors = {
    peripheral.find("monitor")
}

local speaker = peripheral.find("speaker")

-- =========================================================
-- FUNCIONES DE PANTALLA
-- =========================================================

local function centrar(monitor, texto, linea)
    local ancho = monitor.getSize()
    local x = math.floor((ancho - #texto) / 2) + 1

    if x < 1 then
        x = 1
    end

    monitor.setCursorPos(x, linea)
    monitor.write(texto)
end

local function actualizarPantallas(estado, color)
    term.clear()
    term.setCursorPos(1, 1)

    print("Detector de jugadores")
    print("---------------------")
    print("Objetivo: " .. JUGADOR)
    print("Radio: " .. RADIO .. " bloques")
    print("Estado: " .. estado)
    print("")
    print("Chat Boxes: " .. #chatBoxes)
    print("Monitores: " .. #monitors)
    print("Speaker: " .. (speaker and "Conectado" or "No conectado"))

    for _, monitor in ipairs(monitors) do
        monitor.setTextScale(0.5)
        monitor.setBackgroundColor(colors.black)
        monitor.clear()

        monitor.setTextColor(colors.cyan)
        centrar(monitor, "DETECTOR DE JUGADORES", 2)

        monitor.setTextColor(colors.white)
        centrar(monitor, "Objetivo:", 4)

        monitor.setTextColor(colors.yellow)
        centrar(monitor, JUGADOR, 5)

        monitor.setTextColor(colors.white)
        centrar(monitor, "Radio: " .. RADIO .. " bloques", 7)

        monitor.setTextColor(color)
        centrar(monitor, estado, 9)
    end
end

-- =========================================================
-- DETECCIÓN
-- =========================================================

local function estaDentro()
    local ok, jugadores = pcall(function()
        return detector.getPlayersInRange(RADIO)
    end)

    if not ok then
        print("Error del detector: " .. tostring(jugadores))
        return false
    end

    if type(jugadores) ~= "table" then
        return false
    end

    for _, nombre in ipairs(jugadores) do
        if nombre == JUGADOR then
            return true
        end
    end

    return false
end

-- =========================================================
-- CHAT BOX
-- =========================================================

local function enviarMensaje(mensaje)
    for _, chatBox in ipairs(chatBoxes) do
        local ok, enviado, errorMensaje = pcall(function()
            return chatBox.sendMessageToPlayer(
                mensaje,
                JUGADOR,
                PREFIJO_CHAT,
                "[]",
                "&b"
            )
        end)

        if ok and enviado then
            return true
        end

        if not ok then
            print("Error al utilizar Chat Box: " .. tostring(enviado))
        elseif errorMensaje then
            print("Chat Box ocupada: " .. tostring(errorMensaje))
        end
    end

    return false
end

local function reproducirSonido()
    if speaker then
        speaker.playSound(
            SONIDO_ENTRADA,
            VOLUMEN,
            TONO
        )
    end
end

-- =========================================================
-- PROGRAMA PRINCIPAL
-- =========================================================

local estabaDentro = false

actualizarPantallas(
    "ESPERANDO...",
    colors.orange
)

while true do
    local dentro = estaDentro()

    if dentro and not estabaDentro then
        actualizarPantallas(
            "MIA DETECTADA",
            colors.lime
        )

        reproducirSonido()

        local enviado = enviarMensaje(MENSAJE_ENTRADA)

        if enviado then
            print("Mensaje enviado correctamente.")
        else
            print("No se pudo enviar el mensaje.")
        end

        estabaDentro = true

    elseif not dentro and estabaDentro then
        actualizarPantallas(
            "FUERA DE LA ZONA",
            colors.red
        )

        if AVISAR_AL_SALIR then
            enviarMensaje(MENSAJE_SALIDA)
        end

        estabaDentro = false

    elseif not dentro then
        actualizarPantallas(
            "ESPERANDO...",
            colors.orange
        )
    end

    sleep(COMPROBAR_CADA)
end
