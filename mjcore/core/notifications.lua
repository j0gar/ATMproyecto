local notifications = {}

local function now()
    if os.epoch then return os.epoch("utc") / 1000 end
    return os.clock()
end

function notifications.new(config, logger)
    local self = { current = nil, expiresAt = nil }

    function self.push(message, level)
        self.current = { message = tostring(message), level = level or "info" }
        self.expiresAt = now() + (config.notificationSeconds or 4)
        if logger then logger.log("Notificacion: " .. tostring(message), string.upper(level or "info")) end
    end

    function self.dismiss()
        self.current = nil
        self.expiresAt = nil
    end

    function self.update()
        if self.current and self.expiresAt and now() >= self.expiresAt then
            self.dismiss()
            return true
        end
        return false
    end

    function self.handleTimer(_)
        return self.update()
    end

    return self
end

return notifications
