data:extend({
  {
    type = "item",
    name = "psyc-tower",
    icons = {
      {
        icon = "__base__/graphics/icons/beacon.png",
        icon_size = 64,
        tint = {r = 0.5, g = 0.5, b = 1.0, a = 1.0}
      }
},
    subgroup = "defensive-structure",
    order = "b[turret]-a[psyc-tower]",
    place_result = "psyc-tower",
    stack_size = 50
  }
})