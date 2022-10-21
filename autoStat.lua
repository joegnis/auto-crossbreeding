local Action = require "action"
local config = require "autoStatConfig".config
local globalConfig = require "config"
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


---@param breedFarmSize integer
---@param storageFarmSize integer
---@param globalConfig GlobalConfig
---@param statConfig StatConfig
local function autoStat(breedFarmSize, storageFarmSize, globalConfig, statConfig)
    local farmer = StatFarmer:new(globalConfig)
    farmer.action:equippedOrExit(true, true, true)
    print(string.format(
        "Started auto-stat. Breed farm size: %d, storage farm size: %d.",
        breedFarmSize, storageFarmSize
    ))

    -- Scans storage farm first
    local storageFarm = farmer:scanStorageFarm(storageFarmSize, statConfig.checkStorageFarmland)
    farmer.gps:backOrigin()

    local breedFarm, errMsg = scanBreedFarm(action, breedFarmSize, config.checkBreedFarmland)
    if not breedFarm then
        io.stderr:write(errMsg .. "\n")
        os.exit(false)
    end

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

    autoStat(breedFarmSize, storageFarmSize, )
end

local function testTargetCrop()
    print(locateTargetCrop(Action:new(), 6))
end

local function testAutoStat()
    print(autoStat(6, 1))
    gps.backOrigin()
end

main({ ... }, config.breedFarmSize, config.storageFarmSize)
