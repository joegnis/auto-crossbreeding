local M = {}

M.SPADE_MCNAME = "berriespp:itemSpade"
M.BINDER_MCNAME = "ThaumicTinkerer:connector"
M.CROPSTICK_MCNAME = "IC2:blockCrop"
M.SEED_BAG_MCNAME = "IC2:itemCropSeed"

---Converts a table to string
---@param obj table
---@return string
function M.tableToString(obj)
    local function toString(o)
        if type(o) == 'table' then
            local s = '{ '
            for k, v in pairs(o) do
                if type(k) ~= 'number' then
                    k = '"' .. k .. '"'
                end
                s = s .. '[' .. k .. '] = ' .. toString(v) .. ','
            end
            return s .. '} '
        else
            return tostring(o)
        end
    end

    return toString(obj)
end

---Tests if a ScannedInfo instance represents weed
---@param scannedInfo ScannedInfo
---@return boolean
function M.isWeed(scannedInfo)
    return scannedInfo.name == "weed" or
        scannedInfo.name == "Grass" or
        (scannedInfo.gr and scannedInfo.gr > 23) or
        (scannedInfo.name == "venomilia" and scannedInfo.gr and scannedInfo.gr > 7);
end

---@class Set<T>: { [T]: any }
---@generic T
---@param list T[]
---@return Set<T>
function M.listToSet(list)
    local set = {}
    for _, value in ipairs(list) do
        set[value] = true
    end
    return set
end

---@generic T
---@param set Set<`T`>
---@return string
function M.setToString(set)
    local stringList = {}
    for key in pairs(set) do
        stringList[#stringList + 1] = M.tableToString(key)
    end
    return "Set{ " .. table.concat(stringList, ", ") .. " }"
end

---@generic T
---@param set1 Set<`T`>
---@param set2 Set<T>
---@return Set<T>
function M.mergeSets(set1, set2)
    local merged = {}
    for key in pairs(set1) do
        merged[key] = true
    end
    for key in pairs(set2) do
        merged[key] = true
    end
    return merged
end

---@generic T
---@param set Set<`T`>
---@return T[]
function M.setToList(set)
    local list = {}
    for key in pairs(set) do
        list[#list + 1] = key
    end
    return list
end

---@generic T
---@param set Set<`T`>
---@return integer
function M.sizeOfSet(set)
    local count = 0
    for _ in pairs(set) do
        count = count + 1
    end
    return count
end

---@alias Error
---| { type: '"msg"', msg: string }
---@param msg string
---@return Error
function M.newMsgError(msg)
    local mt = {}
    function mt.__tostring(err)
        return err.msg
    end
    local err = { type = "msg", msg = msg }
    setmetatable(err, mt)
    return err
end

---@return boolean
function M.isMsgError(obj)
    return type(obj) == "table" and obj.type == "msg" and type(obj.msg) == "string"
end

---@class Deque
---@field list_ table
---@field first_ integer
---@field last_ integer
---@field size_ integer
local Deque = {}
M.Deque = Deque

function Deque:new()
    local o = {}
    self.__index = self
    o = setmetatable(o, self)

    o.list_ = {}
    o.first_ = 0
    o.last_ = -1
    o.size_ = 0

    return o
end

function Deque:size()
    return self.size_
end

function Deque:pushFirst(key)
    local first = self.first_ - 1
    self.list_[first] = key
    self.first_ = first
    self.size_ = self.size_ + 1
end

function Deque:pushLast(key)
    local last = self.last_ + 1
    self.last_ = last
    self.list_[last] = key
    self.size_ = self.size_ + 1
end

function Deque:popFirst()
    local first = self.first_
    if first > self.last_ then error("deque is empty", 2) end
    local key = self.list_[first]
    self.list_[first] = nil -- to allow garbage collection
    self.first_ = first + 1
    self.size_ = self.size_ - 1
    return key
end

function Deque:popLast()
    local last = self.last_
    if self.first_ > last then error("deque is empty", 2) end
    local key = self.list_[last]
    self.list_[last] = nil -- to allow garbage collection
    self.last_ = last - 1
    self.size_ = self.size_ - 1
    return key
end

function Deque:peekFirst()
    if self.first_ > self.last_ then error("deque is empty", 2) end
    return self.list_[self.first_]
end

function Deque:peekLast()
    if self.first_ > self.last_ then error("deque is empty", 2) end
    return self.list_[self.last_]
end

return M
