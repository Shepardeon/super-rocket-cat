local OptionsScene = {}
local InputActions = require("src.InputActions")
local SceneManager = require("src.SceneManager")
local Localizer = require("src.Localizer")
local AudioManager = require("src.AudioManager")
local OptionsManager = require("src.OptionsManager")
local ConfirmDialog = require("src.ui.ConfirmDialog")
local OptionsData = require("src.data.OptionsData")
local Slider = require("src.ui.Slider")

-- ============================================================
-- Tabs
-- ============================================================
local tabs = {
    { key = "tab_controls", id = "controls", enabled = true },
    { key = "tab_audio", id = "audio", enabled = true },
    { key = "tab_language", id = "language", enabled = true },
}

local active_tab
local tab_rects = {}

-- ============================================================
-- Shared options state
-- ============================================================
local original_options
local working_options
local dirty = false
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
-- Display name maps (shared, rebuilt on language change)
-- ============================================================
local key_display = {}
local gamepad_display = {}

local axis_display = {
    leftx = "Stick X",
    lefty = "Stick Y",
    rightx = "Stick RX",
    righty = "Stick RY",
    triggerleft = "Trig L",
    triggerright = "Trig R",
}

local function rebuild_display_maps()
    key_display = {
        left = Localizer.get("input_left"),
        right = Localizer.get("input_right"),
        up = Localizer.get("input_up"),
        down = Localizer.get("input_down"),
        space = "SPACE",
        escape = "ESC",
        ["return"] = "ENTER",
        delete = "DEL",
        backspace = "BKSP",
        tab = "TAB",
        home = "HOME",
        ["end"] = "END",
        pageup = "PG UP",
        pagedown = "PG DN",
        rshift = "R SHIFT",
        lshift = "L SHIFT",
        rctrl = "R CTRL",
        lctrl = "L CTRL",
        ralt = "R ALT",
        lalt = "L ALT",
        comma = ",",
        period = ".",
        minus = "-",
        equals = "=",
        ["["] = "[",
        ["]"] = "]",
        backslash = "\\",
        semicolon = ";",
        apostrophe = "'",
        grave = "`",
        slash = "/",
        a = "A",
        b = "B",
        c = "C",
        d = "D",
        e = "E",
        f = "F",
        g = "G",
        h = "H",
        i = "I",
        j = "J",
        k = "K",
        l = "L",
        m = "M",
        n = "N",
        o = "O",
        p = "P",
        q = "Q",
        r = "R",
        s = "S",
        t = "T",
        u = "U",
        v = "V",
        w = "W",
        x = "X",
        y = "Y",
        z = "Z",
        ["0"] = "0",
        ["1"] = "1",
        ["2"] = "2",
        ["3"] = "3",
        ["4"] = "4",
        ["5"] = "5",
        ["6"] = "6",
        ["7"] = "7",
        ["8"] = "8",
        ["9"] = "9",
    }

    gamepad_display = {
        dpleft = "D-Pad " .. Localizer.get("input_left"),
        dpright = "D-Pad " .. Localizer.get("input_right"),
        dpup = "D-Pad " .. Localizer.get("input_up"),
        dpdown = "D-Pad " .. Localizer.get("input_down"),
        a = "A",
        b = "B",
        x = "X",
        y = "Y",
        start = "START",
        back = "BACK",
        leftshoulder = "LB",
        rightshoulder = "RB",
        lefttrigger = "LT",
        righttrigger = "RT",
        leftstick = "L3",
        rightstick = "R3",
    }
end

local function format_axis(binding)
    if not binding then
        return "-"
    end
    local base = axis_display[binding.axis] or binding.axis
    if binding.threshold > 0 then
        return base .. "+"
    elseif binding.threshold < 0 then
        return base .. "-"
    end
    return base
end

-- ============================================================
-- Save button (shared)
-- ============================================================
local SAVE_BTN_W = 200
local SAVE_BTN_H = 40
local save_btn_rect = { x = (1280 - SAVE_BTN_W) / 2, y = 0, w = SAVE_BTN_W, h = SAVE_BTN_H }
local save_btn_hover = false
local save_btn_focused = false

-- ============================================================
-- Controls tab
-- ============================================================
local TABLE_Y = 180
local ROW_H = 36
local COL_W = 156
local COL_SPACING = 8
local HEADER_H = 28

local configurable_actions = {
    "move_left",
    "move_right",
    "move_up",
    "move_down",
    "qte_action",
    "pause",
}

