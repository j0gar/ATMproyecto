return function(ctx)
    local monitor = ctx.monitor
    local ui = ctx.ui
    local theme = ctx.theme
    local updater = dofile("/mjcore/core/updater.lua")
    local _, h = monitor.getSize()

    monitor.setBackgroundColor(theme.background)
    monitor.clear()
    ui.header(monitor, "ACTUALIZADOR", "GitHub", theme)
    ui.center(monitor, math.floor(h / 2) - 2, "Buscando actualizaciones...", theme.text)

    local status, err = updater.check()

    if not status then
        ui.center(monitor, math.floor(h / 2), "ERROR: " .. ui.clip(err, 40), theme.danger)
        ui.footer(monitor, "Toca para volver", "ERROR", theme)
        os.pullEvent()
        return
    end

    if not status.available then
        ui.center(monitor, math.floor(h / 2), "Sistema actualizado: v" .. status.current, theme.success)
        ui.footer(monitor, "Toca para volver", "ACTUALIZADO", theme)
        os.pullEvent()
        return
    end

    ui.center(monitor, math.floor(h / 2) - 1, "Nueva version: v" .. status.latest, theme.warning)
    ui.center(monitor, math.floor(h / 2) + 1, "Usa 'mj update' en el ordenador", theme.text)
    ui.footer(monitor, "Toca para volver", "DISPONIBLE", theme)
    os.pullEvent()
end
