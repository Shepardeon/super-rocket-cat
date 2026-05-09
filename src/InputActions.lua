local InputActions = {}

local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = deep_copy(v)
    end
    return out
end

local default_mappings = {
    move_left = { key = "left", gamepad = "dpleft" },
    move_right = { key = "right", gamepad = "dpright" },
    move_up = { key = "up", gamepad = "dpup" },
    move_down = { key = "down", gamepad = "dpdown" },
    qte_action = { key = "space", gamepad = "a" },
    pause = { key = "escape", gamepad = "start" },
    ui_confirm = { key = "return", gamepad = "a" },
    ui_back = { key = "escape", gamepad = "b" },
    ui_delete = { key = "delete", gamepad = "y" },
}

local default_axis_bindings = {
    move_left = { axis = "leftx", threshold = -0.5 },
    move_right = { axis = "leftx", threshold = 0.5 },
    move_up = { axis = "lefty", threshold = -0.5 },
    move_down = { axis = "lefty", threshold = 0.5 },
}

local mappings = deep_copy(default_mappings)

local axis_bindings = deep_copy(default_axis_bindings)

local keys = {}
local buttons = {}
local axes = {}
local just_pressed = {}
local axis_states = {}

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
    for action, binding in pairs(axis_bindings) do
        if binding.axis == axis then
            local was = axis_states[action] or false
            local is = binding.threshold > 0 and value > binding.threshold or binding.threshold < 0 and value < binding.threshold
            if is and not was then
                just_pressed[action] = true
            end
            axis_states[action] = is
        end
    end
end

function InputActions.pressed(action)
    return just_pressed[action] == true
end

function InputActions.isDown(action)
    local mapping = mappings[action]
    if not mapping then
        return false
    end
    if mapping.key and keys[mapping.key] then
        return true
    end
    if mapping.gamepad and buttons[mapping.gamepad] then
        return true
    end
    local axis = axis_bindings[action]
    if axis then
        local val = axes[axis.axis]
        if val then
            if axis.threshold > 0 and val > axis.threshold then
                return true
            end
            if axis.threshold < 0 and val < axis.threshold then
                return true
            end
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

function InputActions.getAxisBinding(action)
    return axis_bindings[action]
end

function InputActions.clearPressed()
    just_pressed = {}
end

function InputActions.getAllMappings()
    return deep_copy(mappings)
end

function InputActions.setAllMappings(tbl)
    mappings = deep_copy(tbl)
end

function InputActions.getAllAxisBindings()
    return deep_copy(axis_bindings)
end

function InputActions.setAllAxisBindings(tbl)
    axis_bindings = deep_copy(tbl)
end

function InputActions.getDefaultMappings()
    return deep_copy(default_mappings)
end

function InputActions.getDefaultAxisBindings()
    return deep_copy(default_axis_bindings)
end

return InputActions
