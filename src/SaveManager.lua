local SaveManager = {}
local dkjson = require("lib.dkjson")
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
    local tbl = saveData:serialize()
    local json, err = dkjson.encode(tbl, { indent = true })
    if not json then
        return false, "Erreur serialisation: " .. tostring(err)
    end
    local ok, write_err = pcall(love.filesystem.write, path, json)
    if not ok or write_err == false then
        return false, "Erreur ecriture fichier: " .. tostring(write_err)
    end
    return true
end

function SaveManager.load(slot)
    local path = path_for_slot(slot)
    if not love.filesystem.getInfo(path) then
        return nil, "Aucune sauvegarde trouvee"
    end
    ---@type string, number|string|nil
    local content, read_err = love.filesystem.read(path)
    if not content then
        return nil, "Erreur lecture fichier: " .. tostring(read_err)
    end
    local tbl, _, json_err = dkjson.decode(content)
    if type(tbl) ~= "table" then
        local msg = "Fichier de sauvegarde corrompu"
        if json_err then msg = msg .. ": " .. json_err end
        return nil, msg
    end
    tbl, read_err = migrate(tbl)
    if not tbl then
        return nil, read_err
    end
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
            local content, err = love.filesystem.read(f)
            if content then
                local tbl, _, json_err = dkjson.decode(content)
                if type(tbl) == "table" then
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
    end
    table.sort(metas, function(a, b) return a.slot < b.slot end)
    return metas
end

function SaveManager.deleteSave(slot)
    local path = path_for_slot(slot)
    if not love.filesystem.getInfo(path) then
        return false, "Aucune sauvegarde trouvee"
    end
    local ok, err = pcall(love.filesystem.remove, path)
    if not ok then
        return false, "Erreur suppression: " .. tostring(err)
    end
    return true
end

return SaveManager
