local cfg = {}

cfg.permission = "player.sync.roles"

cfg.token = ""  -- "[Discord Server Token]"

cfg.guildId = ""    -- "Discord server ID"

cfg.cooldown = 60 -- Cooldown in seconds for checking roles

cfg.groups = {
    -- { roleId = "12345", group = "superadmin"}  Role id its id that you copy from your discord server and the group from vrp/cfg/groups.lua
    { roleId = "12345", group = "superadmin"},
    { roleId = "12345", group = "admin"},
    { roleId = "12345", group = "police", grade = 5 }, -- Chief
    { roleId = "12345", group = "emergency"}

}

return cfg
