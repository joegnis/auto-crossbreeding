local testUtils = require "testsInGame.utils"


local function testBackOrig()
    local farmer = testUtils.createTestFarmer()
    farmer.gps:go({ 0, 9 })
    farmer.gps:backOrigin()
end

testBackOrig()
