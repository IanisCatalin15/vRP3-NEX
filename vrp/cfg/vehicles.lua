local cfg = {}

cfg.vehicle_update_interval = 15 -- seconds
cfg.vehicle_check_interval = 15  -- seconds, re-own/respawn task


-- list of all purchasable vehicles
-- model       = spawn code
-- name        = display name
-- price       = purchase price
-- category    = as per GetVehicleClass() (see FiveM docs)
-- type        = as per IsThisModelACar()/IsThisModelABike(), etc.
-- shop        = single shop key or array of shop keys
cfg.vehicles = {
  { model = 'alpha',     name = 'Alpha',          price = 53000, category = 'sports',      type = 'automobile', shop = 'pdm' },
  { model = 'banshee',   name = 'Banshee',        price = 56000, category = 'sports',      type = 'automobile', shop = 'pdm' },
  { model = 'bestiagts', name = 'Bestia GTS',     price = 37000, category = 'sports',      type = 'automobile', shop = 'pdm' },
  { model = 'buffalo',   name = 'Buffalo',        price = 18750, category = 'sports',      type = 'automobile', shop = 'pdm' },
  { model = 'buffalo2',  name = 'Buffalo S',      price = 24500, category = 'sports',      type = 'automobile', shop = 'pdm' },
  { model = "blista",    name = "Blista",         price = 100,   category = "compacts",    type = "automobile", shop = { "pdm", "luxury" } },
  { model = "buzzard",   name = "Buzzard Attack", price = 100,   category = "helicopter",  type = "aircraft",   shop = "aircraft" },
  { model = "avenger",   name = "Avenger",        price = 100,   category = "helicopter",  type = "aircraft",   shop = "aircraft" },
  { model = "dinghy",    name = "Dinghy",         price = 100,   category = "boats",       type = "boat",       shop = "marina" }
  -- add your own entries below
}

-- configuration for each vehicle shop
-- key = shop identifier (matches cfg.vehicles.shop)
-- showroom_location = vec3(x,y,z)
-- preview            = vec4(x,y,z,heading)
-- blip               = { id = blipId, color = blipColor }
-- marker             = { id = markerId, scale = { x,y,z }, color = { r,g,b,a } }
cfg.vehicleshops = {
  pdm = {
    shop_name         = "Luxury Car Dealership",
    showroom_location = vec3(-54.94, -1111.50, 26.44),
    preview           = vec4(-60.0, -1110.0, 26.4, 120.0),
    blip              = { id = 326, color = 69 },
    marker            = { id = 1, scale = { 1.5, 1.5, 1.0 }, color = { 255, 215, 0, 100 } }
  },
  aircraft = {
    shop_name         = "LSIA Hangar",
    showroom_location = vec3(-1068.3375244141, -2912.9306640625, 13.948853492737),
    preview           = vec3(-1075.5056152344, -2927.0688476562, 13.94483757019),
    blip              = { id = 90, color = 38 },
    marker            = { id = 1, scale = { 2.0, 2.0, 1.0 }, color = { 0, 191, 255, 120 } }
  }
}

-- where players can sell back vehicles
cfg.sellvehicle = {
  cars = {
    name = "Sell Cars",
    type = "automobile",
    sellPrice = 75,   -- players get 75% of original price
    blip = { id = 369, color = 25 },
    marker = { id = 1, scale = { 1.5, 1.5, 1.0 }, color = { 0, 128, 255, 100 } },
    coords = {
      vec3(-61.744976043701, -1117.8952636719, 26.432458877563)
    }
  },

  aircraft = {
    name = "Sell Aircraft",
    type = "aircraft",
    sellPrice = 50,   -- players get 50% of original price
    blip = { id = 370, color = 38 },
    marker = { id = 1, scale = { 2.0, 2.0, 1.0 }, color = { 0, 191, 255, 120 } },
    coords = {
      vec3(-1063.3536376953, -2903.9650878906, 13.948486328125)
    }
  }
}

return cfg
