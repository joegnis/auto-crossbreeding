local Action = require "action"
local utils = require "utils"
local gps = require "gps"
local posUtil = require "posUtil"
local globalConfig = require "config"


---@class Farmer
---@field action_ Action
---@field getBreedStatScore_ funGetStatScore
---@field getSpreadStatScore_ funGetStatScore
local Farmer = {}

function Farmer:new()
    error("Farmer should not be instantiated", 2)
end

---For child class constructor to call
---@param action Action?
---@param getBreedStatScore funGetStatScore?
---@param getSpreadStatScore funGetStatScore?
function Farmer:init_(action, getBreedStatScore, getSpreadStatScore)
    self.action_ = action or Action:new()
    self.getBreedStatScore_ = getBreedStatScore or function(ga, gr, re)
        return ga + gr - re
    end
    self.getSpreadStatScore_ = getSpreadStatScore or function(ga, gr, re)
        return ga + gr
    end
end

function Farmer:newChildClass()
    local o = {}
    self.__index = self
    o = setmetatable(o, self)

    function o:super()
        return self
    end

    return o
end

---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
---@return boolean # true if breeding finished
function Farmer:breed(breedFarm, storageFarm)
    for slot, pos in posUtil.allBreedPos(breedFarm:size()) do
        if storageFarm:isFull() then
            print("Storage farm full.")
            return true
        end

        gps.go(pos)

        local scanned = self.action_:scanBelow()
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
    maxBreedRound = maxBreedRound or globalConfig.maxBreedRound
    local breedRound = 1
    local ok = xpcall(
        function()
            while true do
                print(string.format("Breeding round %d. Max %d.", breedRound, maxBreedRound))
                self.action_:dumpLootsIfNeeded()
                self.action_:restockCropSticksIfNotEnough()
                self.action_:chargeIfLowEnergy()
                gps.go({ 0, 0 })
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
        end,
        function (err)
            if utils.isMsgError(err) then
                io.stderr:write(err.msg .. "\n")
            else
                io.stderr:write(err .. "\n")
                io.stderr:write(debug.traceback() .. "\n")
            end
        end
    )
    -- Cleans up
    if ok then
        print("Breeding completed. Cleaning up farms...")
    else
        print("Something went wrong during breeding. Cleaning up farms...")
    end
    self.action_:cleanUpFarm(posUtil.allBreedPos(breedFarm:size()))
    self.action_:cleanUpFarm(posUtil.allStoragePos(storageFarm:size()))
    self.action_:dumpLoots()
end

---@param slot integer
---@param pos Position
---@param scanned ScannedInfo
---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
function Farmer:handleBreedParent_(slot, pos, scanned, breedFarm, storageFarm)
    if utils.isWeed(scanned) then
        self.action_:deweed()
        breedFarm:removeParentCropAt(slot)
    elseif scanned.name == "cropStick" then
        self.action_:breakCrop()
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
    self.action_:placeCropSticks(true)
end

---@param slot integer
---@param pos Position
---@param stick ScannedInfo
---@param breedFarm BreedFarm
function Farmer:handleOffspringCropStick_(slot, pos, stick, breedFarm)
    if not self.action_.assumeNoBareStick then
        self.action_:placeCropSticks()
    end
end

---@param slot integer
---@param pos Position
---@param weed ScannedInfo
---@param breedFarm BreedFarm
function Farmer:handleOffspringWeed_(slot, pos, weed, breedFarm)
    self.action_:deweed()
    self.action_:placeCropSticks(true)
end

---@param slot integer
---@param pos Position
---@param crop ScannedInfo guaranteed to be a crop
---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
function Farmer:handleOffspringCrop_(slot, pos, crop, breedFarm, storageFarm)
end

return Farmer
