return function(context)
    local updater = dofile("/mjcore/core/updater.lua")

    local app = {
        id = "updater",
        title = "ACTUALIZADOR",
        state = "checking",
        message = "Buscando actualizaciones...",
        current = context.config.version,
        latest = "?",
        progress = 0,
        total = 1,
        currentFile = "",
        error = nil,
        buttons = {}
    }

    local function checkForUpdates(self)
        self.state = "checking"
        self.message = "Buscando actualizaciones..."
        self.error = nil

        local status, err = updater.check()

        if not status then
            self.state = "error"
            self.message = "No se pudo comprobar GitHub"
            self.error = tostring(err)
            return
        end

        self.current = status.current
        self.latest = status.latest

        if status.available then
            self.state = "available"
            self.message = "Nueva version disponible"
        else
            self.state = "updated"
            self.message = "El sistema ya esta actualizado"
        end
    end

    local function installUpdate(self, ctx)
        self.state = "installing"
        self.message = "Descargando actualizacion..."
        self.progress = 0
        self.total = 1
        self.currentFile = ""
        self.error = nil

        self:draw(ctx)
        sleep(0.15)

        local ok, result = updater.install(function(index, total, path)
            self.progress = index
            self.total = math.max(1, total)
            self.currentFile = path
            self.message = "Descargando archivos..."
            self:draw(ctx)
            sleep(0)
        end)

        if not ok then
            self.state = "error"
            self.message = "La actualizacion ha fallado"
            self.error = tostring(result)
            ctx.logger.log("Actualizacion fallida: " .. tostring(result), "ERROR")
            return
        end

        self.state = "done"
        self.latest = tostring(result)
        self.message = "Actualizacion completada"
        ctx.logger.log("Actualizado a " .. tostring(result))
        self:draw(ctx)
        sleep(1.5)
        os.reboot()
    end

    function app:start(ctx)
        checkForUpdates(self)
    end

    function app:draw(ctx)
        local m = ctx.monitor
        local ui = ctx.ui
        local t = ctx.theme
        local w, h = m.getSize()
        self.buttons = {}

        m.setBackgroundColor(t.background)
        m.clear()

        ui.fill(m, 1, 1, w, 2, t.topbar)
        ui.write(m, 2, 1, self.title, t.text, t.topbar)
        ui.footer(m, t, "")
        ui.write(m, 2, 2, "Actualizacion desde GitHub", t.muted, t.topbar)

        ui.write(m, 4, 5, "Instalada:  " .. tostring(self.current), t.text, t.background)
        ui.write(m, 4, 7, "Disponible: " .. tostring(self.latest), t.text, t.background)

        local statusColor = t.text
        if self.state == "available" then statusColor = t.warning end
        if self.state == "updated" or self.state == "done" then statusColor = t.success end
        if self.state == "error" then statusColor = t.danger end

        ui.center(m, 10, self.message, statusColor, t.background)

        if self.state == "available" then
            local buttonW = math.min(28, w - 8)
            local buttonX = math.floor((w - buttonW) / 2) + 1
            local buttonY = 13

            ui.fill(m, buttonX, buttonY, buttonW, 5, t.accent)
            ui.center(m, buttonY + 1, "INSTALAR AHORA", t.selectedText, t.accent)
            ui.center(m, buttonY + 3, "Toca este boton", t.selectedText, t.accent)

            self.installButton = {
                x = buttonX,
                y = buttonY,
                w = buttonW,
                h = 5
            }

        elseif self.state == "installing" then
            local barW = math.min(42, w - 10)
            local barX = math.floor((w - barW) / 2) + 1
            local ratio = self.progress / math.max(1, self.total)

            ui.progress(m, barX, 13, barW, self.progress, self.total, t)
            ui.center(
                m,
                15,
                tostring(self.progress) .. " / " .. tostring(self.total),
                t.text,
                t.background
            )
            ui.center(
                m,
                17,
                ui.clip(self.currentFile, w - 8),
                t.muted,
                t.background
            )

        elseif self.state == "updated" then
            ui.center(m, 13, "No tienes que hacer nada.", t.muted, t.background)
            ui.center(m, 15, "Toca para volver.", t.text, t.background)

        elseif self.state == "error" then
            ui.center(m, 13, ui.clip(self.error or "Error desconocido", w - 8), t.danger, t.background)
            ui.center(m, 15, "Toca para reintentar", t.text, t.background)
        end

        ui.fill(m, 1, h, w, 1, t.panel)
        ui.write(m, 2, h, "ESC: volver", t.text, t.panel)
        table.insert(self.buttons, ui.closeButton(m, t))
    end

    function app:touch(x, y, ctx)
        if self.state == "available" and self.installButton then
            local b = self.installButton
            if x >= b.x and x < b.x + b.w
            and y >= b.y and y < b.y + b.h then
                installUpdate(self, ctx)
                return
            end
        elseif self.state == "error" then
            checkForUpdates(self)
            return
        elseif self.state == "updated" then
            return "close"
        end
    end

    function app:key(key, ctx)
        if key == keys.enter and self.state == "available" then
            installUpdate(self, ctx)
        elseif key == keys.enter and self.state == "error" then
            checkForUpdates(self)
        end
    end

    return app
end
