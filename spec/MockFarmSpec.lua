local utils = require "utils"

local MockFarm = require "spec.mocks.MockFarm"


describe("MockFarm", function()
  it("is created with specific slots info", function()
    local farmSize = 3
    local slotsInfo = {
      [1] = utils.ScannedInfoFactory:newCropStick(),
      [3] = utils.ScannedInfoFactory:newCrop("stickreed", 30, 24, 0, 4),
      [4] = utils.ScannedInfoFactory:newWeed(),
      [8] = utils.ScannedInfoFactory:newOther("minecraft:stone"),
    }

    local farm = MockFarm:new(farmSize, slotsInfo)
    local actualSlotsInfo = {}
    for slot = 1, farmSize ^ 2 do
      actualSlotsInfo[slot] = farm:slotInfo(slot)
    end
    assert.are.same(slotsInfo, actualSlotsInfo)
  end)

  it("is created with specific farm blocks info", function()
    local farmSize = 3
    local nonFarmBlocks = { 4, 6, 7, 9 }
    local expectedIsFarmBlocks = {
      true, true, true,
      false, true, false,
      false, true, false,
    }

    local farm = MockFarm:new(farmSize, nil, nonFarmBlocks)
    local actualNonFarmBlocks = {}
    for slot = 1, farmSize ^ 2 do
      actualNonFarmBlocks[#actualNonFarmBlocks + 1] = farm:isFarmBlockBelow(slot)
    end
    assert.are.same(expectedIsFarmBlocks, actualNonFarmBlocks)
  end)
end)
