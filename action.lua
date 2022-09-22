local component = require("component")
local robot = require("robot")
local computer = require("computer")
local os = require("os")
local sides = require("sides")
local gps = require("gps")
local signal = require("signal")

local posUtil = require("posUtil")
local utils = require("utils")
local Deque = utils.Deque
local globalConfig = require("config")

local geolyzer = component.geolyzer
local inventoryController = component.inventory_controller


---@class Action
---@field chargerPos Position
---@field cropSticksContainerPos Position
---@field relayFarmlandPos Position
---@field dislocatorPos Position
---@field storagePos Position
---@field spadeSlot integer
---@field binderSlot integer
---@field cropStickSlot integer
---@field storageStopSlot integer
---@field takeCareOfDrops boolean
---@field assumeNoBareStick boolean
---@field needChargeLevel number
---@field getBreedStatScore_ fun(ga: integer, gr: integer, re: integer): integer
---@field getSpreadStatScore_ fun(ga: integer, gr: integer, re: integer): integer
---@field curEquip_ string
local Action = {}

function Action:new(o)
    o = o or {}
    self.__index = self
    o = setmetatable(o, self)

    local inventorySize = robot.inventorySize()
    o.chargerPos = o.chargerPos or globalConfig.chargerPos
    o.cropSticksContainerPos = o.cropSticksContainerPos or globalConfig.stickContainerPos
    o.relayFarmlandPos = o.relayFarmlandPos or globalConfig.relayFarmlandPos
    o.dislocatorPos = o.dislocatorPos or globalConfig.dislocatorPos
    o.storagePos = o.storagePos or globalConfig.storagePos
    o.spadeSlot = inventorySize + (o.spadeSlotOffset or globalConfig.spadeSlot)
    o.binderSlot = inventorySize + (o.binderSlotOffset or globalConfig.binderSlot)
    o.cropStickSlot = inventorySize + (o.cropStickSlotOffset or globalConfig.stickSlot)
    o.storageStopSlot = inventorySize + (o.storageStopSlotOffset or globalConfig.storageStopSlot)
    o.takeCareOfDrops = o.takeCareOfDrops or globalConfig.takeCareOfDrops
    o.assumeNoBareStick = o.assumeNoBareStick or globalConfig.assumeNoBareStick
    o.needChargeLevel = o.needChargeLevel or globalConfig.needChargeLevel

    return o
end

---Scans a farm with slots and positions provided by an iterator.
---Provides initial parameters for farms' constructor.
---Returns slot->scanned info dict, crop name->slot dict, and
---empty farmland slots deque.
---Can check if a slot really has a farmblock beneath by trying to
---place a crop stick. This can slow down the process but it enables
---the support for water block, non-farmblock etc.
---If checkFarmland is true, only real farm land slots will be added to
---the deque.
---@param iterSlotAndPos fun(): integer, Position
---@param checkFarmland boolean?
---@return table<integer, ScannedInfo>, table<string, integer>, Deque
function Action:scanFarm(iterSlotAndPos, checkFarmland)
    checkFarmland = checkFarmland or false
    local cropsInfo = {}
    local reverseCropsInfo = {}
    local emptyFarmlands = Deque:new()
    local countCrops = 0
    local countBlocks = 0
    for slot, pos in iterSlotAndPos do
        gps.go(pos)
        local scannedInfo = self:scanBelow()
        if scannedInfo.isCrop then
            cropsInfo[slot] = scannedInfo
            reverseCropsInfo[scannedInfo.name] = slot
            countCrops = countCrops + 1
        elseif utils.isWeed(scannedInfo) then
            self:deweed()
        else
            if scannedInfo.name == "air" then
                if checkFarmland then
                    if self:placeCropSticks() then
                        emptyFarmlands:pushFirst(slot)
                        self:breakCrop()
                    end
                else
                    emptyFarmlands:pushFirst(slot)
                end
            end
        end
        countBlocks = countBlocks + 1
    end
    return cropsInfo, reverseCropsInfo, emptyFarmlands
end

---@alias ScannedInfo
---| { isCrop: 'true', name: string, gr: integer, ga: integer, re: integer, tier: integer }
---| { isCrop: 'false', name: '"weed"' }
---| { isCrop: 'false', name: '"air"' }
---| { isCrop: 'false', name: '"cropStick"' }
---| { isCrop: 'false', name: string }
---Scans the block below the robot
---@return ScannedInfo
function Action:scanBelow()
    local rawResult = geolyzer.analyze(sides.down)
    if rawResult.name == "minecraft:air"
        or rawResult.name == "GalacticraftCore:tile.brightAir"
        or rawResult.name == "Thaumcraft:blockAiry" then
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

