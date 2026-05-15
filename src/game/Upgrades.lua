local Upgrades = {}

local BASE_STATS = {
    max_speed = 50,
    hp = 100,
    fuel = 100,
    maneuverability = 1.0,
    magnet_radius = 0,
    points_multiplier = 1.0,
    auto_repair = 0,
    qte_window = 1.0,
}

local UPGRADE_DEFS = {
    {
        id = "engine",
        name_key = "upgrade_engine_name",
        desc_key = "upgrade_engine_desc",
        stat_display_key = "upgrade_engine_effect",
        stat_display_field = "max_speed",
        max_level = 10,
        base_cost = 10,
        cost_multiplier = 1.5,
        get_cost = function(self, level)
            return math.floor(self.base_cost * (self.cost_multiplier ^ level))
        end,
        stat_effect = function(self, level)
            return { max_speed = level * 10 }
        end,
    },
    {
        id = "hull",
        name_key = "upgrade_hull_name",
        desc_key = "upgrade_hull_desc",
        stat_display_key = "upgrade_hull_effect",
        stat_display_field = "hp",
        max_level = 10,
        base_cost = 8,
        cost_multiplier = 1.6,
        get_cost = function(self, level)
            return math.floor(self.base_cost * (self.cost_multiplier ^ level))
        end,
        stat_effect = function(self, level)
            return { hp = level * 50 }
        end,
    },
    {
        id = "tank",
        name_key = "upgrade_tank_name",
        desc_key = "upgrade_tank_desc",
        stat_display_key = "upgrade_tank_effect",
        stat_display_field = "fuel",
        max_level = 10,
        base_cost = 12,
        cost_multiplier = 1.4,
        get_cost = function(self, level)
            return math.floor(self.base_cost * (self.cost_multiplier ^ level))
        end,
        stat_effect = function(self, level)
            return { fuel = level * 25 }
        end,
    },
    {
        id = "fins",
        name_key = "upgrade_fins_name",
        desc_key = "upgrade_fins_desc",
        stat_display_key = "upgrade_fins_effect",
        stat_display_field = "maneuverability",
        max_level = 10,
        base_cost = 15,
        cost_multiplier = 1.3,
        get_cost = function(self, level)
            return math.floor(self.base_cost * (self.cost_multiplier ^ level))
        end,
        stat_effect = function(self, level)
            return { maneuverability = level * 0.1 }
        end,
    },
    {
        id = "magnet",
        name_key = "upgrade_magnet_name",
        desc_key = "upgrade_magnet_desc",
        stat_display_key = "upgrade_magnet_effect",
        stat_display_field = "magnet_radius",
        max_level = 10,
        base_cost = 20,
        cost_multiplier = 1.5,
        get_cost = function(self, level)
            return math.floor(self.base_cost * (self.cost_multiplier ^ level))
        end,
        stat_effect = function(self, level)
            return { magnet_radius = level * 20 }
        end,
    },
    {
        id = "multiplier",
        name_key = "upgrade_multiplier_name",
        desc_key = "upgrade_multiplier_desc",
        stat_display_key = "upgrade_multiplier_effect",
        stat_display_field = "points_multiplier",
        max_level = 10,
        base_cost = 50,
        cost_multiplier = 1.8,
        get_cost = function(self, level)
            return math.floor(self.base_cost * (self.cost_multiplier ^ level))
        end,
        stat_effect = function(self, level)
            return { points_multiplier = level * 0.5 }
        end,
    },
    {
        id = "auto_repair",
        name_key = "upgrade_auto_repair_name",
        desc_key = "upgrade_auto_repair_desc",
        stat_display_key = "upgrade_auto_repair_effect",
        stat_display_field = "auto_repair",
        max_level = 10,
        base_cost = 25,
        cost_multiplier = 1.6,
        get_cost = function(self, level)
            return math.floor(self.base_cost * (self.cost_multiplier ^ level))
        end,
        stat_effect = function(self, level)
            return { auto_repair = level * 2 }
        end,
    },
    {
        id = "survival_qte",
        name_key = "upgrade_survival_qte_name",
        desc_key = "upgrade_survival_qte_desc",
        stat_display_key = "upgrade_survival_qte_effect",
        stat_display_field = "qte_window",
        max_level = 10,
        base_cost = 30,
        cost_multiplier = 1.7,
        get_cost = function(self, level)
            return math.floor(self.base_cost * (self.cost_multiplier ^ level))
        end,
        stat_effect = function(self, level)
            return { qte_window = level * 0.15 }
        end,
    },
}

function Upgrades.get_all()
    return UPGRADE_DEFS
end

function Upgrades.get_by_id(id)
    for _, def in ipairs(UPGRADE_DEFS) do
        if def.id == id then
            return def
        end
    end
    return nil
end

function Upgrades.get_cost(id, level)
    local def = Upgrades.get_by_id(id)
    if not def then return nil end
    if level >= def.max_level then return nil end
    return def:get_cost(level)
end

function Upgrades.get_display_info(id, level)
    local def = Upgrades.get_by_id(id)
    if not def then return nil end
    local bonus = def:stat_effect(level)
    local base = BASE_STATS[def.stat_display_field] or 0
    local value = base + (bonus[def.stat_display_field] or 0)
    return {
        key = def.stat_display_key,
        value = value,
    }
end

function Upgrades.get_display_info_next(id, level)
    local def = Upgrades.get_by_id(id)
    if not def then return nil end
    if level >= def.max_level then return nil end
    return Upgrades.get_display_info(id, level + 1)
end

function Upgrades.compute_stats(upgrades_data)
    local stats = {}
    for k, v in pairs(BASE_STATS) do
        stats[k] = v
    end
    if not upgrades_data then return stats end
    for _, entry in ipairs(upgrades_data) do
        local def = Upgrades.get_by_id(entry.id)
        if def and entry.level and entry.level > 0 then
            local bonus = def:stat_effect(entry.level)
            for k, v in pairs(bonus) do
                stats[k] = (stats[k] or 0) + v
            end
        end
    end
    return stats
end

function Upgrades.get_level(upgrades_data, id)
    if not upgrades_data then return 0 end
    for _, entry in ipairs(upgrades_data) do
        if entry.id == id then
            return entry.level
        end
    end
    return 0
end

function Upgrades.get_all_levels(upgrades_data)
    if not upgrades_data then return {} end
    local out = {}
    for _, def in ipairs(UPGRADE_DEFS) do
        out[def.id] = Upgrades.get_level(upgrades_data, def.id)
    end
    return out
end

return Upgrades
