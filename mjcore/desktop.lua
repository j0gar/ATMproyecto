local config = dofile("/mjcore/core/config.lua")
local theme = dofile("/mjcore/core/theme.lua")
local ui = dofile("/mjcore/core/ui.lua")
local logger = dofile("/mjcore/core/logger.lua")
local notificationsFactory = dofile("/mjcore/core/notifications.lua")
local appCore = dofile("/mjcore/core/app.lua")
local appsCore = dofile("/mjcore/core/apps.lua")
local miaDetector = dofile("/mjcore/core/mia_detector.lua")

local monitor, monitorName = ui.findMonitor(config.monitorName)
if not monitor then error("No hay monitor conectado", 0) end
monitor.setTextScale(config.textScale)

local notifications = notificationsFactory.new(config, logger)
local registry = appsCore.loadRegistry()
local buttons, page = {}, 1
local pageSize = 4
local redraw, running = true, true

local context = {
  monitor=monitor, monitorName=monitorName, config=config, theme=theme,
  ui=ui, logger=logger, notifications=notifications
}

local icons = {inventory="[#]",players="[O]",todo="[=]",energy="[*]",alarms="[!]",settings="[+]",updater="[^]",system="[S]"}

local function pages() return math.max(1, math.ceil(#registry / pageSize)) end

local function buildLayout()
  local w, h = monitor.getSize()
  buttons = {}
  local top, bottom = 3, h - 2
  local gapX, gapY = 1, 1
  local marginX = 2
  local buttonW = math.floor((w - marginX * 2 - gapX) / 2)
  local availableH = bottom - top + 1
  local buttonH = math.max(3, math.floor((availableH - gapY) / 2))
  local first = (page - 1) * pageSize + 1

  for slot=1,pageSize do
    local entry = registry[first + slot - 1]
    if entry then
      local col=(slot-1)%2
      local row=math.floor((slot-1)/2)
      buttons[#buttons+1]={
        id="app", entry=entry,
        x=marginX+col*(buttonW+gapX), y=top+row*(buttonH+gapY),
        w=buttonW, h=buttonH,
        label=entry.name, icon=icons[entry.icon] or "[ ]"
      }
    end
  end

  local navW=7
  buttons[#buttons+1]={id="prev",x=2,y=h,w=navW,h=1}
  buttons[#buttons+1]={id="next",x=w-navW+1,y=h,w=navW,h=1}
end

local function draw()
  local w,h=monitor.getSize()
  monitor.setBackgroundColor(theme.desktop); monitor.clear()
  ui.fill(monitor,1,1,w,2,theme.topbar)
  ui.write(monitor,2,1,"M&J CORE",theme.text,theme.topbar)
  local clock=textutils.formatTime(os.time(),true)
  ui.write(monitor,w-#clock-1,1,clock,theme.text,theme.topbar)
  ui.write(monitor,2,2,"4x2 RESPONSIVE",theme.muted,theme.topbar)
  ui.write(monitor,w-#("v"..config.version)-1,2,"v"..config.version,theme.accent,theme.topbar)

  for _,b in ipairs(buttons) do
    if b.id=="app" then
      ui.fill(monitor,b.x,b.y,b.w,b.h,theme.button)
      ui.border(monitor,b.x,b.y,b.w,b.h,theme.panelAlt,theme.button)
      local label=ui.clip(b.label,b.w-2)
      if b.h>=5 then ui.centerInBox(monitor,b.x,b.y,b.w,2,b.icon,theme.accent,theme.button) end
      ui.centerInBox(monitor,b.x,b.y+(b.h>=5 and 1 or 0),b.w,b.h-(b.h>=5 and 1 or 0),label,theme.buttonText,theme.button)
    end
  end

  ui.fill(monitor,1,h,w,1,theme.topbar)
  ui.write(monitor,2,h,"< ANTERIOR",theme.text,theme.topbar)
  local p=tostring(page).."/"..tostring(pages())
  ui.center(monitor,h,p,theme.accent,theme.topbar)
  ui.write(monitor,w-9,h,"SIG. >",theme.text,theme.topbar)
  ui.notification(monitor,notifications.current,theme)
end

local function launch(entry)
  local app,err=appCore.load(entry.path,context)
  if not app then notifications.push("Error: "..entry.name,"error"); logger.log(err,"ERROR"); return end
  local ok,runErr=appCore.run(app,context)
  if not ok then notifications.push("App detenida","error"); logger.log(runErr,"ERROR") end
  monitor.setTextScale(config.textScale); buildLayout(); redraw=true
end

buildLayout(); miaDetector.reload(); miaDetector.update(true)
notifications.push("Interfaz 4x2 cargada","success")
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
