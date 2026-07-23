return function(context)
    local node = dofile("/mjcore/core/node.lua")
    local network = dofile("/mjcore/core/network.lua")
    local app = {id="logistics",title="LOGISTICA",state=nil,error=nil,buttons={},originalScale=context.config.textScale}

    local function status()
        if node.role == "terminal" then return network.request("logistics_status", {}, 4) end
        local path = "/mjcore/data/logistics_state.lua"
        if not fs.exists(path) then return nil, "Servicio de logistica sin estado" end
        local ok, data = pcall(dofile, path)
        if not ok then return nil, tostring(data) end
        return data
    end

    local function refresh(self)
        self.state, self.error = status()
    end

    function app:start(ctx) ctx.monitor.setTextScale(ctx.config.textScale); refresh(self) end
    function app:close(ctx) ctx.monitor.setTextScale(self.originalScale) end
    function app:draw(ctx)
        local m,ui,theme=ctx.monitor,ctx.ui,ctx.theme
        local w,h=m.getSize(); m.setBackgroundColor(theme.background); m.clear(); self.buttons={}
        ui.fill(m,1,1,w,2,theme.topbar); ui.write(m,2,1,"LOGISTICA",theme.text,theme.topbar)
        if self.error then ui.center(m,math.floor(h/2),ui.clip(self.error,w-4),theme.danger,theme.background)
        else
            local s=self.state or {}; local y=4
            local function line(label,value,color)
                ui.write(m,3,y,label..":",theme.muted,theme.background)
                ui.write(m,16,y,ui.clip(tostring(value),math.max(1,w-18)),color or theme.text,theme.background); y=y+2
            end
            line("Estado",s.active and "ACTIVA" or "INACTIVA",s.active and theme.success or theme.danger)
            line("Storage",s.storageConnected and "Conectado" or "Desconectado",s.storageConnected and theme.success or theme.danger)
            local machine=(s.machines or {})[1]
            line("Maquinas",machine and machine.name or "Ninguna")
            line("Trabajo",machine and machine.job or "En espera",theme.accent)
            line("Cola",s.queue or 0)
            line("Combustible",machine and ((machine.fuel or 0).." carbon") or "0 carbon")
        end
        self.buttons[#self.buttons+1]=ui.closeButton(m,theme)
    end
    function app:touch(x,y,ctx)
        for _,b in ipairs(self.buttons) do if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h and b.id=="close" then return "close" end end
    end
    function app:update(ctx) refresh(self) end
    return app
end
