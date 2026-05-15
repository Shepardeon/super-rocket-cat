--- UpgradeCard - reusable upgrade card for the upgrades grid
---
--- Usage:
---   local card = UpgradeCard.new(x, y, w, h, upgrade_def)
---   card:setLevel(3)
---   card:setPoints(42)
---
---   -- per-frame in the scene:
---   function draw()
---       card:draw()
---   end
---   function mousemoved(x, y)
---       card:mousemoved(x, y)
---   end
---   function mousepressed(x, y, button)
---       if button == 1 and card:hitTest(x, y) then
---           -- trigger buy logic
---       end
---   end
---
--- Public API:
---   UpgradeCard.new(x, y, w, h, upgrade_def)  → UpgradeCard instance
---   card:setLevel(level)                       → nil  (current upgrade level)
---   card:setPoints(points)                     → nil  (player points for affordability)
---   card:hitTest(mx, my)                       → bool (hit test)
---   card:mousemoved(mx, my)                    → nil  (hover state update)
---   card:canAfford()                           → bool
---   card:getCost()                             → number | nil
---   card:isMaxed()                             → bool
---   card:draw()                                → nil  (renders card only)
---   card:drawTooltip(scroll_y)                 → nil  (renders tooltip at screen position, pass scroll offset)
local UpgradeCard = {}
UpgradeCard.__index = UpgradeCard

local Localizer = require("src.Localizer")
local Upgrades = require("src.game.Upgrades")

local PAD = 8
local LINE_GAP = 2

function UpgradeCard.new(x, y, w, h, upgrade_def)
    return setmetatable({
        x = x,
        y = y,
        w = w,
        h = h,
        def = upgrade_def,
        level = 0,
        points = 0,
        hovered = false,
        buy_flash_timer = 0,
        deny_flash_timer = 0,
        shake_elapsed = 0,
    }, UpgradeCard)
end

function UpgradeCard:setLevel(level)
    self.level = level
end

function UpgradeCard:setPoints(points)
    self.points = points
end

function UpgradeCard:hitTest(mx, my)
    return mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h
end

function UpgradeCard:mousemoved(mx, my)
    self.hovered = self:hitTest(mx, my)
end

function UpgradeCard:canAfford()
    local cost = Upgrades.get_cost(self.def.id, self.level)
    if not cost then
        return false
    end
    return self.points >= cost
end

function UpgradeCard:getCost()
    return Upgrades.get_cost(self.def.id, self.level)
end

function UpgradeCard:isMaxed()
    return self.level >= self.def.max_level
end

function UpgradeCard:playBuyAnimation()
    self.buy_flash_timer = 0.3
    self.deny_flash_timer = 0
end

function UpgradeCard:playDenyAnimation()
    self.deny_flash_timer = 0.5
    self.buy_flash_timer = 0
    self.shake_elapsed = 0
end

function UpgradeCard:updateAnimation(dt)
    if self.buy_flash_timer > 0 then
        self.buy_flash_timer = self.buy_flash_timer - dt
    end
    if self.deny_flash_timer > 0 then
        self.deny_flash_timer = self.deny_flash_timer - dt
        self.shake_elapsed = self.shake_elapsed + dt
    end
end

