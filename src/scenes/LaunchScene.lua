local LaunchScene = {}
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")

function LaunchScene.load()
end

function LaunchScene.unload()
end

function LaunchScene.update(dt)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        local UpgradesScene = require("src.scenes.UpgradesScene")
        SceneManager.switch(UpgradesScene)
    end
end

function LaunchScene.draw()
    local fh = love.graphics.getFont():getHeight()
    love.graphics.setColor(0.08, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    love.graphics.setColor(0.6, 0.6, 0.7)
    love.graphics.printf("LaunchScene", 0, 300, 1280, "center")
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.printf("(to be implemented)", 0, 330, 1280, "center")

    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.printf(Localizer.get("upgrades_back") .. " (" .. Localizer.get("back_hint") .. ")", 0, 400, 1280, "center")

    local btn_w, btn_h = 200, 50
    local btn_x = (1280 - btn_w) / 2
    local btn_y = 450
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", btn_x, btn_y, btn_w, btn_h, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(Localizer.get("upgrades_back"), btn_x, btn_y + btn_h / 2 - fh / 2, btn_w, "center")
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("line", btn_x, btn_y, btn_w, btn_h, 6)
end

function LaunchScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    local btn_w, btn_h = 200, 50
    local btn_x = (1280 - btn_w) / 2
    local btn_y = 450
    if x >= btn_x and x <= btn_x + btn_w and y >= btn_y and y <= btn_y + btn_h then
        local SceneManager = require("src.SceneManager")
        local UpgradesScene = require("src.scenes.UpgradesScene")
        SceneManager.switch(UpgradesScene)
    end
end

return LaunchScene
