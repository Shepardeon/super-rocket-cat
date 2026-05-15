--- QTE - Oscillating bar quick-time event for rocket launch
---
--- Usage:
---   local qte = QTE.new({ speed = 1.5 })
---
---   -- per-frame in the scene:
---   function update(dt)
---       if qte:isActive() then
---           qte:update(dt)
---           if InputActions.pressed("qte_action") then
---               local result = qte:trigger()
---               AudioManager.playSfx(result == "red" and "qte_fail" or "qte_ok")
---           end
---       end
---   end
---   function draw()
---       qte:draw(340, 280, 600)
---   end
---
--- Public API:
---   QTE.new(config)           → QTE instance
---   qte:update(dt)            → nil   (oscillate marker via triangle wave)
---   qte:trigger()             → str   ("green"|"yellow"|"red", deactivates)
---   qte:isActive()            → bool  (false after trigger)
---   qte:getResult()           → str|nil
---   qte:getMarkerPos()        → num   (0.0 – 1.0)
---   qte:draw(x, y, w)         → nil   (render bar with zones + marker)
local QTE = {}
QTE.__index = QTE

local COLORS = {
    red = { 0.8, 0.15, 0.15 },
    yellow = { 0.8, 0.7, 0.1 },
    green = { 0.15, 0.7, 0.15 },
}

function QTE.getZoneColor(name)
    local c = COLORS[name]
    if not c then
        print("warning: unknown zone name '" .. tostring(name) .. "'")
        c = COLORS.yellow
    end
    return c
end

local DEFAULT_ZONES = {
    { name = "red", lo = 0.0, hi = 0.125 },
    { name = "yellow", lo = 0.125, hi = 0.4375 },
    { name = "green", lo = 0.4375, hi = 0.5625 },
    { name = "yellow", lo = 0.5625, hi = 0.875 },
    { name = "red", lo = 0.875, hi = 1.0 },
}

local BAR_HEIGHT = 20
local BORDER = 2
local MARKER_WIDTH = 3
local TRIANGLE_SIZE = 4

function QTE.new(config)
    config = config or {}
    local self = setmetatable({}, QTE)
    self.speed = config.speed or 1.5
    self.zones = config.zones or DEFAULT_ZONES
    self.time = 0
    self.active = true
    self.result = nil
    self.marker_pos = 0
    return self
end

function QTE:update(dt)
    if not self.active then
        return
    end
    self.time = self.time + dt
    local phase = (self.time * self.speed) % 2
    if phase <= 1 then
        self.marker_pos = phase
    else
        self.marker_pos = 2 - phase
    end
end

function QTE:trigger()
    if not self.active then
        return nil
    end
    self.active = false
    local pos = self.marker_pos
    for _, zone in ipairs(self.zones) do
        if pos >= zone.lo and pos <= zone.hi then
            self.result = zone.name
            return zone.name
        end
    end
    self.result = "yellow"
    return "yellow"
end

function QTE:isActive()
    return self.active
end

function QTE:getResult()
    return self.result
end

function QTE:getMarkerPos()
    return self.marker_pos
end

function QTE:draw(x, y, w)
    local bar_y = y
    local outer_h = BAR_HEIGHT + BORDER * 2

    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", x - BORDER, bar_y - BORDER, w + BORDER * 2, outer_h)

    love.graphics.setColor(0.08, 0.08, 0.12)
    love.graphics.rectangle("fill", x, bar_y, w, BAR_HEIGHT)

    for _, zone in ipairs(self.zones) do
        local color = QTE.getZoneColor(zone.name)
        local zx = x + zone.lo * w
        local zw = (zone.hi - zone.lo) * w
        love.graphics.setColor(color[1], color[2], color[3], 0.55)
        love.graphics.rectangle("fill", zx, bar_y, zw, BAR_HEIGHT)
    end

    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.setLineWidth(1)
    for _, zone in ipairs(self.zones) do
        if zone.lo > 0 then
            love.graphics.line(x + zone.lo * w, bar_y, x + zone.lo * w, bar_y + BAR_HEIGHT)
        end
    end

    local mx = x + self.marker_pos * w
    local r, g, b, a
    if self.active then
        r, g, b, a = 1, 1, 1, 0.9
    else
        local rc = COLORS[self.result or "yellow"]
        r, g, b = rc[1], rc[2], rc[3]
        a = 0.6 + 0.4 * math.sin(love.timer.getTime() * 5)
    end

    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(MARKER_WIDTH)
    love.graphics.line(mx, bar_y - TRIANGLE_SIZE, mx, bar_y + BAR_HEIGHT + TRIANGLE_SIZE)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("fill", mx - TRIANGLE_SIZE, bar_y - TRIANGLE_SIZE - 4, TRIANGLE_SIZE * 2, 4)
    love.graphics.rectangle("fill", mx - TRIANGLE_SIZE, bar_y + BAR_HEIGHT + TRIANGLE_SIZE, TRIANGLE_SIZE * 2, 4)

    love.graphics.setColor(1, 1, 1)
end

return QTE
