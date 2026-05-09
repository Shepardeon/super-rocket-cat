local MenuScene = {}
local SceneManager = require("src.SceneManager")
local InputActions = require("src.InputActions")
local AudioManager = require("src.AudioManager")
local Localizer = require("src.Localizer")
local SaveManager = require("src.SaveManager")
local SaveData = require("src.data.SaveData")

local items = {
    { key = "menu_new_game", action = "new_game" },
    { key = "menu_continue", action = "continue" },
    { key = "menu_options", action = "options" },
    { key = "menu_quit", action = "quit" },
}

local selected = 1
local saves = {}
local item_rects = {}
local title_font
local item_font

local TITLE_Y = 200
local ITEMS_START_Y = 350
local ITEM_SPACING = 60

local function refresh_saves()
    saves = SaveManager.listSaves()
end

local function is_disabled(idx)
    return items[idx].action == "continue" and #saves == 0
end

local function next_enabled(from, direction)
    local count = #items
    for _ = 1, count do
        from = ((from - 1 + direction) % count) + 1
        if not is_disabled(from) then
            return from
        end
    end
    return from
end

local function get_item_label(idx)
    return Localizer.get(items[idx].key)
end

local function compute_rects()
    item_rects = {}
    for i in ipairs(items) do
        local label = get_item_label(i)
        local w = item_font:getWidth(label)
        local h = item_font:getHeight()
        local x = (1280 - w) / 2
        local y = ITEMS_START_Y + (i - 1) * ITEM_SPACING
        item_rects[i] = { x = x, y = y, w = w, h = h }
    end
end

local function execute_action(action)
    if action == "new_game" then
        local slot = #saves + 1
        local data = SaveData.new("Partie " .. slot)
        SaveManager.save(slot, data)
        SaveManager.currentSlot = slot
        local UpgradesScene = require("src.scenes.UpgradesScene")
        SceneManager.switch(UpgradesScene)
    elseif action == "continue" then
        local LoadGameScene = require("src.scenes.LoadGameScene")
        SceneManager.push(LoadGameScene)
    elseif action == "options" then
        local OptionsScene = require("src.scenes.OptionsScene")
        SceneManager.push(OptionsScene)
    elseif action == "quit" then
        love.event.quit()
    end
end

function MenuScene.load()
    title_font = love.graphics.newFont(48)
    item_font = love.graphics.newFont(24)
    AudioManager.playMusic("menu")
end

function MenuScene.activate()
    refresh_saves()
    selected = 1
    if is_disabled(selected) then
        selected = next_enabled(selected, 1)
    end
    compute_rects()
end

function MenuScene.unload() end

function MenuScene.update(dt)
    if InputActions.pressed("move_down") then
        local new = next_enabled(selected, 1)
        if new ~= selected then
            selected = new
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("move_up") then
        local new = next_enabled(selected, -1)
        if new ~= selected then
            selected = new
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("ui_confirm") then
        if not is_disabled(selected) then
            AudioManager.playSfx("confirm")
            execute_action(items[selected].action)
        end
    end
end

function MenuScene.mousemoved(x, y)
    local hit = nil
    for i, rect in ipairs(item_rects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if not is_disabled(i) then
                hit = i
            end
            break
        end
    end
    if hit and hit ~= selected then
        selected = hit
    end
end

function MenuScene.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    for i, rect in ipairs(item_rects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if not is_disabled(i) then
                AudioManager.playSfx("confirm")
                execute_action(items[i].action)
            end
            break
        end
    end
end

function MenuScene.draw()
    if not SceneManager.is_top(MenuScene) then
        return
    end
    love.graphics.setFont(title_font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(Localizer.get("menu_title"), 0, TITLE_Y, 1280, "center")

    love.graphics.setFont(item_font)
    for i in ipairs(items) do
        local label = get_item_label(i)
        local y = ITEMS_START_Y + (i - 1) * ITEM_SPACING

        if is_disabled(i) then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.printf(label, 0, y, 1280, "center")
        elseif i == selected then
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.printf("> " .. label .. " <", 0, y, 1280, "center")
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(label, 0, y, 1280, "center")
        end
    end
end

return MenuScene
