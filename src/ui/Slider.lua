--- Slider - reusable horizontal slider with label, fill track, and thumb
--
-- Usage:
--   local slider = Slider.new({
--       x         = 100,
--       y         = 200,
--       w         = 500,
--       h         = 36,
--       value     = 0.5,
--       label     = "Volume",
--       on_change = function(v) AudioManager.setMusicVolume(v) end,
--   })
--
--   -- per-frame integration in the host scene:
--   function update(dt)
--       slider:update(dt)
--   end
--   function draw()
--       love.graphics.setFont(my_font)
--       slider:draw()
--   end
--   function mousemoved(x, y)
--       slider:mousemoved(x, y)
--   end
--   function mousepressed(x, y, button)
--       slider:mousepressed(x, y, button)
--   end
--
-- Public API:
--   Slider.new(opts)                   → Slider instance
--   slider:update(dt)                  → nil   (keyboard repeat, drag release)
--   slider:draw()                      → nil   (renders label, track, fill, thumb, %)
--   slider:mousemoved(x, y)            → nil   (hover + drag update)
--   slider:mousepressed(x, y, button)  → nil   (start drag or jump-to-position)
--   slider:setFocus(bool)              → nil   (enable/disable keyboard control)
--   slider:isFocused()                 → bool
--   slider:getValue()                  → number (0.0 – 1.0)
--   slider:setValue(v)                 → nil   (no callback fired)
local Slider = {}
Slider.__index = Slider

local InputActions = require("src.InputActions")

local LABEL_W = 120
local LABEL_GAP = 10
local PCT_W = 45
local TRACK_H = 12
local THUMB_R = 8
local KB_STEP = 0.05
local HOLD_DELAY = 0.3
local HOLD_REPEAT = 0.08

local function calc_track(s)
    local tx = s.x + LABEL_W + LABEL_GAP
    local tw = s.w - LABEL_W - LABEL_GAP - PCT_W
    return tx, tw
end

local function value_from_x(s, mx)
    local tx, tw = calc_track(s)
    if tw <= 0 then
        return 0
    end
    local rel = (mx - tx) / tw
    return math.max(0, math.min(1, rel))
end

local function fire_change(s)
    if s.on_change then
        s.on_change(s.value)
    end
end

function Slider.new(opts)
    opts = opts or {}
    return setmetatable({
        x = opts.x or 0,
        y = opts.y or 0,
        w = opts.w or 400,
        h = opts.h or 36,
        value = math.max(0, math.min(1, opts.value or 0.5)),
        label = opts.label or "",
        on_change = opts.on_change,
        focused = false,
        hovered = false,
        dragging = false,
        _hold_dir = nil,
        _hold_timer = nil,
        _hold_repeating = nil,
    }, Slider)
end

function Slider:getValue()
    return self.value
end

function Slider:setValue(v)
    self.value = math.max(0, math.min(1, v))
end

function Slider:setFocus(f)
    self.focused = f
    if not f then
        self._hold_dir = nil
        self._hold_timer = nil
        self._hold_repeating = nil
    end
end

function Slider:isFocused()
    return self.focused
end

function Slider:hitTest(x, y)
    return x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h
end

function Slider:update(dt)
    if self.dragging then
        if not love.mouse.isDown(1) then
            self.dragging = false
        else
            local v = value_from_x(self, love.mouse.getX())
            if v ~= self.value then
                self.value = v
                fire_change(self)
            end
        end
        return
    end

    if not self.focused then
        self._hold_dir = nil
        self._hold_timer = nil
        self._hold_repeating = nil
        return
    end

    local dir = nil
    if InputActions.isDown("move_left") then
        dir = -1
    elseif InputActions.isDown("move_right") then
        dir = 1
    end

    if dir then
        if dir ~= self._hold_dir then
            self._hold_dir = dir
            self._hold_timer = 0
            self._hold_repeating = false
            local v = math.max(0, math.min(1, self.value + dir * KB_STEP))
            if v ~= self.value then
                self.value = v
                fire_change(self)
            end
            return
        end

        self._hold_timer = (self._hold_timer or 0) + dt
        local delay = self._hold_repeating and HOLD_REPEAT or HOLD_DELAY
        if self._hold_timer >= delay then
            self._hold_timer = self._hold_timer - delay
            self._hold_repeating = true
            local v = math.max(0, math.min(1, self.value + dir * KB_STEP))
            if v ~= self.value then
                self.value = v
                fire_change(self)
            end
        end
    else
        self._hold_dir = nil
        self._hold_timer = nil
        self._hold_repeating = nil
    end
end

function Slider:draw()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local font = love.graphics.getFont()
    local fh = font:getHeight()
    local center_y = y + h / 2
    local tx, tw = calc_track(self)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self.label, x, center_y - fh / 2, LABEL_W, "left")

    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.rectangle("fill", tx, center_y - TRACK_H / 2, tw, TRACK_H, 4)

    if self.value > 0 then
        local fill_w = tw * self.value
        love.graphics.setColor(0.2, 0.6, 0.9)
        love.graphics.rectangle("fill", tx, center_y - TRACK_H / 2, fill_w, TRACK_H)
    end

    local thumb_x = tx + tw * self.value
    local thumb_bright = self.dragging and 1 or (self.hovered and 0.9 or 0.7)
    love.graphics.setColor(thumb_bright, thumb_bright, thumb_bright)
    love.graphics.circle("fill", thumb_x, center_y, THUMB_R)

    if self.focused then
        love.graphics.setColor(1, 1, 0.4)
        love.graphics.rectangle("line", tx - 2, center_y - TRACK_H / 2 - 2, tw + 4, TRACK_H + 4, 4)
    end

    local pct = math.floor(self.value * 100 + 0.5)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(tostring(pct) .. "%", tx + tw + 8, center_y - fh / 2)
end

function Slider:mousemoved(x, y)
    self.hovered = self:hitTest(x, y)
    if self.dragging then
        local v = value_from_x(self, x)
        if v ~= self.value then
            self.value = v
            fire_change(self)
        end
    end
end

function Slider:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    if not self:hitTest(x, y) then
        return
    end
    self.dragging = true
    local v = value_from_x(self, x)
    if v ~= self.value then
        self.value = v
        fire_change(self)
    end
end

return Slider
