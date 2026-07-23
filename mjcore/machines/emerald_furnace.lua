return {
    id = "emerald_furnace",
    name = "Emerald Furnace",
    peripheral = "ironfurnaces:emerald_furnace_0",
    slots = {inputs={1}, fuel={2}, outputs={3}},
    fuel = {name="minecraft:coal", target=32},
    accepts = function(detail)
        return detail and detail.tags and detail.tags["c:raw_materials"] == true
    end
}
