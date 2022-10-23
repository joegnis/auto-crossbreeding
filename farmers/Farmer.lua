local computer = require "computer"
local robot = require "robot"

local Action = require "action"
local Gps = require "gps"
local posUtil = require "posUtil"
local StorageFarm = require "farms.StorageFarm"
local utils = require "utils"


---@alias Facing '0' | '1' | '2' | '3'

---@class Farmer
---@field globalConfig GlobalConfig
---@field action Action
---@field gps Gps
---@field position_ Position
---@field facing_ Facing
---@field getBreedStatScore_ funGetStatScore
---@field getSpreadStatScore_ funGetStatScore
local Farmer = {}

-------------------
-- Class Methods --
-------------------
function Farmer:new()
    error("Farmer should not be instantiated", 2)
end

----------------------
-- Instance Methods --
----------------------

---For child class constructor to call
---@param config GlobalConfig
---@param initPos Position?
---@param initFacing Facing?
---@param getBreedStatScore funGetStatScore?
---@param getSpreadStatScore funGetStatScore?
function Farmer:init_(
    config, initPos, initFacing, getBreedStatScore, getSpreadStatScore
)
    self.globalConfig = config
    self.action = Action:new(self)
    self.gps = Gps:new(self)
    self.position_ = initPos or { 0, 0 }
    self.facing_ = initFacing or 1
    self.getBreedStatScore_ = getBreedStatScore or function(ga, gr, re)
        return ga + gr - re
    end
    self.getSpreadStatScore_ = getSpreadStatScore or function(ga, gr, re)
        return ga + gr
    end
end

function Farmer:facing()
    return self.facing_
end

function Farmer:pos()
    return self.position_
end

---@return integer
function Farmer:spadeSlot()
    return robot.inventorySize() + self.globalConfig.spadeSlotOffset
end

---@return integer
function Farmer:binderSlot()
    return robot.inventorySize() + self.globalConfig.binderSlotOffset
end

---@return integer
function Farmer:cropStickSlot()
    return robot.inventorySize() + self.globalConfig.stickSlotOffset
end

---@return integer
function Farmer:storageEndSlot()
    return robot.inventorySize() + self.globalConfig.storageEndSlotOffset
end

function Farmer:chargeLevel()
    return computer.energy() / computer.maxEnergy()
end

function Farmer:needsCharge(needChargeLevel)
    needChargeLevel = needChargeLevel or self.globalConfig.needChargeLevel
    return self:chargeLevel() <= needChargeLevel
end

function Farmer:isFullyCharged()
    return self:chargeLevel() > 0.99
end

---@param needChargeLevel number?
function Farmer:chargeIfLowEnergy(needChargeLevel)
    if self:needsCharge(needChargeLevel) then
        self.gps:go(self.globalConfig.chargerPos)
        repeat
            os.sleep(0.5)
        until self:isFullyCharged()
    end
end

