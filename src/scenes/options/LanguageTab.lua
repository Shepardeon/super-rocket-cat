local LanguageTab = {}
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")
local AudioManager = require("src.AudioManager")

-- ============================================================
-- Layout
-- ============================================================
local TABLE_Y = 180
local LANG_ROW_W = 300
local LANG_ROW_H = 40
local LANG_SPACING = 16

-- ============================================================
-- Mutable state
-- ============================================================
local ctx
local language_options = {
    { key = "lang_en", value = "en" },
    { key = "lang_fr", value = "fr" },
}
local lang_selected = 1
local lang_hover
local lang_rects = {}

-- ============================================================
-- Helpers
-- ============================================================
local function compute_lang_rects()
    local total_h = #language_options * LANG_ROW_H + (#language_options - 1) * LANG_SPACING
    local start_y = TABLE_Y + (300 - total_h) / 2
    local start_x = (1280 - LANG_ROW_W) / 2
    lang_rects = {}
    for i in ipairs(language_options) do
        lang_rects[i] = {
            x = start_x,
            y = start_y + (i - 1) * (LANG_ROW_H + LANG_SPACING),
            w = LANG_ROW_W,
            h = LANG_ROW_H,
        }
    end
end

local function apply_language()
    local opt = language_options[lang_selected]
    if opt.value ~= ctx.working_options.language then
        ctx.working_options.language = opt.value
        Localizer.setLanguage(opt.value)
        ctx.dirty = true
        ctx.on_language_change()
        AudioManager.playSfx("confirm")
    end
end

-- ============================================================
-- Interface
-- ============================================================
function LanguageTab.activate(c)
    ctx = c
    for i, opt in ipairs(language_options) do
        if opt.value == ctx.working_options.language then
            lang_selected = i
            break
        end
    end
    lang_hover = nil
    compute_lang_rects()
    local last = lang_rects[#lang_rects]
    ctx.save_btn_rect.y = (last and last.y + last.h or TABLE_Y) + 24
end

function LanguageTab.deactivate()
    lang_rects = {}
    lang_hover = nil
    ctx.save_btn_focused = false
end

function LanguageTab.update(dt)
    if ctx.save_btn_focused then
        if InputActions.pressed("move_up") then
            ctx.save_btn_focused = false
            lang_selected = #language_options
            AudioManager.playSfx("select")
        elseif InputActions.pressed("ui_confirm") then
            ctx.save_options()
            AudioManager.playSfx("confirm")
        end
        return
    end

    if InputActions.pressed("move_up") then
        if lang_selected > 1 then
            lang_selected = lang_selected - 1
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("move_down") then
        if lang_selected < #language_options then
            lang_selected = lang_selected + 1
            AudioManager.playSfx("select")
        elseif ctx.dirty then
            ctx.save_btn_focused = true
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("ui_confirm") then
        apply_language()
    end
end

function LanguageTab.draw()
    if #lang_rects == 0 then
        return
    end
    love.graphics.setFont(ctx.cell_font)
    for i, opt in ipairs(language_options) do
        local r = lang_rects[i]
        if not r then
            break
        end

        local is_cursor = i == lang_selected
        local is_hover = i == lang_hover
        local is_actual = ctx.working_options.language == opt.value

        if is_cursor or is_hover then
            love.graphics.setColor(0.3, 0.5, 0.9, is_cursor and 0.4 or 0.2)
            love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
        end

        local cx = r.x + 20
        local cy = r.y + r.h / 2
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", cx, cy, 8)
        if is_actual then
            love.graphics.circle("fill", cx, cy, 5)
        end

        local label = Localizer.get(opt.key)
        love.graphics.printf(label, r.x + 40, r.y + (r.h - ctx.cell_font:getHeight()) / 2, LANG_ROW_W - 50, "left")
    end
end

function LanguageTab.keypressed(key)
    return false
end

function LanguageTab.mousemoved(x, y)
    lang_hover = nil
    for i, r in ipairs(lang_rects) do
        if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            lang_hover = i
            lang_selected = i
            return
        end
    end
end

function LanguageTab.mousepressed(x, y, button)
    if button ~= 1 then
        return false
    end
    for i, r in ipairs(lang_rects) do
        if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            lang_selected = i
            apply_language()
            return true
        end
    end
    return false
end

return LanguageTab
