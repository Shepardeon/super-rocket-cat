local OptionsManager = {}
local dkjson = require("lib.dkjson")
local OptionsData = require("src.data.OptionsData")
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")
local AudioManager = require("src.AudioManager")

local FILE_PATH = "options.json"

function OptionsManager.save(optsData)
    local tbl = optsData:serialize()
    local json, err = dkjson.encode(tbl, { indent = true })
    if not json then
        return false, "Serialization error: " .. tostring(err)
    end
    local ok, write_err = pcall(love.filesystem.write, FILE_PATH, json)
    if not ok or write_err == false then
        return false, "Write error: " .. tostring(write_err)
    end
    return true
end

function OptionsManager.load()
    if not love.filesystem.getInfo(FILE_PATH) then
        return OptionsData.new_default(), nil
    end
    local content, read_err = love.filesystem.read(FILE_PATH)
    if not content then
        return OptionsData.new_default(), "Read error: " .. tostring(read_err)
    end
    local tbl, _, json_err = dkjson.decode(content)
    if type(tbl) ~= "table" then
        return OptionsData.new_default(), "Corrupted options file: " .. tostring(json_err)
    end
    return OptionsData.deserialize(tbl)
end

function OptionsManager.apply(optsData)
    InputActions.setAllMappings(optsData.mappings)
    InputActions.setAllAxisBindings(optsData.axis_bindings)
    Localizer.setLanguage(optsData.language)
    AudioManager.setMusicVolume(optsData.music_volume)
    AudioManager.setSfxVolume(optsData.sfx_volume)
end

return OptionsManager
