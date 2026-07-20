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
        pageSize = 8,
        buttons = {}
    }

    local function sortItems(self)
        if not self.data then return end

        table.sort(self.data.items, function(a, b)
            if self.sortMode == "name" then
                local left = string.lower(a.displayName or a.name)
                local right = string.lower(b.displayName or b.name)
                if left == right then return a.count > b.count end
                if self.descending then return left > right end
                return left < right
            elseif self.sortMode == "mod" then
                if a.mod == b.mod then
                    return a.displayName < b.displayName
                end
                if self.descending then return a.mod > b.mod end
                return a.mod < b.mod
            else
                if a.count == b.count then
                    return a.displayName < b.displayName
                end
                if self.descending then return a.count > b.count end
                return a.count < b.count
            end
        end)
    end

    local function refresh(self, ctx)
        self.error = nil
        local result, err = inventoryCore.scan()

        if not result then
            self.data = nil
            self.error = tostring(err)
            ctx.logger.log("Inventario: " .. tostring(err), "ERROR")
            return
        end

        self.data = result
        self.page = 1
        sortItems(self)
        ctx.logger.log("Inventario sincronizado: " .. result.totalTypes .. " tipos")
    end

    function app:start(ctx)
        refresh(self, ctx)
    end

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

        if self.data then
            ui.write(
                m,
                w - 24,
                1,
                tostring(self.data.totalTypes) .. " tipos",
                t.accent,
                t.topbar
            )
        end

        local controls = {
            {id="sortCount", label="CANTIDAD"},
            {id="sortName", label="NOMBRE"},
            {id="sortMod", label="MOD"},
            {id="refresh", label="ACTUALIZAR"}
        }

        local gap = 1
        local controlW = math.floor((w - 5 - gap * 3) / 4)
        local x = 2

        for _, control in ipairs(controls) do
            local active =
                (control.id == "sortCount" and self.sortMode == "count") or
                (control.id == "sortName" and self.sortMode == "name") or
                (control.id == "sortMod" and self.sortMode == "mod")

            ui.smallButton(m, x, 4, controlW, control.label, active, t)
            table.insert(self.buttons, {
                id = control.id,
                x = x, y = 4, w = controlW, h = 3
            })
            x = x + controlW + gap
        end

        if self.error then
            ui.center(m, math.floor(h / 2) - 1, "NO SE PUDO LEER EL INVENTARIO", t.danger, t.background)
            ui.center(m, math.floor(h / 2) + 1, ui.clip(self.error, w - 8), t.muted, t.background)
            ui.center(m, math.floor(h / 2) + 3, "Pulsa ACTUALIZAR para reintentar", t.text, t.background)
        elseif self.data then
            local listTop = 8
            local listBottom = h - 5
            local availableRows = listBottom - listTop + 1
            self.pageSize = math.max(1, math.floor(availableRows / 2))

            local pageCount = math.max(1, math.ceil(#self.data.items / self.pageSize))
            if self.page > pageCount then self.page = pageCount end

            local first = (self.page - 1) * self.pageSize + 1
            local last = math.min(#self.data.items, first + self.pageSize - 1)

            local row = listTop
            for index = first, last do
                local item = self.data.items[index]
                local bg = ((index - first) % 2 == 0) and t.panel or t.background
                ui.fill(m, 2, row, w - 3, 2, bg)
                ui.write(m, 3, row, ui.clip(item.displayName, w - 24), t.text, bg)
                ui.write(m, 3, row + 1, ui.clip(item.mod, w - 24), t.muted, bg)

                local count = ui.formatNumber(item.count)
                ui.write(m, w - #count - 2, row, count, t.accent, bg)
                row = row + 2
            end

            local footerY = h - 4
            local navW = 14

            ui.smallButton(m, 2, footerY, navW, "< ANTERIOR", false, t)
            table.insert(self.buttons, {id="previous", x=2, y=footerY, w=navW, h=3})

            local nextX = w - navW - 1
            ui.smallButton(m, nextX, footerY, navW, "SIGUIENTE >", false, t)
            table.insert(self.buttons, {id="next", x=nextX, y=footerY, w=navW, h=3})

            local pageText = "PAG " .. self.page .. "/" .. pageCount
            ui.center(m, footerY + 1, pageText, t.text, t.background)

            ui.fill(m, 1, h, w, 1, t.topbar)
            ui.write(
                m,
                2,
                h,
                "Total: " .. ui.formatNumber(self.data.totalItems),
                t.text,
                t.topbar
            )
            ui.write(
                m,
                w - #self.data.controllerName,
                h,
                self.data.controllerName,
                t.muted,
                t.topbar
            )
        end
    end

    function app:touch(x, y, ctx)
        for _, button in ipairs(self.buttons) do
            if x >= button.x and x < button.x + button.w
            and y >= button.y and y < button.y + button.h then

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

        if y <= 2 then
            return "close"
        end
    end

    return app
end
