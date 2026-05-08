local UpgradesScene = {}
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")

function UpgradesScene.load() end
function UpgradesScene.unload() end
function UpgradesScene.update(dt) end

function UpgradesScene.keypressed(key)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        local MenuScene = require("src.scenes.MenuScene")
        SceneManager.switch(MenuScene)
    end
end

function UpgradesScene.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Ameliorations — a venir", 0, 300, 1280, "center")
    love.graphics.printf("Echap pour retourner au menu", 0, 340, 1280, "center")
end

return UpgradesScene
