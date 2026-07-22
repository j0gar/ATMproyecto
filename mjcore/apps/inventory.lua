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

    local function inside(button, x, y)
        return x >= button.x and x < button.x + button.w
           and y >= button.y and y < button.y + button.h
    end

    local function scan()
        if node.role == "terminal" then
            return network.request("inventory_scan", {}, 4)
        end
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

    local function setMessage(self, text)
        self.message = tostring(text)
        self.messageUntil = os.clock() + 3
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
        table.sort(self.data.items, function(a, b)
            if a.count == b.count then
                return tostring(a.displayName) < tostring(b.displayName)
            end
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
        ui.write(m, w - #node.player - 1, 1, node.player, theme.accent, theme.topbar)

        if self.error then
            ui.center(m, math.floor(h / 2), ui.clip(self.error, w - 4), theme.danger, theme.background)
            table.insert(self.buttons, ui.closeButton(m, theme))
            return
        end

        if not self.data then return end

        local cols = 4
        local rows = 2
        local gapX = 1
        local gapY = 1
        local marginX = 1
        local top = 3
        local footerH = 3
        local navY = h - 2
        local gridH = navY - top

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

                for i, amount in ipairs(amounts) do
                    local buttonW = baseW
                    if i <= extra then buttonW = buttonW + 1 end

                    ui.fill(m, buttonX, buttonY, buttonW, 1, theme.button)
                    ui.centerInBox(
                        m,
                        buttonX,
                        buttonY,
                        buttonW,
                        1,
                        tostring(amount),
                        theme.buttonText,
                        theme.button
                    )

                    table.insert(self.buttons, {
                        id = "take",
                        item = item,
                        count = amount,
                        x = buttonX,
                        y = buttonY,
                        w = buttonW,
                        h = 1
                    })

                    buttonX = buttonX + buttonW
                end
            end
        end

        ui.fill(m, 1, navY, w, 2, theme.footer)
        ui.write(m, 2, navY, "<", theme.text, theme.footer)
        ui.center(m, navY, tostring(self.page) .. "/" .. tostring(pages), theme.accent, theme.footer)
        ui.write(m, w - 1, navY, ">", theme.text, theme.footer)

        table.insert(self.buttons, {id = "prev", x = 1, y = navY, w = 5, h = 2})
        table.insert(self.buttons, {id = "next", x = w - 4, y = navY, w = 5, h = 2})
        table.insert(self.buttons, ui.closeButton(m, theme))

        if self.message then
            ui.notification(m, {
                message = self.message,
                level = "success"
            }, theme)
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
                end

                return
            end
        end
    end

    function app:update(ctx)
        if self.message and self.messageUntil and os.clock() >= self.messageUntil then
            self.message = nil
            self.messageUntil = nil
        end
    end

    return app
end
