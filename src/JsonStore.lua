local JsonStore = {}
local dkjson = require("lib.dkjson")

function JsonStore.read(path)
    if not love.filesystem.getInfo(path) then return nil end
    local content, read_err = love.filesystem.read(path)
    if not content then return nil, read_err end
    local tbl, _, json_err = dkjson.decode(content)
    if type(tbl) ~= "table" then return nil, json_err end
    return tbl
end

function JsonStore.write(path, tbl)
    local json, err = dkjson.encode(tbl, { indent = true })
    if not json then return false, err end
    local ok, write_err = pcall(love.filesystem.write, path, json)
    if not ok or write_err == false then return false, write_err end
    return true
end

function JsonStore.delete(path)
    if not love.filesystem.getInfo(path) then return false, "not found" end
    local ok, err = pcall(love.filesystem.remove, path)
    if not ok then return false, err end
    return true
end

return JsonStore
