--[[
    In-game, not automated tests
]]
local robot = require "robot"
local component = require "component"
local gps = require "gps"
local posUtil = require "posUtil"
local action  = require "Action"
local config = require "config"

local INVENTORY_CONTROLLER = component.inventory_controller

local function testUse()
    gps.go(posUtil.storageToGlobal(1))
    robot.select(14)  -- crop sticks
    INVENTORY_CONTROLLER.equip()
    print(robot.useDown())
end

local function testPlaceStickInStorageFarm()
    config.storageFarmSize = 3
    config.storageFarmArea = 9
    gps.go(posUtil.storageToGlobal(1))
    print(action.placeCropStick())
end

local function testPlaceStickInBreedFarm()
    config.farmSize = 3
    config.farmArea = 9
    gps.go(posUtil.farmToGlobal(2))
    print(action.placeCropStick())
end

local function testIter()
    local function iter()
        local nextSlot = 0
        return function ()
            nextSlot = nextSlot + 1
            if nextSlot < 36 then
                return nextSlot
            else
                return nil
            end
        end
    end

    local it = iter()
    for i = 1, 5 do
        print(it())
    end
end

local function testTransplantSkipBlocks()
    config.autoSpread.breedFarmSize = 6
    config.autoSpread.storageFarmSize = 11
    local BREED_FARM_SLOTS = {2, 3, 10, 12, 17, 18}

    local nextStorageSlot = 1
    for _, breedSlot in ipairs(BREED_FARM_SLOTS) do
        print("Transporting crop at farm slot " .. breedSlot)
        gps.go(posUtil.farmToGlobal(breedSlot))
        local firstFailed = false
        local success = action.transplantToStorageFarm(
            posUtil.farmToGlobal(breedSlot),
            posUtil.storageToGlobal(nextStorageSlot),
            function ()
                firstFailed = true
                local slot = nextStorageSlot
                if slot <= config.storageFarmArea then
                    nextStorageSlot = nextStorageSlot + 1
                    return posUtil.storageToGlobal(slot)
                end
            end
        )
        if not firstFailed then
            nextStorageSlot = nextStorageSlot + 1
        end
        if success then
            print(string.format("Transported crop to storage slot %d", nextStorageSlot - 1))
        else
            print(string.format("Failed transporting crop to storage slot %d", nextStorageSlot - 1))
        end
        if nextStorageSlot > config.storageFarmArea then
            print(string.format("Storage farm is full (%d). Stopping.", config.storageFarmArea))
            break
        end
    end
    gps.go({0, 0})
end
