return function(context)
    local node = dofile("/mjcore/core/node.lua")
    local network = dofile("/mjcore/core/network.lua")
    local machineConfig = dofile("/mjcore/core/machine_config.lua")
    local app = {id="logistics",title="LOGISTICA",state=nil,error=nil,buttons={},selected=1,originalScale=context.config.textScale}

    local function status()
        if node.role == "terminal" then return network.request("logistics_status", {}, 4) end
        local path = "/mjcore/data/logistics_state.lua"
        if not fs.exists(path) then return nil, "Servicio de logistica sin estado" end
        local ok, data = pcall(dofile, path)
        if not ok then return nil, tostring(data) end
        return data
    end

    local function refresh(self) self.state, self.error = status() end

    local function setValue(self, machine, setting, value)
        local result, err
        if node.role == "terminal" then
            result, err = network.request("logistics_set_config", {id=machine.id,key=setting.key,value=value}, 4)
        else
            local path = "/mjcore/machines/" .. machine.id .. ".lua"
            local ok, definition = pcall(dofile, path)
            if ok then result, err = machineConfig.set(definition, setting.key, value) else err = definition end
        end
        if not result then self.error=tostring(err or "No se pudo guardar") else refresh(self) end
    end

    function app:start(ctx) ctx.monitor.setTextScale(ctx.config.textScale); refresh(self) end
    function app:close(ctx) ctx.monitor.setTextScale(self.originalScale) end
    function app:draw(ctx)
        local m,ui,theme=ctx.monitor,ctx.ui,ctx.theme
        local w,h=m.getSize(); m.setBackgroundColor(theme.background); m.clear(); self.buttons={}
        ui.fill(m,1,1,w,2,theme.topbar); ui.write(m,2,1,"LOGISTICA",theme.text,theme.topbar)
        if self.error then
            ui.center(m,math.floor(h/2),ui.clip(self.error,w-4),theme.danger,theme.background)
        else
            local s=self.state or {}; local machines=s.machines or {}
            if self.selected>#machines then self.selected=math.max(1,#machines) end
            local machine=machines[self.selected]
            ui.write(m,2,4,"Estado: "..(s.active and "ACTIVA" or "INACTIVA"),s.active and theme.success or theme.danger,theme.background)
            ui.write(m,2,6,"Storage: "..(s.storageConnected and "Conectado" or "Desconectado"),s.storageConnected and theme.success or theme.danger,theme.background)
            if machine then
                ui.write(m,2,8,"Maquina "..self.selected.."/"..#machines..": "..ui.clip(machine.name,w-18),theme.text,theme.background)
                ui.write(m,2,10,"Trabajo: "..ui.clip(machine.job or "En espera",w-11),theme.accent,theme.background)
                ui.write(m,2,12,"Combustible actual: "..tostring(machine.fuel or 0),theme.text,theme.background)
                local y=15
                for _,setting in ipairs(machine.settings or {}) do
                    local value=tonumber((machine.config or {})[setting.key]) or 0
                    ui.write(m,2,y,setting.label..": "..value..tostring(setting.suffix or ""),theme.text,theme.background)
                    local minus={id="minus",machine=machine,setting=setting,value=value,x=2,y=y+2,w=7,h=2}
                    local plus={id="plus",machine=machine,setting=setting,value=value,x=11,y=y+2,w=7,h=2}
                    ui.fill(m,minus.x,minus.y,minus.w,minus.h,theme.panel); ui.center(m,minus.y,"- "..tostring(setting.step or 1),theme.text,theme.panel)
                    ui.fill(m,plus.x,plus.y,plus.w,plus.h,theme.accent); ui.center(m,plus.y,"+ "..tostring(setting.step or 1),theme.selectedText,theme.accent)
                    self.buttons[#self.buttons+1]=minus; self.buttons[#self.buttons+1]=plus
                    y=y+5
                end
                if #machines>1 then
                    local prev={id="prev",x=w-15,y=h-3,w=6,h=2}; local nextb={id="next",x=w-8,y=h-3,w=6,h=2}
                    ui.fill(m,prev.x,prev.y,prev.w,prev.h,theme.panel); ui.write(m,prev.x+1,prev.y,"<",theme.text,theme.panel)
                    ui.fill(m,nextb.x,nextb.y,nextb.w,nextb.h,theme.panel); ui.write(m,nextb.x+1,nextb.y,">",theme.text,theme.panel)
                    self.buttons[#self.buttons+1]=prev; self.buttons[#self.buttons+1]=nextb
                end
            else ui.center(m,10,"No hay maquinas registradas",theme.muted,theme.background) end
        end
        self.buttons[#self.buttons+1]=ui.closeButton(m,theme)
    end
    function app:touch(x,y,ctx)
        for _,b in ipairs(self.buttons) do
            if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then
                if b.id=="close" then return "close"
                elseif b.id=="prev" then self.selected=math.max(1,self.selected-1)
                elseif b.id=="next" then self.selected=math.min(#((self.state or {}).machines or {}),self.selected+1)
                elseif b.id=="minus" or b.id=="plus" then
                    local step=tonumber(b.setting.step) or 1
                    local value=b.value+(b.id=="plus" and step or -step)
                    value=math.max(tonumber(b.setting.min) or value,math.min(tonumber(b.setting.max) or value,value))
                    setValue(self,b.machine,b.setting,value)
                end
            end
        end
    end
    function app:update(ctx) refresh(self) end
    return app
end
