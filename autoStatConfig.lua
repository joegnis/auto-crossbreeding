---@type StatConfig
local config = {
    ---the side length of the crossbreeding farm
    breedFarmSize = 6,
    ---the side length of the new crop storage farm
    storageFarmSize = 11,
    ---Whether to double check if a farm block is a farmland that can
    ---be placed with crop sticks.
    ---Non-farmland, e.g. water block, will be skipped when
    ---transplanting crops.
    checkStorageFarmland = true,
    checkBreedFarmland = true,
}

---@class StatConfig: ConfigBase

return config
