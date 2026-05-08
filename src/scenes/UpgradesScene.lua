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
    data = nil
end

function UpgradesScene.update(dt)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        local MenuScene = require("src.scenes.MenuScene")
        SceneManager.switch(MenuScene)
    end
end

function UpgradesScene.draw()
    love.graphics.setColor(1, 1, 1)
    if data then
        love.graphics.printf("Partie: " .. data.name, 0, 260, 1280, "center")
    end
    love.graphics.printf("Ameliorations — a venir", 0, 300, 1280, "center")
    love.graphics.printf("Echap pour retourner au menu", 0, 340, 1280, "center")
end

return UpgradesScene
