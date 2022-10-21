local M = {}

M.SPADE_MCNAME = "berriespp:itemSpade"
M.BINDER_MCNAME = "ThaumicTinkerer:connector"
M.CROPSTICK_MCNAME = "IC2:blockCrop"
M.SEED_BAG_MCNAME = "IC2:itemCropSeed"

---Converts a table to string recursively
---@param obj table
---@return string
function M.tableToString(obj)
    local function toString(o)
        if type(o) == 'table' then
            local elements = {}
            for k, v in pairs(o) do
                if type(k) ~= 'number' then
                    k = '"' .. k .. '"'
                end
                elements[#elements + 1] = string.format("[%s]=%s", k, toString(v))
            end
            return string.format("{%s}", table.concat(elements, ","))
        else
            return tostring(o)
        end
    end

    return toString(obj)
end

---Converts a list to string recursively
---@param obj table
---@return string
function M.listToString(obj)
    local function toString(o)
        if type(o) == 'table' then
            local elements = {}
            for _, v in ipairs(o) do
                elements[#elements + 1] = toString(v)
            end
            return string.format("[%s]", table.concat(elements, ","))
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

---@param t table
---@return integer
function M.sizeOfTable(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---Copies a value. If it is a table, only copies top-level value.
---@generic T
---@param orig `T`
---@return T
function M.shallowCopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---@param o1 any
---@param o2 any
---@return boolean
function M.isEqual(o1, o2)
    if o1 == o2 then
        return true
    else
        local t1 = type(o1)
        local t2 = type(o2)
        if t1 == "table" and t2 == "table" then
            local size1 = 0
            for key, val in pairs(o1) do
                if not M.isEqual(val, o2[key]) then
                    return false
                end
                size1 = size1 + 1
            end
            local size2 = 0
            for _ in pairs(o2) do
                size2 = size2 + 1
            end
            return size1 == size2
        end
        return false
    end
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

---Calls a function, catches error thrown, and prints the error.
---Returns whatever 'funDo' returns when success, nil otherwise.
---@param funDo fun(arg1?: any, ...): ...
---@param success fun() function to call when 'funDo' finishes without errors
---@param fail fun() function to call after error is handled and printed
---@param arg1? any
---@return any result
---@return any ...
function M.safeDoPrintError(funDo, success, fail, arg1, ...)
    local ret = { xpcall(
        funDo,
        function(err)
            if M.isMsgError(err) then
                io.stderr:write(err.msg .. "\n")
            else
                io.stderr:write(err .. "\n")
                io.stderr:write(debug.traceback() .. "\n")
            end
        end,
        arg1,
        ...
    ) }
    if ret[1] then
        success()
    else
        fail()
    end
    return table.unpack(ret, 2)
end

---@alias ScannedCrop { isCrop: true, name: string, gr: integer, ga: integer, re: integer, tier: integer }
---@alias ScannedWeed { isCrop: false, name: "weed" }
---@alias ScannedAir { isCrop: false, name: "air" }
---@alias ScannedCropStick { isCrop: false, name: "cropStick" }
---@alias ScannedOther { isCrop: false, name: string }
---@alias ScannedInfo ScannedCrop | ScannedWeed | ScannedAir | ScannedCropStick | ScannedOther
---@class ScannedInfoFactory
local ScannedInfoFactory = {}
M.ScannedInfoFactory = ScannedInfoFactory

---@param name string
---@param ga integer
---@param gr integer
---@param re integer
---@param tier integer
---@return ScannedCrop
function ScannedInfoFactory.newCrop(name, ga, gr, re, tier)
    return {
        isCrop = true,
        name = name,
        ga = ga,
        gr = gr,
        re = re,
        tier = tier,
    }
end

---@param info ScannedInfo
---@return boolean
function M.isScannedCrop(info)
    return info.isCrop
end

---@return ScannedWeed
function ScannedInfoFactory.newWeed()
    return { isCrop = false, name = "weed" }
end

---@param info ScannedInfo
---@return boolean
function M.isScannedWeed(info)
    return not info.isCrop and info.name == "weed"
end

---@return ScannedAir
function ScannedInfoFactory.newAir()
    return { isCrop = false, name = "air" }
end

---@param info ScannedInfo
---@return boolean
function M.isScannedAir(info)
    return not info.isCrop and info.name == "air"
end

---@return ScannedCropStick
function ScannedInfoFactory.newCropStick()
    return { isCrop = false, name = "cropStick" }
end

---@param info ScannedInfo
---@return boolean
function M.isScannedCropStick(info)
    return not info.isCrop and info.name == "cropStick"
end

---@return ScannedOther
function ScannedInfoFactory.newOther(name)
    return { isCrop = false, name = name }
end

---@param info ScannedInfo
---@return boolean
function M.isScannedOther(info)
    return not info.isCrop
        and info.name ~= "air"
        and info.name ~= "cropStick"
        and info.name ~= "weed"
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

--[[
Creates a Deque from a table.

Uses pairs() to iterate the table's values.
Elements are pushed to front in the iteration order.
]]
---@param table table
---@return Deque
function Deque:newFromTable(table)
    local o = self:new()
    for _, val in pairs(table) do
        o:pushFirst(val)
    end
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
