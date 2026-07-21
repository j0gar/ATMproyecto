return function(context)
    local detector = dofile("/mjcore/core/mia_detector.lua")

    local app = {
        id = "players",
        title = "DETECTOR DE MIA",
        buttons = {}
    }

    local function addButton(self, id, x, y, w, h)
        table.insert(self.buttons, { id = id, x = x, y = y, w = w, h = h })
    end

    local function inside(button, x, y)
        return x >= button.x and x < button.x + button.w
           and y >= button.y and y < button.y + button.h
    end

    function app:start(ctx)
        detector.reload()
        detector.update(true)
    end

    function app:update(ctx)
        detector.update(false)
    end

    function app:draw(ctx)
        local monitor = ctx.monitor
        local ui = ctx.ui
        local theme = ctx.theme
        local w, h = monitor.getSize()
        local status = detector.status()

        monitor.setBackgroundColor(theme.background)
        monitor.clear()
        self.buttons = {}

        ui.fill(monitor, 1, 1, w, 2, theme.topbar)
        ui.write(monitor, 2, 1, self.title, theme.text, theme.topbar)
        ui.footer(monitor, theme, "")
        table.insert(self.buttons, ui.closeButton(monitor, theme))

        local stateText
        local stateColor

        if not status.enabled then
            stateText = "DESACTIVADO"
            stateColor = theme.warning
        elseif status.inside then
            stateText = "MIA ESTA EN LA ZONA"
            stateColor = theme.success
        else
            stateText = "MIA FUERA DE LA ZONA"
            stateColor = theme.muted
        end

        ui.center(monitor, 5, stateText, stateColor, theme.background)

        ui.fill(monitor, 3, 8, w - 5, 7, theme.panel)
        ui.border(monitor, 3, 8, w - 5, 7, theme.panelAlt, theme.panel)

        ui.write(monitor, 5, 9, "MENSAJE DEL DIA", theme.accent, theme.panel)
        ui.writeRich(monitor, 5, 11, ui.richClip(status.message or "", w - 10), theme.text, theme.panel)

        local p1 = status.corner1
        local p2 = status.corner2
        local coordText = string.format(
            "%d,%d,%d  ->  %d,%d,%d",
            p1.x, p1.y, p1.z,
            p2.x, p2.y, p2.z
        )
        ui.write(monitor, 5, 13, ui.clip(coordText, w - 10), theme.muted, theme.panel)

        local buttonW = math.floor((w - 7) / 2)
        local buttonY = h - 6

        ui.smallButton(monitor, 2, buttonY, buttonW, "RECARGAR", false, theme)
        addButton(self, "reload", 2, buttonY, buttonW, 3)

        ui.smallButton(monitor, w - buttonW - 1, buttonY, buttonW, "PROBAR MENSAJE", false, theme)
        addButton(self, "test", w - buttonW - 1, buttonY, buttonW, 3)

        if status.error then
            ui.write(monitor, 2, h - 2, ui.clip(status.error, w - 3), theme.warning, theme.background)
        end

        ui.fill(monitor, 1, h, w, 1, theme.topbar)
        ui.write(monitor, 2, h, "Toca arriba para volver", theme.text, theme.topbar)
    end

    function app:touch(x, y, ctx)
        for _, button in ipairs(self.buttons) do
            if inside(button, x, y) then
                if button.id == "close" then return "close" end
                if button.id == "reload" then
                    detector.reload()
                    detector.update(true)
                    ctx.notifications.push("Configuracion recargada", "success")

                elseif button.id == "test" then
                    local ok, err = detector.sendDailyMessage()
                    if ok then
                        ctx.notifications.push("Mensaje enviado a Mia", "success")
                    else
                        ctx.notifications.push(err or "No se pudo enviar", "error")
                    end
                end
                return
            end
        end

    end

    return app
end
