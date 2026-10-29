local TAG = "psyc-tower-immune"

local constants = data.raw["utility-constants"] and data.raw["utility-constants"].default
local defaults = constants and constants.default_trigger_target_mask_by_type or {}

data:extend({
  {
    type = "trigger-target-type",
    name = "psyc-tower-immune"
  }
})

local function add_tag(proto)
  -- Start from the prototype's mask, or the engine default for its type
  local mask = table.deepcopy(proto.trigger_target_mask or defaults[proto.type] or {"common"})
  table.insert(mask, TAG)
  proto.trigger_target_mask = mask
end

for _, spawner in pairs(data.raw["unit-spawner"] or {}) do add_tag(spawner) end
for _, worm in pairs(data.raw["turret"] or {}) do add_tag(worm) end

local TINT = {r = 0.55, g = 0.6, b = 1.0, a = 1.0}

-- Tint every non-shadow layer, walking through nested "layers" tables
local function tint_anim(a)
  if type(a) ~= "table" then return end
  if a.layers then
    for _, layer in pairs(a.layers) do tint_anim(layer) end
  elseif not a.draw_as_shadow then
    a.tint = TINT
  end
end

local clones = {}
for name, unit in pairs(data.raw["unit"]) do
  if not name:find("^psyc%-") then
    local clone = table.deepcopy(unit)
    clone.name = "psyc-" .. name
    clone.localised_name = unit.localised_name or {"entity-name." .. name}
    clone.hidden = true
    tint_anim(clone.run_animation)
    if clone.attack_parameters then tint_anim(clone.attack_parameters.animation) end
    table.insert(clones, clone)
  end
end

  log("PSYC worm mask: " .. serpent.line(data.raw["turret"]["small-worm-turret"].trigger_target_mask))
  log("PSYC spawner mask: " .. serpent.line(data.raw["unit-spawner"]["biter-spawner"].trigger_target_mask))
  log("PSYC tower ignore: " .. serpent.line(data.raw["electric-turret"]["psyc-tower"].ignore_target_mask))
data:extend(clones)