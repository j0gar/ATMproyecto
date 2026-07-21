local ui = {}

function ui.findMonitor(preferredName)
    if preferredName and peripheral.isPresent(preferredName)
    and peripheral.getType(preferredName) == "monitor" then
        return peripheral.wrap(preferredName), preferredName
    end

    local names = peripheral.getNames()
    table.sort(names)

    for _, name in ipairs(names) do
        if peripheral.getType(name) == "monitor" then
            return peripheral.wrap(name), name
        end
    end

    return nil, nil
end

function ui.fill(target, x, y, width, height, bg)
    target.setBackgroundColor(bg)
    for row = y, y + height - 1 do
        target.setCursorPos(x, row)
        target.write(string.rep(" ", math.max(0, width)))
    end
end

function ui.write(target, x, y, text, fg, bg)
    if bg then target.setBackgroundColor(bg) end
    if fg then target.setTextColor(fg) end
    target.setCursorPos(x, y)
    target.write(tostring(text))
end

-- Convierte texto UTF-8 a caracteres que el terminal de CC:Tweaked puede
-- dibujar. Los signos diacríticos se pintan en la fila superior, de modo
-- que una ñ se representa como una n con una virgulilla encima.
local spanishGlyphs = {
    ["á"] = { base = "a", mark = "'" },
    ["é"] = { base = "e", mark = "'" },
    ["í"] = { base = "i", mark = "'" },
    ["ó"] = { base = "o", mark = "'" },
    ["ú"] = { base = "u", mark = "'" },
    ["Á"] = { base = "A", mark = "'" },
    ["É"] = { base = "E", mark = "'" },
    ["Í"] = { base = "I", mark = "'" },
    ["Ó"] = { base = "O", mark = "'" },
    ["Ú"] = { base = "U", mark = "'" },
    ["ñ"] = { base = "n", mark = "~" },
    ["Ñ"] = { base = "N", mark = "~" },
    ["ü"] = { base = "u", mark = ":" },
    ["Ü"] = { base = "U", mark = ":" },
    ["¿"] = { base = "?" },
    ["¡"] = { base = "!" }
}

