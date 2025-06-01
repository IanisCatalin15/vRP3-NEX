-- vrp/modules/faction.lua
-- Faction module for managing faction-based organizations like Police, Gangs, etc.

if not vRP.modules.faction then return end

local lang = vRP.lang
local Faction = class("Faction", vRP.Extension)

-- Constants
local DEFAULT_GRADE = 1

Faction.User = class("User")

-- Get the faction the user belongs to
function Faction.User:getFaction()
    return self.cdata.faction
end

-- Get the grade (rank level) in the user's faction
function Faction.User:getFactionGrade()
    return self.cdata.faction_grade
end

-- Get faction member count by grade type
function Faction:getFactionMemberCountByType(faction, type)
    local count = 0
    local faction_cfg = self:getFactionConfig(faction)

    for _, user in pairs(vRP.users) do
        if user:isReady() and user:getFaction() == faction then
            local grade = user:getFactionGrade()
            local grade_cfg = faction_cfg._config.grades[grade]

            if type == "leader" and grade_cfg.Lider then
                count = count + 1
            elseif type == "coleader" and grade_cfg.Co_Lider then
                count = count + 1
            end
        end
    end

    return count
end

-- Check if faction can have more leaders/co-leaders
function Faction:canHaveMoreLeaders(faction, type)
    local faction_cfg = self:getFactionConfig(faction)
    if not faction_cfg then return false end

    local current_count = self:getFactionMemberCountByType(faction, type)
    local max_count = type == "leader" and faction_cfg._config.max_liders or faction_cfg._config.max_co_liders

    return current_count < max_count
end

-- Set user's faction and grade
function Faction.User:setFaction(faction, grade)
    if faction then
        local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)
        if not faction_cfg then
            return false, "Faction does not exist"
        end

        -- Check member limit
        local member_count = vRP.EXT.Faction:getFactionMemberCount(faction)
        if member_count >= faction_cfg._config.max_members then
            return false, "Faction is full"
        end

        grade = grade or DEFAULT_GRADE
        if not faction_cfg._config.grades[grade] then
            return false, "Invalid grade for faction"
        end

        -- Check leader/co-leader limits
        local grade_cfg = faction_cfg._config.grades[grade]
        if grade_cfg.Lider and not vRP.EXT.Faction:canHaveMoreLeaders(faction, "leader") then
            return false, "Maximum number of leaders reached"
        elseif grade_cfg.Co_Lider and not vRP.EXT.Faction:canHaveMoreLeaders(faction, "coleader") then
            return false, "Maximum number of co-leaders reached"
        end
    end

    -- Store old values for event
    local old_faction = self.cdata.faction
    local old_grade = self.cdata.faction_grade

    -- Update values
    self.cdata.faction = faction
    self.cdata.faction_grade = grade

    -- Trigger events
    if old_faction ~= faction then
        vRP.EXT.Base.remote._triggerClientEvent(self.source, "vRP:faction:changed", faction, grade)
    end

    return true
end

-- Get faction config table
function Faction:getFactionConfig(faction)
    return self.cfg.factions[faction]
end

-- Get grade config from faction and grade
function Faction:getGradeConfig(faction, grade)
    local faction_cfg = self:getFactionConfig(faction)
    if faction_cfg and faction_cfg._config and faction_cfg._config.grades then
        return faction_cfg._config.grades[grade or 0]
    end
    return nil
end

-- Check if the player is currently on duty
function Faction.User:isOnDuty()
    return self.cdata.faction_duty or false
end

-- Toggle player's duty status (on/off)
function Faction.User:toggleDuty()
    self.cdata.faction_duty = not self:isOnDuty()

    -- Trigger duty change event
    vRP.EXT.Base.remote._triggerClientEvent(self.source, "vRP:faction:duty", self.cdata.faction_duty)

    if self:isOnDuty() then
        vRP.EXT.Base.remote._notify(self.source, "You are now ~g~on duty~w~.")
    else
        vRP.EXT.Base.remote._notify(self.source, "You are now ~r~off duty~w~.")
    end

    return true
