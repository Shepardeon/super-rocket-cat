local OptionsScene = {}
local SceneManager = require("src.SceneManager")
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")
local AudioManager = require("src.AudioManager")
local OptionsManager = require("src.OptionsManager")
local ConfirmDialog = require("src.ui.ConfirmDialog")
local OptionsData = require("src.data.OptionsData")
local ControlsTab = require("src.scenes.options.ControlsTab")
local AudioTab = require("src.scenes.options.AudioTab")
local LanguageTab = require("src.scenes.options.LanguageTab")

-- ============================================================
-- Tabs
-- ============================================================
local tabs = {
    { key = "tab_controls", id = "controls", enabled = true, impl = ControlsTab },
    { key = "tab_audio", id = "audio", enabled = true, impl = AudioTab },
    { key = "tab_language", id = "language", enabled = true, impl = LanguageTab },
}

local active_tab
local tab_rects = {}

-- ============================================================
-- Shared state
-- ============================================================
local original_options
local working_options
local dialog

-- ============================================================
-- Layout constants
-- ============================================================
local TITLE_Y = 50
local TAB_Y = 110
local TAB_W = 200
local TAB_H = 36
local TAB_SPACING = 20

local title_font
local tab_font
local cell_font
local header_font

-- ============================================================
-- Save button
-- ============================================================
local SAVE_BTN_W = 200
local SAVE_BTN_H = 40
local save_btn_rect = { x = (1280 - SAVE_BTN_W) / 2, y = 0, w = SAVE_BTN_W, h = SAVE_BTN_H }
local save_btn_hover = false

-- ============================================================
-- Tab switching
-- ============================================================
local ctx = {} -- Context shared with tabs

local function tab_activate()
    tabs[active_tab].impl.activate(ctx)
end

local function tab_deactivate()
    tabs[active_tab].impl.deactivate()
end

local function switchTab(delta)
    local next = active_tab + delta
    while next >= 1 and next <= #tabs do
        if tabs[next].enabled then
            tab_deactivate()
            active_tab = next
            tab_activate()
            return true
        end
        next = next + delta
    end
    return false
end

-- ============================================================
-- Context shared with tabs
-- ============================================================
local function save_options()
    OptionsManager.save(working_options)
    original_options = working_options:clone()
    ctx.dirty = false
    ctx.save_btn_focused = false
end

local function build_ctx()
    ctx.working_options = working_options
    ctx.save_btn_rect = save_btn_rect
    ctx.cell_font = cell_font
    ctx.header_font = header_font
    ctx.save_options = save_options
    ctx.dirty = false
    ctx.save_btn_focused = false
    ctx.switch_tab = switchTab
    ctx.on_language_change = function()
        tab_deactivate()
        tab_activate()
    end
end

-- ============================================================
-- Shared helpers
-- ============================================================
local function compute_tab_rects()
    local total_w = #tabs * TAB_W + (#tabs - 1) * TAB_SPACING
    local start_x = (1280 - total_w) / 2
    tab_rects = {}
    for i in ipairs(tabs) do
        local x = start_x + (i - 1) * (TAB_W + TAB_SPACING)
        tab_rects[i] = { x = x, y = TAB_Y, w = TAB_W, h = TAB_H }
    end
end

local function draw_cell_text(x, y, w, h, text)
    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    local tx = x + (w - tw) / 2
    local ty = y + (h - th) / 2
    love.graphics.print(text, tx, ty)
end

local function draw_tabs()
    love.graphics.setFont(tab_font)
    for i, tab in ipairs(tabs) do
        local rect = tab_rects[i]
        if not rect then
            break
        end
        local is_active = i == active_tab
        if not tab.enabled then
            love.graphics.setColor(0.35, 0.35, 0.35)
        elseif is_active then
            love.graphics.setColor(0.25, 0.45, 0.85)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
        end
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
        if is_active and tab.enabled then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.printf(
            Localizer.get(tab.key),
            rect.x,
            rect.y + (TAB_H - tab_font:getHeight()) / 2,
            rect.w,
            "center"
        )
    end
end

local function draw_save_button()
    if not ctx.dirty then
        ctx.save_btn_focused = false
        return
    end
    love.graphics.setFont(cell_font)
    if save_btn_hover or ctx.save_btn_focused then
        love.graphics.setColor(0.3, 0.7, 0.3)
    else
        love.graphics.setColor(0.2, 0.5, 0.2)
    end
    love.graphics.rectangle("fill", save_btn_rect.x, save_btn_rect.y, save_btn_rect.w, save_btn_rect.h)
    if ctx.save_btn_focused then
        love.graphics.setColor(1, 1, 0.4)
        love.graphics.rectangle(
            "line",
            save_btn_rect.x - 2,
            save_btn_rect.y - 2,
            save_btn_rect.w + 4,
            save_btn_rect.h + 4
        )
    end
    love.graphics.setColor(1, 1, 1)
    draw_cell_text(save_btn_rect.x, save_btn_rect.y, save_btn_rect.w, save_btn_rect.h, Localizer.get("btn_save"))
