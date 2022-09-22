local config = {
    -- be aware that each config should be followed by a comma
    -- farm size config for each mode is moved to separate files

    -- below which percentage should the robot to charge itself.
    needChargeLevel = 0.2,
    -- the coordinate for charger
    chargerPos = { 0, 0 },
    -- the coordinate for the container contains crop sticks
    stickContainerPos = { 0, 1 },
    -- the coordinate for the farmland that the dislocaotr is facing
    relayFarmlandPos = { 0, 2 },
    -- the coordinate for the transvector dislocator
    dislocatorPos = { 0, 3 },
    -- the coordinate for the container to store seeds, products, etc
    -- has no effect unless you turn on "takeCareOfDrops" flag.
    storagePos = { 0, 5 },

    -- the slot for spade, count from 0, count from bottom-right to top-left
    spadeSlot = 0,
    -- the slot for binder for the transvector dislocator
    binderSlot = -1,
    -- the slot for crop sticks
    stickSlot = -2,
    -- to which slot should the robot stop storing items
    storageStopSlot = -3,
    -- Max breed round before termination. Used on server to avoid left-alone robot endlessly
    -- consuming resources. Set to nil for infinite loop.
    maxBreedRound = 1000,

    -- flags

    -- if you turn on this flag, the robot will try to take care of the item drops
    -- from destroying crops, harvesting crops, destroying sticks, etc
    -- if you are using this scrip set to do everything, there isn't realy any point to use this.
    -- this option and the option below isn't actively maintained because I don't use this function.
    takeCareOfDrops = true,

    -- if you turn on this flag, the robot will only choose the crop with
    -- gr > 21, < 24, ga == 31, re == 0 to spread.
    -- helpful while debuging.
    bestStatWhileSpreading = true,

    -- assume there is no bare stick in the farm, should increace speed.
    -- On the other side, turning it on along with weed-ex makes sure weeds are taken care of
    assumeNoBareStick = false,

    -----------Do Not Change Zone------------

    multifarmCentorOffset = { -3, 4 },

    multifarmDislocatorPoses = {
        { 2, 0 },
        { 0, -2 },
        { -2, 0 },
        { 0, 2 }
    },

    multifarmRelayFarmlandPoses = {
        { 3, 0 },
        { 0, -3 },
        { -3, 0 },
        { 0, 3 }
    },

    multifarmSize = 20,
    elevatorPos = { 0, 4 }
}

return config