end

-- Check if user is a faction leader
function Faction.User:isFactionLeader()
    local faction = self:getFaction()
    local grade = self:getFactionGrade()
    local cfg = vRP.EXT.Faction:getGradeConfig(faction, grade)
    return cfg and cfg.Lider == true
end

-- Check if user is co-leader
function Faction.User:isFactionCoLeader()
    local faction = self:getFaction()
    local grade = self:getFactionGrade()
    local cfg = vRP.EXT.Faction:getGradeConfig(faction, grade)
    return cfg and cfg.Co_Lider == true
end

-- Get permissions for user's current faction grade
function Faction.User:getFactionPermissions()
    local faction = self:getFaction()
    local grade = self:getFactionGrade()
    local grade_cfg = vRP.EXT.Faction:getGradeConfig(faction, grade)
    local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)

    local permissions = {}

    -- Merge default permissions
    if faction_cfg and faction_cfg._config and faction_cfg._config.default_permissions then
        for _, perm in ipairs(faction_cfg._config.default_permissions) do
            table.insert(permissions, perm)
        end
    end

    -- Merge grade-specific permissions
    if grade_cfg and grade_cfg.permissions then
        for _, perm in ipairs(grade_cfg.permissions) do
            table.insert(permissions, perm)
        end
    end

    return permissions
end

-- Check if user has a specific faction permission
function Faction.User:hasFactionPermission(perm)
    if not self:getFaction() then return false end
    for _, p in ipairs(self:getFactionPermissions()) do
        if p == perm then return true end
    end
    return false
end

-- Register a special permission function for factions
function Faction:registerPermissionFunction(name, callback)
    if self.func_perms[name] then
        self:log("WARNING: re-registered faction permission function \"" .. name .. "\"")
    end
    self.func_perms[name] = callback
end

-- Get all members of a faction
function Faction:getFactionMembers(faction)
    local members = {}
    for _, user in pairs(vRP.users) do
        if user:isReady() and user:getFaction() == faction then
            table.insert(members, user)
        end
    end
    return members
end

-- Get faction member count
function Faction:getFactionMemberCount(faction)
    local count = 0
    for _, user in pairs(vRP.users) do
        if user:isReady() and user:getFaction() == faction then
            count = count + 1
        end
    end
    return count
end

-- Get all online faction members on duty
function Faction:getFactionMembersOnDuty(faction)
    local members = {}
    for _, user in pairs(vRP.users) do
        if user:isReady() and user:getFaction() == faction and user:isOnDuty() then
            table.insert(members, user)
        end
    end
    return members
end

-- Get faction member count on duty
function Faction:getFactionMembersOnDutyCount(faction)
    local count = 0
    for _, user in pairs(vRP.users) do
        if user:isReady() and user:getFaction() == faction and user:isOnDuty() then
            count = count + 1
        end
    end
    return count
end

