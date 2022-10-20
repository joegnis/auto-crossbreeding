local utils = require "utils"

local MockFarm = require "spec.mocks.MockFarm"
local specUtils = require "spec.mocks.utils"


describe("MockFarm", function()
  it("is created with specific slots info", function()
    local farmSize = 3
    local slotsInfo = {
      [1] = utils.ScannedInfoFactory.newCropStick(),
      [3] = utils.ScannedInfoFactory.newCrop("stickreed", 30, 24, 0, 4),
      [4] = utils.ScannedInfoFactory.newWeed(),
      [8] = utils.ScannedInfoFactory.newOther("minecraft:stone"),
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
    local farmBlocksMap = {
      true, false, false,
      true, true, true,
      true, false, false,
    }

    local farm = specUtils.createFarmFromMaps(farmSize, nil, farmBlocksMap)
    local actualFarmBlocks = {}
    for slot = 1, farmSize ^ 2 do
      actualFarmBlocks[#actualFarmBlocks + 1] = farm:isFarmBlockBelow(slot)
    end
    assert.are.same(MockFarm:mapToSlotsTable(farmSize, farmBlocksMap), actualFarmBlocks)
  end)

  it("compares its equality with another", function()
    local farm1 = specUtils.createFarmFromMaps(3,
      {
        nil, "w", "w",
        nil, nil, nil,
        "w", nil, nil,
      }
    )
    local farm2 = specUtils.createFarmFromMaps(3,
      {
        nil, nil, nil,
        "w", "w", nil,
        nil, nil, "w",
      }
    )
    local farm3 = specUtils.createFarmFromMaps(3,
      {
        nil, "w", "w",
        nil, nil, nil,
        "w", nil, nil,
      }
    )
    assert.are.equal(farm1, farm3)
    assert.are.not_equal(farm1, farm2)
    assert.are.not_equal(farm3, farm2)
  end)
end)
