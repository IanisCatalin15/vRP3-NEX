local cfg = {}

cfg.inventory_unit = "kg"              -- "lb" | "kg"
cfg.inventory_weight_per_strength = 10 -- Weight for player inventory per strength level
cfg.inventory_base_strength = 100      -- Standard base at strength level 0

cfg.lose_inventory_on_death = true
cfg.keep_items_on_death = { -- Keep these items on death if lose inventory is true
    "weed"
}

-- Backpack configuration
cfg.backpacks = {
    ["small_backpack"] = {
        name = "Small Backpack",
        description = "A small backpack that increases your carrying capacity by 10kg",
        weight = 1.0,
        capacity_bonus = 10,
        prop_name = "prop_michael_backpack"
    },
    ["medium_backpack"] = {
        name = "Medium Backpack",
        description = "A medium backpack that increases your carrying capacity by 15kg",
        weight = 1.5,
        capacity_bonus = 15,
        prop_name = "p_ld_heist_bag_01"
    },
    ["large_backpack"] = {
        name = "Large Backpack",
        description = "A large backpack that increases your carrying capacity by 20kg",
        weight = 2.0,
        capacity_bonus = 20,
        prop_name = "p_ld_heist_bag_s_pro2_s"
    }
}

-- List of static inventories
--[[ ["evidence"] = { -- Name of chests
    title = "Seized Items", -- Title of inventory (Will show at the top of the menu)
    weight = 500, -- How much the inventory can hold
    job = {"police"}, -- OPTIONAL - Permission needed to access the inventory
    gang = {""}, -- OPTIONAL - Same as job but for gang affiliation
    coords = vec3() -- Location of the inventory
  }, ]]

cfg.chests = {
    ["evidence"] = {
        title = "Police Evidence",
        weight = 5000,
        permission = "police.chief.managebudget",
        coords = vec3(452.4429, -980.1745, 30.6895),
        blip_id = 285,
        blip_color = 38,
        marker_id = 1
    },
    ["police"] = {
        title = "Police Inventory",
        weight = 5000,
        permission = "police",
        coords = vec3(0, 0, 0),
        blip_id = 60,
        blip_color = 29,
        marker_id = 1
    },
    ["ambulance"] = {
        title = "Ambulance Inventory",
        weight = 5000,
        coords = vec3(0, 0, 0),
        blip_id = 61,
        blip_color = 1,
        marker_id = 1
    }
}

return cfg
