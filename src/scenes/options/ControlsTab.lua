local ControlsTab = {}
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")
local AudioManager = require("src.AudioManager")

-- ============================================================
-- Layout constants
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

-- ============================================================
-- Mutable state
-- ============================================================
local ctx
local selected_row = 1
local selected_col = COL_KEY
local listening = false
local listening_row
local listening_col
local listening_timer = 0
local cell_rects = {}
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

-- ============================================================
-- Helpers
-- ============================================================
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

local function draw_cell_text(x, y, w, h, text)
    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    local tx = x + (w - tw) / 2
    local ty = y + (h - th) / 2
    love.graphics.print(text, tx, ty)
end

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

local function unbind_conflicts(tbl, field, value)
    for _, entry in pairs(tbl) do
        if entry and entry[field] == value then
            entry[field] = nil
        end
    end
end

local function assign_key(action, key)
    local wm = ctx.working_options.mappings
    unbind_conflicts(wm, "key", key)
    if not wm[action] then wm[action] = {} end
    wm[action].key = key
    InputActions.setAllMappings(wm)
    ctx.dirty = true
end

local function assign_gamepad(action, button)
    local wm = ctx.working_options.mappings
    unbind_conflicts(wm, "gamepad", button)
    if not wm[action] then wm[action] = {} end
    wm[action].gamepad = button
    InputActions.setAllMappings(wm)
    ctx.dirty = true
end

local function assign_axis(action, axis, value)
    local threshold = value > 0 and 0.5 or -0.5
    local wab = ctx.working_options.axis_bindings
    for a, b in pairs(wab) do
        if b and b.axis == axis and b.threshold == threshold then
            wab[a] = nil
        end
    end
    wab[action] = { axis = axis, threshold = threshold }
    InputActions.setAllAxisBindings(wab)
    ctx.dirty = true
end

-- ============================================================
-- Interface
-- ============================================================
function ControlsTab.activate(c)
    ctx = c
    selected_row = 1
    selected_col = COL_KEY
    end_listening()
    rebuild_display_maps()
    compute_cell_rects()
    local table_bottom = TABLE_Y + HEADER_H + 4 + #configurable_actions * ROW_H
    ctx.save_btn_rect.y = table_bottom + 24
end

function ControlsTab.deactivate()
    end_listening()
    ctx.save_btn_focused = false
end

function ControlsTab.update(dt)
    if listening then
        listening_timer = listening_timer + dt
        return
    end

    if ctx.save_btn_focused then
        if InputActions.pressed("move_up") then
            ctx.save_btn_focused = false
            selected_row = #configurable_actions
            AudioManager.playSfx("select")
        elseif InputActions.pressed("ui_confirm") then
            ctx.save_options()
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
        elseif ctx.dirty then
            ctx.save_btn_focused = true
            AudioManager.playSfx("select")
        end
    elseif InputActions.pressed("move_left") then
        if selected_col > COL_ACTION then
            selected_col = selected_col - 1
            AudioManager.playSfx("select")
        elseif ctx.switch_tab then
            ctx.switch_tab(-1)
        end
    elseif InputActions.pressed("move_right") then
        if selected_col < COL_COUNT then
            selected_col = selected_col + 1
            AudioManager.playSfx("select")
        elseif ctx.switch_tab then
            ctx.switch_tab(1)
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

function ControlsTab.draw()
    if not cell_rects[1] then
        return
    end

    love.graphics.setFont(ctx.header_font)
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

    love.graphics.setFont(ctx.cell_font)

    for row in ipairs(configurable_actions) do
        local action = configurable_actions[row]
        local mapping = ctx.working_options.mappings[action]
        local axis_binding = ctx.working_options.axis_bindings[action]

        local is_selected = not listening and not ctx.save_btn_focused and row == selected_row
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

function ControlsTab.keypressed(key)
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

function ControlsTab.gamepadpressed(joystick, button)
    if not listening or listening_col ~= COL_GAMEPAD then
        return false
    end
    assign_gamepad(configurable_actions[listening_row], button)
    end_listening()
    return true
end

function ControlsTab.gamepadaxis(joystick, axis, value)
    if not listening or listening_col ~= COL_AXIS or math.abs(value) < 0.5 then
        return false
    end
    assign_axis(configurable_actions[listening_row], axis, value)
    end_listening()
    return true
end

function ControlsTab.mousemoved(x, y)
    local row, col = find_cell(x, y)
    if row and col then
        selected_row = row
        selected_col = col
    end
end

function ControlsTab.mousepressed(x, y, button)
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

return ControlsTab
