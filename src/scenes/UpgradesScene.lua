local UpgradesScene = {}
local InputActions = require("src.InputActions")
local SaveManager = require("src.SaveManager")
local Localizer = require("src.Localizer")

local data = nil

function UpgradesScene.load()
    if not SaveManager.currentSlot then
        data = nil
        return
    end
    data = SaveManager.load(SaveManager.currentSlot)
end

function UpgradesScene.unload()
    if data and SaveManager.currentSlot then
        SaveManager.save(SaveManager.currentSlot, data)
    end
    data = nil
end

function UpgradesScene.update(dt)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        local MenuScene = require("src.scenes.MenuScene")
        SceneManager.switch(MenuScene)
    end
end

local debug_buttons = {
    {
        label = "[DEBUG] +10 pts",
        x = 40,
        y = 500,
        w = 180,
        h = 40,
        action = function()
            if data then
                data:add_points(10)
            end
        end,
    },
    {
        label = "[DEBUG] -5 pts",
        x = 240,
        y = 500,
        w = 180,
        h = 40,
        action = function()
            if data then
                data:spend_points(5)
            end
        end,
    },
}

function UpgradesScene.draw()
    love.graphics.setColor(1, 1, 1)
    if data then
        love.graphics.printf("Partie: " .. data.name, 0, 260, 1280, "center")
        love.graphics.printf(Localizer.getFormatted("upgrades_points", data.points), 0, 290, 1280, "center")
    end
    love.graphics.printf("Ameliorations — a venir", 0, 320, 1280, "center")
    love.graphics.printf("Echap pour retourner au menu", 0, 340, 1280, "center")

    for _, btn in ipairs(debug_buttons) do
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf(btn.label, btn.x, btn.y + 8, btn.w, "center")
    end
end

function UpgradesScene.mousepressed(x, y, button)
    if button ~= 1 or not data then
        return
    end
    for _, btn in ipairs(debug_buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            btn.action()
            return
        end
    end
end

return UpgradesScene