-- Menu: manage_faction
local function menu_manage_faction(self)
    -- Check if user has Lider or Co_Lider
    local function has_leader_permissions(user, faction_cfg, grade)
        local grade_cfg = faction_cfg._config.grades[grade]
        return grade_cfg and (grade_cfg.Lider or grade_cfg.Co_Lider)
    end

    -- Get grade config
    local function get_grade_cfg(faction_cfg, grade)
        return faction_cfg._config.grades[grade]
    end

    -- Add a nearby player to faction
    local function m_add_player_in_faction(menu)
        local user = menu.user
        local near_player = vRP.EXT.Base.remote.getNearestPlayer(user.source, 10)

        if not near_player then
            vRP.EXT.Base.remote._notify(user.source, "No player nearby")
            return
        end

        local nuser = vRP.users_by_source[near_player]
        if not nuser or nuser:getFaction() then
            vRP.EXT.Base.remote._notify(user.source, "Player is already in a faction")
            return
        end

        local faction = user:getFaction()
        local grade = user:getFactionGrade()
        local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)

        if has_leader_permissions(user, faction_cfg, grade) then
            local confirm = user:request("Do you want to add " .. nuser.name .. " to your faction?", 30)
            if confirm then
                local success, err = nuser:setFaction(faction, DEFAULT_GRADE)
                if success then
                    vRP.EXT.Base.remote._notify(user.source, "Added " .. nuser.name .. " to the faction")
                    vRP.EXT.Base.remote._notify(nuser.source, "You were added to the faction")
                else
                    vRP.EXT.Base.remote._notify(user.source, "Failed to add player: " .. err)
                end
            end
        else
            vRP.EXT.Base.remote._notify(user.source, "You don't have permission to add members")
        end
    end

    -- Remove a faction member
    local function m_remove_player_in_faction(menu)
        local user = menu.user
        local faction = user:getFaction()
        local grade = user:getFactionGrade()
        local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)

        if not has_leader_permissions(user, faction_cfg, grade) then
            vRP.EXT.Base.remote._notify(user.source, "You don't have permission to remove members")
            return
        end

        vRP.EXT.GUI:registerMenuBuilder("faction_members", function(submenu)
            submenu.title = "Faction Members"
            submenu.css.header_color = "rgba(0,125,255,0.75)"

            local members = vRP.EXT.Faction:getFactionMembers(faction)
            for _, target in ipairs(members) do
                if target.id ~= user.id then -- Can't remove yourself
                    if not get_grade_cfg(faction_cfg, grade).Co_Lider or target:getFactionGrade() < grade then
                        local grade_cfg = get_grade_cfg(faction_cfg, target:getFactionGrade())
                        local duty_status = target:isOnDuty() and "~g~On Duty~w~" or "~r~Off Duty~w~"
                        submenu:addOption(string.format("%s - %s (%s)", target.name, grade_cfg.name, duty_status),
                            function()
                                local confirm = user:request(
                                    "Do you want to remove " .. target.name .. " from the faction?", 30)
                                if confirm then
                                    local success, err = target:setFaction(nil, nil)
                                    if success then
                                        vRP.EXT.Base.remote._notify(user.source, "Removed " .. target.name)
                                        vRP.EXT.Base.remote._notify(target.source, "You were removed from the faction")
                                        user:closeMenu(submenu)
                                    else
                                        vRP.EXT.Base.remote._notify(user.source, "Failed to remove player: " .. err)
                                    end
                                end
                            end)
                    end
                end
            end
        end)

        user:openMenu("faction_members")
    end

    -- Check if user can modify target's grade
    local function can_modify_grade(user_grade_cfg, user_grade, target_grade, is_self)
        -- Lider can't modify other Liders or themselves
        if user_grade_cfg.Lider then
            if is_self then return false end
            return target_grade < user_grade
        end

        -- Co-Lider can modify lower grades
        if user_grade_cfg.Co_Lider then
            return target_grade < user_grade
        end

        return false
    end

    -- Grades management menu
    vRP.EXT.GUI:registerMenuBuilder("faction_grades", function(menu)
        local user = menu.user
        local faction = user:getFaction()
        local user_grade = user:getFactionGrade()
        local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)

        menu.title = "Manage Grades"
        menu.css.header_color = "rgba(0,125,255,0.75)"

        local user_grade_cfg = get_grade_cfg(faction_cfg, user_grade)
        if not user_grade_cfg.Lider and not user_grade_cfg.Co_Lider then
            vRP.EXT.Base.remote._notify(user.source, "You don't have permission to manage grades")
            return
        end

        -- Populate member list
        local members = vRP.EXT.Faction:getFactionMembers(faction)
        for _, target in ipairs(members) do
            local target_grade = target:getFactionGrade()
            local is_self = (target == user)

            if can_modify_grade(user_grade_cfg, user_grade, target_grade, is_self) then
                local target_grade_name = get_grade_cfg(faction_cfg, target_grade).name
                local duty_status = target:isOnDuty() and "~g~On Duty~w~" or "~r~Off Duty~w~"

                menu:addOption(string.format("%s - %s (%s)", target.name, target_grade_name, duty_status), function()
                    vRP.EXT.GUI:registerMenuBuilder("faction_grade_selector", function(grade_menu)
                        grade_menu.title = "Grade " .. target.name
                        grade_menu.css.header_color = "rgba(0,125,255,0.75)"

                        local max_grade = user_grade_cfg.Lider
                            and #faction_cfg._config.grades
                            or (user_grade - 1)

                        for g = 0, max_grade do
                            local ginfo = faction_cfg._config.grades[g]
                            if ginfo then
                                grade_menu:addOption(ginfo.name, function()
                                    local confirm = user:request("Set " .. target.name .. " to " .. ginfo.name .. "?", 30)
                                    if confirm then
                                        local success, err = target:setFaction(faction, g)
                                        if success then
                                            vRP.EXT.Base.remote._notify(user.source,
                                                "Set " .. target.name .. " to " .. ginfo.name)
                                            vRP.EXT.Base.remote._notify(target.source,
                                                "Your rank changed to " .. ginfo.name)
                                            user:closeMenu(grade_menu)
                                        else
                                            vRP.EXT.Base.remote._notify(user.source, "Failed to change grade: " .. err)
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                    user:openMenu("faction_grade_selector")
                end)
            end
        end
    end)

    -- Open grades management menu
    local function m_manage_grades(menu)
        local user = menu.user
        local faction = user:getFaction()
        local grade = user:getFactionGrade()
        local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)

        local user_grade_cfg = get_grade_cfg(faction_cfg, grade)
        if not user_grade_cfg.Lider and not user_grade_cfg.Co_Lider then
            vRP.EXT.Base.remote._notify(user.source, "You don't have permission to manage grades")
            return
        end

        user:openMenu("faction_grades")
    end

    -- Exit faction
    local function m_exit_faction(menu)
        local user = menu.user
        local faction = user:getFaction()
        local grade = user:getFactionGrade()
        local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)
        local grade_cfg = get_grade_cfg(faction_cfg, grade)

        if not grade_cfg.Lider then
            local confirm = user:request("Do you want to leave the faction?", 30)
            if confirm then
                local success, err = user:setFaction(nil, nil)
                if success then
                    vRP.EXT.Base.remote._notify(user.source, "You left the faction")
                    user:closeMenu(menu)
                else
                    vRP.EXT.Base.remote._notify(user.source, "Failed to leave faction: " .. err)
                end
            end
        end
    end

    -- Toggle duty status
    local function m_toggle_duty(menu)
        local user = menu.user
        local success, err = user:toggleDuty()
        if not success then
            vRP.EXT.Base.remote._notify(user.source, "Failed to toggle duty: " .. err)
        end
    end

    -- Main faction menu
    vRP.EXT.GUI:registerMenuBuilder("manage_faction", function(menu)
        local user = menu.user
        local faction = user:getFaction()
        local grade = user:getFactionGrade()
        local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)
        local grade_cfg = get_grade_cfg(faction_cfg, grade)

        menu.title = "Faction"
        menu.css.header_color = "rgba(0,125,255,0.75)"

        -- Add faction info
        local member_count = vRP.EXT.Faction:getFactionMemberCount(faction)
        local on_duty_count = vRP.EXT.Faction:getFactionMembersOnDutyCount(faction)
        menu:addOption(string.format("Members: %d (%d on duty)", member_count, on_duty_count), nil,
            "View faction statistics")

        if grade_cfg.Lider or grade_cfg.Co_Lider then
            menu:addOption("Add Member", m_add_player_in_faction)
            menu:addOption("Remove Member", m_remove_player_in_faction)
            menu:addOption("Grades", m_manage_grades)
        end

        menu:addOption("Toggle Duty", m_toggle_duty)

        if not grade_cfg.Lider then
            menu:addOption("Exit Faction", m_exit_faction)
        end
    end)
