return function(context)
    local app = {
        id = "todo",
        title = "TAREAS",
        view = "profiles",
        profile = nil,
        data = nil,
        page = 1,
        pageSize = 4,
        buttons = {},
        originalScale = context.config.textScale
    }

    local profiles = {
        { id = "j0gar", label = "TAREAS J0GAR", path = "/mjcore/data/t-J0gar.lua" },
        { id = "mia", label = "TAREAS MIA", path = "/mjcore/data/t-Mia.lua" }
    }

    local function inside(button, x, y)
        return x >= button.x and x < button.x + button.w
           and y >= button.y and y < button.y + button.h
    end

    local function loadProfile(self, profile)
        local ok, result = pcall(dofile, profile.path)
        if not ok or type(result) ~= "table" then
            self.data = {
                owner = string.upper(profile.id),
                tasks = {
                    { text = "No se pudo cargar " .. profile.path, done = false }
                }
            }
        else
            result.tasks = result.tasks or {}
            self.data = result
        end

        self.profile = profile
        self.page = 1
        self.view = "list"
    end

    function app:start(ctx)
        -- Letras mayores que en el escritorio.
        ctx.monitor.setTextScale(ctx.config.textScale)
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
        ui.footer(monitor, theme, "")
        table.insert(self.buttons, ui.closeButton(monitor, theme))

        if self.view == "profiles" then
            ui.center(monitor, 4, "SELECCIONA UNA LISTA", theme.accent, theme.background)

            local buttonW = w - 6
            local buttonH = math.max(3, math.floor((h - 8) / 2))
            local firstY = 4

            for index, profile in ipairs(profiles) do
                local y = firstY + (index - 1) * (buttonH + 1)
                ui.fill(monitor, 4, y, buttonW, buttonH, theme.button)
                ui.border(monitor, 4, y, buttonW, buttonH, theme.accent, theme.button)
                ui.centerInBox(monitor, 4, y, buttonW, buttonH, profile.label, theme.buttonText, theme.button)

                table.insert(self.buttons, {
                    id = "profile",
                    profile = profile,
                    x = 4,
                    y = y,
                    w = buttonW,
                    h = buttonH
                })
            end

            ui.fill(monitor, 1, h, w, 1, theme.panel)
            ui.write(monitor, 2, h, "Toca arriba para volver al escritorio", theme.text, theme.panel)
            return
        end

        local owner = self.data and self.data.owner or "?"
        ui.write(monitor, w - #owner - 1, 1, owner, theme.accent, theme.topbar)

        local tasks = self.data.tasks
        local cardH = 4
        local navY = h - 4
        self.pageSize = math.max(1, math.floor((navY - 4) / (cardH + 1)))
        local pages = math.max(1, math.ceil(#tasks / self.pageSize))
        if self.page > pages then self.page = pages end

        local first = (self.page - 1) * self.pageSize + 1
        local last = math.min(#tasks, first + self.pageSize - 1)
        local y = 4

        if #tasks == 0 then
            ui.center(monitor, math.floor(h / 2), "NO HAY TAREAS", theme.muted, theme.background)
        else
            for index = first, last do
                local task = tasks[index]
                local marker = task.done and "[X]" or "[ ]"
                local fg = task.done and theme.success or theme.text

                ui.fill(monitor, 2, y, w - 3, cardH, theme.panel)
                ui.border(monitor, 2, y, w - 3, cardH, theme.panelAlt, theme.panel)
                ui.write(monitor, 4, y + 1, marker, fg, theme.panel)
                ui.write(
                    monitor,
                    9,
                    y + 1,
                    ui.clip(task.text or "Tarea sin nombre", w - 12),
                    fg,
                    theme.panel
                )

                table.insert(self.buttons, {
                    id = "toggle",
                    taskIndex = index,
                    x = 2,
                    y = y,
                    w = w - 3,
                    h = cardH
                })

                y = y + cardH + 1
            end
        end

        local navW = math.max(6, math.min(10, math.floor(w / 4)))

        ui.smallButton(monitor, 2, navY, navW, "<", false, theme)
        table.insert(self.buttons, { id = "previous", x = 2, y = navY, w = navW, h = 3 })

        ui.smallButton(monitor, w - navW - 1, navY, navW, ">", false, theme)
        table.insert(self.buttons, { id = "next", x = w - navW - 1, y = navY, w = navW, h = 3 })

        ui.center(monitor, navY + 1, tostring(self.page) .. "/" .. tostring(pages), theme.text, theme.background)

        ui.fill(monitor, 1, h, w, 1, theme.topbar)
        ui.write(monitor, 2, h, "Toca una tarea para marcarla", theme.text, theme.topbar)
    end

    function app:touch(x, y, ctx)
        for _, button in ipairs(self.buttons) do
            if inside(button, x, y) then
                if button.id == "close" then return "close" end
                if button.id == "profile" then
                    loadProfile(self, button.profile)

                elseif button.id == "toggle" then
                    local task = self.data.tasks[button.taskIndex]
                    if task then task.done = not task.done end

                elseif button.id == "previous" then
                    self.page = math.max(1, self.page - 1)

                elseif button.id == "next" then
                    local pages = math.max(1, math.ceil(#self.data.tasks / self.pageSize))
                    self.page = math.min(pages, self.page + 1)
                end

                return
            end
        end
    end

    return app
end
