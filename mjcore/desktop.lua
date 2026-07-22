local config = dofile("/mjcore/core/config.lua")
local theme = dofile("/mjcore/core/theme.lua")
local ui = dofile("/mjcore/core/ui.lua")
local icons = dofile("/mjcore/core/icons.lua")
local logger = dofile("/mjcore/core/logger.lua")
local notificationsFactory = dofile("/mjcore/core/notifications.lua")
local appCore = dofile("/mjcore/core/app.lua")
local appsCore = dofile("/mjcore/core/apps.lua")
local miaDetector = dofile("/mjcore/core/mia_detector.lua")
local node = dofile("/mjcore/core/node.lua")

local monitor, monitorName = ui.findMonitor(config.monitorName)
if not monitor then error("No hay monitor conectado", 0) end
monitor.setTextScale(config.textScale)
theme.apply(monitor)

local notifications = notificationsFactory.new(config, logger)
local registry = appsCore.loadRegistry()
if type(node.apps) == "table" then
  local allowed={}
  for _,id in ipairs(node.apps) do allowed[id]=true end
  local filtered={}
  for _,entry in ipairs(registry) do if allowed[entry.id] then filtered[#filtered+1]=entry end end
  registry=filtered
end
local buttons, page = {}, 1
local pageSize = 8
local redraw, running = true, true

local context = { monitor=monitor, monitorName=monitorName, config=config, theme=theme,
  ui=ui, logger=logger, notifications=notifications, node=node }

local iconColours = {
  inventory=colors.orange, players=colors.lightBlue, todo=colors.lime,
  energy=colors.yellow, alarms=colors.red, settings=colors.lightGray,
  updater=colors.cyan, system=colors.white
}

local function pages() return math.max(1, math.ceil(#registry / pageSize)) end

local function buildLayout()
  local w, h = monitor.getSize()
  buttons = {}
  local cols = w >= 44 and 4 or 2
  local rows = math.ceil(pageSize / cols)
  local top, bottom = 4, h - 2
  local gapX, gapY, marginX = 1, 1, 1
  local cellW = math.floor((w - marginX * 2 - (cols - 1) * gapX) / cols)
  local cellH = math.max(3, math.floor((bottom - top + 1 - (rows - 1) * gapY) / rows))
  local first = (page - 1) * pageSize + 1

  for slot = 1, pageSize do
    local entry = registry[first + slot - 1]
    if entry then
      local col = (slot - 1) % cols
      local row = math.floor((slot - 1) / cols)
      buttons[#buttons+1] = { id="app", entry=entry,
        x=marginX + col*(cellW+gapX), y=top + row*(cellH+gapY),
        w=cellW, h=cellH }
    end
  end
  buttons[#buttons+1] = {id="prev",x=1,y=h,w=8,h=1}
  buttons[#buttons+1] = {id="next",x=w-7,y=h,w=8,h=1}
end

local function drawCard(b)
  local e=b.entry
  ui.fill(monitor,b.x,b.y,b.w,b.h,theme.panel)
  ui.border(monitor,b.x,b.y,b.w,b.h,theme.panelAlt,theme.panel)
  local icon=icons.get(e.icon)
  if icon and b.w >= 9 and b.h >= 3 then
    local iy=b.y+math.max(0,math.floor((b.h-3)/2))
    ui.drawPixelIcon(monitor,b.x+1,iy,icon,iconColours[e.icon] or theme.accent,theme.panel)
    ui.write(monitor,b.x+5,b.y+math.floor(b.h/2),ui.clip(e.name,b.w-6),theme.text,theme.panel)
  else
    ui.centerInBox(monitor,b.x,b.y,b.w,b.h,ui.clip(e.name,b.w-2),theme.text,theme.panel)
  end
end

local function draw()
  local w,h=monitor.getSize()
  theme.apply(monitor)
  monitor.setBackgroundColor(theme.desktop); monitor.clear()
  ui.fill(monitor,1,1,w,2,theme.topbar)
  ui.write(monitor,2,1,"M&J CORE",theme.text,theme.topbar)
  local clock=textutils.formatTime(os.time(),true)
  ui.write(monitor,w-#clock-1,1,clock,theme.text,theme.topbar)
  ui.write(monitor,2,2,node.role=="terminal" and "TERMINAL" or "AURORA UI",theme.muted,theme.topbar)
  ui.write(monitor,w-#("v"..config.version)-1,2,"v"..config.version,theme.accent,theme.topbar)
  ui.write(monitor,2,3,"APLICACIONES",theme.muted,theme.desktop)

  for _,b in ipairs(buttons) do if b.id=="app" then drawCard(b) end end

  ui.footer(monitor,theme, "< ANT")
  local p=tostring(page).."/"..tostring(pages())
  ui.center(monitor,h,p,theme.accent,theme.footer)
  ui.write(monitor,w-6,h,"SIG >",theme.text,theme.footer)
  ui.notification(monitor,notifications.current,theme)
end

local function launch(entry)
  local app,err=appCore.load(entry.path,context)
  if not app then notifications.push("Error: "..entry.name,"error"); logger.log(err,"ERROR"); return end
  local ok,runErr=appCore.run(app,context)
  if not ok then notifications.push("App detenida","error"); logger.log(runErr,"ERROR") end
  monitor.setTextScale(config.textScale); theme.apply(monitor); buildLayout(); redraw=true
end

buildLayout(); miaDetector.reload(); miaDetector.update(true)
notifications.push("Aurora UI cargada","success")
local timer=os.startTimer(config.refreshSeconds)

while running do
  if redraw then draw(); redraw=false end
  local event,a,b,c=os.pullEvent()
  if event=="monitor_touch" and a==monitorName then
    local _,hit=ui.hit(buttons,b,c)
    if hit then
      if hit.id=="app" then launch(hit.entry)
      elseif hit.id=="prev" then page=page-1; if page<1 then page=pages() end; buildLayout(); redraw=true
      elseif hit.id=="next" then page=page+1; if page>pages() then page=1 end; buildLayout(); redraw=true end
    end
  elseif event=="monitor_resize" and a==monitorName then monitor.setTextScale(config.textScale); buildLayout(); redraw=true
  elseif event=="timer" then
    if notifications.handleTimer(a) then redraw=true
    elseif a==timer then miaDetector.update(false); timer=os.startTimer(config.refreshSeconds); redraw=true end
  elseif event=="key" and a==keys.q then running=false end
end
monitor.setBackgroundColor(colors.black); monitor.clear()