end


-- menu: admin users user
local function menu_admin_users_user(self)
    local function m_factions(menu, value, mod, index)
        local user = menu.user
        local tuser = vRP.users[menu.data.id]

        local faction_info = "No faction"
        if tuser and tuser:isReady() then
            local faction = tuser:getFaction()
            local grade = tuser:getFactionGrade()
            if faction then
                local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction)
                local grade_cfg = faction_cfg and faction_cfg._config.grades[grade]
                local grade_name = grade_cfg and grade_cfg.name
                faction_info = string.format("%s (Grade: %s)", faction, grade_name)
            end
        end

        menu:updateOption(index, nil, "Current faction: " .. faction_info)
    end

    -- Register the faction selector menu at module level
    vRP.EXT.GUI:registerMenuBuilder("admin.faction_selector", function(menu)
        local user = menu.user
        local tuser = menu.data.target
        local factions = {}

        for faction_name, _ in pairs(vRP.EXT.Faction.cfg.factions) do
            table.insert(factions, faction_name)
        end

        menu.title = "Select Faction"
        menu.css.header_color = "rgba(0,125,255,0.75)"

        for _, faction_name in ipairs(factions) do
            menu:addOption(faction_name, function()
                local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction_name)
                if faction_cfg and faction_cfg._config and faction_cfg._config.grades then
                    user:openMenu("admin.grade_selector", { faction = faction_name, target = tuser })
                end
            end)
        end
    end)

    -- Register the grade selector menu at module level
    vRP.EXT.GUI:registerMenuBuilder("admin.grade_selector", function(menu)
        local user = menu.user
        local faction_name = menu.data.faction
        local tuser = menu.data.target
        local faction_cfg = vRP.EXT.Faction:getFactionConfig(faction_name)

        if faction_cfg and faction_cfg._config and faction_cfg._config.grades then
            menu.title = "Select Grade for " .. faction_name
            menu.css.header_color = "rgba(0,125,255,0.75)"

            -- Sort grades by number
            local sorted_grades = {}
            for grade, _ in pairs(faction_cfg._config.grades) do
                table.insert(sorted_grades, grade)
            end
            table.sort(sorted_grades)

            -- Add grade options in order
            for _, grade in ipairs(sorted_grades) do
                local grade_cfg = faction_cfg._config.grades[grade]
                menu:addOption(grade_cfg.name, function()
                    local confirm = user:request(
                        string.format("Set %s to %s (Grade: %s)?", tuser.name, faction_name,
                            grade_cfg.name), 30)
                    if confirm then
                        tuser:setFaction(faction_name, grade)
                        vRP.EXT.Base.remote._notify(user.source,
                            string.format("Set %s's faction to %s (Grade: %s)", tuser.name,
                                faction_name, grade_cfg.name))
                        vRP.EXT.Base.remote._notify(tuser.source,
                            string.format("Your faction was set to %s (Grade: %s)", faction_name,
                                grade_cfg.name))
                        user:closeMenu(menu)
                    end
                end)
            end
        end
    end)

    local function m_setfaction(menu)
        local user = menu.user
        local tuser = vRP.users[menu.data.id]

        if tuser then
            user:openMenu("admin.faction_selector", { target = tuser })
        end
    end

    local function m_removefaction(menu)
        local user = menu.user
        local tuser = vRP.users[menu.data.id]

        if tuser and tuser:getFaction() then
            local confirm = user:request(string.format("Remove %s from faction %s?", tuser.name, tuser:getFaction()), 30)
            if confirm then
                tuser:setFaction(nil, nil)
                vRP.EXT.Base.remote._notify(user.source, string.format("Removed %s from faction", tuser.name))
                vRP.EXT.Base.remote._notify(tuser.source, "You were removed from your faction")
            end
        else
            vRP.EXT.Base.remote._notify(user.source, "Player is not in a faction")
        end
    end

    vRP.EXT.GUI:registerMenuBuilder("admin.users.user", function(menu)
        local user = menu.user
        if user:hasPermission("admin.faction.manage") then
            menu:addOption("Faction", function(menu)
                menu.user:openMenu("admin.users.faction", menu.data)
            end)
        end
    end)

    vRP.EXT.GUI:registerMenuBuilder("admin.users.faction", function(menu)
        local tuser = vRP.users[menu.data.id]

        if tuser then
            menu:addOption("Faction Info", m_factions, "View current faction information")
            menu:addOption("Set Faction", m_setfaction)
            menu:addOption("Remove from Faction", m_removefaction)
        end
    end)
