if not vRP.modules.inventory then return end

local Inventory = class("Inventory", vRP.Extension)

local prop = nil

local function setBackpack(prop_name)
    local playerPed = GetPlayerPed(-1)
    local x, y, z = table.unpack(GetEntityCoords(playerPed))

    Citizen.CreateThread(function()
        if prop then DeleteObject(prop) end
        prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)

        local offsets = {
            ["prop_michael_backpack"] = { 0.046, -0.17, -0.040 },
            ["p_ld_heist_bag_01"] = { 0.020, 0.03, 0.0 },
            ["p_ld_heist_bag_s_pro2_s"] = { -0.19, -0.19, 0.00 }
        }

        local ox, oy, oz = table.unpack(offsets[prop_name] or { 0.0, 0.0, 0.0 })
        AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, 24818), ox, oy, oz, 0.0, 90.0, 180.0, true, true,
            false, true, 1, true)
    end)
end

function Inventory:__construct()
    vRP.Extension.__construct(self)
end

-- TUNNEL
Inventory.tunnel = {}

function Inventory.tunnel:toggleBackpack(prop_name)
    setBackpack(prop_name)
end

function Inventory.tunnel:removeBackpack()
    if prop then
        DeleteObject(prop)
        prop = nil
    end
end

vRP:registerExtension(Inventory)
