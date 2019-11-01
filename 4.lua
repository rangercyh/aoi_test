
local function test()
    local aoi = require "3"
    local world = aoi.new(10, 20, 10, 20)
    local n = 2000
    local b  = os.clock()
    for i=1,n do
        world:add_avatar(1, 0, 0)
        -- if i == n then
        --     print_r(ret)
        -- end
    end
    local e  = os.clock()
    print("test cost:", e-b)
end

test()
