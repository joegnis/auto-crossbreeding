---Base class of all farms
---@class Farm
---@field size_ integer
local Farm = {}

------------------------------
-- Class & Instance Methods --
------------------------------
--[[
    Usage:
    1. Call from the class table, but must pass in instance members,
        e.g. size in these methods:

        local BreedFarm = Farm:newChildClass()
        BreedFarm:slotToPos(1, 6)

    2. Call from an instance (the usual way). Can skip passing in:

        local farm = BreedFarm:new(...)
        farm:slotToPos(1)
]]

---Given a slot in the farm, returns its position
---@param slot integer
---@param size integer? farm's size
---@return Position
function Farm:slotToPos(slot, size)
    error("not implemented")
end

---Given a position, returns its corresponding slot in the farm
---@param pos Position
---@param size integer? farm's size
---@return integer
function Farm:posToSlot(pos, size)
    error("not implemented")
end

---Creates an iterator of all slots and their positions
---@param size integer? farm's size
---@return fun(): integer?, Position?
function Farm:iterAllSlotPos(size)
    size = size or self.size_
    local farmArea = size ^ 2
    local slot = 0
    return function()
        slot = slot + 1
        if slot <= farmArea then
            return slot, self:slotToPos(slot, size)
        end
    end
end

---@param pos Position
---@param size integer?
function Farm:isPosInFarm(pos, size)
    error("not implemented")
end

-------------------
-- Class Methods --
-------------------

function Farm:new()
    error("should not instantiate Farm", 2)
end

---@class FarmBase: Farm
--[[
    Adds a superClass method to make it easier for child class instances
    to get access to their base class
]]
---@field superClass fun(self: Farm): FarmBase

function Farm:newChildClass()
    local o = {}
    self.__index = self

    function o:superClass()
        return Farm
    end

    o = setmetatable(o, self)
    return o  --[[@as FarmBase]]
end

----------------------
-- Instance Methods --
----------------------

function Farm:size()
    return self.size_
end

---For child class constructor to call
---@param size integer
function Farm:init_(size)
    self.size_ = size
end

return Farm
