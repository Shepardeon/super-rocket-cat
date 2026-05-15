local LaunchScene = {}
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")
local SaveManager = require("src.SaveManager")
local Upgrades = require("src.game.Upgrades")
local RocketVisual = require("src.game.RocketVisual")
local C = require("src.constants")

local save_data = nil

function LaunchScene.load()
    if SaveManager.currentSlot then
        save_data = SaveManager.load(SaveManager.currentSlot)
    end
end

function LaunchScene.unload()
    save_data = nil
end

function LaunchScene.update(dt)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        local UpgradesScene = require("src.scenes.UpgradesScene")
        SceneManager.switch(UpgradesScene)
    end
end

function LaunchScene.draw()
    local fh = love.graphics.getFont():getHeight()
    love.graphics.setColor(0.08, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    if save_data then
        local rocket_w = 250
        local rocket_h = math.floor(rocket_w * (C.SCREEN_H - C.HEADER_H) / C.LEFT_W)
        local rocket_x = (1280 - rocket_w) / 2
        local rocket_y = 100
        RocketVisual.draw(rocket_x, rocket_y, rocket_w, rocket_h, Upgrades.get_all_levels(save_data.upgrades))
    end

    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.printf(Localizer.get("upgrades_back") .. " (" .. Localizer.get("back_hint") .. ")", 0, 550, 1280, "center")

    local btn_w, btn_h = 200, 50
    local btn_x = (1280 - btn_w) / 2
    local btn_y = 570
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", btn_x, btn_y, btn_w, btn_h, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(Localizer.get("upgrades_back"), btn_x, btn_y + btn_h / 2 - fh / 2, btn_w, "center")
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("line", btn_x, btn_y, btn_w, btn_h, 6)
end

function LaunchScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    local btn_w, btn_h = 200, 50
    local btn_x = (1280 - btn_w) / 2
    local btn_y = 570
    if x >= btn_x and x <= btn_x + btn_w and y >= btn_y and y <= btn_y + btn_h then
        local SceneManager = require("src.SceneManager")
        local UpgradesScene = require("src.scenes.UpgradesScene")
        SceneManager.switch(UpgradesScene)
    end
end

return LaunchScene
