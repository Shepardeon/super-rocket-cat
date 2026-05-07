local PauseScene = {}

function PauseScene.load() end
function PauseScene.update(dt) end
function PauseScene.unload() end

function PauseScene.keypressed(key)
    if key == "escape" then
        local SceneManager = require("src.SceneManager")
        SceneManager.pop()
    end
end

function PauseScene.draw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("PAUSE — Echap pour reprendre", 10, 10)
end

return PauseScene
