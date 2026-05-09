local OptionsManager = {}
local JsonStore = require("src.JsonStore")
local OptionsData = require("src.data.OptionsData")
local InputActions = require("src.InputActions")
local Localizer = require("src.Localizer")
local AudioManager = require("src.AudioManager")

local FILE_PATH = "options.json"

function OptionsManager.save(optsData)
    return JsonStore.write(FILE_PATH, optsData:serialize())
end

function OptionsManager.load()
    local tbl = JsonStore.read(FILE_PATH)
    if not tbl then return OptionsData.new_default() end
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
