local CrossbreedFarm = require "farms.CrossbreedFarm"
local globalConfig = require "config".defaultConfig
local utils = require "utils"

local mocks = require "spec.mocks.mock"
local specUtils = require "spec.mocks.utils"


---@param breedFarm MockFarm
---@param storageFarm MockFarm
---@return Farmer farmer
local function mockFarmer(breedFarm, storageFarm)
  mocks.mockCrossbreeder(breedFarm, storageFarm)
  local Crossbreeder = require "farmers.Crossbreeder"
  return Crossbreeder:new(globalConfig)
end

describe("A farmer", function()
  describe("scans a breed farm", function()
    local c1 = utils.ScannedInfoFactory.newCrop("stickreed", 1, 1, 1, 4)
    local farmSizes = { 3 }
    local iterators = {
      CrossbreedFarm:iterParentSlotPos(3)
    }
    local checkFarmlandList = {
      true
    }
    local farmMaps = {
      {
        nil, nil, nil,
        c1, c1, c1,
        c1, nil, nil,
      }
    }
    local farmBlocksMaps = {
      {
        false, true, false,
        true, true, true,
        true, true, true,
      }
    }
    local expectedScannedInfosList = {
      {
        [1] = c1,
        [5] = c1,
      }
    }
    local expectedEmptySlotsList = {
      { 7 }
    }

    for i = 1, #iterators do
      local farmSize = farmSizes[i]
      local iterator = iterators[i]
      local checkFarmland = checkFarmlandList[i]
      local farmMap = farmMaps[i]
      local farmBlocksMap = farmBlocksMaps[i]
      local expectedScannedInfos = expectedScannedInfosList[i]
      local expectedEmptySlots = expectedEmptySlotsList[i]

      local testName = string.format("no. %d", i)
      it(testName, function()
        local breedFarm = specUtils.createFarmFromMaps(farmSize, farmMap, farmBlocksMap)
        local farmer = mockFarmer(breedFarm, specUtils.createFarmFromMaps(farmSize))
        local actualSlotsInfo, actualEmptySlots = farmer:scanFarm(iterator, checkFarmland)
        assert.are.same(expectedScannedInfos, actualSlotsInfo)
        assert.are.same(expectedEmptySlots, actualEmptySlots)
      end)
    end
  end)
end)
