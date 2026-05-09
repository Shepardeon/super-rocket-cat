local SaveManager = {}
local JsonStore = require("src.JsonStore")
local SaveData = require("src.data.SaveData")

local CURRENT_VERSION = 1

SaveManager.currentSlot = nil

local migrations = {}

local function path_for_slot(slot)
    return string.format("save_%03d.json", slot)
end

local function migrate(data)
    local v = data.version or 0
    while v < CURRENT_VERSION do
        local fn = migrations[v]
        if not fn then
            return nil, string.format("Migration impossible depuis la version %d", v)
        end
        local ok, result = pcall(fn, data)
        if not ok then
            return nil, string.format("Erreur migration v%d -> v%d", v, v + 1)
        end
        data = result
        v = v + 1
    end
    data.version = CURRENT_VERSION
    return data
end

function SaveManager.save(slot, saveData)
    local path = path_for_slot(slot)
    return JsonStore.write(path, saveData:serialize())
end

function SaveManager.load(slot)
    local path = path_for_slot(slot)
    local tbl = JsonStore.read(path)
    if not tbl then return nil, "Aucune sauvegarde trouvee" end
    local err
    tbl, err = migrate(tbl)
    if not tbl then return nil, err end
    return SaveData.deserialize(tbl)
end

function SaveManager.listSaves()
    local files = love.filesystem.getDirectoryItems("")
    local saves = {}
    for _, f in ipairs(files) do
        local slot = string.match(f, "^save_(%d+)%.json$")
        if slot then
            saves[#saves + 1] = tonumber(slot)
        end
    end
    table.sort(saves)
    return saves
end

function SaveManager.listMeta()
    local files = love.filesystem.getDirectoryItems("")
    local metas = {}
    for _, f in ipairs(files) do
        local slot = string.match(f, "^save_(%d+)%.json$")
        if slot then
            slot = tonumber(slot)
            local tbl = JsonStore.read(f)
            if tbl then
                if type(tbl.meta) == "table" then
                    tbl.meta.slot = slot
                    metas[#metas + 1] = tbl.meta
                else
                    metas[#metas + 1] = {
                        slot = slot,
                        name = tbl.name or "Sauvegarde",
                        play_time = tbl.play_time or 0,
                        global_level = SaveData.computeGlobalLevel(tbl.upgrades),
                    }
                end
            end
        end
    end
    table.sort(metas, function(a, b) return a.slot < b.slot end)
    return metas
end

function SaveManager.deleteSave(slot)
    return JsonStore.delete(path_for_slot(slot))
end

return SaveManager
