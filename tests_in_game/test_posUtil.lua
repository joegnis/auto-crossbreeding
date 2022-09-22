local posUtil = require "posUtil"


local function testAllStorageSlotsAndPos()
    for slot, pos in posUtil.allStoragePos(3) do
        print(string.format("slot %d, pos %s", slot, posUtil.posToString(pos)))
    end
end

local function testUseAllStorageSlotsAndPos()
    local function test()
        local iterSlotPos = posUtil.allStoragePos(3)
        return function ()
            local slot, pos = iterSlotPos()
            if slot ~= nil then
                return slot, pos
            else
                return nil
            end
        end
    end

    for slot, pos in test() do
        print(string.format("slot %d, pos %s", slot, posUtil.posToString(pos)))
    end
end

testUseAllStorageSlotsAndPos()
