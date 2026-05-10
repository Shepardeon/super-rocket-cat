local UpgradesScene = {}

local InputActions = require("src.InputActions")
local SaveManager = require("src.SaveManager")
local Localizer = require("src.Localizer")
local Upgrades = require("src.game.Upgrades")
local UpgradeCard = require("src.ui.UpgradeCard")
local RocketVisual = require("src.game.RocketVisual")

local data = nil
local cards = {}
local scroll_y = 0
local max_scroll = 0
local selected_idx = 1
local focus_launch = false

local HEADER_H = 44
local LEFT_W = 420
local RIGHT_W = 860
local CARD_W = math.floor((RIGHT_W - 20 - 8) / 2)
local CARD_H = 85
local CARD_GAP = 8
local PANEL_PAD = 10
local NAV_DELAY = 0.2
local NAV_REPEAT = 0.08
local nav_timer = 0
local nav_repeating = false

local function find_upgrade(id)
    if not data then
        return nil
    end
    for _, entry in ipairs(data.upgrades) do
        if entry.id == id then
            return entry
        end
    end
    return nil
end

local function scroll_to_card(idx)
    local card = cards[idx]
    if not card then
        return
    end
    local card_top = card.y + scroll_y
    local card_bot = card.y + scroll_y + CARD_H
    local panel_top = HEADER_H + PANEL_PAD
    local panel_bot = 720 - PANEL_PAD
    if card_top < panel_top then
        scroll_y = scroll_y + (panel_top - card_top)
    elseif card_bot > panel_bot then
        scroll_y = scroll_y - (card_bot - panel_bot)
    end
    if scroll_y > 0 then
        scroll_y = 0
    end
    if scroll_y < max_scroll then
        scroll_y = max_scroll
    end
end

