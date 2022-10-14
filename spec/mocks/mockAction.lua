local utils = require "utils"

local mockUtils = require "spec.mocks.utils"


local M = {}

function M.mockGo()
    ---@param action Action
    ---@param pos Position
    return function(action, pos)
        action.farmer_.position_ = pos
    end
end

---@param breedFarm MockFarm
---@param storageFarm MockFarm
function M.mockScanBelow(breedFarm, storageFarm)
    ---@param action Action
    return function(action)
        return mockUtils.doIfInEitherFarm_(
            action.farmer_:pos(), breedFarm, storageFarm,
            function(farm, slot, pos)
                return farm:slotInfo(slot) or utils.ScannedInfoFactory:newAir()
            end
        )
    end
end

---@param breedFarm MockFarm
---@param storageFarm MockFarm
function M.mockDeweed(breedFarm, storageFarm)
    ---@param action Action
    return function(action)
        mockUtils.doIfInEitherFarm_(
            action.farmer_:pos(), breedFarm, storageFarm,
            function(farm, slot, pos)
                farm:clearSlot(slot)
            end
        )
    end
end

M.mockBreakCrop = M.mockDeweed

---@param breedFarm MockFarm
---@param storageFarm MockFarm
function M.mockTestsIfFarmlandBelow(breedFarm, storageFarm)
    ---@param action Action
    ---@param info ScannedInfo?
    return function(action, info)
        return mockUtils.doIfInEitherFarm_(
            action.farmer_:pos(), breedFarm, storageFarm,
            function(farm, slot, pos)
                return farm:isFarmBlockBelow(slot)
            end,
            function(pos)
                return false
            end
        )
    end
end

return M
