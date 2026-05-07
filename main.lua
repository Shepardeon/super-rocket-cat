local SceneManager = require("src.SceneManager")
local MenuScene = require("src.scenes.MenuScene")

function love.load()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    SceneManager.push(MenuScene)
end

function love.update(dt)
    SceneManager.update(dt)
end

function love.draw()
    SceneManager.draw()
end

function love.keypressed(key)
    SceneManager.keypressed(key)
end
