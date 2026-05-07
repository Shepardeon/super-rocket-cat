local SceneManager = require("src.SceneManager")
local MenuScene = require("src.scenes.MenuScene")
local InputActions = require("src.InputActions")
local AudioManager = require("src.AudioManager")

function love.load()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    SceneManager.push(MenuScene)
    AudioManager.load()
end

function love.update(dt)
    SceneManager.update(dt)
    AudioManager.update(dt)
    InputActions.clearPressed()
end

function love.draw()
    SceneManager.draw()
end

function love.keypressed(key)
    InputActions.keypressed(key)   -- MUST be first: populates just_pressed for pressed()
    SceneManager.keypressed(key)   -- depends on InputActions state from above
end

function love.keyreleased(key)
    InputActions.keyreleased(key)
end

function love.gamepadpressed(joystick, button)
    InputActions.gamepadpressed(joystick, button)   -- MUST be first: populates just_pressed for pressed()
    SceneManager.keypressed(button)                 -- depends on InputActions state from above
end

function love.gamepadreleased(joystick, button)
    InputActions.gamepadreleased(joystick, button)
end

function love.gamepadaxis(joystick, axis, value)
    InputActions.gamepadaxis(joystick, axis, value)
end
