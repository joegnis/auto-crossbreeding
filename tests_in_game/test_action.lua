local Action = require "action"
local gps = require "gps"


local function testRestockCropSticks()
    local action = Action:new()
    action:restockCropSticksIfNotEnough()
end

local function testDumpLootsIfNeeded()
    local action = Action:new()
    action:dumpLootsIfNeeded()
    gps.backOrigin()
end

local function testBreakCrop()
    local action = Action:new()
    action:breakCrop()
end

local function testTransplantCrop()
    local action = Action:new()
    action:checkEquipment(true, true, true)
    action:transplantCrop({ -1, 1 }, { 2, 0 })
    action:transplantCrop({ -3, 1 }, { 2, 2 })
    gps.backOrigin()
end

local function testSafeEquip()
    local component = require "component"
    local invControl = component.inventory_controller

    local action = Action:new()
    action:checkEquipment(true, true, true)
    action:doAfterSafeEquip(action.spadeSlot, function()
        os.sleep(0.5)
        action:doAfterSafeEquip(action.binderSlot, function()
            os.sleep(0.5)
            action:doAfterSafeEquip(action.cropStickSlot, function()
                os.sleep(0.5)
            end)
        end)
    end)
    print("slot spade: " .. invControl.getStackInInternalSlot(action.spadeSlot).name)
    print("slot binder: " .. invControl.getStackInInternalSlot(action.binderSlot).name)
    print("slot crop stick: " .. invControl.getStackInInternalSlot(action.cropStickSlot).name)
end

local function testCheckEquipment()
    local action = Action:new()
    action:checkEquipment(true, true, true)
end

local function testCleanUpBreedFarm()
    local farmSize = 5
    local action = Action:new()
    action:checkEquipment(true, false, false)
    action:cleanUpBreedFarm(farmSize)
    gps.backOrigin()
end

local function testDumpLoots()
    local action = Action:new()
    action:dumpLoots()
    gps.backOrigin()
end

testDumpLoots()
