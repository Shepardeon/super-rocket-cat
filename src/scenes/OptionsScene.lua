local OptionsScene = {}
local InputActions = require("src.InputActions")
local SceneManager = require("src.SceneManager")
local Localizer = require("src.Localizer")
local AudioManager = require("src.AudioManager")
local OptionsManager = require("src.OptionsManager")
local ConfirmDialog = require("src.ui.ConfirmDialog")
local OptionsData = require("data.OptionsData")

-- Tabs
local tabs = {
    { key = "tab_controls", id = "controls", enabled = true },
    { key = "tab_audio", id = "audio", enabled = false },
    { key = "tab_language", id = "language", enabled = false },
}

local active_tab
local tab_rects = {}

-- Options state
local original_options
local working_options
local dirty = false
local dialog

-- Configurable actions
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

-- Listening state
local listening = false
local listening_row
local listening_col
local listening_timer = 0

-- Cell grid
local cell_rects = {}

-- Save button
local SAVE_BTN_W = 200
local SAVE_BTN_H = 40
local save_btn_rect = { x = 0, y = 0, w = SAVE_BTN_W, h = SAVE_BTN_H }
local save_btn_hover = false

-- Display name maps
local key_display = {
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

local gamepad_display = {
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

local axis_display = {
    leftx = "Stick X",
    lefty = "Stick Y",
    rightx = "Stick RX",
    righty = "Stick RY",
    triggerleft = "Trig L",
    triggerright = "Trig R",
}

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

-- Layout constants
local TITLE_Y = 50
local TAB_Y = 110
local TAB_W = 200
local TAB_H = 36
local TAB_SPACING = 20
local TABLE_Y = 180
local ROW_H = 36
local COL_W = 156
local COL_SPACING = 8
local HEADER_H = 28

local title_font
local tab_font
local cell_font
local header_font

-- Tab helpers
local function tab_count()
    return #tabs
end

local function compute_tab_rects()
    local total_w = tab_count() * TAB_W + (tab_count() - 1) * TAB_SPACING
    local start_x = (1280 - total_w) / 2
    tab_rects = {}
    for i in ipairs(tabs) do
        local x = start_x + (i - 1) * (TAB_W + TAB_SPACING)
        tab_rects[i] = { x = x, y = TAB_Y, w = TAB_W, h = TAB_H }
    end
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

local function compute_save_btn_rect()
    local table_bottom = TABLE_Y + HEADER_H + 4 + #configurable_actions * ROW_H
    save_btn_rect.x = (1280 - SAVE_BTN_W) / 2
    save_btn_rect.y = table_bottom + 24
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

-- Override helpers
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

local function save_options()
    OptionsManager.save(working_options)
    original_options = working_options:clone()
    dirty = false
end

local function end_listening()
    listening = false
    listening_row = nil
    listening_col = nil
    listening_timer = 0
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

-- Scene lifecycle
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
    selected_row = 1
    selected_col = COL_KEY
    end_listening()
    save_btn_hover = false
    compute_tab_rects()
    compute_cell_rects()
    compute_save_btn_rect()
end

function OptionsScene.unload()
    tab_rects = {}
    cell_rects = {}
    original_options = nil
    working_options = nil
    dirty = false
    dialog = nil
    end_listening()
end

function OptionsScene.update(dt)
    if dialog and dialog:isOpen() then
        dialog:update(dt)
        return
    end

    if listening then
        listening_timer = listening_timer + dt
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
        end
    elseif InputActions.pressed("move_left") then
        if selected_col > COL_ACTION then
            selected_col = selected_col - 1
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("move_right") then
        if selected_col < COL_COUNT then
            selected_col = selected_col + 1
            AudioManager.playSfx("select")
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

function OptionsScene.keypressed(key)
    if dialog and dialog:isOpen() then
        return
    end

    if listening then
        if key == "escape" then
            end_listening()
            return
        end
        if listening_col == COL_KEY then
            assign_key(configurable_actions[listening_row], key)
            end_listening()
        end
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
    if listening and listening_col == COL_GAMEPAD then
        assign_gamepad(configurable_actions[listening_row], button)
        end_listening()
    end
end

function OptionsScene.gamepadaxis(joystick, axis, value)
    if dialog and dialog:isOpen() then
        return
    end
    if listening and listening_col == COL_AXIS and math.abs(value) >= 0.5 then
        assign_axis(configurable_actions[listening_row], axis, value)
        end_listening()
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

    local row, col = find_cell(x, y)
    if row and col then
        selected_row = row
        selected_col = col
        return
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

    local row, col = find_cell(x, y)
    if row and col and col ~= COL_ACTION then
        selected_row = row
        selected_col = col
        listening = true
        listening_row = row
        listening_col = col
        listening_timer = 0
        return
    end

    for i, rect in ipairs(tab_rects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if tabs[i].enabled then
                active_tab = i
            end
            return
        end
    end
end

-- Drawing helpers
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

local function draw_cell_text(x, y, w, h, text)
    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    local tx = x + (w - tw) / 2
    local ty = y + (h - th) / 2
    love.graphics.print(text, tx, ty)
end

local function draw_controls_table()
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

        local is_selected = not listening and row == selected_row
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

local function draw_save_button()
    if not dirty then
        return
    end

    love.graphics.setFont(cell_font)
    if save_btn_hover then
        love.graphics.setColor(0.3, 0.7, 0.3)
    else
        love.graphics.setColor(0.2, 0.5, 0.2)
    end
    love.graphics.rectangle("fill", save_btn_rect.x, save_btn_rect.y, save_btn_rect.w, save_btn_rect.h)
    love.graphics.setColor(1, 1, 1)
    draw_cell_text(save_btn_rect.x, save_btn_rect.y, save_btn_rect.w, save_btn_rect.h, Localizer.get("btn_save"))
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

    local active_id = tabs[active_tab].id
    if active_id == "controls" then
        draw_controls_table()
        draw_save_button()
    elseif active_id == "audio" or active_id == "language" then
        love.graphics.setFont(cell_font)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf(Localizer.get("tab_coming_soon"), 0, TABLE_Y + 60, 1280, "center")
    end

    love.graphics.setFont(cell_font)
    love.graphics.setColor(0.45, 0.45, 0.45)
    love.graphics.printf(Localizer.get("back_hint"), 0, 680, 1280, "center")
end

return OptionsScene
