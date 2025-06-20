-- https://github.com/ImagicTheCat/vRP
-- MIT license (see LICENSE or vrp/vRPShared.lua)
if not vRP.modules.hours then return end

local Hours = class("Hours", vRP.Extension)

function Hours:__construct()
    vRP.Extension.__construct(self)

    Citizen.CreateThread(function()
        while true do
            Wait(15 * 60000)
            print("Hours: 15 minutes have passed.")
            self.remote._updateHours(0.25)
        end
    end)
end

vRP:registerExtension(Hours)
