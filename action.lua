local component = require "component"
local inventoryController = component.inventory_controller
local geolyzer = component.geolyzer
local redstone = component.redstone
local robot = require "robot"
local os = require "os"
local sides = require "sides"

local utils = require "utils"


---@class Action
---@field farmer_ Farmer
---@field globalConfig_ GlobalConfig
---@field gps_ table
---@field curEquip_ string
local Action = {}

---@param farmer Farmer
function Action:new(farmer)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)

    o.farmer_ = farmer
    o.globalConfig_ = farmer.globalConfig
    o.gps_ = farmer.gps

    return o
end

---@param duration number?
function Action:pulseDown(duration)
    if duration == nil then
        duration = 0.2
    end
    redstone.setOutput(sides.down, 15)
    os.sleep(duration)
    redstone.setOutput(sides.down, 0)
end


---Tests if it is a farmable block two blocks below the robot by
---trying to place a cropstick
---@param scannedInfo ScannedInfo?
---@return boolean
function Action:testsIfFarmlandBelow(scannedInfo)
    if not scannedInfo then
        scannedInfo = self:scanBelow()
    end
    if scannedInfo.name == "air" then
        if self:placeCropSticks() then
            self:breakCrop()
            return true
        end
    end
    return false
end

---Scans the block below the robot
---@return ScannedInfo
function Action:scanBelow()
    local rawResult = geolyzer.analyze(sides.down)
    if rawResult.name == "minecraft:air"
        or rawResult.name == "GalacticraftCore:tile.brightAir"
    then
        return { isCrop = false, name = "air" }
    elseif rawResult.name == "IC2:blockCrop" then
        if rawResult["crop:name"] == nil then
            return { isCrop = false, name = "cropStick" }
        elseif rawResult["crop:name"] == "weed" then
            return { isCrop = false, name = "weed" }
        else
            return {
                isCrop = true,
                name = rawResult["crop:name"],
                gr = rawResult["crop:growth"],
                ga = rawResult["crop:gain"],
                re = rawResult["crop:resistance"],
                tier = rawResult["crop:tier"]
            }
        end
    else
        return { isCrop = false, name = rawResult.name }
    end
end

---@param placeDouble boolean?
---@return boolean # true if placed
function Action:placeCropSticks(placeDouble)
    placeDouble = placeDouble or false
    local count = placeDouble and 2 or 1

    self:doAfterSavePos(function()
        self:restockCropSticksIfNotEnough()
    end)

    return self:doAfterSafeEquip(self.farmer_:cropStickSlot(), function()
        local placed = true
        local _, interact_result = robot.useDown()
        if interact_result ~= "item_placed" then
            placed = false
        else
            for _ = 1, count - 1 do
                robot.useDown()
            end
        end
        return placed
    end)
end

function Action:breakCrop()
    self:doAfterSavePos(function()
        self:dumpLootsIfNeeded()
    end)
    self:doAfterSafeEquip(self.farmer_:spadeSlot(), function()
        robot.useDown()
        robot.swingDown()
        if self.globalConfig_.takeCareOfDrops then
            robot.suckDown()
        end
    end)
end

function Action:deweed()
    self:doAfterSafeEquip(self.farmer_:spadeSlot(), function()
        robot.useDown()
        robot.swingDown()
        if self.globalConfig_.takeCareOfDrops then
            robot.suckDown()
        end
    end)
end

---Dumps all items in internal inventory, except for the three tools (last three slots)
---and any item in toolbelt (hand), into storage inventory
---when internal inventory's fullness reaches a certain level
function Action:dumpLootsIfNeeded()
    self:dumpLootsThreshold_(robot.inventorySize() * 0.65)
end

---Dumps all items in internal inventory, except for the three tools (last three slots)
---and any item in toolbelt (hand), into storage inventory
function Action:dumpLoots()
    self:dumpLootsThreshold_(0)
end

