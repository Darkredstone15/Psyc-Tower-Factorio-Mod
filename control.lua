local FORCE_NAME = "psyc-tower-controlled"

-- Create the force (if needed) and set who it likes and dislikes.
local function setup_force()
  local controlled = game.forces[FORCE_NAME] or game.create_force(FORCE_NAME)
  local enemy = game.forces["enemy"]

  -- At war with the biters, in both directions
  controlled.set_cease_fire(enemy, false)
  enemy.set_cease_fire(controlled, false)
  controlled.set_friend(enemy, false)
  enemy.set_friend(controlled, false)

  -- Friendly with every other real force (the player, other player teams)
  for _, force in pairs(game.forces) do
    if force ~= controlled and force ~= enemy and force.name ~= "neutral" then
      controlled.set_friend(force, true)
      force.set_friend(controlled, true)
      controlled.set_cease_fire(force, true)
      force.set_cease_fire(controlled, true)
    end
  end
end

script.on_init(setup_force)
script.on_configuration_changed(setup_force) -- covers adding the mod to an existing save
script.on_event(defines.events.on_force_created, setup_force) -- covers forces created later

script.on_event(defines.events.on_script_trigger_effect, function(event)
  if event.effect_id ~= "psyc-tower-convert" then return end

  local target = event.target_entity
  if not (target and target.valid and target.type == "unit") then return end
  if target.force.name ~= "enemy" then return end

  local controlled = game.forces[FORCE_NAME]
  if not controlled then
    setup_force()
    controlled = game.forces[FORCE_NAME]
  end

  -- Stop the nest from treating this unit as one of its own
  target.release_from_spawner()

  -- Switch sides
  target.force = controlled

  -- Wipe its old orders (e.g. "attack the player's base") and give it
  -- something to do. It will engage nearby enemies while wandering.
    local commandable = target.commandable
  if commandable then
    commandable.set_command({
      type = defines.command.wander,
      distraction = defines.distraction.by_enemy
    })
  end



local FORCE_NAME = "psyc-tower-controlled"
local MAX_CONVERTED = 3
local LIFETIME_TICKS = 30 * 60 -- 30 seconds at 60 ticks/sec

local function init_storage()
  storage.converted = storage.converted or {}   -- [unit_number] = {entity, tower_id, expires}
  storage.full_towers = storage.full_towers or {} -- [tower_id] = tower entity
end

local function setup_force()
  local controlled = game.forces[FORCE_NAME] or game.create_force(FORCE_NAME)
  local enemy = game.forces["enemy"]

  controlled.set_cease_fire(enemy, false)
  enemy.set_cease_fire(controlled, false)
  controlled.set_friend(enemy, false)
  enemy.set_friend(controlled, false)

  for _, force in pairs(game.forces) do
    if force ~= controlled and force ~= enemy and force.name ~= "neutral" then
      controlled.set_friend(force, true)
      force.set_friend(controlled, true)
      controlled.set_cease_fire(force, true)
      force.set_cease_fire(controlled, true)
    end
  end
end

local function setup()
  init_storage()
  setup_force()
end

script.on_init(setup)
script.on_configuration_changed(setup)
script.on_event(defines.events.on_force_created, setup_force)

local function count_for_tower(tower_id)
  local n = 0
  for _, rec in pairs(storage.converted) do
    if rec.tower_id == tower_id and rec.entity.valid then n = n + 1 end
  end
  return n
end

local function give_orders(unit)
  local commandable = unit.commandable
  if commandable then
    commandable.set_command({
      type = defines.command.wander,
      distraction = defines.distraction.by_enemy
    })
  end
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
  if event.effect_id ~= "psyc-tower-convert" then return end

  local target = event.target_entity
  if not (target and target.valid and target.type == "unit") then return end
  if target.force.name ~= "enemy" then return end

  init_storage()

  local source = event.source_entity
  local tower_id = (source and source.valid and source.unit_number) or 0
  if count_for_tower(tower_id) >= MAX_CONVERTED then return end

  local controlled = game.forces[FORCE_NAME]
  if not controlled then
    setup_force()
    controlled = game.forces[FORCE_NAME]
  end

  -- Swap the biter for its tinted twin
  local converted
  local twin_name = "psyc-" .. target.name
  if prototypes.entity[twin_name] then
    converted = target.surface.create_entity{
      name = twin_name,
      position = target.position,
      force = controlled
    }
    if converted then
      converted.health = target.health
      target.destroy()
    end
  end

  -- Fallback: no twin available, so convert in place (no tint)
  if not converted then
    target.release_from_spawner()
    target.force = controlled
    converted = target
  end

  give_orders(converted)

  storage.converted[converted.unit_number] = {
    entity = converted,
    tower_id = tower_id,
    expires = game.tick + LIFETIME_TICKS
  }

  -- Full: stop the tower from wasting shots until a slot frees up
  if source and source.valid and count_for_tower(tower_id) >= MAX_CONVERTED then
    source.disabled_by_script = true
    storage.full_towers[tower_id] = source
  end
end)

-- Once a second: expire old units, re-enable towers with free slots
script.on_nth_tick(60, function()
  if not storage.converted then return end

  for id, rec in pairs(storage.converted) do
    if not rec.entity.valid then
      storage.converted[id] = nil
    elseif game.tick >= rec.expires then
      rec.entity.die() -- "brain rot"
      storage.converted[id] = nil
    end
  end

  for tower_id, tower in pairs(storage.full_towers) do
    if not tower.valid then
      storage.full_towers[tower_id] = nil
    elseif count_for_tower(tower_id) < MAX_CONVERTED then
      tower.disabled_by_script = false
      storage.full_towers[tower_id] = nil
    end
  end
end)
end)