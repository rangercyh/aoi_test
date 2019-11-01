local MapGrid = require "map_grid"
local Avatar = require 'avatar'
local idx_start = 0

local mt = {}
mt.__index = mt

-- return the grid according to the x, y coordinates
local function get_map_grid(self, x, y)
    assert(type(x) == 'number' and type(y) == 'number')
    if x >= self.width or x < 0 or y >= self.height or y < 0 then
        return nil
    end
    local idx_x = math.ceil(x / self.MAP_GRID_WIDTH)
    local idx_y = math.ceil(y / self.MAP_GRID_HEIGHT)
    return self.map_grid[idx_x][idx_y]
end

local function broadcast_grid(self, x, y, avatar_id, event)
    if self.map_grid[x][y] == nil then
        return
    end
    local avatar_map = self.map_grid[x][y]:get_avatar_map()
    if avatar_map then
        for id, _ in pairs(avatar_map) do
            local a = self.avatar_map[id]
            if a and id ~= avatar_id then
                a:push_aoi(event)
            end
        end
    end
end

-- 通知九宫格所有玩家avatar事件
local function broadcast_screen(self, x, y, avatar_id, event)
    if self.map_grid[x][y] == nil then
        return
    end
    local xb = math.max(x - 1, 0)
    local xe = math.min(x + 1, self.xcount - 1)
    local yb = math.max(y - 1, 0)
    local ye = math.min(y + 1, self.ycount - 1)
    for i = xb, xe do
        for j = yb, ye do
            broadcast_grid(self, i, j, avatar_id, event)
        end
    end
end

-- 通知avatar九宫格所有玩家
local function broadcast_screen_new_player(self, avatar, x, y)
    if self.map_grid[x][y] == nil then
        return
    end
    local xb = math.max(x - 1, 0)
    local xe = math.min(x + 1, self.xcount - 1)
    local yb = math.max(y - 1, 0)
    local ye = math.min(y + 1, self.ycount - 1)
    for i = xb, xe do
        for j = yb, ye do
            local avatar_map = self.map_grid[i][j]:get_avatar_map()
            for id, _ in pairs(avatar_map) do
                local a = self.avatar_map[id]
                if a then
                    avatar:push_aoi(a:gen_add_avatar_event())
                end
            end
        end
    end
end

local function inrange(x, y, left, right, top, bottom)
    if x >= left and x <= right and y >= bottom and y <= top then
        return true
    end
end

local function get_rect(x, y, x_limit, y_limit, distance)
    return math.max(0, x - distance), math.min(x + distance, x_limit), math.min(y + distance, y_limit), math.max(0, y - distance)
end

-- =============================================================================
function mt:init()
    assert(self.width > 0 and self.height > 0)
    -- Calc the count of map grid
    self.xcount = math.ceil(self.width / self.MAP_GRID_WIDTH)
    self.ycount = math.ceil(self.height / self.MAP_GRID_HEIGHT)

    self.map_grid = {}
    for x = 0, self.xcount - 1 do
        self.map_grid[x] = self.map_grid[x] or {}
        for y = 0, self.ycount - 1 do
            self.map_grid[x][y] = MapGrid.new(x, y)
        end
    end
end

function mt:add_avatar(avatar_type, x, y)
    -- local avatar_id = self.id_allocator:acquire()
    idx_start = idx_start + 1
    local avatar_id = idx_start
    local avatar = Avatar:new(avatar_id, avatar_type)
    local grid = assert(get_map_grid(self, x, y))
    broadcast_screen_new_player(self, avatar, grid.x, grid.y)
    broadcast_screen(self, grid.x, grid.y, avatar_id, avatar:gen_add_avatar_event())
    grid:add_avatar(avatar_id)
    avatar:set_grid(grid.x, grid.y)
    self.avatar_map[avatar_id] = avatar
    return avatar_id
end

function mt:del_avatar(avatar_id)
    local avatar = self.avatar_map[avatar_id]
    if avatar then
        local gx, gy = avatar:get_grid()
        if gx and gy and self.map_grid[gx][gy] then
            self.map_grid[gx][gy]:del_avatar(avatar_id)
            broadcast_screen(self, gx, gy, avatar_id, avatar:gen_del_avatar_event())
        end
    end
    self.avatar_map[avatar_id] = nil
end

function mt:mov_avatar(avatar_id, source_x, source_y, dest_x, dest_y)
    local source_grid = assert(get_map_grid(self, source_x, source_y))
    local dest_grid = assert(get_map_grid(self, dest_x, dest_y))

    local avatar = self.avatar_map[avatar_id]
    if not(avatar) then
        return false
    end
    local ax, ay = avatar:get_grid()
    local sgx, sgy, dgx, dgy = source_grid.x, source_grid.y, dest_grid.x, dest_grid.y
    if not(ax == sgx and ay == sgy) then -- 源格子不一致
        return false
    end
    -- The source grid and dest grid must be adjacent to each other
    if math.abs(sgx - dgx) > 1 or math.abs(sgy - dgy) > 1 then
        return false
    end

    if source_grid ~= dest_grid then
        source_grid:del_avatar(avatar_id)
        dest_grid:add_avatar(avatar_id)
    end

    local sleft, sright, stop, sbottom = get_rect(sgx, sgy, self.xcount - 1, self.ycount - 1, 1)
    local dleft, dright, dtop, dbottom = get_rect(dgx, dgy, self.xcount - 1, self.ycount - 1, 1)
    for gx = math.max(sgx - 2, 0), math.min(sgx + 2, self.xcount - 1) do
        for gy = math.max(sgy - 2, 0), math.min(sgy + 2, self.ycount - 1) do
            local in_source_T9 = inrange(gx, gy, sleft, sright, stop, sbottom)
            local in_dest_T9 = inrange(gx, gy, dleft, dright, dtop, dbottom)
            if in_source_T9 and in_dest_T9 then
                broadcast_grid(self, gx, gy, avatar_id, avatar:gen_mov_avatar_event())
            elseif in_source_T9 then
                broadcast_grid(self, gx, gy, avatar_id, avatar:gen_del_avatar_event())
            elseif in_dest_T9 then
                broadcast_grid(self, gx, gy, avatar_id, avatar:gen_add_avatar_event())
            end
        end
    end
    return true
end

function mt:query_event(id)
    local avatar = self.avatar_map[id]
    if avatar then
        local event_list = avatar:get_aoi()
        avatar:clear_aoi()
        return event_list
    end
end

-- For debug
function mt:dump()
    print("Dump map grid")
    print("-----------------------------")
    local r, l
    for i = 0, self.ycount - 1 do
        r, l = "", ""
        for j = 0, self.xcount - 1 do
            local grid = self.map_grid[j][i]
            r = r .. string.format("[%d-%d] ", j, i)
            l = l .. string.format("%s ", table.concat(grid:get_avatar_id_list(), '-'))
        end
        print(r)
        print(l)
    end
    print("-----------------------------")
end

local M = {}
function M.new(width, height, w, h)
    local self = setmetatable({
        width = width,
        height = height,
        MAP_GRID_WIDTH = w,
        MAP_GRID_HEIGHT = h,
        avatar_map = {},
    }, mt)
    self:init()
    return self
end
return M

