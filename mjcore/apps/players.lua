return function(ctx)
    local monitor = ctx.monitor
    local ui = ctx.ui
    local theme = ctx.theme
    local _, h = monitor.getSize()

    monitor.setBackgroundColor(theme.background)
    monitor.clear()
    ui.header(monitor, "JUGADORES", "PROXIMAMENTE", theme)
    ui.center(monitor, math.floor(h / 2), "Detector de Mia y J0gar", theme.warning)
    ui.footer(monitor, "Toca para volver", "M&J CORE", theme)
    os.pullEvent()
end
