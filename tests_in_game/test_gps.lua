local gps = require "gps"


local function testBackOrig()
    gps.go({ 0, 9 })
    gps.backOrigin()
end

testBackOrig()
