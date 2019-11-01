
local mt = {}
mt.__index = mt

function mt:init()
    self.all_avatar = {}
end

function mt:add_avatar(avatar_id)
    self.all_avatar[avatar_id] = true
end

function mt:del_avatar(avatar_id)
    self.all_avatar[avatar_id] = nil
end

function mt:get_avatar_map()
    return self.all_avatar
end

local M = {}
function M.new(grid_x, grid_y)
    local self = setmetatable({
        x = grid_x,
        y = grid_y,
    }, mt)
    self:init()
    return self
end
return M
