fx_version 'cerulean'
games { 'gta5' }

description "RP module/framework"
version '3.0.1'

ui_page "gui/index.html"

shared_script {
  "lib/utils.lua"
}

server_script {
  "base.lua",
  "modules/map.lua",
  "modules/gui.lua",
  "modules/admin.lua",
  "modules/group.lua",
  "modules/identity.lua",
  "modules/weather.lua",
  "modules/commands.lua",
  "modules/misc.lua",
  "modules/player_state.lua",
  "modules/weapon.lua",
  "modules/log.lua",
  "modules/hours.lua",
  "modules/vehicle.lua",
  "modules/bank.lua",
  "modules/discord_roles.lua",
  "modules/faction.lua",
  "modules/inventory.lua",
  "modules/money.lua"

}

client_scripts {
  "client/base.lua",
  "client/map.lua",
  "client/gui.lua",
  "client/identity.lua",
  "client/admin.lua",
  "client/weather.lua",
  "client/commands.lua",
  "client/misc.lua",
  "client/player_state.lua",
  "client/weapon.lua",
  "client/hours.lua",
  "client/vehicle.lua",
  "client/inventory.lua"
}

files {
  "lib/Luaoop.lua",
  "lib/Tunnel.lua",
  "lib/Proxy.lua",
  "lib/IDManager.lua",
  "lib/ActionDelay.lua",
  "lib/Luang.lua",
  "lib/ELProfiler.lua",
  "client/vRP.lua",
  "vRPShared.lua",
  "cfg/client.lua",
  "cfg/modules.lua",
  "gui/index.html",
  "gui/design.css",
  "gui/main.js",
  "gui/Menu.js",
  "gui/ProgressBar.js",
  "gui/WPrompt.js",
  "gui/RequestManager.js",
  "gui/AnnounceManager.js",
  "gui/RadioDisplay.js",
  "gui/Div.js",
  "gui/config.js",
  "gui/dynamic_classes.js",
  "gui/countdown.js",
  "gui/AudioEngine.js",
  "gui/lib/libopus.wasm.js",
  "gui/images/voice_active.png",
  "gui/sounds/phone_dialing.ogg",
  "gui/sounds/phone_ringing.ogg",
  "gui/sounds/phone_sms.ogg",
  "gui/sounds/radio_on.ogg",
  "gui/sounds/radio_off.ogg",
  "gui/sounds/eating.ogg",
  "gui/sounds/drinking.ogg"
}
