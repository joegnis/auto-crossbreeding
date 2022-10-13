local CrossbreedFarm = require "farms.CrossbreedFarm"
local BreedFarm = require "farms.BreedFarm"
local StorageFarm = require "farms.StorageFarm"
local globalConfig = require "config".defaultConfig
local utils = require "utils"

local mocks = require "spec.mocks.mock"
local MockFarm = require "spec.mocks.MockFarm"


---@param breedFarmSize integer
---@param breedSlotsInfo table<integer, ScannedInfo>?
---@param breedNonFarmBlockSlots integer[]?
---@param storageFarmSize integer
---@param storageSlotsInfo table<integer, ScannedInfo>?
---@param storageNonFarmBlockSlots integer[]?
---@return Farmer farmer
---@return MockFarm mockBreedFarm
---@return MockFarm mockStorageFarm
local function mockAll(
  breedFarmSize, breedSlotsInfo, breedNonFarmBlockSlots,
  storageFarmSize, storageSlotsInfo, storageNonFarmBlockSlots
)
  local breedFarm = MockFarm:new(breedFarmSize, breedSlotsInfo, breedNonFarmBlockSlots)
  local storageFarm = MockFarm:new(storageFarmSize, storageSlotsInfo, storageNonFarmBlockSlots)
  mocks.mockCrossbreeder(breedFarm, storageFarm)
  local Crossbreeder = require "farmers.Crossbreeder"
  return Crossbreeder:new(globalConfig), breedFarm, storageFarm
end

describe("Action", function()
  describe("deweeds", function()
    local farmSizes = {
      3, 3, 6
    }
    local weedsPosList = {
      { 1, 4, 9 },
      { 2, 5, 7 },
      { 10, 17, 28, 36 },
    }

    for i = 1, #farmSizes do
      local farmSize = farmSizes[i]
      local weeds = weedsPosList[i]
      local testName = string.format(
        "in breed farm with size %d and weeds at %s",
        farmSize,
        utils.listToString(weeds)
      )
      it(testName, function()
        local slotsInfo = {}
        for _, slot in ipairs(weeds) do
          slotsInfo[slot] = utils.ScannedInfoFactory:newWeed()
        end
        local farmer, breedFarm, _ = mockAll(
          farmSize, slotsInfo, nil,
          farmSize, nil, nil
        )

        for slot = 1, farmSize ^ 2 do
          farmer.gps:go(BreedFarm:slotToPos(slot, farmSize))
          farmer.action:deweed()
        end

        local isWeeds = {}
        local expected = {}
        for _, slot in ipairs(weeds) do
          isWeeds[#isWeeds + 1] = breedFarm:slotInfo(slot) ~= nil
          expected[#expected + 1] = false
        end
        assert.are.same(expected, isWeeds)
      end)
    end
  end)

  describe("tests if there is farm block below", function()
    local farmSizes = {
      3, 3, 6
    }
    local nonFarmBlockPosLists = {
      { 1, 4, 9 },
      { 2, 5, 7 },
      { 10, 17, 28, 36 },
    }

    for i = 1, #farmSizes do
      local farmSize = farmSizes[i]
      local nonFarmBlocks = nonFarmBlockPosLists[i]
      local testName = string.format(
        "in storage farm with size %d and non-farm blocks below %s",
        farmSize,
        utils.listToString(nonFarmBlocks)
      )
      it(testName, function()
        local farmer = mockAll(
          farmSize, nil, nil,
          farmSize, nil, nonFarmBlocks
        )

        local actualNonFarmBlocks = {}
        for slot = 1, farmSize ^ 2 do
          farmer.gps:go(StorageFarm:slotToPos(slot, farmSize))
          if not farmer.action:testsIfFarmlandBelow() then
            actualNonFarmBlocks[#actualNonFarmBlocks + 1] = slot
          end
        end

        -- Tests
        assert.are.same(nonFarmBlocks, actualNonFarmBlocks)
      end)
    end
  end)

  describe("scans a breed farm", function()
    local farmSizes = { 3 }
    local iterators = {
      CrossbreedFarm:iterParentSlotPos(3)
    }
    local checkFarmlandList = {
      true
    }
    local slotsInfoList = {
      {
        [1] = utils.ScannedInfoFactory:newCrop("stickreed", 1, 1, 1, 4),
        [2] = utils.ScannedInfoFactory:newCrop("stickreed", 1, 1, 1, 4),
        [5] = utils.ScannedInfoFactory:newCrop("stickreed", 1, 1, 1, 4),
        [8] = utils.ScannedInfoFactory:newCrop("stickreed", 1, 1, 1, 4),
      }
    }
    local nonFarmBlocksList = {
      { 3, 9 }
    }
    local expectedScannedInfosList = {
      {
        [1] = utils.ScannedInfoFactory:newCrop("stickreed", 1, 1, 1, 4),
        [5] = utils.ScannedInfoFactory:newCrop("stickreed", 1, 1, 1, 4),
      }
    }
    local expectedEmptySlotsList = {
      { 7 }
    }

    for i = 1, #iterators do
      local farmSize = farmSizes[i]
      local iterator = iterators[i]
      local checkFarmland = checkFarmlandList[i]
      local slotsInfo = slotsInfoList[i]
      local nonFarmBlocks = nonFarmBlocksList[i]
      local expectedScannedInfos = expectedScannedInfosList[i]
      local expectedEmptySlots = expectedEmptySlotsList[i]

      local testName = string.format("No. %d", i)
      it(testName, function()
        local farmer = mockAll(farmSize, slotsInfo, nonFarmBlocks, 1)
        local actualSlotsInfo, actualEmptySlots = farmer:scanFarm(iterator, checkFarmland)
        assert.are.same(expectedScannedInfos, actualSlotsInfo)
        assert.are.same(expectedEmptySlots, actualEmptySlots)
      end)
    end
  end)
end)
