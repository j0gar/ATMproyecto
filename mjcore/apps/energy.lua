return function(context)
    local app = {
        id = "energy",
        title = "ENERGIA"
    }

    function app:draw(ctx)
        local monitor = ctx.monitor
        local ui = ctx.ui
        local theme = ctx.theme
        local w, h = monitor.getSize()

        monitor.setBackgroundColor(theme.background)
        monitor.clear()

        ui.fill(monitor, 1, 1, w, 2, theme.topbar)
        ui.write(monitor, 2, 1, self.title, theme.text, theme.topbar)
        table.insert(self.buttons, ui.closeButton(monitor, theme))
        ui.write(monitor, 2, 2, "M&J Core", theme.muted, theme.topbar)

        ui.center(monitor, math.floor(h / 2), "Panel de energia preparado", theme.warning, theme.background)

        ui.fill(monitor, 1, h, w, 1, theme.panel)
        ui.write(monitor, 2, h, "Toca o pulsa ESC para volver", theme.text, theme.panel)
    end

    function app:touch()
        return "close"
    end

    return app
end
