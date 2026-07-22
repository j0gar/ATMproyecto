local appCore = {}

function appCore.load(path, context)
    if not fs.exists(path) then
        return nil, "No existe la aplicacion: " .. path
    end

    local chunk, err = loadfile(path)
    if not chunk then
        return nil, err
    end

    local ok, appFactory = pcall(chunk)
    if not ok then
        return nil, appFactory
    end

    if type(appFactory) ~= "function" then
        return nil, "La aplicacion no devuelve una funcion."
    end

    local okApp, app = pcall(appFactory, context)
    if not okApp then
        return nil, app
    end

    if type(app) ~= "table" then
        return nil, "La aplicacion no devuelve una tabla."
    end

    app.id = app.id or fs.getName(path)
    app.title = app.title or app.id

    return app
end

function appCore.run(app, context)
    if app.start then
        local ok, err = pcall(app.start, app, context)
        if not ok then return false, err end
    end

    local running = true
    local redraw = true
    local timer = os.startTimer(1)

    while running do
        if redraw and app.draw then
            local ok, err = pcall(app.draw, app, context)
            if not ok then return false, err end
            redraw = false
        end

        local event, a, b, c = os.pullEvent()

        if event == "monitor_touch" and a == context.monitorName then
            if app.touch then
                local ok, result = pcall(app.touch, app, b, c, context)
                if not ok then return false, result end
                if result == "close" then running = false end
                redraw = true
            else
                running = false
            end

        elseif event == "key" then
            if a == keys.backspace or a == keys.escape then
                running = false
            elseif app.key then
                local ok, result = pcall(app.key, app, a, context)
                if not ok then return false, result end
                if result == "close" then running = false end
                redraw = true
            end

        elseif event == "timer" then
            if a == timer then
                if app.update then
                    local ok, err = pcall(app.update, app, context)
                    if not ok then return false, err end
                end
                timer = os.startTimer(1)
                redraw = true
            end
            if context.notifications.update() then redraw = true end
        end
    end

    if app.close then
        pcall(app.close, app, context)
    end

    return true
end

return appCore
