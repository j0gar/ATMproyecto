local github = {}

local function encodePath(path)
    return tostring(path):gsub(" ", "%%20")
end

function github.baseUrl(config)
    local data = config.github
    return "https://raw.githubusercontent.com/" ..
        data.owner .. "/" ..
        data.repo .. "/" ..
        data.branch .. "/"
end

function github.get(config, path)
    local url = github.baseUrl(config) .. encodePath(path)
    local response, err = http.get(url)

    if not response then
        return nil, err or ("No se pudo descargar " .. path)
    end

    local body = response.readAll()
    response.close()
    return body
end

function github.getJSON(config, path)
    local body, err = github.get(config, path)
    if not body then
        return nil, err
    end

    local value = textutils.unserializeJSON(body)
    if value == nil then
        return nil, "JSON no valido: " .. path
    end

    return value
end

return github