local function utf8Chars(text)
    text = tostring(text or "")
    local chars = {}
    local i = 1

    while i <= #text do
        local first = text:byte(i)
        local length = 1
        if first and first >= 240 then
            length = 4
        elseif first and first >= 224 then
            length = 3
        elseif first and first >= 192 then
            length = 2
        end

        chars[#chars + 1] = text:sub(i, i + length - 1)
        i = i + length
    end

    return chars
end

function ui.richLength(text)
    return #utf8Chars(text)
end

function ui.richClip(text, width)
    local chars = utf8Chars(text)
    width = math.floor(tonumber(width) or 0)
    if width <= 0 then return "" end
    if #chars <= width then return table.concat(chars) end
    if width <= 2 then
        local out = {}
        for i = 1, width do out[#out + 1] = chars[i] end
        return table.concat(out)
    end

    local out = {}
    for i = 1, width - 2 do out[#out + 1] = chars[i] end
    return table.concat(out) .. ".."
end

function ui.writeRich(target, x, y, text, fg, bg)
    local chars = utf8Chars(text)
    local cursorX = x

    if bg then target.setBackgroundColor(bg) end
    if fg then target.setTextColor(fg) end

    for _, char in ipairs(chars) do
        local glyph = spanishGlyphs[char]
        local base = glyph and glyph.base or char

        -- Los caracteres UTF-8 no contemplados se sustituyen para evitar
        -- que aparezcan dos símbolos corruptos en pantalla.
        if #base > 1 then base = "?" end

        target.setCursorPos(cursorX, y)
        target.write(base)

        if glyph and glyph.mark and y > 1 then
            target.setCursorPos(cursorX, y - 1)
            target.write(glyph.mark)
        end

        cursorX = cursorX + 1
    end
end

function ui.center(target, y, text, fg, bg)
    local width = target.getSize()
    local x = math.max(1, math.floor((width - #tostring(text)) / 2) + 1)
    ui.write(target, x, y, text, fg, bg)
end

function ui.clip(text, width)
    text = tostring(text or "")
    if width <= 0 then return "" end
    if #text <= width then return text end
    if width <= 2 then return text:sub(1, width) end
    return text:sub(1, width - 2) .. ".."
end

function ui.border(target, x, y, width, height, fg, bg)
    local horizontal = string.rep("-", math.max(0, width - 2))
    ui.write(target, x, y, "+" .. horizontal .. "+", fg, bg)

    for row = y + 1, y + height - 2 do
        ui.write(target, x, row, "|", fg, bg)
        ui.write(target, x + width - 1, row, "|", fg, bg)
    end

    ui.write(target, x, y + height - 1, "+" .. horizontal .. "+", fg, bg)
end

function ui.progress(target, x, y, width, value, maximum, theme)
    maximum = math.max(1, maximum or 100)
    value = math.max(0, math.min(value or 0, maximum))

    local filled = math.floor((value / maximum) * width)

    ui.fill(target, x, y, width, 1, theme.panel)
    if filled > 0 then
        ui.fill(target, x, y, filled, 1, theme.accent)
    end
end

function ui.button(target, button, selected, theme)
    local bg = selected and theme.accent or theme.button
    local fg = selected and theme.selectedText or theme.buttonText

    ui.fill(target, button.x, button.y, button.w, button.h, bg)

    local label = ui.clip(button.label, button.w - 2)
    local labelX = button.x + math.max(1, math.floor((button.w - #label) / 2))
    local labelY = button.y + math.floor(button.h / 2)

    if button.icon and button.h >= 5 then
        local icon = ui.clip(button.icon, button.w - 2)
        local iconX = button.x + math.max(1, math.floor((button.w - #icon) / 2))
        ui.write(target, iconX, button.y + 1, icon, fg, bg)
        labelY = button.y + 3
    end

    ui.write(target, labelX, labelY, label, fg, bg)

    if button.subtitle and button.h >= 6 then
        local subtitle = ui.clip(button.subtitle, button.w - 2)
        local subX = button.x + math.max(1, math.floor((button.w - #subtitle) / 2))
        ui.write(target, subX, labelY + 1, subtitle, selected and colors.gray or theme.muted, bg)
    end
end

function ui.hit(buttons, x, y)
    for index, button in ipairs(buttons) do
        if x >= button.x and x < button.x + button.w
        and y >= button.y and y < button.y + button.h then
            return index, button
        end
    end
    return nil, nil
end

function ui.dialog(target, title, message, theme)
    local w, h = target.getSize()
    local boxW = math.min(w - 6, 50)
    local boxH = 7
    local x = math.floor((w - boxW) / 2) + 1
    local y = math.floor((h - boxH) / 2) + 1

    ui.fill(target, x, y, boxW, boxH, theme.panel)
    ui.border(target, x, y, boxW, boxH, theme.accent, theme.panel)
    ui.center(target, y + 1, title, theme.accent, theme.panel)
    ui.write(target, x + 2, y + 3, ui.clip(message, boxW - 4), theme.text, theme.panel)
    ui.write(target, x + 2, y + 5, "Toca o pulsa una tecla", theme.muted, theme.panel)
end

function ui.notification(target, notification, theme)
    if not notification then return end

    local w = target.getSize()
    local boxW = math.min(32, w - 4)
    local x = w - boxW - 1
    local y = 3

    local bg = theme.panel
    local fg = theme.text

    if notification.level == "success" then fg = theme.success end
    if notification.level == "warning" then fg = theme.warning end
    if notification.level == "error" then fg = theme.danger end

    ui.fill(target, x, y, boxW, 4, bg)
    ui.border(target, x, y, boxW, 4, fg, bg)
    ui.write(target, x + 2, y + 1, ui.clip(notification.message, boxW - 4), fg, bg)
end


function ui.card(target, x, y, width, height, title, subtitle, selected, theme)
    local border = selected and theme.accent or theme.panelAlt
    local bg = theme.panel
    local fg = theme.text

    ui.fill(target, x, y, width, height, bg)
    ui.border(target, x, y, width, height, border, bg)

    if title then
        ui.write(target, x + 2, y + 1, ui.clip(title, width - 4), fg, bg)
    end

    if subtitle and height >= 4 then
        ui.write(target, x + 2, y + 2, ui.clip(subtitle, width - 4), theme.muted, bg)
    end
end

function ui.smallButton(target, x, y, width, label, active, theme)
    local bg = active and theme.accent or theme.button
    local fg = active and theme.selectedText or theme.buttonText
    ui.fill(target, x, y, width, 3, bg)
    ui.centerInBox(target, x, y, width, 3, label, fg, bg)
end

function ui.centerInBox(target, x, y, width, height, text, fg, bg)
    local tx = x + math.max(0, math.floor((width - #tostring(text)) / 2))
    local ty = y + math.floor(height / 2)
    ui.write(target, tx, ty, ui.clip(text, width), fg, bg)
end

function ui.formatNumber(value)
    local number = tonumber(value) or 0
    local text = tostring(math.floor(number))
    local result = text

    while true do
        local nextResult, count = result:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
        result = nextResult
        if count == 0 then break end
    end

    return result
end


function ui.closeButton(target, theme, label)
    local w, h = target.getSize()
    label = label or "CERRAR"
    local width = math.max(7, #label + 2)
    local x = w - width + 1
    local y = h

    ui.fill(target, x, y, width, 1, theme.danger)
    ui.centerInBox(target, x, y, width, 1, label, colors.white, theme.danger)

    return { id = "close", x = x, y = y, w = width, h = 1 }
end

function ui.footer(target, theme, leftText)
    local w, h = target.getSize()
    ui.fill(target, 1, h, w, 1, theme.footer or theme.topbar)
    if leftText and leftText ~= "" then
        ui.write(target, 2, h, ui.clip(leftText, math.max(0, w - 12)), theme.text, theme.footer or theme.topbar)
    end
end

function ui.compactButton(target, x, y, width, label, active, theme, colour)
    local bg = colour or (active and theme.accent or theme.button)
    local fg = active and theme.selectedText or theme.buttonText
    ui.fill(target, x, y, width, 1, bg)
    ui.centerInBox(target, x, y, width, 1, label, fg, bg)
    return { x=x, y=y, w=width, h=1 }
end

function ui.drawPixelIcon(target, x, y, icon, colour, background)
    if not icon then return end
    background = background or colors.black
    for row, line in ipairs(icon) do
        for col = 1, #line do
            local on = line:sub(col, col) ~= " " and line:sub(col, col) ~= "0"
            ui.fill(target, x + col - 1, y + row - 1, 1, 1, on and colour or background)
        end
    end
end

return ui
