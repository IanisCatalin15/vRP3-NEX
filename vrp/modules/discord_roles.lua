local discord_roles = class("discord_roles", vRP.Extension)
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
    print("[discord_roles] [WARN] No valid Discord ID for player " .. source)
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
                print("[discord_roles] [ERROR] Failed to parse Discord response.")
                r(nil)
            end
        else
            print("[discord_roles] [ERROR] Discord API returned HTTP code " .. code)
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
        print("[discord_roles] [WARN] No roles found for user " .. user.id)
        return
    end

    for _, entry in ipairs(cfg.groups or {}) do
        if entry.roleId and entry.group then
            local hasRole = contains(member.roles, entry.roleId)
            local hasGroup = user:hasGroup(entry.group)

            if hasRole and not hasGroup then
                user:addGroup(entry.group)
                vRP.EXT.Base.remote._notifyPicture(user.source, "CHAR_LESTER", 1, "Discord Sync", "Role Assigned", "You have been assigned the '" .. entry.group .. "' role.")
            elseif not hasRole and hasGroup then
                user:removeGroup(entry.group)
                vRP.EXT.Base.remote._notifyPicture(user.source, "CHAR_BLOCKED", 2, "Discord Sync", "Role Removed", "Your " .. entry.group .. " role has been removed.")
            end
        end
    end
end

function discord_roles:__construct()
  vRP.Extension.__construct(self)

  vRP.EXT.GUI:registerMenuBuilder("admin.users.user", function(menu)
    local adminUser = menu.user
    local targetUser = vRP.users[menu.data.id]

    if targetUser and adminUser:hasPermission("player.sync.roles") then
      menu:addOption("Sync Discord Roles", function(menu)
        checkPlayerRoles(targetUser, true)
        vRP.EXT.Base.remote._notify(adminUser.source, "Synced roles for " .. targetUser.id)
      end)
    end
  end)
end


-- Events
discord_roles.event = {}

function discord_roles.event:characterLoad(user)
    checkPlayerRoles(user, false) -- use cache
end

vRP:registerExtension(discord_roles)