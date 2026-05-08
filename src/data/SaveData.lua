local SaveData = {}
SaveData.__index = SaveData

local CURRENT_VERSION = 1

function SaveData.new(name)
    return setmetatable({
        name = name or "Sauvegarde",
        play_time = 0,
        points = 0,
        prestige_count = 0,
        upgrades = {},
    }, SaveData)
end

function SaveData:serialize()
    return {
        version = CURRENT_VERSION,
        name = self.name,
        play_time = self.play_time,
        points = self.points,
        prestige_count = self.prestige_count,
        upgrades = self.upgrades,
    }
end

local function validate(data)
    if type(data) ~= "table" then return false end
    if type(data.name) ~= "string" then return false end
    if type(data.play_time) ~= "number" then return false end
    if type(data.points) ~= "number" then return false end
    if type(data.prestige_count) ~= "number" then return false end
    if type(data.upgrades) ~= "table" then return false end
    for _, u in ipairs(data.upgrades) do
        if type(u.id) ~= "string" or type(u.level) ~= "number" then
            return false
        end
    end
    return true
end

local function clone_upgrades(upgrades)
    local out = {}
    for _, u in ipairs(upgrades) do
        out[#out + 1] = { id = u.id, level = u.level }
    end
    return out
end

function SaveData.deserialize(tbl)
    if not validate(tbl) then
        return nil, "Fichier de sauvegarde corrompu"
    end
    local data = SaveData.new(tbl.name)
    data.play_time = tbl.play_time
    data.points = tbl.points
    data.prestige_count = tbl.prestige_count
    data.upgrades = clone_upgrades(tbl.upgrades)
    return data
end

return SaveData