end

local function prompt_unsaved()
    dialog = ConfirmDialog.new({
        message = Localizer.get("unsaved_changes"),
        onConfirm = function()
            dialog = nil
            working_options = original_options:clone()
            OptionsManager.apply(working_options)
            ctx.dirty = false
            SceneManager.pop()
        end,
        onCancel = function()
            dialog = nil
        end,
    })
end

-- ============================================================
-- Scene lifecycle
-- ============================================================
function OptionsScene.load()
    title_font = love.graphics.newFont(32)
    tab_font = love.graphics.newFont(18)
    cell_font = love.graphics.newFont(16)
    header_font = love.graphics.newFont(14)
end

function OptionsScene.activate()
    local load_ok, _ = OptionsManager.load()
    if load_ok ~= nil then
        original_options = load_ok
        working_options = original_options:clone()
        OptionsManager.apply(working_options)
    else
        original_options = OptionsData.new_default()
        working_options = original_options:clone()
    end
    dialog = nil
    active_tab = 1
    save_btn_hover = false
    build_ctx()
    compute_tab_rects()
    tab_activate()
end

function OptionsScene.unload()
    tab_deactivate()
    tab_rects = {}
    original_options = nil
    working_options = nil
    dialog = nil
    save_btn_hover = false
end

function OptionsScene.update(dt)
    if dialog and dialog:isOpen() then
        dialog:update(dt)
        return
    end
    tabs[active_tab].impl.update(dt)
end

function OptionsScene.draw()
    if dialog and dialog:isOpen() then
        dialog:draw()
        return
    end
    love.graphics.setFont(title_font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(Localizer.get("options_title"), 0, TITLE_Y, 1280, "center")
    draw_tabs()
    tabs[active_tab].impl.draw()
    draw_save_button()
    love.graphics.setFont(cell_font)
    love.graphics.setColor(0.45, 0.45, 0.45)
    love.graphics.printf(Localizer.get("back_hint"), 0, 680, 1280, "center")
end

function OptionsScene.keypressed(key)
    if dialog and dialog:isOpen() then
        return
    end
    if key == "tab" then
        local lshift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
        switchTab(lshift and -1 or 1)
        return
    end
    local impl = tabs[active_tab].impl
    if impl.keypressed and impl.keypressed(key) then
        return
    end
    if InputActions.pressed("ui_back") then
        if ctx.dirty then
            prompt_unsaved()
        else
            SceneManager.pop()
        end
    end
end

function OptionsScene.gamepadpressed(joystick, button)
    if dialog and dialog:isOpen() then
        return
    end
    if button == "leftshoulder" then
        switchTab(-1)
        return
    end
    if button == "rightshoulder" then
        switchTab(1)
        return
    end
    local impl = tabs[active_tab].impl
    if impl.gamepadpressed then
        impl.gamepadpressed(joystick, button)
    end
end

function OptionsScene.gamepadaxis(joystick, axis, value)
    if dialog and dialog:isOpen() then
        return
    end
    local impl = tabs[active_tab].impl
    if impl.gamepadaxis then
        impl.gamepadaxis(joystick, axis, value)
    end
end

function OptionsScene.mousemoved(x, y)
    if dialog and dialog:isOpen() then
        dialog:mousemoved(x, y)
        return
    end
    save_btn_hover = ctx.dirty
        and x >= save_btn_rect.x
        and x <= save_btn_rect.x + save_btn_rect.w
        and y >= save_btn_rect.y
        and y <= save_btn_rect.y + save_btn_rect.h
    local impl = tabs[active_tab].impl
    if impl.mousemoved then
        impl.mousemoved(x, y)
    end
end

function OptionsScene.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    if dialog and dialog:isOpen() then
        dialog:mousepressed(x, y, button)
        return
    end
    if ctx.dirty and save_btn_hover then
        save_options()
        AudioManager.playSfx("confirm")
        return
    end
    for i, rect in ipairs(tab_rects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if tabs[i].enabled and i ~= active_tab then
                tab_deactivate()
                active_tab = i
                tab_activate()
            end
            return
        end
    end
    local impl = tabs[active_tab].impl
    if impl.mousepressed then
        impl.mousepressed(x, y, button)
    end
end

return OptionsScene
