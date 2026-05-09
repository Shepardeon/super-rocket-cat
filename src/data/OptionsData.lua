local OptionsData = {}
OptionsData.__index = OptionsData

local CURRENT_VERSION = 1

local InputActions = require("src.InputActions")

local function deep_copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = deep_copy(v)
    end
    return out
end

function OptionsData.new(opts)
    opts = opts or {}
    return setmetatable({
        language = opts.language or "fr",
        music_volume = opts.music_volume or 0.5,
        sfx_volume = opts.sfx_volume or 0.5,
        mappings = opts.mappings and deep_copy(opts.mappings) or InputActions.getDefaultMappings(),
        axis_bindings = opts.axis_bindings and deep_copy(opts.axis_bindings) or InputActions.getDefaultAxisBindings(),
    }, OptionsData)
end

function OptionsData.new_default()
    return OptionsData.new()
end

function OptionsData:clone()
    return OptionsData.new({
        language = self.language,
        music_volume = self.music_volume,
        sfx_volume = self.sfx_volume,
        mappings = deep_copy(self.mappings),
        axis_bindings = deep_copy(self.axis_bindings),
    })
end

function OptionsData:serialize()
    return {
        version = CURRENT_VERSION,
        language = self.language,
        music_volume = self.music_volume,
        sfx_volume = self.sfx_volume,
        mappings = deep_copy(self.mappings),
        axis_bindings = deep_copy(self.axis_bindings),
    }
end

local function validate(tbl)
    if type(tbl) ~= "table" then return false end
    if type(tbl.language) ~= "string" then return false end
    if type(tbl.music_volume) ~= "number" then return false end
    if type(tbl.sfx_volume) ~= "number" then return false end
    if type(tbl.mappings) ~= "table" then return false end
    if type(tbl.axis_bindings) ~= "table" then return false end
    for action, mapping in pairs(tbl.mappings) do
        if type(action) ~= "string" then return false end
        if type(mapping) ~= "table" then return false end
        if mapping.key and type(mapping.key) ~= "string" then return false end
        if mapping.gamepad and type(mapping.gamepad) ~= "string" then return false end
    end
    for action, binding in pairs(tbl.axis_bindings) do
        if type(action) ~= "string" then return false end
        if type(binding) ~= "table" then return false end
        if type(binding.axis) ~= "string" then return false end
        if type(binding.threshold) ~= "number" then return false end
    end
    return true
end

function OptionsData.deserialize(tbl)
    if not validate(tbl) then
        return nil, "Options file corrupted"
    end
    return OptionsData.new({
        language = tbl.language,
        music_volume = tbl.music_volume,
        sfx_volume = tbl.sfx_volume,
        mappings = tbl.mappings,
        axis_bindings = tbl.axis_bindings,
    }), nil
end

return OptionsData
