local testUtils = require "tests_in_game.utils"


local function testBackOrig()
    local farmer = testUtils.createTestFarmer()
    farmer.gps:go({ 0, 9 })
    farmer.gps:backOrigin()
end

testBackOrig()
