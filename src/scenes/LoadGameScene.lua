local LoadGameScene = {}
local InputActions = require("src.InputActions")
local SaveManager = require("src.SaveManager")

local saves = {}
local selected = 1

function LoadGameScene.load()
    saves = SaveManager.listSaves()
    selected = 1
end

function LoadGameScene.unload() end

function LoadGameScene.update(dt) end

function LoadGameScene.keypressed(key)
    if InputActions.pressed("ui_back") then
        local SceneManager = require("src.SceneManager")
        SceneManager.pop()
        return
    end

    if #saves == 0 then return end

    if InputActions.pressed("move_down") then
        selected = selected % #saves + 1
    elseif InputActions.pressed("move_up") then
        selected = ((selected - 2) % #saves) + 1
    elseif InputActions.pressed("ui_confirm") then
        local SlotScene = require("src.scenes.UpgradesScene")
        local SceneManager = require("src.SceneManager")
        SceneManager.switch(SlotScene)
    end
end

local function format_time(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

function LoadGameScene.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Continuer", 0, 50, 1280, "center")

    if #saves == 0 then
        love.graphics.printf("Aucune sauvegarde", 0, 300, 1280, "center")
        love.graphics.printf("Echap pour retourner", 0, 340, 1280, "center")
        return
    end

    for i, slot in ipairs(saves) do
        local data, err = SaveManager.load(slot)
        if data then
            local y = 150 + (i - 1) * 50
            if i == selected then
                love.graphics.setColor(1, 0.8, 0.2)
                love.graphics.printf("> ", 0, y, 1280, "center")
            else
                love.graphics.setColor(1, 1, 1)
            end
            local global_level = 0
            for _, u in ipairs(data.upgrades) do
                global_level = global_level + u.level
            end
            local text = string.format("%s  |  Niveau %d  |  %s", data.name, global_level, format_time(data.play_time))
            love.graphics.printf(text, 0, y, 1280, "center")
        end
    end
end

return LoadGameScene
