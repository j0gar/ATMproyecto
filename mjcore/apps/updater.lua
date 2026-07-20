return function(context)
    local updater = dofile("/mjcore/core/updater.lua")
    local app = {
        id = "updater",
        title = "ACTUALIZADOR",
        status = "Buscando actualizaciones...",
        level = "info"
    }

    function app:start(ctx)
        local result, err = updater.check()

        if not result then
            self.status = "Error: " .. tostring(err)
            self.level = "error"
            return
        end

        if result.available then
            self.status = "Nueva version: " .. result.latest
            self.level = "warning"
        else
            self.status = "Sistema actualizado: " .. result.current
            self.level = "success"
        end
    end

    function app:draw(ctx)
        local m = ctx.monitor
        local ui = ctx.ui
        local t = ctx.theme
        local w, h = m.getSize()

        m.setBackgroundColor(t.background)
        m.clear()

        ui.fill(m, 1, 1, w, 2, t.topbar)
        ui.write(m, 2, 1, self.title, t.text, t.topbar)
        ui.write(m, 2, 2, "GitHub", t.muted, t.topbar)

        local color = t.text
        if self.level == "success" then color = t.success end
        if self.level == "warning" then color = t.warning end
        if self.level == "error" then color = t.danger end

        ui.center(m, math.floor(h / 2), self.status, color, t.background)

        if self.level == "warning" then
            ui.center(m, math.floor(h / 2) + 2, "Usa 'mj update' en el ordenador", t.text, t.background)
        end

        ui.fill(m, 1, h, w, 1, t.panel)
        ui.write(m, 2, h, "Toca o pulsa ESC para volver", t.text, t.panel)
    end

    function app:touch()
        return "close"
    end

    return app
end