local COL_ACTION = 1
local COL_KEY = 2
local COL_GAMEPAD = 3
local COL_AXIS = 4
local COL_COUNT = 4

local selected_row = 1
local selected_col = COL_KEY
local listening = false
local listening_row
local listening_col
local listening_timer = 0
local cell_rects = {}

local function end_listening()
    listening = false
    listening_row = nil
    listening_col = nil
    listening_timer = 0
end

local function compute_cell_rects()
    local table_w = COL_COUNT * COL_W + (COL_COUNT - 1) * COL_SPACING
    local start_x = (1280 - table_w) / 2
    cell_rects = {}
    for row in ipairs(configurable_actions) do
        cell_rects[row] = {}
        for col = 1, COL_COUNT do
            local x = start_x + (col - 1) * (COL_W + COL_SPACING)
            local y = TABLE_Y + HEADER_H + 4 + (row - 1) * ROW_H
            cell_rects[row][col] = { x = x, y = y, w = COL_W, h = ROW_H }
        end
    end
end

local function find_cell(x, y)
    for row in ipairs(configurable_actions) do
        for col = 1, COL_COUNT do
            local r = cell_rects[row][col]
            if r and x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
                return row, col
            end
        end
    end
    return nil, nil
end

local function assign_key(action, key)
    local wm = working_options.mappings
    for a, m in pairs(wm) do
        if m and m.key == key then
            m.key = nil
        end
    end
    if not wm[action] then
        wm[action] = {}
    end
    wm[action].key = key
    InputActions.setAllMappings(wm)
    dirty = true
end

local function assign_gamepad(action, button)
    local wm = working_options.mappings
    for a, m in pairs(wm) do
        if m and m.gamepad == button then
            m.gamepad = nil
        end
    end
    if not wm[action] then
        wm[action] = {}
    end
    wm[action].gamepad = button
    InputActions.setAllMappings(wm)
    dirty = true
end

local function assign_axis(action, axis, value)
    local threshold = value > 0 and 0.5 or -0.5
    local wab = working_options.axis_bindings
    for a, b in pairs(wab) do
        if b and b.axis == axis and b.threshold == threshold then
            wab[a] = nil
        end
    end
    wab[action] = { axis = axis, threshold = threshold }
    InputActions.setAllAxisBindings(wab)
    dirty = true
end

local function controls_activate()
    selected_row = 1
    selected_col = COL_KEY
    end_listening()
    rebuild_display_maps()
    compute_cell_rects()
    local table_bottom = TABLE_Y + HEADER_H + 4 + #configurable_actions * ROW_H
    save_btn_rect.y = table_bottom + 24
end

local function controls_deactivate()
    end_listening()
    save_btn_focused = false
end

-- ============================================================
-- Audio tab
-- ============================================================
local sliders = {}
local slider_focus = 1

local function update_slider_focus()
    for i, s in ipairs(sliders) do
        s:setFocus(i == slider_focus)
    end
end

local function audio_activate()
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
        value = working_options.music_volume,
        label = Localizer.get("slider_music_volume"),
        on_change = function(v)
            working_options.music_volume = v
            AudioManager.setMusicVolume(v)
            dirty = true
        end,
    })

    sliders[2] = Slider.new({
        x = SLIDER_X,
        y = SLIDER_Y2,
        w = SLIDER_W,
        h = SLIDER_H,
        value = working_options.sfx_volume,
        label = Localizer.get("slider_sfx_volume"),
        on_change = function(v)
            working_options.sfx_volume = v
            AudioManager.setSfxVolume(v)
            dirty = true
        end,
    })

    slider_focus = 1
    update_slider_focus()
    save_btn_rect.y = SLIDER_Y2 + SLIDER_H + 24
end

local function audio_deactivate()
    sliders = {}
    slider_focus = 1
    save_btn_focused = false
end

local function draw_cell_text(x, y, w, h, text)
    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    local tx = x + (w - tw) / 2
    local ty = y + (h - th) / 2
    love.graphics.print(text, tx, ty)
end