end


------------------------------------------
-- Paycheck System
------------------------------------------

function Faction:taskPaycheck()
    for faction_name, faction_cfg in pairs(self.cfg.factions) do
        if faction_cfg._config then
            local interval = faction_cfg._config.paycheck_interval or 60
            self.paychecks_elapsed[faction_name] = (self.paychecks_elapsed[faction_name] or 0) + 1

            if self.paychecks_elapsed[faction_name] >= interval then
                self.paychecks_elapsed[faction_name] = 0

                local members = self:getFactionMembersOnDuty(faction_name)
                for _, user in ipairs(members) do
                    if user:isReady() and user.spawns > 0 then
                        local grade = user:getFactionGrade()
                        local grade_cfg = faction_cfg._config.grades and faction_cfg._config.grades[grade]

                        if grade_cfg and grade_cfg.payment and grade_cfg.payment > 0 then
                            user:giveWallet(grade_cfg.payment)
                            vRP.EXT.Base.remote._notify(user.source, "Faction salary: ~g~$" .. grade_cfg.payment)
                        end
                    end
                end
            end
        end
    end
end

------------------------------------------
-- Extension Constructor
------------------------------------------

function Faction:__construct()
    vRP.Extension.__construct(self)

    self.cfg = module("cfg/factions")
    self.paychecks_elapsed = {} -- faction name => elapsed minutes
    self.func_perms = {}        -- permission functions

    -- Register default permission functions
    self:registerPermissionFunction("faction", function(user, params)
        local faction = params[2]
        if faction then
            return user:getFaction() == faction
        end
        return false
    end)

    self:registerPermissionFunction("faction.grade", function(user, params)
        local faction = params[2]
        local grade = tonumber(params[3])
        if faction and grade then
            return user:getFaction() == faction and user:getFactionGrade() >= grade
        end
        return false
    end)

    self:registerPermissionFunction("faction.leader", function(user, params)
        local faction = params[2]
        if faction then
            return user:getFaction() == faction and user:isFactionLeader()
        end
        return false
    end)

    self:registerPermissionFunction("faction.coleader", function(user, params)
        local faction = params[2]
        if faction then
            return user:getFaction() == faction and user:isFactionCoLeader()
        end
        return false
    end)

    self:registerPermissionFunction("faction.duty", function(user, params)
        local faction = params[2]
        if faction then
            return user:getFaction() == faction and user:isOnDuty()
        end
        return false
    end)

    menu_manage_faction(self)
    menu_admin_users_user(self)

    -- Register main menu options
    vRP.EXT.GUI:registerMenuBuilder("main", function(menu)
        local user = menu.user
        if user:getFaction() then
            menu:addOption("Faction", function()
                user:openMenu("manage_faction")
            end)
        end
    end)
end

Faction.event = {}

-- Event handlers
function Faction.event:playerSpawn(user)
    local faction = user:getFaction()
    if faction then
        local faction_cfg = self:getFactionConfig(faction)
        if faction_cfg and faction_cfg._config and faction_cfg._config.onspawn then
            faction_cfg._config.onspawn(user)
        end
    end
end

function Faction.event:characterLoad(user)
    if not user.cdata.faction then
        user.cdata.faction = nil
        user.cdata.faction_grade = nil
        user.cdata.faction_duty = false
    end
end

vRP:registerExtension(Faction)
