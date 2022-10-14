local posUtil = require "posUtil"

local testUtils = require "testsInGame.utils"


local function testRestockCropSticks()
    local farmer = testUtils.createTestFarmer()
    farmer.action:restockCropSticksIfNotEnough()
end

local function testDumpLootsIfNeeded()
    local farmer = testUtils.createTestFarmer()
    farmer.action:dumpLootsIfNeeded()
    farmer.gps:backOrigin()
end

local function testBreakCrop()
    local farmer = testUtils.createTestFarmer()
    farmer.action:breakCrop()
end

local function testTransplantCrop()
    local farmer = testUtils.createTestFarmer()
    farmer.action:equippedOrExit(true, true, true)
    farmer.action:transplantCrop({ -1, 1 }, { 2, 0 })
    farmer.action:transplantCrop({ -3, 1 }, { 2, 2 })
    farmer.gps:backOrigin()
end

local function testSafeEquip()
    local component = require "component"
    local invControl = component.inventory_controller

    local farmer = testUtils.createTestFarmer()
    farmer.action:equippedOrExit(true, true, true)
    farmer.action:doAfterSafeEquip(farmer:spadeSlot(), function()
        os.sleep(0.5)
        farmer.action:doAfterSafeEquip(farmer:binderSlot(), function()
            os.sleep(0.5)
            farmer.action:doAfterSafeEquip(farmer:cropStickSlot(), function()
                os.sleep(0.5)
            end)
        end)
    end)
    print("slot spade: " .. invControl.getStackInInternalSlot(farmer:spadeSlot()).name)
    print("slot binder: " .. invControl.getStackInInternalSlot(farmer:binderSlot()).name)
    print("slot crop stick: " .. invControl.getStackInInternalSlot(farmer:cropStickSlot()).name)
end

local function testCheckEquipment()
    local farmer = testUtils.createTestFarmer()
    print(farmer.action:checkEquipment(true, true, true))
end

local function testCleanUpBreedFarm()
    local farmSize = 5
    local farmer = testUtils.createTestFarmer()
    farmer.action:equippedOrExit(true, false, false)
    farmer.action:cleanUpFarm(posUtil.allBreedPos(farmSize))
    farmer.gps:backOrigin()
end

local function testDumpLoots()
    local farmer = testUtils.createTestFarmer()
    farmer.action:dumpLoots()
    farmer.gps:backOrigin()
end

local function testPlaceCropSticks()
    local farmer = testUtils.createTestFarmer()
    farmer.gps:go({ -2, -1 })
    farmer.action:placeCropSticks(true)
    farmer.gps:backOrigin()
end

local function testTestsIfFarmlandBelow(pos)
    local farmer = testUtils.createTestFarmer()
    farmer.action:checkEquipment(true, false, true)
    farmer.gps:go(pos)
    print(farmer.action:testsIfFarmlandBelow())
    farmer.gps:backOrigin()
end

testTestsIfFarmlandBelow({-1, -1})
