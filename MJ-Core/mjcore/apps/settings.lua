return function(ctx)
    local monitor = ctx.monitor
    local ui = ctx.ui
    local theme = ctx.theme
    local config = ctx.config
    local w, h = monitor.getSize()

    monitor.setBackgroundColor(theme.background)
    monitor.clear()
    ui.header(monitor, "AJUSTES", "v" .. config.version, theme)

    ui.write(monitor, 4, 5, "Monitor: " .. tostring(ctx.monitorName), theme.text, theme.background)
    ui.write(monitor, 4, 7, "Escala: " .. tostring(config.textScale), theme.text, theme.background)
    ui.write(monitor, 4, 9, "Resolucion: " .. w .. "x" .. h, theme.text, theme.background)
    ui.write(monitor, 4, 11, "Propietarios: " .. config.ownerLine, theme.text, theme.background)

    ui.footer(monitor, "Toca para volver", "M&J CORE", theme)
    os.pullEvent()
end
