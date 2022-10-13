local M = {}

---@type GlobalConfig
M.config = {
    -- be aware that each config should be followed by a comma
    -- farm size config for each mode is moved to separate files

    -- below which percentage should the robot to charge itself.
    needChargeLevel = 0.2,
    -- the coordinate for charger
    chargerPos = { 0, 0 },
    -- the coordinate for the container contains crop sticks
    stickContainerPos = { 0, 1 },
    -- the coordinate for the farmland that the dislocator is facing
    relayFarmlandPos = { 0, 2 },
    -- the coordinate for the transvector dislocator
    dislocatorPos = { 0, 3 },
    -- the coordinate for the container to store seeds, products, etc
    -- has no effect unless you turn on "takeCareOfDrops" flag.
    storagePos = { 0, 5 },

    -- the slot for spade, count from 0, count from bottom-right to top-left
    spadeSlotOffset = 0,
    -- the slot for binder for the transvector dislocator
    binderSlotOffset = -1,
    -- the slot for crop sticks
    stickSlotOffset = -2,
    -- to which slot should the robot stop storing items
    storageEndSlotOffset = -3,
    -- Max breed round before termination. Used on server to avoid left-alone robot endlessly
    -- consuming resources. Set to nil for infinite loop.
    maxBreedRound = 1000,

    -- flags

    -- if you turn on this flag, the robot will try to take care of the item drops
    -- from destroying crops, harvesting crops, destroying sticks, etc
    takeCareOfDrops = true,

    -- assume there is no bare stick in the farm, should increase speed.
    -- On the other side, turning it on along with weed-ex makes sure weeds are taken care of
    assumeNoBareStick = false,
}

---@class GlobalConfig
---@field needChargeLevel number
---@field chargerPos Position
---@field stickContainerPos Position
---@field relayFarmlandPos Position
---@field dislocatorPos Position
---@field storagePos Position
---@field spadeSlotOffset integer
---@field binderSlotOffset integer
---@field stickSlotOffset integer
---@field storageEndSlotOffset integer
---@field maxBreedRound integer
---@field takeCareOfDrops boolean
---@field assumeNoBareStick boolean

---@type GlobalConfig
M.defaultConfig = {
    needChargeLevel = 0.2,
    chargerPos = { 0, 0 },
    stickContainerPos = { 0, 1 },
    relayFarmlandPos = { 0, 2 },
    dislocatorPos = { 0, 3 },
    storagePos = { 0, 5 },

    spadeSlotOffset = 0,
    binderSlotOffset = -1,
    stickSlotOffset = -2,
    storageEndSlotOffset = -3,
    maxBreedRound = 1000,

    takeCareOfDrops = true,
    assumeNoBareStick = false,
}

return M
