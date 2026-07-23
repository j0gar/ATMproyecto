return {
    id = "emerald_furnace",
    name = "Emerald Furnace",
    peripheral = "ironfurnaces:emerald_furnace_0",
    slots = {inputs={1}, fuel={2}, outputs={3}},
    defaults = {enabled=true, fuelTarget=32, inputBatch=64},
    settings = {
        {key="fuelTarget", label="Combustible", type="number", min=1, max=64, step=1, suffix=" carbon"}
    },
    fuel = {name="minecraft:coal"},
    accepts = function(detail)
        return detail and detail.tags and detail.tags["c:raw_materials"] == true
    end
}