function UpgradeCard:draw()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local font = love.graphics.getFont()
    local fh = font:getHeight()
    local maxed = self:isMaxed()
    local can_afford = self:canAfford()

    love.graphics.push()

    if self.deny_flash_timer > 0 then
        love.graphics.translate(math.sin(self.shake_elapsed * 60) * 4, 0)
    elseif self.buy_flash_timer > 0 then
        local t = 1 - self.buy_flash_timer / 0.3
        local s = 1 + 0.06 * math.sin(math.pi * t)
        love.graphics.translate(x + w / 2, y + h / 2)
        love.graphics.scale(s, s)
        love.graphics.translate(-(x + w / 2), -(y + h / 2))
    end

    if maxed then
        love.graphics.setColor(0.15, 0.3, 0.15)
    elseif self.hovered then
        love.graphics.setColor(can_afford and 0.25 or 0.2, can_afford and 0.25 or 0.2, 0.35)
    else
        love.graphics.setColor(can_afford and 0.2 or 0.15, can_afford and 0.2 or 0.15, can_afford and 0.3 or 0.2)
    end
    love.graphics.rectangle("fill", x, y, w, h, 4)

    if maxed then
        love.graphics.setColor(1, 0.85, 0.2)
    elseif self.hovered then
        love.graphics.setColor(0.6, 0.6, 0.8)
    else
        love.graphics.setColor(0.4, 0.4, 0.6)
    end
    love.graphics.rectangle("line", x, y, w, h, 4)

    local name = Localizer.get(self.def.name_key)
    if maxed or not can_afford then
        love.graphics.setColor(0.6, 0.6, 0.6)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.printf(name, x + PAD, y + PAD, w - PAD * 2, "left")

    local level_text
    if maxed then
        level_text = Localizer.get("upgrade_max")
        love.graphics.setColor(1, 0.85, 0.2)
    else
        level_text = Localizer.getFormatted("upgrade_level", self.level, self.def.max_level)
        love.graphics.setColor(0.8, 0.8, 1)
    end
    love.graphics.printf(level_text, x + PAD, y + PAD, w - PAD * 2, "right")

    if not maxed then
        local cost = self:getCost()
        local cost_text = Localizer.getFormatted("upgrade_cost", cost)
        love.graphics.setColor(can_afford and 0.6 or 0.8, can_afford and 1 or 0.4, can_afford and 0.6 or 0.4)
        love.graphics.printf(cost_text, x + PAD, y + h - fh - PAD, w - PAD * 2, "left")
    end

    if self.buy_flash_timer > 0 then
        local a = math.min(self.buy_flash_timer / 0.3 * 0.35, 0.35)
        love.graphics.setColor(0.2, 1, 0.2, a)
        love.graphics.rectangle("fill", x, y, w, h, 4)
    elseif self.deny_flash_timer > 0 then
        local a = math.min(self.deny_flash_timer / 0.5 * 0.35, 0.35)
        love.graphics.setColor(1, 0.2, 0.2, a)
        love.graphics.rectangle("fill", x, y, w, h, 4)
    end

    love.graphics.pop()
end

function UpgradeCard:drawTooltip(scroll_offs)
    scroll_offs = scroll_offs or 0
    local x, y, w, h = self.x, self.y + scroll_offs, self.w, self.h
    local font = love.graphics.getFont()
    local fh = font:getHeight()
    local line_h = fh + LINE_GAP

    local display = Upgrades.get_display_info(self.def.id, self.level)
    local desc = Localizer.get(self.def.desc_key)

    local lines = { desc, "", display and Localizer.getFormatted(display.key, display.value) or "" }

    local next_info = nil
    local progress_text = nil
    if not self:isMaxed() and display then
        next_info = Upgrades.get_display_info_next(self.def.id, self.level)
        if next_info then
            local cv = ("%g"):format(display.value)
            local nv = ("%g"):format(next_info.value)
            progress_text = cv .. " -> " .. nv
        end
    end

    local tooltip_w = 280
    local tooltip_h = (#lines + (progress_text and 1 or 0)) * line_h + 10
    local tooltip_x = math.min(x, love.graphics.getWidth() - tooltip_w - 4)
    local tooltip_y = y + h + 4
    local screen_h = love.graphics.getHeight()
    if tooltip_y + tooltip_h > screen_h then
        tooltip_y = y - tooltip_h - 4
    end

    love.graphics.setColor(0.08, 0.08, 0.12, 0.95)
    love.graphics.rectangle("fill", tooltip_x, tooltip_y, tooltip_w, tooltip_h, 4)
    love.graphics.setColor(0.5, 0.5, 0.7)
    love.graphics.rectangle("line", tooltip_x, tooltip_y, tooltip_w, tooltip_h, 4)

    love.graphics.setColor(0.9, 0.9, 1)
    local ty = tooltip_y + 5
    for _, line in ipairs(lines) do
        love.graphics.printf(line, tooltip_x + 6, ty, tooltip_w - 12, "left")
        ty = ty + line_h
    end

    if progress_text then
        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.printf(progress_text, tooltip_x + 6, ty, tooltip_w - 12, "left")
    end
end

return UpgradeCard
