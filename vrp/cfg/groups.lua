local cfg = {}

-- define each group with a set of permissions
-- _config property:
--- title (optional): group display name
--- gtype (optional): used to have only one group with the same gtype per player (example: a job gtype to only have one job)
--- onspawn (optional): function(user) (called when the character spawn with the group)
--- onjoin (optional): function(user) (called when the character join the group)
--- onleave (optional): function(user) (called when the character leave the group)

cfg.groups = {
  ["superadmin"] = {
    _config = {onspawn = function(user) vRP.EXT.Base.remote._notify(user.source, "You are superadmin.") end},
    "player.group.add",
    "player.group.remove",
    "player.givemoney",
    "player.giveitem",
	  "player.giveweapon",
    "profiler.server",
    "profiler.client",
    "player.sync.roles"
  },
  ["admin"] = {
    "admin.tickets",
    "admin.announce",
    "player.list",
    "player.whitelist",
    "player.unwhitelist",
    "player.kick",
    "player.ban",
    "player.unban",
    "player.noclip",
    "player.custom_emote",
    "player.custom_model",
    "player.custom_sound",
    "player.display_custom",
    "player.coords",
	  "player.revive",
	  "player.spectate",
    "player.tptome",
    "player.tpto"
  },
  ["god"] = {
    "admin.god" -- reset survivals/health periodically
  },
  ["user"] = {
    "player.characters", -- characters menu
    "player.phone",
    "player.calladmin",
    "player.store_weapons",
    "police.seizable" -- can be seized
  },
  ["repair"] = {
    _config = {
      title = "Repair",
      gtype = "job"
    },
    "vehicle.repair",
    "vehicle.replace",
    "repair.service"
--    "mission.repair.satellite_dishes", -- basic mission
--    "mission.repair.wind_turbines" -- basic mission
  },
  ["taxi"] = {
    _config = {
      title = "Taxi",
      gtype = "job"
    },
    "taxi.service",
    "taxi.vehicle"
  },
  ["citizen"] = {
    _config = {
      title = "Citizen",
      gtype = "job"
    }
  }
}

-- groups are added dynamically using the API or the menu, but you can add group when a character is loaded here
-- groups for everyone
cfg.default_groups = {
  "user"
}

-- groups per user
-- map of user id => list of groups
cfg.users = {
  [1] = { -- give superadmin and admin group to the first created user in the database
    "superadmin",
    "admin"
  }
}

-- group selectors
-- _config
--- x,y,z, map_entity, permissions (optional)
---- map_entity: {ent,cfg} will fill cfg.title, cfg.pos

cfg.selectors = {
  ["Jobs"] = {
    _config = {x = -268.363739013672, y = -957.255126953125, z = 31.22313880920410, map_entity = {"PoI", {blip_id = 351, blip_color = 47, marker_id = 1}}},
    "taxi",
    "repair",
    "citizen"
  },
  ["police"] = {
    _config = {x = 437.924987792969,y = -987.974182128906, z = 30.6896076202393, map_entity = {"PoI", {blip_id = 351, blip_color = 38, marker_id = 1}}},
    -- Job group entries can now be a string or a table with group name + config
    { group = "police", grade = 1 },
    "citizen"
  },
  ["Emergency job"] = {
    _config = {x = -498.959716796875,y = -335.715148925781,z = 34.5017547607422, map_entity = {"PoI", {blip_id = 351, blip_color = 1, marker_id = 1}}},
    "emergency",
    "citizen"
  }
}

-- identity display gtypes
-- used to display gtype groups in the identity
-- map of gtype => title
--[[
cfg.identity_gtypes = {
  job = "Job"
} ]]

return cfg