--[[
Scans a farm with slots and positions provided by an iterator.
Provides initial parameters for farms' constructor.

Returns slot->scanned info dict and a list of empty farmland slots.
Only slots with crops are added to the dictionaries.

If checkFarmland is true, checks if a slot really has a farmable block beneath
by trying placing a crop stick.
This can slow down the process but it detects non-farmable blocks like water block.

When checkFarmland is true, only real farmland slots will be added to the list.
]]
---@param iterSlotAndPos fun(): integer, Position
---@param checkFarmland boolean?
---@return table<integer, ScannedInfo>, integer[]
function Farmer:scanFarm(iterSlotAndPos, checkFarmland)
    checkFarmland = checkFarmland or false
    local cropsInfo = {}
    local emptyFarmlands = {}
    local countCrops = 0
    local countBlocks = 0
    for slot, pos in iterSlotAndPos do
        self.gps:go(pos)
        local scannedInfo = self.action:scanBelow()
        if scannedInfo.isCrop then
            cropsInfo[slot] = scannedInfo
            countCrops = countCrops + 1
        elseif utils.isWeed(scannedInfo) then
            self.action:deweed()
        else
            if scannedInfo.name == "air" then
                if checkFarmland then
                    if self.action:testsIfFarmlandBelow(scannedInfo) then
                        emptyFarmlands[#emptyFarmlands + 1] = slot
                    end
                else
                    emptyFarmlands[#emptyFarmlands + 1] = slot
                end
            end
        end
        countBlocks = countBlocks + 1
    end
    return cropsInfo, emptyFarmlands
end

---Scans storage farm and creates a StorageFarm instance
---@param checkFarmland boolean
---@param cropsBlacklist? string[]
---@return StorageFarm
function Farmer:scanStorageFarm(size, checkFarmland, cropsBlacklist)
    local storageCrops, storageEmptyLands = self:scanFarm(
        StorageFarm:iterAllSlotPos(size), checkFarmland
    )
    return StorageFarm:new(
        size, storageCrops, storageEmptyLands,
        cropsBlacklist
    )
end

------------------------
-- Breed Loop Related --
------------------------

---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
---@return boolean # true if breeding finished
function Farmer:breed(breedFarm, storageFarm)
    for slot, pos in posUtil.allBreedPos(breedFarm:size()) do
        if storageFarm:isFull() then
            print("Storage farm full.")
            return true
        end

        self.gps:go(pos)

        local scanned = self.action:scanBelow()
        if slot % 2 == 0 then
            self:handleBreedOffspring_(slot, pos, scanned, breedFarm, storageFarm)
        else
            self:handleBreedParent_(slot, pos, scanned, breedFarm, storageFarm)
        end
    end
    return false
end

---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
---@param maxBreedRound integer?
function Farmer:breedLoop(breedFarm, storageFarm, maxBreedRound)
    maxBreedRound = maxBreedRound or self.globalConfig.maxBreedRound
    local breedRound = 1
    while true do
        print(string.format("Breeding round %d. Max %d.", breedRound, maxBreedRound))
        self.action:dumpLootsIfNeeded()
        self.action:restockCropSticksIfNotEnough()
        self:chargeIfLowEnergy()
        self.gps:go({ 0, 0 })
        local done = self:breed(breedFarm, storageFarm)
        if done then
            break
        end

        breedRound = breedRound + 1
        if breedRound > maxBreedRound then
            print("Max breeding round reached.")
            break
        end
    end
end

---@param slot integer
---@param pos Position
---@param scanned ScannedInfo
---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
function Farmer:handleBreedParent_(slot, pos, scanned, breedFarm, storageFarm)
    if utils.isWeed(scanned) then
        self.action:deweed()
        breedFarm:removeParentCropAt(slot)
    elseif scanned.name == "cropStick" then
        self.action:breakCrop()
    end
end

---@param slot integer
---@param pos Position
---@param scanned ScannedInfo
---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
function Farmer:handleBreedOffspring_(slot, pos, scanned, breedFarm, storageFarm)
    if scanned.name == "air" then
        self:handleOffspringAir_(slot, pos, scanned, breedFarm)
    elseif scanned.name == "cropStick" then
        self:handleOffspringCropStick_(slot, pos, scanned, breedFarm)
    elseif utils.isWeed(scanned) then
        self:handleOffspringWeed_(slot, pos, scanned, breedFarm)
    elseif scanned.isCrop then
        self:handleOffspringCrop_(slot, pos, scanned, breedFarm, storageFarm)
    end
end

---@param slot integer
---@param pos Position
---@param scanned ScannedInfo
---@param breedFarm BreedFarm
function Farmer:handleOffspringAir_(slot, pos, scanned, breedFarm)
    self.action:placeCropSticks(true)
end

---@param slot integer
---@param pos Position
---@param stick ScannedInfo
---@param breedFarm BreedFarm
function Farmer:handleOffspringCropStick_(slot, pos, stick, breedFarm)
    if not self.globalConfig.assumeNoBareStick then
        self.action:placeCropSticks()
    end
end

---@param slot integer
---@param pos Position
---@param weed ScannedInfo
---@param breedFarm BreedFarm
function Farmer:handleOffspringWeed_(slot, pos, weed, breedFarm)
    self.action:deweed()
    self.action:placeCropSticks(true)
end

---@param slot integer
---@param pos Position
---@param crop ScannedInfo guaranteed to be a crop
---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
function Farmer:handleOffspringCrop_(slot, pos, crop, breedFarm, storageFarm)
end

return Farmer