local function draw_save_button()
    if not dirty then
        save_btn_focused = false
        return
    end

    love.graphics.setFont(cell_font)
    if save_btn_hover or save_btn_focused then
        love.graphics.setColor(0.3, 0.7, 0.3)
    else
        love.graphics.setColor(0.2, 0.5, 0.2)
    end
    love.graphics.rectangle("fill", save_btn_rect.x, save_btn_rect.y, save_btn_rect.w, save_btn_rect.h)

    if save_btn_focused then
        love.graphics.setColor(1, 1, 0.4)
        love.graphics.rectangle("line", save_btn_rect.x - 2, save_btn_rect.y - 2, save_btn_rect.w + 4, save_btn_rect.h + 4)
    end

    love.graphics.setColor(1, 1, 1)
    draw_cell_text(save_btn_rect.x, save_btn_rect.y, save_btn_rect.w, save_btn_rect.h, Localizer.get("btn_save"))
end

local function save_options()
    OptionsManager.save(working_options)
    original_options = working_options:clone()
    dirty = false
    save_btn_focused = false
end

local function audio_update(dt)
    if #sliders == 0 then
        return
    end

    if save_btn_focused then
        if InputActions.pressed("move_up") then
            save_btn_focused = false
            slider_focus = #sliders
            update_slider_focus()
            AudioManager.playSfx("select")
        elseif InputActions.pressed("ui_confirm") then
            save_options()
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
            if dirty then
                save_btn_focused = true
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

local function audio_draw()
    if #sliders == 0 then
        return
    end
    love.graphics.push()
    love.graphics.setFont(cell_font)
    for _, s in ipairs(sliders) do
        s:draw()
    end
    love.graphics.pop()
end

local function audio_keypressed(key)
    return false
end

local function audio_gamepadpressed(joystick, button)
    return false
end

local function audio_gamepadaxis(joystick, axis, value)
    return false
end

local function audio_mousemoved(x, y)
    for _, s in ipairs(sliders) do
        s:mousemoved(x, y)
    end
end

local function audio_mousepressed(x, y, button)
    for _, s in ipairs(sliders) do
        s:mousepressed(x, y, button)
    end
end

-- ============================================================
-- Language data (declared before tab switching / apply_language)
-- ============================================================
local language_options = {
    { key = "lang_en", value = "en" },
    { key = "lang_fr", value = "fr" },
}
local lang_selected = 1
local lang_hover
local lang_rects = {}
local LANG_ROW_W = 300
local LANG_ROW_H = 40
local LANG_SPACING = 16

-- ============================================================
-- Language tab (functions needed by tab_activate/deactivate)
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

