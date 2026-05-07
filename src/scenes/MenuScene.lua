local MenuScene = {}

function MenuScene.load() end
function MenuScene.update(dt) end
function MenuScene.unload() end

function MenuScene.keypressed(key)
    if key == "return" then
        local SceneManager = require("src.SceneManager")
        local GameScene = require("src.scenes.GameScene")
        SceneManager.switch(GameScene)
    elseif key == "escape" then
        love.event.quit()
    end
end

function MenuScene.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Menu — Entrée pour jouer, Echap pour quitter", 10, 10)
end

return MenuScene
