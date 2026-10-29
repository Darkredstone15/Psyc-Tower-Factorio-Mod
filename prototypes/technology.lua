data:extend({
  {
    type = "technology",
    name = "psyc-tower-technology",
    icon = "__base__/graphics/technology/laser-turret.png",
    icon_size = 256,
    effects = {
      {
        type = "unlock-recipe",
        recipe = "psyc-tower"
      }
    },
    prerequisites = {"military-4"},
    unit = {
      count = 350,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1},
        {"military-science-pack", 1},
        {"utility-science-pack", 1}
      },
      time = 30
    },
    order = "a-j-a"
  }
})