local function language_activate()
    for i, opt in ipairs(language_options) do
        if opt.value == working_options.language then
            lang_selected = i
            break
        end
    end
    lang_hover = nil
    compute_lang_rects()
    local last = lang_rects[#lang_rects]
    save_btn_rect.y = (last and last.y + last.h or TABLE_Y) + 24
end

local function language_deactivate()
    lang_rects = {}
    lang_hover = nil
    save_btn_focused = false
end

-- ============================================================
-- Tab switching
-- ============================================================
local function tab_activate()
    local id = tabs[active_tab].id
    if id == "controls" then
        controls_activate()
    elseif id == "audio" then
        audio_activate()
    elseif id == "language" then
        language_activate()
    end
end

local function tab_deactivate()
    local id = tabs[active_tab].id
    if id == "controls" then
        controls_deactivate()
    elseif id == "audio" then
        audio_deactivate()
    elseif id == "language" then
        language_deactivate()
    end
end

local function switchTab(delta)
    local next_tab = active_tab + delta
    while next_tab >= 1 and next_tab <= #tabs do
        if tabs[next_tab].enabled then
            tab_deactivate()
            active_tab = next_tab
            tab_activate()
            return true
        end
        next_tab = next_tab + delta
    end
    return false
end

local function apply_language()
    local opt = language_options[lang_selected]
    if opt.value ~= working_options.language then
        working_options.language = opt.value
        Localizer.setLanguage(opt.value)
        dirty = true
        tab_deactivate()
        tab_activate()
        AudioManager.playSfx("confirm")
    end
end

local function language_update(dt)
    if save_btn_focused then
        if InputActions.pressed("move_up") then
            save_btn_focused = false
            lang_selected = #language_options
            AudioManager.playSfx("select")
        elseif InputActions.pressed("ui_confirm") then
            save_options()
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
        elseif dirty then
            save_btn_focused = true
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("ui_confirm") then
        apply_language()
    end
end

local function language_draw()
    if #lang_rects == 0 then
        return
    end
    love.graphics.setFont(cell_font)
    for i, opt in ipairs(language_options) do
        local r = lang_rects[i]
        if not r then
            break
        end

        local is_cursor = i == lang_selected
        local is_hover = i == lang_hover
        local is_actual = working_options.language == opt.value

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
        love.graphics.printf(label, r.x + 40, r.y + (r.h - cell_font:getHeight()) / 2, LANG_ROW_W - 50, "left")
    end
end

local function language_keypressed(key)
    return false
end

local function language_mousemoved(x, y)
    lang_hover = nil
    for i, r in ipairs(lang_rects) do
        if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            lang_hover = i
            lang_selected = i
            return
        end
    end
end

local function language_mousepressed(x, y, button)
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

local function controls_update(dt)
    if listening then
        listening_timer = listening_timer + dt
        return
    end

    if save_btn_focused then
        if InputActions.pressed("move_up") then
            save_btn_focused = false
            selected_row = #configurable_actions
            AudioManager.playSfx("select")
        elseif InputActions.pressed("ui_confirm") then
            save_options()
            AudioManager.playSfx("confirm")
        end
        return
    end

    if InputActions.pressed("move_up") then
        if selected_row > 1 then
            selected_row = selected_row - 1
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("move_down") then
        if selected_row < #configurable_actions then
            selected_row = selected_row + 1
            AudioManager.playSfx("select")
        elseif dirty then
            save_btn_focused = true
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("move_left") then
        if selected_col > COL_ACTION then
            selected_col = selected_col - 1
            AudioManager.playSfx("select")
        else
            switchTab(-1)
        end
    elseif InputActions.pressed("move_right") then
        if selected_col < COL_COUNT then
            selected_col = selected_col + 1
            AudioManager.playSfx("select")
        else
            switchTab(1)
        end
    elseif InputActions.pressed("ui_confirm") then
        if selected_col ~= COL_ACTION then
            listening = true
            listening_row = selected_row
            listening_col = selected_col
            listening_timer = 0
        end
    end
end

local function controls_keypressed(key)
    if listening then
        if key == "escape" then
            end_listening()
            return true
        end
        if listening_col == COL_KEY then
            assign_key(configurable_actions[listening_row], key)
            end_listening()
        end
        return true
    end
    return false
end

local function controls_gamepadpressed(joystick, button)
    if not listening or listening_col ~= COL_GAMEPAD then
        return false
    end
    assign_gamepad(configurable_actions[listening_row], button)
    end_listening()
    return true
end

local function controls_gamepadaxis(joystick, axis, value)
    if not listening or listening_col ~= COL_AXIS or math.abs(value) < 0.5 then
        return false
    end
    assign_axis(configurable_actions[listening_row], axis, value)
    end_listening()
    return true
end

local function controls_mousemoved(x, y)
    local row, col = find_cell(x, y)
    if row and col then
        selected_row = row
        selected_col = col
    end
end

local function controls_mousepressed(x, y, button)
    local row, col = find_cell(x, y)
    if row and col and col ~= COL_ACTION then
        selected_row = row
        selected_col = col
        listening = true
        listening_row = row
        listening_col = col
        listening_timer = 0
        return true
    end
    return false
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

        local label = Localizer.get(tab.key)
        love.graphics.printf(label, rect.x, rect.y + (TAB_H - tab_font:getHeight()) / 2, rect.w, "center")
    end
end

local function prompt_unsaved()
    dialog = ConfirmDialog.new({
        message = Localizer.get("unsaved_changes"),
        onConfirm = function()
            dialog = nil
            working_options = original_options:clone()
            OptionsManager.apply(working_options)
            dirty = false
            SceneManager.pop()
        end,
        onCancel = function()
            dialog = nil
        end,
    })
end

local function controls_draw()
    if not cell_rects[1] then
        return
    end

    love.graphics.setFont(header_font)
    love.graphics.setColor(0.7, 0.7, 0.7)

    local header_labels = {
        Localizer.get("bind_action"),
        Localizer.get("bind_keyboard"),
        Localizer.get("bind_gamepad"),
        Localizer.get("bind_axis"),
    }

    for col = 1, COL_COUNT do
        local r = cell_rects[1][col]
        draw_cell_text(r.x, TABLE_Y, r.w, HEADER_H, header_labels[col])
    end

    love.graphics.setFont(cell_font)

    for row in ipairs(configurable_actions) do
        local action = configurable_actions[row]
        local mapping = working_options.mappings[action]
        local axis_binding = working_options.axis_bindings[action]

        local is_selected = not listening and not save_btn_focused and row == selected_row
        local is_listening_here = listening and row == listening_row

        for col = 1, COL_COUNT do
            local r = cell_rects[row][col]
            if not r then
                break
            end

            local cell_selected = is_selected and col == selected_col
            local cell_listening = is_listening_here and col == listening_col

            if cell_listening then
                local flash = math.floor(listening_timer * 4) % 2 == 0
                love.graphics.setColor(flash and 0.3 or 0.2, flash and 0.55 or 0.4, flash and 0.9 or 0.7, 0.6)
                love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
                love.graphics.setColor(1, 1, 1)
                draw_cell_text(r.x, r.y, r.w, r.h, Localizer.get("listening_hint"))
            elseif cell_selected then
                love.graphics.setColor(0.3, 0.5, 0.9, 0.4)
                love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
            end

            love.graphics.setColor(1, 1, 1)

            if col == COL_ACTION then
                draw_cell_text(r.x, r.y, r.w, r.h, Localizer.get("action_" .. action))
            elseif col == COL_KEY then
                local key = mapping and mapping.key
                draw_cell_text(r.x, r.y, r.w, r.h, key and (key_display[key] or key:upper()) or "-")
            elseif col == COL_GAMEPAD then
                local gp = mapping and mapping.gamepad
                draw_cell_text(r.x, r.y, r.w, r.h, gp and (gamepad_display[gp] or gp:upper()) or "-")
            elseif col == COL_AXIS then
                draw_cell_text(r.x, r.y, r.w, r.h, axis_binding and format_axis(axis_binding) or "-")
            end
        end
    end
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
    dirty = false
    dialog = nil
    active_tab = 1
    save_btn_hover = false
    save_btn_focused = false
    compute_tab_rects()
    tab_activate()
end

function OptionsScene.unload()
    tab_deactivate()
    tab_rects = {}
    original_options = nil
    working_options = nil
    dirty = false
    dialog = nil
    save_btn_hover = false
end

function OptionsScene.update(dt)
    if dialog and dialog:isOpen() then
        dialog:update(dt)
        return
    end

    local id = tabs[active_tab].id
    if id == "controls" then
        controls_update(dt)
    elseif id == "audio" then
        audio_update(dt)
    elseif id == "language" then
        language_update(dt)
    end
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

    local id = tabs[active_tab].id
    if id == "controls" then
        controls_draw()
    elseif id == "audio" then
        audio_draw()
    elseif id == "language" then
        language_draw()
    end

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

    local id = tabs[active_tab].id
    local consumed = false
    if id == "controls" then
        consumed = controls_keypressed(key)
    elseif id == "audio" then
        consumed = audio_keypressed(key)
    elseif id == "language" then
        consumed = language_keypressed(key)
    end
    if consumed then
        return
    end

    if InputActions.pressed("ui_back") then
        if dirty then
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
    elseif button == "rightshoulder" then
        switchTab(1)
        return
    end

    local id = tabs[active_tab].id
    if id == "controls" then
        controls_gamepadpressed(joystick, button)
    elseif id == "audio" then
        audio_gamepadpressed(joystick, button)
    elseif id == "language" then
        language_keypressed(button)
    end
end

function OptionsScene.gamepadaxis(joystick, axis, value)
    if dialog and dialog:isOpen() then
        return
    end

    local id = tabs[active_tab].id
    if id == "controls" then
        controls_gamepadaxis(joystick, axis, value)
    elseif id == "audio" then
        audio_gamepadaxis(joystick, axis, value)
    end
end

function OptionsScene.mousemoved(x, y)
    if dialog and dialog:isOpen() then
        dialog:mousemoved(x, y)
        return
    end

    save_btn_hover = dirty
        and x >= save_btn_rect.x
        and x <= save_btn_rect.x + save_btn_rect.w
        and y >= save_btn_rect.y
        and y <= save_btn_rect.y + save_btn_rect.h

    local id = tabs[active_tab].id
    if id == "controls" then
        controls_mousemoved(x, y)
    elseif id == "audio" then
        audio_mousemoved(x, y)
    elseif id == "language" then
        language_mousemoved(x, y)
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

    if dirty and save_btn_hover then
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

    local id = tabs[active_tab].id
    if id == "controls" then
        controls_mousepressed(x, y, button)
    elseif id == "audio" then
        audio_mousepressed(x, y, button)
    elseif id == "language" then
        language_mousepressed(x, y, button)
    end
end

return OptionsScene
