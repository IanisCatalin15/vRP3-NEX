if not vRP.modules.discord_roles then return end

local Discord_Roles = class("Discord_Roles", vRP.Extension)
local cfg = module("vrp", "cfg/discord_roles")

-- Internal cache for Discord member data
local discord_cache = {}
local CACHE_COOLDOWN = cfg.cooldown or 60 -- in seconds

-- Utility function to check if a value exists in a table
local function contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

-- Get Discord ID from player source
local function getDiscordID(source)
  local identifiers = GetPlayerIdentifiers(source)
  for _, identifier in ipairs(identifiers) do
    local type, value = identifier:match("([^:]+):(.+)")
    if type == "discord" and value and value:match("^%d+$") then
      return value
    end
  end
  print("[discord_roles] [WARN] No valid Discord ID for player " .. source)
  return nil
end

-- Get cached Discord member data
local function getCachedMember(discord_id)
  local entry = discord_cache[discord_id]
  if entry and (os.time() - entry.timestamp) < CACHE_COOLDOWN then
    return entry.data
  end
  return nil
end

-- Fetch member data from Discord API
local function fetchDiscordMember(guild_id, user_id)
  local r = async()

  PerformHttpRequest(("https://discord.com/api/guilds/%s/members/%s"):format(guild_id, user_id), function(code, data)
    if code == 200 then
      local success, parsed = pcall(json.decode, data)
      if success and parsed then
        r(parsed)
      else
        print("[discord_roles] [ERROR] Failed to parse Discord response.")
        r(nil)
      end
    else
      print("[discord_roles] [ERROR] Discord API returned HTTP code " .. code)
      r(nil)
    end
  end, 'GET', '', { ["Authorization"] = "Bot " .. cfg.token })

  return r:wait()
end

-- Process a single role entry
local function processRoleEntry(user, entry, hasRole, isFaction)
  if isFaction then
    return entry.group, entry.grade
  else
    local hasGroup = user:hasGroup(entry.group)
    if hasRole and not hasGroup then
      user:addGroup(entry.group)
      vRP.EXT.Base.remote._notifyPicture(user.source, "CHAR_LESTER", 1, "Discord Sync", "Role Assigned",
        "You have been assigned the '" .. entry.group .. "' role.")
    elseif not hasRole and hasGroup then
      user:removeGroup(entry.group)
      vRP.EXT.Base.remote._notifyPicture(user.source, "CHAR_BLOCKED", 2, "Discord Sync", "Role Removed",
        "Your " .. entry.group .. " role has been removed.")
    end
    return nil, nil
  end
end

-- Handle faction assignment
local function handleFactionAssignment(user, faction_group, faction_grade)
  if not faction_group or not faction_grade then return end

  local current_faction = user:getFaction()
  local current_grade = user:getFactionGrade()

  if current_faction ~= faction_group or current_grade ~= faction_grade then
    -- Clear existing faction if different
    if current_faction and current_faction ~= faction_group then
      user:setFaction(nil, nil)
    end

    -- Try assigning new faction
    local success, reason = user:setFaction(faction_group, faction_grade)
    if success then
      vRP.EXT.Base.remote._notifyPicture(user.source, "CHAR_LESTER", 1, "Discord Sync", "Faction Assigned",
        "You joined '" .. faction_group .. "' as rank " .. faction_grade .. ".")
    else
      vRP.EXT.Base.remote._notifyPicture(user.source, "CHAR_BLOCKED", 2, "Discord Sync", "Faction Error",
        "Failed to set faction: " .. (reason or "Unknown error"))
    end
  end
end

-- Main function to check and sync player roles
local function checkPlayerRoles(user, force)
  local discord_id = getDiscordID(user.source)
  if not discord_id then return end

  -- Get Discord member data
  local member = force and fetchDiscordMember(cfg.guildId, discord_id) or getCachedMember(discord_id)
  if not member then
    member = fetchDiscordMember(cfg.guildId, discord_id)
    if not member then return end
    discord_cache[discord_id] = { data = member, timestamp = os.time() }
  end

  if not member.roles or type(member.roles) ~= "table" then
    print("[discord_roles] [WARN] No roles found for user " .. user.id)
    return
  end

  local faction_group, faction_grade = nil, nil

  -- First pass: Process all roles and collect faction information
  for _, entry in ipairs(cfg.groups or {}) do
    if entry.roleId and entry.group then
      local hasRole = contains(member.roles, entry.roleId)
      local isFaction = vRP.EXT.Faction:getFactionConfig(entry.group) ~= nil

      if hasRole then
        local new_faction, new_grade = processRoleEntry(user, entry, hasRole, isFaction)
        if new_faction and new_grade then
          if not faction_grade or new_grade > faction_grade then
            faction_group = new_faction
            faction_grade = new_grade
          end
        end
      end
    end
  end

  -- Handle faction assignment
  handleFactionAssignment(user, faction_group, faction_grade)

  -- Remove faction if no matching Discord role found
  if not faction_group and user:getFaction() then
    user:setFaction(nil, nil)
    vRP.EXT.Base.remote._notifyPicture(user.source, "CHAR_BLOCKED", 2, "Discord Sync", "Faction Removed",
      "Your faction membership has been removed.")
  end
end

-- Extension constructor
function Discord_Roles:__construct()
  vRP.Extension.__construct(self)

  self.cfg = module("cfg/discord_roles")

  -- Validate configuration
  if not self.cfg or not self.cfg.token or not self.cfg.guildId or not self.cfg.groups then
    print("[discord_roles] [ERROR] Configuration is missing required fields")
    print("Required fields: token, guildId, groups")
    return
  end

  -- Print configuration info
  print("[Discord Roles] Configuration loaded:")
  print("Guild ID: " .. self.cfg.guildId)
  print("Number of role mappings: " .. #self.cfg.groups)
  -- Register admin menu option
  vRP.EXT.GUI:registerMenuBuilder("admin.users.user", function(menu)
    local adminUser = menu.user
    local targetUser = vRP.users[menu.data.id]

    if targetUser and adminUser:hasPermission(cfg.permission) then
      menu:addOption("Sync Discord Roles", function(menu)
        checkPlayerRoles(targetUser, true)
        vRP.EXT.Base.remote._notify(adminUser.source, "Synced roles for " .. targetUser.id)
      end)
    end
  end)
end

-- Events
Discord_Roles.event = {}

function Discord_Roles.event:characterLoad(user)
  checkPlayerRoles(user, false) -- use cache
end

vRP:registerExtension(Discord_Roles)
