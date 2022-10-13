local Action = require "action"
local config = require "autoStatConfig"
local gps = require "gps"
local StatFarm = require "farms.StatFarm"
local StatFarmer = require "farmers.StatFarmer"
local utils = require "utils"


local DESCRIPTION = string.format([[
Usage:
./autoStat --help | -h

Options:
  -h --help              Shows this message.
]])

---Scans breed farm and creates a StatFarm action
---@param action Action
---@param size integer
---@param checkFarmland boolean
---@return StatFarm?
---@return string? errMsg
local function scanBreedFarm(action, size, checkFarmland)
    print("Scanning center slots...")
    local centerCrops, emptyCenterSlots = action:scanFarm(
        StatFarm:iterCenterParentSlotPos(size),
        checkFarmland
    )
    local targetCrops = {}
    for _, scannedInfo in pairs(centerCrops) do
        if scannedInfo.isCrop then
            targetCrops[#targetCrops + 1] = scannedInfo.name
        end
    end
    local targetCropsSet = utils.listToSet(targetCrops)
    if utils.sizeOfTable(targetCropsSet) > 1 then
        return nil, "More than one crops are found on center slots: " .. utils.setToString(targetCropsSet)
    end

    print("Scanning other parent slots...")
    local nonCenterParentCrops, emptyNonCenterParentSlots = action:scanFarm(
        StatFarm:iterNonCenterParentSlotPos(size),
        checkFarmland
    )

    -- Merging two pairs of dictionaries
    local parentCrops = centerCrops
    for slot, crop in nonCenterParentCrops do
        parentCrops[slot] = crop
    end
    print("Done scanning breed farm.")
    return StatFarm:new(
        size, targetCrops[1], parentCrops,
        emptyCenterSlots, emptyNonCenterParentSlots
    )
end

---@param breedFarmSize integer
---@param storageFarmSize integer
local function autoStat(breedFarmSize, storageFarmSize)
    local action = Action:new()
    action:equippedOrExit(true, true, true)
    print(string.format(
        "Started auto-stat. Breed farm size: %d, storage farm size: %d.",
        breedFarmSize, storageFarmSize
    ))

    -- Scans storage farm first
    local storageFarm = action:scanStorageFarm(storageFarmSize, config.checkStorageFarmland)
    gps.backOrigin()

    local breedFarm, errMsg = scanBreedFarm(action, breedFarmSize, config.checkBreedFarmland)
    if not breedFarm then
        io.stderr:write(errMsg .. "\n")
        os.exit(false)
    end

    local farmer = StatFarmer:new(action)

    gps.backOrigin()
end

---@param args string[]
---@param breedFarmSize integer
---@param storageFarmSize integer
local function main(args, breedFarmSize, storageFarmSize)
    local numArgs = 1
    local curArg = args[numArgs]
    if curArg == "--help" or curArg == "-h" then
        print(DESCRIPTION)
        return true
    end

    autoStat(breedFarmSize, storageFarmSize)
end

local function testTargetCrop()
    print(locateTargetCrop(Action:new(), 6))
end

local function testAutoStat()
    print(autoStat(6, 1))
    gps.backOrigin()
end

main({ ... }, config.breedFarmSize, config.storageFarmSize)
