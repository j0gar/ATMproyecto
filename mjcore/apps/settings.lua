return function(context)
    local app = {
        id = "settings",
        title = "AJUSTES",
        buttons = {}
    }

    function app:draw(ctx)
        local m = ctx.monitor
        local ui = ctx.ui
        local t = ctx.theme
        local c = ctx.config
        local w, h = m.getSize()
        self.buttons = {}

        m.setBackgroundColor(t.background)
        m.clear()

        ui.fill(m, 1, 1, w, 2, t.topbar)
        ui.write(m, 2, 1, self.title, t.text, t.topbar)
        table.insert(self.buttons, ui.closeButton(m, t))
        ui.write(m, 2, 2, "M&J Core", t.muted, t.topbar)

        ui.write(m, 4, 5, "Version: " .. c.version, t.text, t.background)
        ui.write(m, 4, 7, "Nombre: " .. c.title, t.text, t.background)
        ui.write(m, 4, 9, "Monitor: " .. ctx.monitorName, t.text, t.background)
        ui.write(m, 4, 11, "Escala: " .. c.textScale, t.text, t.background)
        ui.write(m, 4, 13, "GitHub: " .. c.github.owner .. "/" .. c.github.repo, t.text, t.background)

        ui.fill(m, 1, h, w, 1, t.panel)
        ui.write(m, 2, h, "Toca o pulsa ESC para volver", t.text, t.panel)
    end

    function app:touch()
        return "close"
    end

    return app
end