function Action:placeCropSticks(placeDouble)
    placeDouble = placeDouble or false
    local count = placeDouble and 2 or 1

    if robot.count(self.cropStickSlot) < count then
        self:doAfterSavePos(function()
            self:restockCropSticks()
        end)
    end

    return self:doAfterSafeEquip(self.cropStickSlot, function()
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
    self:doAfterSafeEquip(self.spadeSlot, function()
        robot.useDown()
        robot.swingDown()
        if self.takeCareOfDrops then
            robot.suckDown()
        end
    end)
end

function Action:deweed()
    self:doAfterSafeEquip(self.spadeSlot, function()
        robot.useDown()
        robot.swingDown()
        if self.takeCareOfDrops then
            robot.suckDown()
        end
    end)
end

---Dumps all items in internal inventory, except for the three tools (last three slots)
---and any item in toolbelt (hand), into storage inventory
---when internal inventory's fullness reachs a certain level
function Action:dumpLootsIfNeeded()
    self:dumpLootsThreshold_(robot.inventorySize() * 0.65)
end

---Dumps all items in internal inventory, except for the three tools (last three slots)
---and any item in toolbelt (hand), into storage inventory
function Action:dumpLoots()
    self:dumpLootsThreshold_(0)
end

function Action:dumpLootsThreshold_(threshold)
    local occupiedSlots = {}
    for slot = 1, self.storageStopSlot do
        if robot.count(slot) > 0 then
            occupiedSlots[#occupiedSlots + 1] = slot
        end
    end

    if #occupiedSlots > threshold then
        self:doAfterSaveSelectedSlot(function()
            gps.go(self.storagePos)
            for _, slot in ipairs(occupiedSlots) do
                robot.select(slot)
                robot.dropDown()
            end
        end)
    end
end

function Action:restockCropSticks()
    self:doAfterSaveSelectedSlot(function()
        gps.go(self.cropSticksContainerPos)
        robot.select(self.cropStickSlot)
        -- Can handle StorageDrawer
        while robot.count() < 64 and robot.suckDown(64 - robot.count()) do

        end
    end)
end

function Action:restockCropSticksIfNotEnough()
    if robot.count(self.cropStickSlot) < 2 then
        self:restockCropSticks()
    end
end

---@param needChargeLevel number?
function Action:chargeIfLowEnergy(needChargeLevel)
    if self:needsCharge(needChargeLevel) then
        gps.go(self.chargerPos)
        repeat
            os.sleep(0.5)
        until self:isFullyCharged()
    end
end

function Action:chargeLevel()
    return computer.energy() / computer.maxEnergy()
end

function Action:needsCharge(needChargeLevel)
    needChargeLevel = needChargeLevel or self.needChargeLevel
    return self:chargeLevel() <= needChargeLevel
end

function Action:isFullyCharged()
    return self:chargeLevel() > 0.99
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
    self:doAfterSafeEquip(self.binderSlot, function()
        -- transfer the crop to the relay location
        gps.go(self.dislocatorPos)
        robot.useDown(sides.down)
        gps.go(fromPos)
        robot.useDown(sides.down, true) -- sneak-right-click on crops to prevent harvesting
        gps.go(self.dislocatorPos)
        signal.pulseDown()

        -- transfer the crop to the destination
        robot.useDown(sides.down)
        gps.go(toPos)
        if self:scanBelow().name == "air" then
            -- e.g. does not place a stick when transplanting to an existing
            -- parent plant in breed farm
            self:placeCropSticks()
        end
        robot.useDown(sides.down, true)
        gps.go(self.dislocatorPos)
        signal.pulseDown()

        -- destroy the original crop
        gps.go(self.relayFarmlandPos)
        self:breakCrop()
    end)
end

---@param checkSpade boolean
---@param checkBinder boolean
---@param checkSticks boolean
function Action:checkEquipment(checkSpade, checkBinder, checkSticks)
    local msg = {}
    local info
    if checkSpade then
        info = inventoryController.getStackInInternalSlot(self.spadeSlot)
        if not info or info.name ~= utils.SPADE_MCNAME then
            msg[#msg + 1] = "Missing spade at slot " .. self.spadeSlot
        end
    end

    if checkBinder then
        info = inventoryController.getStackInInternalSlot(self.binderSlot)
        if not info or info.name ~= utils.BINDER_MCNAME then
            msg[#msg + 1] = "Missing binder at slot " .. self.binderSlot
        end
    end

    if checkSticks then
        info = inventoryController.getStackInInternalSlot(self.cropStickSlot)
        if not info or info.name ~= utils.CROPSTICK_MCNAME then
            msg[#msg + 1] = "Missing crop stick at slot " .. self.cropStickSlot
        end
    end

    if #msg > 0 then
        io.stderr:write(table.concat(msg, "; "))
        os.exit(false)
    end
end

---Breaks all weeds and crop sticks in breed farm
---@param farmSize integer
function Action:cleanUpBreedFarm(farmSize)
    for slot, pos in posUtil.allBreedPos(farmSize) do
        gps.go(pos)
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
    gps.save()
    local ret = funDo()
    gps.resume()
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
---@param funDo fun(): T
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
