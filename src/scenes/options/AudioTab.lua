local AudioTab = {}
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")
local AudioManager = require("src.AudioManager")
local Slider = require("src.ui.Slider")

-- ============================================================
-- Mutable state
-- ============================================================
local ctx
local sliders = {}
local slider_focus = 1

-- ============================================================
-- Helpers
-- ============================================================
local function update_slider_focus()
    for i, s in ipairs(sliders) do
        s:setFocus(i == slider_focus)
    end
end

-- ============================================================
-- Interface
-- ============================================================
function AudioTab.activate(c)
    ctx = c
    local TABLE_Y = 180
    local SLIDER_W = 560
    local SLIDER_H = 36
    local SLIDER_X = (1280 - SLIDER_W) / 2
    local SLIDER_Y1 = TABLE_Y
    local SLIDER_Y2 = TABLE_Y + SLIDER_H + 60

    sliders = {}

    sliders[1] = Slider.new({
        x = SLIDER_X,
        y = SLIDER_Y1,
        w = SLIDER_W,
        h = SLIDER_H,
        value = ctx.working_options.music_volume,
        label = Localizer.get("slider_music_volume"),
        on_change = function(v)
            ctx.working_options.music_volume = v
            AudioManager.setMusicVolume(v)
            ctx.dirty = true
        end,
    })

    sliders[2] = Slider.new({
        x = SLIDER_X,
        y = SLIDER_Y2,
        w = SLIDER_W,
        h = SLIDER_H,
        value = ctx.working_options.sfx_volume,
        label = Localizer.get("slider_sfx_volume"),
        on_change = function(v)
            ctx.working_options.sfx_volume = v
            AudioManager.setSfxVolume(v)
            ctx.dirty = true
        end,
    })

    slider_focus = 1
    update_slider_focus()
    ctx.save_btn_rect.y = SLIDER_Y2 + SLIDER_H + 24
end

function AudioTab.deactivate()
    sliders = {}
    slider_focus = 1
    ctx.save_btn_focused = false
end

function AudioTab.update(dt)
    if #sliders == 0 then
        return
    end

    if ctx.save_btn_focused then
        if InputActions.pressed("move_up") then
            ctx.save_btn_focused = false
            slider_focus = #sliders
            update_slider_focus()
            AudioManager.playSfx("select")
        elseif InputActions.pressed("ui_confirm") then
            ctx.save_options()
            AudioManager.playSfx("confirm")
        end
        return
    end

    if InputActions.pressed("move_up") then
        slider_focus = slider_focus == 1 and #sliders or slider_focus - 1
        update_slider_focus()
        AudioManager.playSfx("select")
    elseif InputActions.pressed("move_down") then
        if slider_focus == #sliders then
            if ctx.dirty then
                ctx.save_btn_focused = true
                AudioManager.playSfx("select")
            else
                slider_focus = 1
                update_slider_focus()
                AudioManager.playSfx("select")
            end
        else
            slider_focus = slider_focus + 1
            update_slider_focus()
            AudioManager.playSfx("select")
        end
    end

    for _, s in ipairs(sliders) do
        s:update(dt)
    end
end

function AudioTab.draw()
    if #sliders == 0 then
        return
    end
    love.graphics.push()
    love.graphics.setFont(ctx.cell_font)
    for _, s in ipairs(sliders) do
        s:draw()
    end
    love.graphics.pop()
end

function AudioTab.keypressed(key)
    return false
end

function AudioTab.gamepadpressed(joystick, button)
    return false
end

function AudioTab.gamepadaxis(joystick, axis, value)
    return false
end

function AudioTab.mousemoved(x, y)
    for _, s in ipairs(sliders) do
        s:mousemoved(x, y)
    end
end

function AudioTab.mousepressed(x, y, button)
    for _, s in ipairs(sliders) do
        s:mousepressed(x, y, button)
    end
end

return AudioTab
