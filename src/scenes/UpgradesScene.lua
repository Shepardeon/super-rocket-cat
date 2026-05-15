local UpgradesScene = {}

local InputActions = require("src.InputActions")
local SaveManager = require("src.SaveManager")
local Localizer = require("src.Localizer")
local Upgrades = require("src.game.Upgrades")
local UpgradeCard = require("src.ui.UpgradeCard")
local RocketVisual = require("src.game.RocketVisual")
local AudioManager = require("src.AudioManager")
local C = require("src.constants")

local state = nil

local RIGHT_W = 860
local CARD_H = 85
local CARD_GAP = 8
local PANEL_PAD = 10
local NAV_DELAY = 0.2
local NAV_REPEAT = 0.08

local function default_state()
    return {
        data = nil,
        cards = {},
        scroll_y = 0,
        max_scroll = 0,
        selected_idx = 1,
        focus_launch = false,
        toast_text = nil,
        toast_timer = 0,
        nav_timer = 0,
        nav_repeating = false,
    }
end

local function find_upgrade(id)
    if not state then
        return nil
    end
    for _, entry in ipairs(state.data.upgrades) do
        if entry.id == id then
            return entry
        end
    end
    return nil
end

local function scroll_to_card(idx)
    if not state then
        return
    end
    local card = state.cards[idx]
    if not card then
        return
    end
    local card_top = card.y + state.scroll_y
    local card_bot = card.y + state.scroll_y + CARD_H
    local panel_top = C.HEADER_H + PANEL_PAD
    local panel_bot = 720 - PANEL_PAD
    if card_top < panel_top then
        state.scroll_y = state.scroll_y + (panel_top - card_top)
    elseif card_bot > panel_bot then
        state.scroll_y = state.scroll_y - (card_bot - panel_bot)
    end
    if state.scroll_y > 0 then
        state.scroll_y = 0
    end
    if state.scroll_y < state.max_scroll then
        state.scroll_y = state.max_scroll
    end
end

