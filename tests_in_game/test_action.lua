local Action = require "action"
local gps = require "gps"
local posUtil = require "posUtil"
local utils = require "utils"


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
    action:equippedOrExit(true, true, true)
    action:transplantCrop({ -1, 1 }, { 2, 0 })
    action:transplantCrop({ -3, 1 }, { 2, 2 })
    gps.backOrigin()
end

local function testSafeEquip()
    local component = require "component"
    local invControl = component.inventory_controller

    local action = Action:new()
    action:equippedOrExit(true, true, true)
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
    print(action:checkEquipment(true, true, true))
end

local function testCleanUpBreedFarm()
    local farmSize = 5
    local action = Action:new()
    action:equippedOrExit(true, false, false)
    action:cleanUpFarm(posUtil.allBreedPos(farmSize))
    gps.backOrigin()
end

local function testDumpLoots()
    local action = Action:new()
    action:dumpLoots()
    gps.backOrigin()
end

local function testPlaceCropSticks()
    local action = Action:new()
    gps.go({ -2, -1 })
    action:placeCropSticks(true)
    gps.backOrigin()
end

local function testMsgError()
    local ok = xpcall(
        function()
            --error(utils.newMsgError("foobar"))
            error("foobar")
        end,
        function(err)
            if utils.isMsgError(err) then
                print("caught a MsgError")
            else
                print("it is a normal error")
                io.stderr:write(err .. "\n")
                io.stderr:write(debug.traceback() .. "\n")
            end
            return err
        end
    )
    print("ok: " .. tostring(ok))
end

testMsgError()
