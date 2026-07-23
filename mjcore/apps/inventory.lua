return function(context)
    local node = dofile("/mjcore/core/node.lua")
    local network = dofile("/mjcore/core/network.lua")
    local logistics = dofile("/mjcore/core/logistics.lua")

    local app = {
        id = "inventory",
        title = "INVENTARIO",
        data = nil,
        error = nil,
        message = nil,
        messageUntil = nil,
        page = 1,
        pageSize = 8,
        buttons = {},
        originalScale = context.config.textScale
    }

    local amounts = {1, 16, 32, 64}

    local function now()
        if os.epoch then return os.epoch("utc") / 1000 end
        return os.clock()
    end

    local function inside(button, x, y)
        return x >= button.x and x < button.x + button.w
           and y >= button.y and y < button.y + button.h
    end

    local function scan()
        if node.role == "terminal" then return network.request("inventory_scan", {}, 4) end
        return logistics.scan()
    end

    local function deliver(item, count)
        if node.role == "terminal" then
            return network.request("inventory_deliver", {
                player = node.player,
                item = item.name,
                count = count
            }, 4)
        end
        return logistics.deliver(node.player, item.name, count)
    end

    local function storeKnown()
        if node.role == "terminal" then
            return network.request("inventory_store_known", {player = node.player}, 6)
        end
        return logistics.storeKnown(node.player)
    end

    local function setMessage(self, text)
        self.message = tostring(text)
        self.messageUntil = now() + 3
    end

    local function refresh(self, keepMessage)
        self.error = nil
        if not keepMessage then
            self.message = nil
            self.messageUntil = nil
        end

        local result, err = scan()
        if not result then
            self.data = nil
            self.error = tostring(err)
            return
        end

        self.data = result
        self.data.items = self.data.items or {}
        table.sort(self.data.items, function(a, b)
            if a.count == b.count then return tostring(a.displayName) < tostring(b.displayName) end
            return a.count > b.count
        end)

        local pages = math.max(1, math.ceil(#self.data.items / self.pageSize))
        if self.page > pages then self.page = pages end
    end

    function app:start(ctx)
        ctx.monitor.setTextScale(ctx.config.textScale)
        refresh(self, false)
    end

    function app:close(ctx)
        ctx.monitor.setTextScale(self.originalScale)
    end

    function app:draw(ctx)
        local m, ui, theme = ctx.monitor, ctx.ui, ctx.theme
        local w, h = m.getSize()

        m.setBackgroundColor(theme.background)
        m.clear()
        self.buttons = {}

        ui.fill(m, 1, 1, w, 2, theme.topbar)
        ui.write(m, 2, 1, "INVENTARIO", theme.text, theme.topbar)
        ui.write(m, math.max(1, w - #node.player - 1), 1, node.player, theme.accent, theme.topbar)

        if self.error then
            ui.center(m, math.floor(h / 2), ui.clip(self.error, w - 4), theme.danger, theme.background)
            self.buttons[#self.buttons + 1] = ui.closeButton(m, theme)
            return
        end

        if not self.data then return end

        local cols, rows = 4, 2
        local gapX, gapY, marginX = 1, 1, 1
        local top = 3
        local navY = h - 1
        local gridBottom = navY - 1
        local gridH = gridBottom - top + 1
        local cardW = math.floor((w - marginX * 2 - (cols - 1) * gapX) / cols)
        local cardH = math.floor((gridH - gapY) / rows)

        cardW = math.max(8, cardW)
        cardH = math.max(5, cardH)
        self.pageSize = cols * rows

        local pages = math.max(1, math.ceil(#self.data.items / self.pageSize))
        if self.page > pages then self.page = pages end
        local first = (self.page - 1) * self.pageSize + 1

        for slot = 1, self.pageSize do
            local item = self.data.items[first + slot - 1]
            if item then
                local col = (slot - 1) % cols
                local row = math.floor((slot - 1) / cols)
                local x = marginX + col * (cardW + gapX)
                local y = top + row * (cardH + gapY)

                ui.fill(m, x, y, cardW, cardH, theme.panel)
                ui.border(m, x, y, cardW, cardH, theme.panelAlt, theme.panel)

                local name = ui.clip(item.displayName, math.max(1, cardW - 2))
                local count = ui.formatNumber(item.count)
                ui.centerInBox(m, x + 1, y + 1, cardW - 2, 1, name, theme.text, theme.panel)
                ui.centerInBox(m, x + 1, y + 2, cardW - 2, 1, count, theme.accent, theme.panel)

                local buttonY = y + cardH - 2
                local innerX = x + 1
                local innerW = cardW - 2
                local baseW = math.floor(innerW / 4)
                local extra = innerW - baseW * 4
                local buttonX = innerX

                for index, amount in ipairs(amounts) do
                    local buttonW = baseW + (index <= extra and 1 or 0)
                    ui.fill(m, buttonX, buttonY, buttonW, 1, theme.button)
                    ui.centerInBox(m, buttonX, buttonY, buttonW, 1, tostring(amount), theme.buttonText, theme.button)
                    self.buttons[#self.buttons + 1] = {
                        id = "take", item = item, count = amount,
                        x = buttonX, y = buttonY, w = buttonW, h = 1
                    }
                    buttonX = buttonX + buttonW
                end
            end
        end

        ui.fill(m, 1, navY, w, 1, theme.footer)
        ui.write(m, 2, navY, "<", theme.text, theme.footer)
        local saveLabel = "GUARDAR TODO"
        local saveX = math.max(6, math.floor((w - #saveLabel) / 2) + 1)
        ui.write(m, saveX, navY, saveLabel, theme.success, theme.footer)

        local closeButton = ui.closeButton(m, theme)
        local nextX = math.max(7, closeButton.x - 3)
        ui.write(m, nextX, navY, ">", theme.text, theme.footer)

        self.buttons[#self.buttons + 1] = {id = "prev", x = 1, y = navY, w = 5, h = 1}
        self.buttons[#self.buttons + 1] = {id = "store", x = saveX - 1, y = navY, w = #saveLabel + 2, h = 1}
        self.buttons[#self.buttons + 1] = {id = "next", x = nextX - 1, y = navY, w = 3, h = 1}
        self.buttons[#self.buttons + 1] = closeButton

        if self.message then
            ui.notification(m, {message = self.message, level = "success"}, theme)
        end
    end

    function app:touch(x, y, ctx)
        for _, button in ipairs(self.buttons) do
            if inside(button, x, y) then
                if button.id == "close" then
                    return "close"
                elseif button.id == "prev" then
                    self.page = math.max(1, self.page - 1)
                elseif button.id == "next" then
                    local pages = math.max(1, math.ceil(#self.data.items / self.pageSize))
                    self.page = math.min(pages, self.page + 1)
                elseif button.id == "take" then
                    local result, err = deliver(button.item, button.count)
                    if result then
                        setMessage(self, "ENTREGADOS " .. tostring(result.moved or 0))
                        refresh(self, true)
                    else
                        self.error = tostring(err)
                    end
                elseif button.id == "store" then
                    local result, err = storeKnown()
                    if result then
                        setMessage(self, "GUARDADOS " .. tostring(result.stored or 0) .. " | DEJADOS " .. tostring(result.skipped or 0))
                        refresh(self, true)
                    else
                        self.error = tostring(err)
                    end
                end
                return
            end
        end
    end

    function app:update(ctx)
        if self.message and self.messageUntil and now() >= self.messageUntil then
            self.message = nil
            self.messageUntil = nil
        end
    end

    return app
end
