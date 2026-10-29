-- Start from the vanilla laser turret prototype, not the gun turret prototype.
-- In Factorio, laser turrets are defined as electric turrets, so this must be copied
-- from data.raw["electric-turret"]["laser-turret"] or the mod will fail to load.
local base_turret = data.raw["electric-turret"] and data.raw["electric-turret"]["laser-turret"]

if not base_turret then
  error("psyc-tower requires the vanilla laser turret prototype, but it was not found.")
end

local psycTower = table.deepcopy(base_turret)

psycTower.name = "psyc-tower"
psycTower.minable = {mining_time = 0.5, result = "psyc-tower"}
psycTower.max_health = 500
psycTower.ignore_target_mask = {"psyc-tower-immune"}

-- Keep the vanilla electric turret attack configuration so the required
-- `ammo_type` data is present. Only tweak the timing/range values we want.
if psycTower.attack_parameters then
  psycTower.attack_parameters.cooldown = 20
  psycTower.attack_parameters.range = 50
  psycTower.attack_parameters.damage_modifier = 0.0
end

local attack = psycTower.attack_parameters
attack.damage_modifier = 0
attack.health_penalty = -100

local delivery = attack.ammo_type.action.action_delivery
delivery.target_effects = {
  {
    type = "script",
    effect_id = "psyc-tower-convert",
    affects_target = true
  }
}

local base_turret = data.raw["electric-turret"] and data.raw["electric-turret"]["laser-turret"]
local base_beam = data.raw["beam"] and data.raw["beam"]["laser-beam"]

if not base_turret then
  error("psyc-tower requires the vanilla laser turret prototype, but it was not found.")
end
if not base_beam then
  error("psyc-tower requires the vanilla laser beam prototype, but it was not found.")
end

-- 1. A beam that triggers our script instead of dealing damage
local psycBeam = table.deepcopy(base_beam)
psycBeam.name = "psyc-tower-beam"
psycBeam.action = {
  type = "direct",
  action_delivery = {
    type = "instant",
    target_effects = {
      {
        type = "script",
        effect_id = "psyc-tower-convert"
      }
    }
  }
}

-- 2. The turret, pointed at that beam
local psycTower = table.deepcopy(base_turret)
psycTower.name = "psyc-tower"
psycTower.minable = {mining_time = 0.5, result = "psyc-tower"}
psycTower.max_health = 500

local attack = psycTower.attack_parameters
attack.cooldown = 20
attack.range = 50
attack.ammo_type.action.action_delivery.beam = "psyc-tower-beam"
attack.ammo_type.action.action_delivery.max_length = 50 -- match the range, or the beam falls short

psycTower.ignore_target_mask = {"psyc-tower-immune"}

local beacon = data.raw["beacon"] and data.raw["beacon"]["beacon"]
if not beacon then
  error("psyc-tower requires the vanilla beacon prototype, but it was not found.")
end

-- Flatten every drawable layer of the beacon into one list
local layers = {}
local function add_anim(a)
  if type(a) ~= "table" then return end
  if a.layers then
    for _, l in pairs(a.layers) do add_anim(l) end
  elseif a.filename or a.stripes then
    local l = table.deepcopy(a)
    l.direction_count = 1 -- turret animations are "rotated"; we only have one direction
    -- l.tint = {r = 0.6, g = 0.6, b = 1.0, a = 1.0} -- optional: tint it so it differs from a real beacon
    table.insert(layers, l)
  end
end

local gs = beacon.graphics_set
for _, entry in pairs((gs and gs.animation_list) or {}) do
  add_anim(entry.animation)
end

if #layers == 0 then
  log("PSYC beacon graphics_set: " .. serpent.block(gs))
  error("psyc-tower could not find beacon sprites; see factorio-current.log")
end

-- Use the beacon image for every turret animation state
local look = {layers = layers}
for _, slot in pairs({
  "folded_animation", "preparing_animation", "prepared_animation",
  "folding_animation", "starting_attack_animation", "attacking_animation",
  "ending_attack_animation"
}) do
  psycTower[slot] = look
end

-- Remove the laser turret's extra art
psycTower.prepared_alternative_animation = nil
psycTower.energy_glow_animation = nil
psycTower.resource_indicator_animation = nil
if psycTower.graphics_set then
  psycTower.graphics_set.base_visualisation = nil
end

-- Match the beacon's 3x3 footprint
psycTower.collision_box = {{-1.2, -1.2}, {1.2, 1.2}}
psycTower.selection_box = {{-1.5, -1.5}, {1.5, 1.5}}
psycTower.icon = "__base__/graphics/icons/beacon.png"
psycTower.icon_size = 64
psycTower.icons = nil

data:extend({psycBeam, psycTower})