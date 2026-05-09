--- ConfirmDialog — reusable modal confirmation dialog
--
-- Usage:
--   local dialog = ConfirmDialog.new({
--       message   = "Are you sure?",
--       onConfirm = function() print("confirmed") end,
--       onCancel  = function() print("cancelled") end,
--   })
--
--   -- per-frame integration in the host scene:
--   function update(dt)
--       if dialog and dialog:isOpen() then
--           dialog:update(dt)
--           return
--       end
--   end
--   function draw()
--       -- scene content …
--       if dialog then dialog:draw() end
--   end
--   function mousemoved(x, y)
--       if dialog and dialog:isOpen() then dialog:mousemoved(x, y) end
--   end
--   function mousepressed(x, y, button)
--       if dialog and dialog:isOpen() then dialog:mousepressed(x, y, button) end
--   end
--
-- Public API:
--   ConfirmDialog.new(opts)       → ConfirmDialog instance
--   dialog:isOpen()               → bool  (active and not resolved)
--   dialog:update(dt)             → nil   (processes input)
--   dialog:draw()                 → nil   (renders overlay + choices)
--   dialog:mousemoved(x, y)       → nil   (hover on Yes/No)
--   dialog:mousepressed(x, y, b)  → nil   (click on Yes/No)
local ConfirmDialog = {}
ConfirmDialog.__index = ConfirmDialog

local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")

function ConfirmDialog.new(opts)
    opts = opts or {}
    return setmetatable({
        message = opts.message or Localizer.get("confirm_message"),
        onConfirm = opts.onConfirm or function() end,
        onCancel = opts.onCancel or function() end,
        active = true,
        resolved = false,
        choice = 1,
        font = love.graphics.newFont(24),
        rects = {},
    }, ConfirmDialog)
end

function ConfirmDialog:isOpen()
    return self.active and not self.resolved
end

function ConfirmDialog:update(dt)
    if not self:isOpen() then
        return
    end

    if InputActions.pressed("move_left") or InputActions.pressed("move_up") then
        self.choice = self.choice == 1 and 2 or 1
    elseif InputActions.pressed("move_right") or InputActions.pressed("move_down") then
        self.choice = self.choice == 1 and 2 or 1
    elseif InputActions.pressed("ui_back") then
        self.resolved = true
        self.onCancel()
    elseif InputActions.pressed("ui_confirm") then
        self.resolved = true
        if self.choice == 1 then
            self.onConfirm()
        else
            self.onCancel()
        end
    end
end

function ConfirmDialog:draw()
    if not self:isOpen() then
        return
    end

    love.graphics.push("all")

    local font = self.font
    love.graphics.setFont(font)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self.message, 0, 280, sw, "center")

    local labels = { Localizer.get("confirm_yes"), Localizer.get("confirm_no") }
    local y = 340
    local zone_w = 200
    local x_positions = { 440, 640 }
    local h = font:getHeight()
    self.rects = {}

    for i = 1, 2 do
        local text = labels[i]
        if i == self.choice then
            text = "> " .. text .. " <"
            love.graphics.setColor(1, 0.8, 0.2)
        else
            love.graphics.setColor(1, 1, 1)
        end
        local zone_x = x_positions[i]
        love.graphics.printf(text, zone_x, y, zone_w, "center")
        local tw = font:getWidth(text)
        local tx = zone_x + (zone_w - tw) / 2
        self.rects[i] = { x = tx, y = y, w = tw, h = h }
    end

    love.graphics.pop()
end

function ConfirmDialog:mousemoved(x, y)
    if not self:isOpen() then
        return
    end
    for i, rect in ipairs(self.rects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            self.choice = i
            return
        end
    end
end

function ConfirmDialog:mousepressed(x, y, button)
    if not self:isOpen() then
        return
    end
    if button ~= 1 then
        return
    end
    for i, rect in ipairs(self.rects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            self.resolved = true
            if i == 1 then
                self.onConfirm()
            else
                self.onCancel()
            end
            return
        end
    end
end

return ConfirmDialog
