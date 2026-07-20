local ui = {}

function ui.findMonitor(preferredName)
    if preferredName and peripheral.isPresent(preferredName) then
        local p = peripheral.wrap(preferredName)
        if peripheral.getType(preferredName) == "monitor" then
            return p, preferredName
        end
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

function ui.center(target, y, text, fg, bg)
    local width = target.getSize()
    local x = math.max(1, math.floor((width - #text) / 2) + 1)
    ui.write(target, x, y, text, fg, bg)
end

function ui.clip(text, width)
    text = tostring(text or "")
    if width <= 0 then return "" end
    if #text <= width then return text end
    if width <= 2 then return text:sub(1, width) end
    return text:sub(1, width - 2) .. ".."
end

function ui.header(target, title, rightText, theme)
    local w = target.getSize()
    ui.fill(target, 1, 1, w, 2, theme.accent2)
    ui.write(target, 2, 1, title, theme.text, theme.accent2)

    if rightText and #rightText < w - 4 then
        ui.write(target, w - #rightText, 1, rightText, theme.text, theme.accent2)
    end

    ui.write(target, 2, 2, "Sistema central de Mia + J0gar", theme.muted, theme.accent2)
end

function ui.footer(target, leftText, rightText, theme)
    local w, h = target.getSize()
    ui.fill(target, 1, h, w, 1, theme.panel)

    if leftText then
        ui.write(target, 2, h, ui.clip(leftText, math.floor(w * 0.65)), theme.text, theme.panel)
    end

    if rightText and #rightText < w - 2 then
        ui.write(target, w - #rightText, h, rightText, theme.success, theme.panel)
    end
end

function ui.button(target, button, selected, theme)
    local bg = selected and theme.buttonSelected or theme.button
    local fg = selected and theme.buttonSelectedText or theme.buttonText

    ui.fill(target, button.x, button.y, button.w, button.h, bg)

    local labelY = button.y + math.floor(button.h / 2)
    local label = ui.clip(button.label, button.w - 2)
    local labelX = button.x + math.max(1, math.floor((button.w - #label) / 2))

    ui.write(target, labelX, labelY, label, fg, bg)

    if button.subtitle and button.h >= 4 then
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

return ui
