local Discord_Roles = class("Discord_Roles", vRP.Extension)
local cfg = module("vrp", "cfg/discord_roles")

-- Internal cache
local discord_cache = {}
local CACHE_COOLDOWN = cfg.cooldown or 60 -- in seconds

-- Helpers
local function splitString(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

local function contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function getDiscordID(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        local type, value = table.unpack(splitString(identifier, ':'))
        if type == 'discord' and value and value:match("^%d+$") then
            return value
        end
    end
    print("[Discord_Roles] [WARN] No valid Discord ID for player " .. source)
    return nil
end

local function getCachedMember(discord_id)
    local entry = discord_cache[discord_id]
    if entry and (os.time() - entry.timestamp) < CACHE_COOLDOWN then
        return entry.data
    end
    return nil
end

local function fetchDiscordMember(guild_id, user_id)
    local r = async()

    PerformHttpRequest(("https://discord.com/api/guilds/%s/members/%s"):format(guild_id, user_id), function(code, data)
        if code == 200 then
            local success, parsed = pcall(json.decode, data)
            if success and parsed then
                r(parsed)
            else
                print("[Discord_Roles] [ERROR] Failed to parse Discord response.")
                r(nil)
            end
        else
            print("[Discord_Roles] [ERROR] Discord API returned HTTP code " .. code)
            r(nil)
        end
    end, 'GET', '', { ["Authorization"] = cfg.token })

    return r:wait()
end

local function checkPlayerRoles(user, force)
    local discord_id = getDiscordID(user.source)
    if not discord_id then return end

    local member = force and fetchDiscordMember(cfg.guildId, discord_id) or getCachedMember(discord_id)

    if not member then
        member = fetchDiscordMember(cfg.guildId, discord_id)
        if not member then return end
        discord_cache[discord_id] = { data = member, timestamp = os.time() }
    end

    if not member.roles or type(member.roles) ~= "table" then
        print("[Discord_Roles] [WARN] No roles found for user " .. user.id)
        return
    end

    local cfg_groups = vRP.EXT.Group.cfg.groups

    -- Track highest-grade group for factions
    local faction_group, faction_grade

    for _, entry in ipairs(cfg.groups or {}) do
        if entry.roleId and entry.group then
            local hasRole = contains(member.roles, entry.roleId)
            local group_cfg = cfg_groups[entry.group]

            -- Determine if this is a faction
            local isFaction = group_cfg and group_cfg._config and group_cfg._config.gtype == "faction"

            if hasRole then
                if isFaction and entry.grade then
                    -- Compare and keep the highest grade
                    if not faction_grade or entry.grade > faction_grade then
                        faction_group = entry.group
                        faction_grade = entry.grade
                    end
                elseif not user:hasGroup(entry.group) then
                    user:addGroup(entry.group)
                    vRP.EXT.Base.remote._notify(user.source, "You have been assigned the '" .. entry.group .. "' group.")
                end
            elseif user:hasGroup(entry.group) then
                user:removeGroup(entry.group)
                vRP.EXT.Base.remote._notify(user.source, "Your '" .. entry.group .. "' group has been removed.")
            end
        end
    end

    -- Handle faction assignment
    if faction_group and not user:hasGroup(faction_group) then
        -- Remove current faction group
        for k, _ in pairs(user:getGroups()) do
            local g = cfg_groups[k]
            if g and g._config and g._config.gtype == "faction" then
                user:removeGroup(k)
            end
        end

        -- Assign new faction and grade
        user.cdata.faction_grade = faction_grade
        user:addGroup(faction_group)

        vRP.EXT.Base.remote._notifyPicture(user.source, "CHAR_LESTER", 1, "Discord Sync", "Faction Assigned", "You joined '" .. faction_group .. "' as rank " .. faction_grade .. ".")
    end
end
-- Extension constructor
function Discord_Roles:__construct()
  vRP.Extension.__construct(self)
 
  self.cfg = module("cfg/discord_roles")
  self:log(#self.cfg.groups.." Groups")

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