---Dumps loots if inventory are used over a threshold
---@param threshold integer
function Action:dumpLootsThreshold_(threshold)
    local occupiedSlots = {}
    for slot = 1, self.farmer_:storageEndSlot() do
        if robot.count(slot) > 0 then
            occupiedSlots[#occupiedSlots + 1] = slot
        end
    end

    if #occupiedSlots > threshold then
        self:doAfterSaveSelectedSlot(function()
            self.gps_:go(self.globalConfig_.storagePos)
            for _, slot in ipairs(occupiedSlots) do
                robot.select(slot)
                robot.dropDown()
            end
        end)
    end
end

function Action:restockCropSticks()
    self:doAfterSaveSelectedSlot(function()
        self.gps_:go(self.globalConfig_.stickContainerPos)
        robot.select(self.farmer_:cropStickSlot())
        -- Can handle StorageDrawer
        while robot.count() < 64 and robot.suckDown(64 - robot.count()) do

        end
        if robot.count() < 64 then
            error(utils.newMsgError("Not enough crop sticks in its inventory"))
        end
    end)
end

function Action:restockCropSticksIfNotEnough()
    -- Weird thing might happen when only having 2 crop sticks
    if robot.count(self.farmer_:cropStickSlot()) < 5 then
        self:restockCropSticks()
    end
end

--[[
    Transplants a crop using transvector

    There should be a crop at fromPos, and toPos should be air above
    an empty farmland.

    The process:
    1. With binder in hand, click transvector
    2. Click the thing to be swapped
    3. Send a redstone signal to transvector
]]
---@param fromPos Position
---@param toPos Position
function Action:transplantCrop(fromPos, toPos)
    self:doAfterSafeEquip(self.farmer_:binderSlot(), function()
        -- transfer the crop to the relay location
        self.gps_:go(self.globalConfig_.dislocatorPos)
        robot.useDown(sides.down)
        self.gps_:go(fromPos)
        robot.useDown(sides.down, true) -- sneak-right-click on crops to prevent harvesting
        self.gps_:go(self.globalConfig_.dislocatorPos)
        self:pulseDown()

        -- transfer the crop to the destination
        robot.useDown(sides.down)
        self.gps_:go(toPos)
        if self:scanBelow().name == "air" then
            -- e.g. does not place a stick when transplanting to an existing
            -- parent plant in breed farm
            self:placeCropSticks()
        end
        robot.useDown(sides.down, true)
        self.gps_:go(self.globalConfig_.dislocatorPos)
        self:pulseDown()

        -- destroy the original crop
        self.gps_:go(self.globalConfig_.relayFarmlandPos)
        self:breakCrop()
    end)
end

---@param checkSpade boolean
---@param checkBinder boolean
---@param checkSticks boolean
---@return boolean
---@return string? msg
function Action:checkEquipment(checkSpade, checkBinder, checkSticks)
    local msg = {}
    local info
    if checkSpade then
        info = inventoryController.getStackInInternalSlot(self.farmer_:spadeSlot())
        if not info or info.name ~= utils.SPADE_MCNAME then
            msg[#msg + 1] = "Missing spade at slot " .. self.farmer_:spadeSlot()
        end
    end

    if checkBinder then
        info = inventoryController.getStackInInternalSlot(self.farmer_:binderSlot())
        if not info or info.name ~= utils.BINDER_MCNAME then
            msg[#msg + 1] = "Missing binder at slot " .. self.farmer_:binderSlot()
        end
    end

    if checkSticks then
        info = inventoryController.getStackInInternalSlot(self.farmer_:cropStickSlot())
        if not info or info.name ~= utils.CROPSTICK_MCNAME then
            msg[#msg + 1] = "Missing crop stick at slot " .. self.farmer_:cropStickSlot()
        end
    end

    if #msg > 0 then
        return false, table.concat(msg, "; ")
    end
    return true
end

---@param checkSpade boolean
---@param checkBinder boolean
---@param checkSticks boolean
function Action:equippedOrExit(checkSpade, checkBinder, checkSticks)
    local res, msg = self:checkEquipment(checkSpade, checkBinder, checkSticks)
    if not res then
        io.stderr:write(msg)
        os.exit(false)
    end
end

---Returns a set of crop names from seed bags in the storage at the position
---@param storagePos Position
---@return Set<string>
function Action:getBreedsFromSeedsInInventory(storagePos)
    self.gps_:go(storagePos)
    local breeds = {}
    for stack in inventoryController.getAllStacks(sides.down) do
        if stack.name == utils.SEED_BAG_MCNAME then
            -- Seed bags might not be scanned yet
            if stack.crop then
                local cropName = stack.crop.name
                breeds[cropName] = true
            end
        end
    end
    return breeds
end

---Breaks all weeds and crop sticks in a farm
---@param iterFarm fun(): integer, Position
function Action:cleanUpFarm(iterFarm)
    for slot, pos in iterFarm do
        self.gps_:go(pos)
        local scanned = self:scanBelow()
        if scanned.name == "cropStick" or utils.isWeed(scanned) then
            self:breakCrop()
        end
    end
end

---@generic T
---@param funDo fun(): T
---@return T
function Action:doAfterSavePos(funDo)
    self.gps_:save()
    local ret = funDo()
    self.gps_:resume()
    return ret
end

---@generic T
---@param funDo fun(): T
---@return T
function Action:doAfterSaveSelectedSlot(funDo)
    local selected = robot.select()
    local ret = funDo()
    robot.select(selected)
    return ret
end

---@generic T
---@param slot integer
---@param funDo fun(): `T`
---@return T
function Action:doAfterSafeEquip(slot, funDo)
    local toEquip = inventoryController.getStackInInternalSlot(slot).name
    if self.curEquip_ and self.curEquip_ == toEquip then
        return funDo()
    end

    local ret
    self:doAfterSaveSelectedSlot(function()
        robot.select(slot)
        inventoryController.equip()
        local oldEquip = self.curEquip_
        self.curEquip_ = toEquip
        ret = funDo()
        robot.select(slot)
        inventoryController.equip()
        self.curEquip_ = oldEquip
    end)
    return ret
end

return Action
