return function(context)
    local app = {
        id = "system",
        title = "SISTEMA",
        buttons = {},
        confirm = nil
    }

    function app:draw(ctx)
        local m = ctx.monitor
        local ui = ctx.ui
        local t = ctx.theme
        local w, h = m.getSize()

        m.setBackgroundColor(t.background)
        m.clear()
        self.buttons = {}

        ui.fill(m, 1, 1, w, 2, t.topbar)
        ui.write(m, 2, 1, self.title, t.text, t.topbar)
        ui.footer(m, t, "")
        table.insert(self.buttons, ui.closeButton(m, t))
        ui.write(m, w - 13, 1, "v" .. ctx.config.version, t.accent, t.topbar)

        ui.write(m, 4, 5, "Monitor", t.accent, t.background)
        ui.write(m, 20, 5, ctx.monitorName, t.text, t.background)
        ui.write(m, 4, 7, "Perifericos", t.accent, t.background)
        ui.write(m, 20, 7, tostring(#peripheral.getNames()), t.text, t.background)
        ui.write(m, 4, 9, "Ordenador", t.accent, t.background)
        ui.write(m, 20, 9, tostring(os.getComputerID()), t.text, t.background)

        local buttonW = math.floor((w - 7) / 3)
        local y = 13
        local actions = {
            {id="logs", label="VER LOGS"},
            {id="reboot", label="REINICIAR"},
            {id="shutdown", label="APAGAR"}
        }

        for i, action in ipairs(actions) do
            local x = 2 + (i - 1) * (buttonW + 1)
            ui.smallButton(m, x, y, buttonW, action.label, false, t)
            table.insert(self.buttons, {id=action.id, x=x, y=y, w=buttonW, h=3})
        end

        if self.confirm then
            ui.dialog(m, "CONFIRMAR", self.confirm.message, t)
        end

        ui.fill(m, 1, h, w, 1, t.topbar)
        ui.write(m, 2, h, "Toca arriba para volver", t.text, t.topbar)
    end

    function app:touch(x, y, ctx)
        if self.confirm then
            local action = self.confirm.action
            self.confirm = nil

            if action == "reboot" then
                os.reboot()
            elseif action == "shutdown" then
                os.shutdown()
            end
            return
        end

        for _, button in ipairs(self.buttons) do
            if x >= button.x and x < button.x + button.w
            and y >= button.y and y < button.y + button.h then
                if button.id == "close" then return "close" end
                if button.id == "logs" then
                    ctx.notifications.push("Logs guardados en el ordenador", "info")
                elseif button.id == "reboot" then
                    self.confirm = {action="reboot", message="Toca de nuevo para reiniciar"}
                elseif button.id == "shutdown" then
                    self.confirm = {action="shutdown", message="Toca de nuevo para apagar"}
                end
                return
            end
        end

    end

    return app
end
