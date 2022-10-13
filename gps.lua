local robot = require("robot")

---@class Gps
---@field farmer_ Farmer
---@field savedPos_ Position[]
local Gps = {}

---@param farmer Farmer
function Gps:new(farmer)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)

    o.farmer_ = farmer
    o.savedPos_ = {}

    return o
end

---@param facing Facing
function Gps:turnTo(facing)
    local delta = (facing - self.farmer_.facing_) % 4
    self.farmer_.facing_ = facing
    if delta <= 2 then
        for _ = 1, delta do
            robot.turnRight()
        end
    else
        for _ = 1, 4 - delta do
            robot.turnLeft()
        end
    end
end

---@param destPos Position
function Gps:go(destPos)
    local destX, destY = table.unpack(destPos)
    local curX, curY = table.unpack(self.farmer_.position_)
    if curX == destX and curY == destY then
        return
    end

    -- find path
    local deltaX = destX - curX
    local deltaY = destY - curY
    local path = {}

    if deltaX > 0 then
        path[#path + 1] = { 2, deltaX }
    elseif deltaX < 0 then
        path[#path + 1] = { 4, -deltaX }
    end

    if deltaY > 0 then
        path[#path + 1] = { 1, deltaY }
    elseif deltaY < 0 then
        path[#path + 1] = { 3, -deltaY }
    end

    -- optimal first turn
    if #path == 2 and self:turningDelta_(path[2][1]) < self:turningDelta_(path[1][1]) then
        path[1], path[2] = path[2], path[1]
    end

    for i = 1, #path do
        self:turnTo(path[i][1])
        for _ = 1, path[i][2] do
            self:safeForward_()
        end
    end

    self.farmer_.position_ = destPos
end

function Gps:backOrigin()
    self:go({ 0, 0 })
    self:turnTo(1)
end

function Gps.down(distance)
    if distance == nil then
        distance = 1
    end
    for _ = 1, distance do
        robot.down()
    end
end

function Gps.up(distance)
    if distance == nil then
        distance = 1
    end
    for _ = 1, distance do
        robot.up()
    end
end

function Gps:save()
    self.savedPos_[#self.savedPos_ + 1] = self.farmer_.position_
end

function Gps:resume()
    if #self.savedPos_ == 0 then
        return
    end
    self:go(self.savedPos_[#self.savedPos_])
    table.remove(self.savedPos_)
end

---@param facing integer
---@return number
function Gps:turningDelta_(facing)
    local delta = (facing - self.farmer_.facing_) % 4
    if delta <= 2 then
        return delta
    else
        return 4 - delta
    end
end

function Gps:safeForward_()
    local forwardSuccess
    repeat
        forwardSuccess = robot.forward()
    until forwardSuccess
end

return Gps
