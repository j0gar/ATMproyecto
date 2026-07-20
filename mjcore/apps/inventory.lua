return function(context)
    local inventoryCore = dofile("/mjcore/core/inventory.lua")

    local app = {
        id = "inventory",
        title = "INVENTARIO",
        data = nil,
        error = nil,
        page = 1,
        sortMode = "count",
        descending = true,
        pageSize = 4,
        buttons = {},
        originalScale = context.config.textScale
    }

    local function inside(button, x, y)
        return x >= button.x and x < button.x + button.w
           and y >= button.y and y < button.y + button.h
    end

    local function sortItems(self)
        if not self.data then return end

        table.sort(self.data.items, function(a, b)
            if self.sortMode == "name" then
                local left = string.lower(a.displayName or a.name)
                local right = string.lower(b.displayName or b.name)
                if left == right then return a.count > b.count end
                return self.descending and left > right or left < right

            elseif self.sortMode == "mod" then
                if a.mod == b.mod then
                    return a.displayName < b.displayName
                end
                return self.descending and a.mod > b.mod or a.mod < b.mod

            else
                if a.count == b.count then
                    return a.displayName < b.displayName
                end
                return self.descending and a.count > b.count or a.count < b.count
            end
        end)
    end

    local function refresh(self, ctx)
        self.error = nil
        local result, err = inventoryCore.scan()

        if not result then
            self.data = nil
            self.error = tostring(err)
            return
        end

        self.data = result
        self.page = 1
        sortItems(self)
    end

    function app:start(ctx)
        -- El inventario usa una escala mayor para que sea legible.
        ctx.monitor.setTextScale(1)
        refresh(self, ctx)
    end

    function app:close(ctx)
        ctx.monitor.setTextScale(self.originalScale)
    end

    function app:draw(ctx)
        local monitor = ctx.monitor
        local ui = ctx.ui
        local theme = ctx.theme
        local w, h = monitor.getSize()

        monitor.setBackgroundColor(theme.background)
        monitor.clear()
        self.buttons = {}

        ui.fill(monitor, 1, 1, w, 2, theme.topbar)
        ui.write(monitor, 2, 1, self.title, theme.text, theme.topbar)
        table.insert(self.buttons, ui.closeButton(monitor, theme))

        if self.data then
            local typeText = tostring(self.data.totalTypes) .. " TIPOS"
            ui.write(monitor, w - #typeText - 1, 1, typeText, theme.accent, theme.topbar)
        end

        local controls = {
            { id = "sortCount", label = "CANT." },
            { id = "sortName", label = "NOMBRE" },
            { id = "sortMod", label = "MOD" },
            { id = "refresh", label = "RECARGAR" }
        }

        local gap = 1
        local controlW = math.floor((w - 5 - gap * 3) / 4)
        local x = 2

        for _, control in ipairs(controls) do
            local active =
                (control.id == "sortCount" and self.sortMode == "count") or
                (control.id == "sortName" and self.sortMode == "name") or
                (control.id == "sortMod" and self.sortMode == "mod")

            ui.smallButton(monitor, x, 4, controlW, control.label, active, theme)
            table.insert(self.buttons, {
                id = control.id,
                x = x,
                y = 4,
                w = controlW,
                h = 3
            })

            x = x + controlW + gap
        end

        if self.error then
            ui.center(monitor, math.floor(h / 2) - 1, "ERROR DE INVENTARIO", theme.danger, theme.background)
            ui.center(monitor, math.floor(h / 2) + 1, ui.clip(self.error, w - 6), theme.muted, theme.background)
            return
        end

        if self.data then
            local listTop = 8
            local footerY = h - 4
            local available = footerY - listTop - 1
            local cardH = 4
            self.pageSize = math.max(1, math.floor(available / (cardH + 1)))

            local pages = math.max(1, math.ceil(#self.data.items / self.pageSize))
            if self.page > pages then self.page = pages end

            local first = (self.page - 1) * self.pageSize + 1
            local last = math.min(#self.data.items, first + self.pageSize - 1)
            local y = listTop

            for index = first, last do
                local item = self.data.items[index]
                local count = ui.formatNumber(item.count)

                ui.fill(monitor, 2, y, w - 3, cardH, theme.panel)
                ui.border(monitor, 2, y, w - 3, cardH, theme.panelAlt, theme.panel)

                ui.write(
                    monitor,
                    4,
                    y + 1,
                    ui.clip(item.displayName, w - #count - 10),
                    theme.text,
                    theme.panel
                )
                ui.write(
                    monitor,
                    w - #count - 3,
                    y + 1,
                    count,
                    theme.accent,
                    theme.panel
                )
                ui.write(
                    monitor,
                    4,
                    y + 2,
                    ui.clip(item.mod, w - 8),
                    theme.muted,
                    theme.panel
                )

                y = y + cardH + 1
            end

            local navW = 10
            ui.smallButton(monitor, 2, footerY, navW, "<", false, theme)
            table.insert(self.buttons, { id = "previous", x = 2, y = footerY, w = navW, h = 3 })

            ui.smallButton(monitor, w - navW - 1, footerY, navW, ">", false, theme)
            table.insert(self.buttons, { id = "next", x = w - navW - 1, y = footerY, w = navW, h = 3 })

            ui.center(monitor, footerY + 1, tostring(self.page) .. "/" .. tostring(pages), theme.text, theme.background)

            ui.fill(monitor, 1, h, w, 1, theme.topbar)
            local total = "TOTAL " .. ui.formatNumber(self.data.totalItems)
            ui.write(monitor, 2, h, total, theme.text, theme.topbar)
        end
    end

    function app:touch(x, y, ctx)
        for _, button in ipairs(self.buttons) do
            if inside(button, x, y) then
                if button.id == "close" then return "close" end
                if button.id == "refresh" then
                    refresh(self, ctx)

                elseif button.id == "sortCount" then
                    if self.sortMode == "count" then
                        self.descending = not self.descending
                    else
                        self.sortMode = "count"
                        self.descending = true
                    end
                    sortItems(self)
                    self.page = 1

                elseif button.id == "sortName" then
                    if self.sortMode == "name" then
                        self.descending = not self.descending
                    else
                        self.sortMode = "name"
                        self.descending = false
                    end
                    sortItems(self)
                    self.page = 1

                elseif button.id == "sortMod" then
                    if self.sortMode == "mod" then
                        self.descending = not self.descending
                    else
                        self.sortMode = "mod"
                        self.descending = false
                    end
                    sortItems(self)
                    self.page = 1

                elseif button.id == "previous" then
                    self.page = math.max(1, self.page - 1)

                elseif button.id == "next" and self.data then
                    local pages = math.max(1, math.ceil(#self.data.items / self.pageSize))
                    self.page = math.min(pages, self.page + 1)
                end

                return
            end
        end
    end

    return app
end
