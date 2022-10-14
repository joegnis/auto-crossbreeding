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
        return mockUtils.doIfInFarm_(
            action.farmer_:pos(), breedFarm, storageFarm,
            function(size, slot, pos)
                return breedFarm:slotInfo(slot) or utils.ScannedInfoFactory:newAir()
            end,
            function(size, slot, pos)
                return storageFarm:slotInfo(slot) or utils.ScannedInfoFactory:newAir()
            end,
            function(pos)
                return utils.ScannedInfoFactory:newAir()
            end
        )
    end
end

---@param breedFarm MockFarm
---@param storageFarm MockFarm
function M.mockDeweed(breedFarm, storageFarm)
    ---@param action Action
    return function(action)
        mockUtils.doIfInFarm_(
            action.farmer_:pos(), breedFarm, storageFarm,
            function(size, slot, pos)
                breedFarm:clearSlot(slot)
            end,
            function(size, slot, pos)
                storageFarm:clearSlot(slot)
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
        return mockUtils.doIfInFarm_(
            action.farmer_:pos(), breedFarm, storageFarm,
            function(size, slot, pos)
                return breedFarm:isFarmBlockBelow(slot)
            end,
            function(size, slot, pos)
                return storageFarm:isFarmBlockBelow(slot)
            end,
            function(pos)
                return false
            end
        )
    end
end

return M
