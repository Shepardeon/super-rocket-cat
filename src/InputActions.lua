local InputActions = {}

local mappings = {
    move_left   = { key = "left",   gamepad = "dpleft" },
    move_right  = { key = "right",  gamepad = "dpright" },
    qte_action  = { key = "space",  gamepad = "a" },
    pause       = { key = "escape", gamepad = "start" },
    ui_confirm  = { key = "return", gamepad = "a" },
    ui_back     = { key = "escape", gamepad = "b" },
}

local axis_bindings = {
    move_left  = { axis = "leftx", threshold = -0.5 },
    move_right = { axis = "leftx", threshold = 0.5 },
}

local keys = {}
local buttons = {}
local axes = {}
local just_pressed = {}

local function findActions(key, field)
    for action, mapping in pairs(mappings) do
        if mapping[field] == key then
            just_pressed[action] = true
        end
    end
end

function InputActions.keypressed(key)
    keys[key] = true
    findActions(key, "key")
end

function InputActions.keyreleased(key)
    keys[key] = nil
end

function InputActions.gamepadpressed(joystick, button)
    buttons[button] = true
    findActions(button, "gamepad")
end

function InputActions.gamepadreleased(joystick, button)
    buttons[button] = nil
end

function InputActions.gamepadaxis(joystick, axis, value)
    axes[axis] = value
end

function InputActions.pressed(action)
    return just_pressed[action] == true
end

function InputActions.isDown(action)
    local mapping = mappings[action]
    if not mapping then return false end
    if mapping.key and keys[mapping.key] then return true end
    if mapping.gamepad and buttons[mapping.gamepad] then return true end
    local axis = axis_bindings[action]
    if axis then
        local val = axes[axis.axis]
        if val then
            if axis.threshold > 0 and val > axis.threshold then return true end
            if axis.threshold < 0 and val < axis.threshold then return true end
        end
    end
    return false
end

function InputActions.setMapping(action, mapping)
    mappings[action] = mapping
end

function InputActions.getMapping(action)
    return mappings[action]
end

function InputActions.clearPressed()
    just_pressed = {}
end

return InputActions