local function navigate(dx, dy)
    if not state then
        return
    end
    if state.focus_launch then
        if dy < 0 then
            state.focus_launch = false
            local num_cols = 2
            state.selected_idx = math.min(#state.cards, num_cols * (math.ceil(#state.cards / num_cols) - 1) + 1)
            scroll_to_card(state.selected_idx)
        end
        return
    end
    local num_cols = 2
    local total_rows = math.ceil(#state.cards / num_cols)
    local row = math.floor((state.selected_idx - 1) / num_cols)
    local col = (state.selected_idx - 1) % num_cols
    local new_row = row + dy
    local new_col = col + dx
    if new_col < 0 then
        new_col = num_cols - 1
    end
    if new_col >= num_cols then
        new_col = 0
    end
    if new_row >= total_rows then
        state.focus_launch = true
        return
    end
    if new_row < 0 then
        new_row = 0
    end
    local new_idx = new_row * num_cols + new_col + 1
    if new_idx > #state.cards then
        new_idx = (total_rows - 1) * num_cols + 1
    end
    state.selected_idx = new_idx
    scroll_to_card(state.selected_idx)
end

local function try_buy_card(idx)
    if not state then
        return
    end
    local card = state.cards[idx]
    if not card then
        return
    end
    if card:isMaxed() then
        card:playDenyAnimation()
        state.toast_text = Localizer.get("upgrade_already_max")
        state.toast_timer = 1.5
        return
    end
    if not card:canAfford() then
        card:playDenyAnimation()
        state.toast_text = Localizer.get("upgrade_no_points")
        state.toast_timer = 1.5
        return
    end
    local cost = card:getCost()
    if not cost then
        return
    end
    local ok = state.data:spend_points(cost)
    if not ok then
        return
    end
    local entry = find_upgrade(card.def.id)
    if entry then
        entry.level = entry.level + 1
    else
        table.insert(state.data.upgrades, { id = card.def.id, level = 1 })
    end
    SaveManager.save(SaveManager.currentSlot, state.data)
    for _, c in ipairs(state.cards) do
        c:setLevel(Upgrades.get_level(state.data.upgrades, c.def.id))
        c:setPoints(state.data.points)
    end
    card:playBuyAnimation()
    AudioManager.playSfx("buy")
end

local function build_cards()
    if not state then
        return
    end
    state.cards = {}
    local defs = Upgrades.get_all()
    local grid_w = RIGHT_W - PANEL_PAD * 2
    local card_w = math.floor((grid_w - CARD_GAP) / 2)
    for i, def in ipairs(defs) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local cx = C.LEFT_W + PANEL_PAD + col * (card_w + CARD_GAP)
        local cy = C.HEADER_H + PANEL_PAD + row * (CARD_H + CARD_GAP)
        local card = UpgradeCard.new(cx, cy, card_w, CARD_H, def)
        card:setLevel(Upgrades.get_level(state.data and state.data.upgrades, def.id))
        card:setPoints(state.data and state.data.points or 0)
        state.cards[#state.cards + 1] = card
    end
    local total_h = #defs / 2 * (CARD_H + CARD_GAP) - CARD_GAP
    local available_h = 720 - C.HEADER_H - PANEL_PAD * 2
    state.max_scroll = math.min(0, available_h - total_h)
    if state.scroll_y < state.max_scroll then
        state.scroll_y = state.max_scroll
    end
end

function UpgradesScene.load()
    if not SaveManager.currentSlot then
        state = nil
        return
    end
    state = default_state()
    state.data = SaveManager.load(SaveManager.currentSlot)
    build_cards()
end

function UpgradesScene.unload()
    if state and state.data and SaveManager.currentSlot then
        SaveManager.save(SaveManager.currentSlot, state.data)
    end
    state = nil
end

function UpgradesScene.update(dt)
    if not state then
        return
    end

    for _, card in ipairs(state.cards) do
        card:updateAnimation(dt)
    end

    if state.toast_timer > 0 then
        state.toast_timer = state.toast_timer - dt
        if state.toast_timer <= 0 then
            state.toast_text = nil
        end
    end

    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        local MenuScene = require("src.scenes.MenuScene")
        SceneManager.switch(MenuScene)
        return
    end

    if InputActions.pressed("ui_confirm") then
        if state.focus_launch then
            local SceneManager = require("src.SceneManager")
            local LaunchScene = require("src.scenes.LaunchScene")
            SceneManager.switch(LaunchScene)
        else
            try_buy_card(state.selected_idx)
        end
        return
    end

    state.nav_timer = state.nav_timer - dt
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
        if state.nav_timer <= 0 then
            navigate(dx, dy)
            state.nav_timer = state.nav_repeating and NAV_REPEAT or NAV_DELAY
            state.nav_repeating = true
        end
    else
        state.nav_timer = 0
        state.nav_repeating = false
    end
end

function UpgradesScene.draw()
    if not state or not state.data then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf("No save loaded", 0, 360, 1280, "center")
        return
    end

    local fh = love.graphics.getFont():getHeight()
    local hc = C.HEADER_H / 2 - fh / 2

    love.graphics.setColor(0.12, 0.12, 0.18)
    love.graphics.rectangle("fill", 0, 0, 1280, C.HEADER_H)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(state.data.name, 10, hc, 300, "left")
    love.graphics.printf(Localizer.get("upgrades_title"), 0, hc, 1280, "center")
    love.graphics.printf(
        Localizer.getFormatted("upgrades_points", state.data.points),
        RIGHT_W,
        hc,
        C.LEFT_W - 10,
        "right"
    )

    love.graphics.setColor(0.3, 0.3, 0.5)
    love.graphics.line(0, C.HEADER_H, 1280, C.HEADER_H)
    love.graphics.setColor(0.1, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, C.HEADER_H, C.LEFT_W, 720 - C.HEADER_H)
    love.graphics.setColor(0.08, 0.08, 0.12)
    love.graphics.rectangle("fill", C.LEFT_W, C.HEADER_H, RIGHT_W, 720 - C.HEADER_H)
    love.graphics.setColor(0.3, 0.3, 0.5)
    love.graphics.line(C.LEFT_W, C.HEADER_H, C.LEFT_W, 720)

    love.graphics.push()
    love.graphics.translate(0, state.scroll_y)
    for i, card in ipairs(state.cards) do
        card:draw()
        if i == state.selected_idx and not state.focus_launch then
            love.graphics.setColor(1, 1, 0.4)
            love.graphics.rectangle("line", card.x - 2, card.y - 2, card.w + 4, card.h + 4, 6)
        end
    end
    love.graphics.pop()

    RocketVisual.draw(0, C.HEADER_H, C.LEFT_W, 720 - C.HEADER_H, Upgrades.get_all_levels(state.data.upgrades))

    local btn_w, btn_h = 180, 50
    local btn_x = (C.LEFT_W - btn_w) / 2
    local btn_y = 720 - 90
    if state.focus_launch then
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
    if state.focus_launch then
        love.graphics.setColor(1, 1, 0.4)
        love.graphics.rectangle("line", btn_x - 2, btn_y - 2, btn_w + 4, btn_h + 4, 6)
        love.graphics.setLineWidth(1)
    end

    if state.max_scroll < 0 then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.printf("scroll", C.LEFT_W, 715, RIGHT_W, "center")
    end

    local tooltip_card = nil
    for _, c in ipairs(state.cards) do
        if c.hovered then
            tooltip_card = c
            break
        end
    end
    if not tooltip_card and not state.focus_launch then
        tooltip_card = state.cards[state.selected_idx]
    end
    if tooltip_card then
        tooltip_card:drawTooltip(state.scroll_y)
    end

    if state.toast_text and state.toast_timer > 0 then
        local alpha = math.min(state.toast_timer / 0.3, 1)
        love.graphics.setColor(0.08, 0.08, 0.12, alpha * 0.9)
        love.graphics.rectangle("fill", 440, 320, 400, 50, 8)
        love.graphics.setColor(1, 0.85, 0.2, alpha)
        love.graphics.printf(state.toast_text, 440, 335, 400, "center")
    end
end

function UpgradesScene.mousemoved(x, y)
    if not state then
        return
    end
    for _, card in ipairs(state.cards) do
        card:mousemoved(x, y - state.scroll_y)
    end
    local hit_idx = nil
    for i, card in ipairs(state.cards) do
        if card:hitTest(x, y - state.scroll_y) then
            hit_idx = i
            break
        end
    end
    if hit_idx then
        state.selected_idx = hit_idx
        state.focus_launch = false
    end
end

function UpgradesScene.mousepressed(x, y, button)
    if button ~= 1 or not state or not state.data then
        return
    end

    local btn_w, btn_h = 180, 50
    local btn_x = (C.LEFT_W - btn_w) / 2
    local btn_y = 720 - 90
    if x >= btn_x and x <= btn_x + btn_w and y >= btn_y and y <= btn_y + btn_h then
        local SceneManager = require("src.SceneManager")
        local LaunchScene = require("src.scenes.LaunchScene")
        SceneManager.switch(LaunchScene)
        return
    end

    for i, card in ipairs(state.cards) do
        if card:hitTest(x, y - state.scroll_y) then
            try_buy_card(i)
            return
        end
    end
end

function UpgradesScene.wheelmoved(_, y)
    if not state then
        return
    end
    state.scroll_y = state.scroll_y + y * 30
    if state.scroll_y > 0 then
        state.scroll_y = 0
    end
    if state.scroll_y < state.max_scroll then
        state.scroll_y = state.max_scroll
    end
end

return UpgradesScene
