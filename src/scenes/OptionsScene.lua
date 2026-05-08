local OptionsScene = {}
local InputActions = require("src.InputActions")

function OptionsScene.load() end
function OptionsScene.unload() end
function OptionsScene.update(dt) end

function OptionsScene.keypressed(key)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        SceneManager.pop()
    end
end

function OptionsScene.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Options — a venir", 0, 300, 1280, "center")
    love.graphics.printf("Echap pour retourner", 0, 340, 1280, "center")
end

return OptionsScene