local function navigate(dx, dy)
    if focus_launch then
        if dy < 0 then
            focus_launch = false
            selected_idx = 7
            scroll_to_card(selected_idx)
        end
        return
    end
    local num_cols = 2
    local total_rows = math.ceil(#cards / num_cols)
    local row = math.floor((selected_idx - 1) / num_cols)
    local col = (selected_idx - 1) % num_cols
    local new_row = row + dy
    local new_col = col + dx
    if new_col < 0 then
        new_col = num_cols - 1
    end
    if new_col >= num_cols then
        new_col = 0
    end
    if new_row >= total_rows then
        focus_launch = true
        return
    end
    if new_row < 0 then
        new_row = 0
    end
    local new_idx = new_row * num_cols + new_col + 1
    if new_idx > #cards then
        new_idx = (total_rows - 1) * num_cols + 1
    end
    selected_idx = new_idx
    scroll_to_card(selected_idx)
end

local function try_buy_card(idx)
    if not data then
        return
    end
    local card = cards[idx]
    if not card then
        return
    end
    if card:isMaxed() or not card:canAfford() then
        return
    end
    local cost = card:getCost()
    data:spend_points(cost)
    local entry = find_upgrade(card.def.id)
    if entry then
        entry.level = entry.level + 1
    else
        table.insert(data.upgrades, { id = card.def.id, level = 1 })
    end
    SaveManager.save(SaveManager.currentSlot, data)
    for _, c in ipairs(cards) do
        c:setLevel(Upgrades.get_level(data.upgrades, c.def.id))
        c:setPoints(data.points)
    end
end

local function build_cards()
    cards = {}
    local defs = Upgrades.get_all()
    local grid_w = RIGHT_W - PANEL_PAD * 2
    local card_w = math.floor((grid_w - CARD_GAP) / 2)
    for i, def in ipairs(defs) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local cx = LEFT_W + PANEL_PAD + col * (card_w + CARD_GAP)
        local cy = HEADER_H + PANEL_PAD + row * (CARD_H + CARD_GAP)
        local card = UpgradeCard.new(cx, cy, card_w, CARD_H, def)
        card:setLevel(Upgrades.get_level(data and data.upgrades, def.id))
        card:setPoints(data and data.points or 0)
        cards[#cards + 1] = card
    end
    local total_h = #defs / 2 * (CARD_H + CARD_GAP) - CARD_GAP
    local available_h = 720 - HEADER_H - PANEL_PAD * 2
    max_scroll = math.min(0, available_h - total_h)
    if scroll_y < max_scroll then
        scroll_y = max_scroll
    end
end

function UpgradesScene.load()
    if not SaveManager.currentSlot then
        data = nil
        return
    end
    data = SaveManager.load(SaveManager.currentSlot)
    scroll_y = 0
    selected_idx = 1
    focus_launch = false
    build_cards()
end

function UpgradesScene.unload()
    if data and SaveManager.currentSlot then
        SaveManager.save(SaveManager.currentSlot, data)
    end
    data = nil
    cards = {}
end

function UpgradesScene.update(dt)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        local MenuScene = require("src.scenes.MenuScene")
        SceneManager.switch(MenuScene)
        return
    end

    if InputActions.pressed("ui_confirm") then
        if focus_launch then
            local SceneManager = require("src.SceneManager")
            local LaunchScene = require("src.scenes.LaunchScene")
            SceneManager.switch(LaunchScene)
        else
            try_buy_card(selected_idx)
        end
        return
    end

    nav_timer = nav_timer - dt
    local dx, dy = 0, 0
    if InputActions.isDown("move_left") then
        dx = -1
    end
    if InputActions.isDown("move_right") then
        dx = 1
    end
    if InputActions.isDown("move_up") then
        dy = -1
    end
    if InputActions.isDown("move_down") then
        dy = 1
    end
    if dx ~= 0 or dy ~= 0 then
        if nav_timer <= 0 then
            navigate(dx, dy)
            nav_timer = nav_repeating and NAV_REPEAT or NAV_DELAY
            nav_repeating = true
        end
    else
        nav_timer = 0
        nav_repeating = false
    end
end

function UpgradesScene.draw()
    if not data then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf("No save loaded", 0, 360, 1280, "center")
        return
    end

    local fh = love.graphics.getFont():getHeight()
    local hc = HEADER_H / 2 - fh / 2

    love.graphics.setColor(0.12, 0.12, 0.18)
    love.graphics.rectangle("fill", 0, 0, 1280, HEADER_H)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(data.name, 10, hc, 300, "left")
    love.graphics.printf(Localizer.get("upgrades_title"), 0, hc, 1280, "center")
    love.graphics.printf(Localizer.getFormatted("upgrades_points", data.points), RIGHT_W, hc, LEFT_W - 10, "right")

    love.graphics.setColor(0.3, 0.3, 0.5)
    love.graphics.line(0, HEADER_H, 1280, HEADER_H)
    love.graphics.setColor(0.1, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, HEADER_H, LEFT_W, 720 - HEADER_H)
    love.graphics.setColor(0.08, 0.08, 0.12)
    love.graphics.rectangle("fill", LEFT_W, HEADER_H, RIGHT_W, 720 - HEADER_H)
    love.graphics.setColor(0.3, 0.3, 0.5)
    love.graphics.line(LEFT_W, HEADER_H, LEFT_W, 720)

    love.graphics.push()
    love.graphics.translate(0, scroll_y)
    for i, card in ipairs(cards) do
        card:draw()
        if i == selected_idx and not focus_launch then
            love.graphics.setColor(1, 1, 0.4)
            love.graphics.rectangle("line", card.x - 2, card.y - 2, card.w + 4, card.h + 4, 6)
        end
    end
    love.graphics.pop()

    RocketVisual.draw(0, HEADER_H, LEFT_W, 720 - HEADER_H, data.upgrades)

    local btn_w, btn_h = 180, 50
    local btn_x = (LEFT_W - btn_w) / 2
    local btn_y = 720 - 90
    if focus_launch then
        love.graphics.setColor(0.3, 0.6, 0.4)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.2, 0.5, 0.3)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("fill", btn_x, btn_y, btn_w, btn_h, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(Localizer.get("btn_launch"), btn_x, btn_y + btn_h / 2 - fh / 2, btn_w, "center")
    love.graphics.setColor(0.15, 0.35, 0.2)
    love.graphics.rectangle("line", btn_x, btn_y, btn_w, btn_h, 6)
    if focus_launch then
        love.graphics.setColor(1, 1, 0.4)
        love.graphics.rectangle("line", btn_x - 2, btn_y - 2, btn_w + 4, btn_h + 4, 6)
        love.graphics.setLineWidth(1)
    end

    if max_scroll < 0 then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.printf("scroll", LEFT_W, 715, RIGHT_W, "center")
    end

    local tooltip_card = nil
    for _, c in ipairs(cards) do
        if c.hovered then
            tooltip_card = c
            break
        end
    end
    if not tooltip_card and not focus_launch then
        tooltip_card = cards[selected_idx]
    end
    if tooltip_card then
        tooltip_card:drawTooltip(scroll_y)
    end
end

function UpgradesScene.mousemoved(x, y)
    for _, card in ipairs(cards) do
        card:mousemoved(x, y - scroll_y)
    end
    local hit_idx = nil
    for i, card in ipairs(cards) do
        if card:hitTest(x, y - scroll_y) then
            hit_idx = i
            break
        end
    end
    if hit_idx then
        selected_idx = hit_idx
        focus_launch = false
    end
end

function UpgradesScene.mousepressed(x, y, button)
    if button ~= 1 or not data then
        return
    end

    local btn_w, btn_h = 180, 50
    local btn_x = (LEFT_W - btn_w) / 2
    local btn_y = 720 - 90
    if x >= btn_x and x <= btn_x + btn_w and y >= btn_y and y <= btn_y + btn_h then
        local SceneManager = require("src.SceneManager")
        local LaunchScene = require("src.scenes.LaunchScene")
        SceneManager.switch(LaunchScene)
        return
    end

    for _, card in ipairs(cards) do
        if card:hitTest(x, y - scroll_y) then
            try_buy_card(selected_idx)
            return
        end
    end
end

function UpgradesScene.wheelmoved(_, y)
    scroll_y = scroll_y + y * 30
    if scroll_y > 0 then
        scroll_y = 0
    end
    if scroll_y < max_scroll then
        scroll_y = max_scroll
    end
end

return UpgradesScene
