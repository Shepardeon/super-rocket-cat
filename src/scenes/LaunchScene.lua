local LaunchScene = {}
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")
local SaveManager = require("src.SaveManager")
local Upgrades = require("src.game.Upgrades")
local RocketVisual = require("src.game.RocketVisual")
local QTE = require("src.game.QTE")
local AudioManager = require("src.AudioManager")
local C = require("src.constants")

local save_data = nil
local qte = nil

local QTE_BAR_W = 600
local QTE_BAR_X = (1280 - QTE_BAR_W) / 2
local QTE_BAR_Y = 530

local BTN_W = 200
local BTN_H = 50
local BTN_X = (1280 - BTN_W) / 2

function LaunchScene.load()
    if SaveManager.currentSlot then
        save_data = SaveManager.load(SaveManager.currentSlot)
    end
    qte = QTE.new()
end

function LaunchScene.unload()
    save_data = nil
    qte = nil
end

function LaunchScene.update(dt)
    if qte and qte:isActive() then
        qte:update(dt)
        if InputActions.pressed("qte_action") then
            local result = qte:trigger()
            AudioManager.playSfx(result == "red" and "qte_fail" or "qte_ok")
        end
        return
    end

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

    if save_data then
        local rocket_w = 250
        local rocket_h = math.floor(rocket_w * (C.SCREEN_H - C.HEADER_H) / C.LEFT_W)
        local rocket_x = (1280 - rocket_w) / 2
        local rocket_y = 100
        RocketVisual.draw(rocket_x, rocket_y, rocket_w, rocket_h, Upgrades.get_all_levels(save_data.upgrades))
    end

    if not qte then
        return
    end

    qte:draw(QTE_BAR_X, QTE_BAR_Y, QTE_BAR_W)

    if qte:isActive() then
        local mapping = InputActions.getMapping("qte_action")
        local key_name = (mapping and mapping.key) or "space"
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.printf(Localizer.getFormatted("qte_prompt", key_name:upper()), 0, QTE_BAR_Y + 30, 1280, "center")
    else
        local result = qte:getResult() or "yellow"
        local rc = QTE.getZoneColor(result)

        love.graphics.setColor(rc[1], rc[2], rc[3])
        love.graphics.printf(Localizer.get("qte_" .. result), 0, QTE_BAR_Y + 28, 1280, "center")

        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.printf(Localizer.get("qte_waiting"), 0, QTE_BAR_Y + 50, 1280, "center")

        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.printf(Localizer.get("upgrades_back") .. " (" .. Localizer.get("back_hint") .. ")", 0, QTE_BAR_Y + 70, 1280, "center")

        local btn_y = QTE_BAR_Y + 80
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", BTN_X, btn_y, BTN_W, BTN_H, 6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(Localizer.get("upgrades_back"), BTN_X, btn_y + BTN_H / 2 - fh / 2, BTN_W, "center")
        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle("line", BTN_X, btn_y, BTN_W, BTN_H, 6)
    end
end

function LaunchScene.mousepressed(x, y, button)
    if button ~= 1 then return end
    if not qte or qte:isActive() then return end
    local btn_y = QTE_BAR_Y + 80
    if x >= BTN_X and x <= BTN_X + BTN_W and y >= btn_y and y <= btn_y + BTN_H then
        local SceneManager = require("src.SceneManager")
        local UpgradesScene = require("src.scenes.UpgradesScene")
        SceneManager.switch(UpgradesScene)
    end
end

return LaunchScene
