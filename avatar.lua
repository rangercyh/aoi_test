local mt = {}
mt.__index = mt

function mt:gen_del_avatar_event()
    return {
        avatar_id = self.avatar_id,
        event_type = 1,
    }
end

function mt:gen_add_avatar_event()
    return {
        avatar_id = self.avatar_id,
        event_type = 2,
    }
end

function mt:gen_mov_avatar_event()
    return {
        avatar_id = self.avatar_id,
        event_type = 3,
    }
end

function mt:init()
    self:clear_aoi()
    self:clear_grid()
end

function mt:clear_aoi()
    self.aoi_list = {}
end

function mt:clear_grid()
    self.gx, self.gy = nil, nil
end

function mt:get_avatar_id()
    return self.avatar_id
end

function mt:push_aoi(event)
    self.aoi_list[#self.aoi_list + 1] = event
end

function mt:get_aoi()
    return self.aoi_list
end

function mt:set_grid(x, y)
    self.gx = x
    self.gy = y
end

function mt:get_grid()
    return self.gx, self.gy
end

local M = {}
function M.new(id, type)
    local self = setmetatable({
        avatar_id = id,
        avatar_type = type,
    }, mt)
    self:init()
    return self
end
return M

