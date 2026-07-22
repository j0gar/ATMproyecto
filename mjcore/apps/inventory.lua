return function(context)
    local node = dofile("/mjcore/core/node.lua")
    local network = dofile("/mjcore/core/network.lua")
    local logistics = dofile("/mjcore/core/logistics.lua")
    local app = {id="inventory",title="INVENTARIO",data=nil,error=nil,message=nil,page=1,pageSize=6,buttons={},originalScale=context.config.textScale}
    local amounts={1,16,32,64}
    local function inside(b,x,y) return x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
    local function scan()
        if node.role=="terminal" then return network.request("inventory_scan",{},4) end
        return logistics.scan()
    end
    local function deliver(item,count)
        if node.role=="terminal" then return network.request("inventory_deliver",{player=node.player,item=item.name,count=count},4) end
        return logistics.deliver(node.player,item.name,count)
    end
    local function refresh(self)
        self.error=nil; self.message=nil
        local result,err=scan(); if not result then self.data=nil; self.error=tostring(err); return end
        self.data=result; table.sort(self.data.items,function(a,b) if a.count==b.count then return a.displayName<b.displayName end return a.count>b.count end)
        local pages=math.max(1,math.ceil(#self.data.items/self.pageSize)); if self.page>pages then self.page=pages end
    end
    function app:start(ctx) ctx.monitor.setTextScale(ctx.config.textScale); refresh(self) end
    function app:close(ctx) ctx.monitor.setTextScale(self.originalScale) end
    function app:draw(ctx)
        local m,ui,theme=ctx.monitor,ctx.ui,ctx.theme; local w,h=m.getSize(); m.setBackgroundColor(theme.background);m.clear();self.buttons={}
        ui.fill(m,1,1,w,2,theme.topbar);ui.write(m,2,1,"INVENTARIO",theme.text,theme.topbar);ui.write(m,w-#node.player-1,1,node.player,theme.accent,theme.topbar)
        if self.error then ui.center(m,math.floor(h/2),ui.clip(self.error,w-4),theme.danger,theme.background); table.insert(self.buttons,ui.closeButton(m,theme)); return end
        if not self.data then return end
        local top=3; local navY=h-3; local availableH=navY-top; local cols=w>=39 and 3 or 2; local gap=1; local margin=1
        local cardW=math.max(10,math.floor((w-margin*2-(cols-1)*gap)/cols)); local cardH=math.max(5,math.floor(availableH/2)); local rows=math.max(1,math.floor(availableH/(cardH+gap))); self.pageSize=math.max(1,cols*rows)
        local pages=math.max(1,math.ceil(#self.data.items/self.pageSize)); if self.page>pages then self.page=pages end
        local first=(self.page-1)*self.pageSize+1
        for slot=1,self.pageSize do
            local item=self.data.items[first+slot-1]; if item then
                local col=(slot-1)%cols; local row=math.floor((slot-1)/cols); local x=margin+col*(cardW+gap); local y=top+row*(cardH+gap)
                ui.fill(m,x,y,cardW,cardH,theme.panel);ui.border(m,x,y,cardW,cardH,theme.panelAlt,theme.panel)
                ui.center(m,y+1,ui.clip(item.displayName,cardW-2),theme.text,theme.panel);ui.center(m,y+2,ui.formatNumber(item.count),theme.accent,theme.panel)
                local by=y+cardH-1; local bw=math.max(2,math.floor((cardW-2)/4)); local bx=x+1
                for i,amount in ipairs(amounts) do local label=amount==1 and "1" or tostring(amount); local actualW=(i==4) and (x+cardW-1-bx) or bw; ui.fill(m,bx,by,actualW,1,theme.button);ui.centerInBox(m,bx,by,actualW,1,label,theme.buttonText,theme.button);table.insert(self.buttons,{id="take",item=item,count=amount,x=bx,y=by,w=actualW,h=1});bx=bx+actualW end
            end
        end
        ui.fill(m,1,navY,w,3,theme.footer);ui.write(m,2,navY+1,"<",theme.text,theme.footer);ui.center(m,navY+1,tostring(self.page).."/"..tostring(pages),theme.accent,theme.footer);ui.write(m,w-1,navY+1,">",theme.text,theme.footer)
        table.insert(self.buttons,{id="prev",x=1,y=navY,w=5,h=3});table.insert(self.buttons,{id="next",x=w-4,y=navY,w=5,h=3});table.insert(self.buttons,ui.closeButton(m,theme))
        if self.message then ui.notification(m,{text=self.message,type="success"},theme) end
    end
    function app:touch(x,y,ctx)
        for _,b in ipairs(self.buttons) do if inside(b,x,y) then
            if b.id=="close" then return "close" elseif b.id=="prev" then self.page=math.max(1,self.page-1) elseif b.id=="next" then local pages=math.max(1,math.ceil(#self.data.items/self.pageSize));self.page=math.min(pages,self.page+1) elseif b.id=="take" then local result,err=deliver(b.item,b.count); if result then self.message="ENTREGADOS "..tostring(result.moved); refresh(self); self.message="ENTREGADOS "..tostring(result.moved) else self.error=tostring(err) end end
            return
        end end
    end
    function app:update(ctx) if self.error and node.role=="terminal" then return end end
    return app
end
