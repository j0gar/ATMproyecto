local notifications = {}

function notifications.new(config, logger)
    local self = {
        current = nil,
        timer = nil
    }

    function self.push(message, level)
        self.current = {
            message = tostring(message),
            level = level or "info"
        }

        if self.timer then
            os.cancelTimer(self.timer)
        end

        self.timer = os.startTimer(config.notificationSeconds or 4)

        if logger then
            logger.log("Notificacion: " .. tostring(message), string.upper(level or "info"))
        end
    end

    function self.dismiss()
        self.current = nil
        self.timer = nil
    end

    function self.handleTimer(timerId)
        if self.timer and timerId == self.timer then
            self.dismiss()
            return true
        end
        return false
    end

    return self
end

return notifications
