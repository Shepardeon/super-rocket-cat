local SceneManager = require("src.SceneManager")
local MenuScene = require("src.scenes.MenuScene")
local InputActions = require("src.InputActions")
local AudioManager = require("src.AudioManager")
local OptionsManager = require("src.OptionsManager")

function love.load()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    local opts, _ = OptionsManager.load()
    OptionsManager.apply(opts)
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
    SceneManager.gamepadpressed(joystick, button)   -- direct gamepad event for listening mode
    SceneManager.keypressed(button)                 -- depends on InputActions state from above
end

function love.gamepadreleased(joystick, button)
    InputActions.gamepadreleased(joystick, button)
end

function love.gamepadaxis(joystick, axis, value)
    InputActions.gamepadaxis(joystick, axis, value)
    SceneManager.gamepadaxis(joystick, axis, value)
end

function love.mousemoved(x, y)
    SceneManager.mousemoved(x, y)
end

function love.mousepressed(x, y, button)
    SceneManager.mousepressed(x, y, button)
end
