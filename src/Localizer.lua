local Localizer = {}

local translations = {}
local current_lang = "fr"

function Localizer.setLanguage(lang)
    current_lang = lang
end

function Localizer.getLanguage()
    return current_lang
end

function Localizer.get(key)
    local tbl = translations[current_lang]
    if tbl then
        return tbl[key] or key
    end
    return key
end

local languages = { "fr", "en" }
for _, lang in ipairs(languages) do
    package.loaded["src.i18n." .. lang] = nil
    local ok, tbl = pcall(require, "src.i18n." .. lang)
    if ok then
        translations[lang] = tbl
    end
end

return Localizer
