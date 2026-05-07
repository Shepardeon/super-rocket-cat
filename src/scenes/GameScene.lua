local GameScene = {}

function GameScene.load() end
function GameScene.update(dt) end
function GameScene.unload() end

function GameScene.keypressed(key)
    if key == "escape" then
        local SceneManager = require("src.SceneManager")
        local PauseScene = require("src.scenes.PauseScene")
        SceneManager.push(PauseScene)
    end
end

function GameScene.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("En jeu — Echap pour pause", 10, 10)
end

return GameScene
