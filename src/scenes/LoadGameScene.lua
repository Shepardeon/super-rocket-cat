local LoadGameScene = {}
local InputActions = require("src.InputActions")
local SaveManager = require("src.SaveManager")
local Localizer = require("src.Localizer")

local saves_data = {}
local selected = 1
local item_rects = {}
local item_font

local function format_time(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function build_text(meta)
    return string.format("%s  |  Niveau %d  |  %s", meta.name, meta.global_level, format_time(meta.play_time))
end

local function total_items()
    return #saves_data + 1
end

local function is_back(idx)
    return idx > #saves_data
end

local function compute_rects()
    item_rects = {}
    for i, meta in ipairs(saves_data) do
        local text = build_text(meta)
        local w = item_font:getWidth(text)
        local h = item_font:getHeight()
        local x = (1280 - w) / 2
        local y = 150 + (i - 1) * 50
        item_rects[i] = { x = x, y = y, w = w, h = h }
    end
    local back_y = #saves_data == 0 and 380 or 150 + #saves_data * 50 + 20
    local back_label = Localizer.get("load_back")
    local w = item_font:getWidth(back_label)
    local h = item_font:getHeight()
    local x = (1280 - w) / 2
    item_rects[#saves_data + 1] = { x = x, y = back_y, w = w, h = h }
end

function LoadGameScene.load()
    item_font = love.graphics.newFont(24)
    saves_data = SaveManager.listMeta()
    selected = 1
    compute_rects()
end

function LoadGameScene.unload() end

function LoadGameScene.update(dt)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        SceneManager.pop()
        return
    end

    if InputActions.pressed("move_down") then
        selected = selected % total_items() + 1
    elseif InputActions.pressed("move_up") then
        selected = ((selected - 2) % total_items()) + 1
    elseif InputActions.pressed("ui_confirm") then
        if is_back(selected) then
            local SceneManager = require("src.SceneManager")
            SceneManager.pop()
        else
            SaveManager.currentSlot = saves_data[selected].slot
            local UpgradesScene = require("src.scenes.UpgradesScene")
            local SceneManager = require("src.SceneManager")
            SceneManager.switch(UpgradesScene)
        end
    end
end

function LoadGameScene.mousemoved(x, y)
    local hit = nil
    for i, rect in ipairs(item_rects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            hit = i
            break
        end
    end
    if hit and hit ~= selected then
        selected = hit
    end
end

function LoadGameScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    for i, rect in ipairs(item_rects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if is_back(i) then
                local SceneManager = require("src.SceneManager")
                SceneManager.pop()
            else
                SaveManager.currentSlot = saves_data[i].slot
                local UpgradesScene = require("src.scenes.UpgradesScene")
                local SceneManager = require("src.SceneManager")
                SceneManager.switch(UpgradesScene)
            end
            return
        end
    end
end

function LoadGameScene.draw()
    love.graphics.setFont(item_font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(Localizer.get("continue_title"), 0, 50, 1280, "center")

    if #saves_data == 0 then
        love.graphics.printf(Localizer.get("no_saves"), 0, 300, 1280, "center")
        love.graphics.printf(Localizer.get("back_hint"), 0, 340, 1280, "center")
    else
        for i, meta in ipairs(saves_data) do
            local y = 150 + (i - 1) * 50
            local text = build_text(meta)

            if i == selected then
                love.graphics.setColor(1, 0.8, 0.2)
                love.graphics.printf("> " .. text .. " <", 0, y, 1280, "center")
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(text, 0, y, 1280, "center")
            end
        end
    end

    local back_y = #saves_data == 0 and 380 or 150 + #saves_data * 50 + 20
    local back_label = Localizer.get("load_back")
    if is_back(selected) then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.printf("> " .. back_label .. " <", 0, back_y, 1280, "center")
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(back_label, 0, back_y, 1280, "center")
    end
end

return LoadGameScene
