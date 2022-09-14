local _, ns = ...

ns.lqt = {}
local lqt = ns.lqt

local keys = ns.util.keys
local values = ns.util.values
local split_at_find = ns.util.split_at_find


local function merge(...)
    local result = {}
    for _, t in pairs({...}) do
        for _, v in pairs(t) do
            table.insert(result, v)
        end
    end
    return result
end

local function has_value(table, value)
    for v in values(table) do
        if v == value then
            return true
        end
    end
end


local function matches(obj, selector, attr_name)
    if selector == '*' then
        return true
    elseif selector:find(':') then
        local found = true
        for part in selector:gmatch('%s*([^:]+)') do
            found = found and matches(obj, part, attr_name)
        end
        return found
    else
        selector = '^' .. selector:gsub("%*", ".*"):gsub("#", "%%d+") .. '$'
        local name = obj:GetName()
        return
                selector == '^NOATTR$' and (not attr_name or #attr_name == 0) or
                selector == '^NONAME$' and not name or
                attr_name and string.match(attr_name, selector) or
                              string.match(obj:GetObjectType(), selector) or
                     name and string.match(name, selector)
    end
end
lqt.matches = matches


local function children(obj)
    if obj == UIParent then
        local found = {}
    
        local object = EnumerateFrames()
        while object do
            if not object:IsForbidden() and not found[object] and object:GetParent() == UIParent then
                found[object] = true
            end
            object = EnumerateFrames(object)
        end
        
        return keys(found)
    else
        if obj.GetRegions and obj.GetChildren then
            return values(merge({ obj:GetRegions() }, { obj:GetChildren() }))
        end
        return values({})
    end
end


local function parent_anchor_value(t, obj, anchoridx)
    if anchoridx[obj] then
        return anchoridx[obj]
    end
    if not pcall(function()
        local from, toF, to, x, y = obj:GetPoint()
        if not t[toF] then
            anchoridx[obj] = { 0, obj:GetTop() or 0, obj:GetLeft() or 0 }
            return
        end
        local i = parent_anchor_value(t, toF, anchoridx)[1]+1
        anchoridx[obj] = { i, obj:GetTop() or 0, obj:GetLeft() or 0 }
    end) then
        anchoridx[obj] = { 0, 100000, 100000 }
    end
    return anchoridx[obj]
end


local function order_keys_by_anchors(parent, t)
    local result = {}
    local anchoridx = {}
    for obj, _ in pairs(t) do
        if not anchoridx[obj] then
            parent_anchor_value(t, obj, anchoridx)
        end
        table.insert(result, obj)
    end
    table.sort(result, function(a, b)
        return anchoridx[a][1] < anchoridx[b][1]
            or anchoridx[a][1] == anchoridx[b][1]
                and anchoridx[a][2] > anchoridx[b][2]
            or anchoridx[a][1] == anchoridx[b][1]
                and anchoridx[a][2] == anchoridx[b][2]
                and anchoridx[a][3] < anchoridx[b][3]
    end)
    return result
end


local function apply_style(obj, style)
    for k, v in pairs(style) do
        if type(k) == 'number' then
            for _, child in pairs(obj) do
                v.apply(child)
            end
        else
            if k:sub(1,1) == '.' then
                assert(type(v) == 'table')
                for _, child in pairs(obj) do
                    child(k)(v)
                end
            else
                if type(v) == 'table' then
                    obj['Set'..k](obj, unpack(v))
                else
                    obj['Set'..k](obj, v)
                end
            end
        end
    end
    return obj
end


local lqt_result_meta = {}


local function lqt_result(table)
    local k, v = nil, nil
    local and_then = nil
    local meta = {
        __call = function(self, style)
            if style then
                return apply_style(self, style)
            end
            k, v = next(self, k)
            if k ~= nil then
                return v
            else
                if and_then then
                    for _, fn in pairs(and_then) do
                        self[fn[1]](self, unpack(fn[2]))
                    end
                end
            end
        end,
        __index = function(self, i)
            return function(self, ...)
                if self ~= table then
                    return lqt_result_meta[i](table, self, ...)
                else
                    for _, entry in pairs(self) do
                        local name = entry:GetName()
                        assert(entry[i], entry:GetObjectType() .. (name and (' ' .. name) or '') .. ' has no function named ' .. i)
                    end
                    for _, entry in pairs(self) do
                        entry[i](entry, ...)
                    end
                    return self
                end
            end
        end,
        __concat = function(self, right)
            and_then = right
            for at_k, at_v in pairs(self) do
                for _, v in pairs(and_then) do
                    local name = at_v:GetName()
                    assert(at_v[v[1]], at_v:GetObjectType() .. (name and (' ' .. name) or '') .. ' has no function named ' .. v[1])
                end
            end
            return self
        end
    }
    setmetatable(table, meta)
    return table
end


function lqt_result_meta:filter(fn)
    local filtered = {}
    for _, v in pairs(self) do
        if fn(v) then
            table.insert(filtered, v)
        end
    end
    return lqt_result(filtered)
end


local function query(obj, pattern, constructor, found)
    if type(pattern) == 'table' then
        return apply_style(lqt_result({ obj }), pattern)
    end
    local root = not found
    local found = found or {}
    if pattern:find(',') then
        for part in pattern:gmatch('%s*([^,]+)') do
            query(obj, part, constructor, found)
        end
    elseif pattern:sub(1, 1) == '.' then
        pattern = strsub(pattern, 2)

        local selector, remainder = split_at_find(pattern, '[%.%s]')
        remainder = strtrim(remainder)

        if tonumber(selector) ~= nil then
            selector = tonumber(selector)
        end

        if #remainder == 0 then
            if constructor then
                if not obj[selector] then
                    obj[selector] = constructor(obj)
                end
                return lqt_result { obj[selector] }
            end
        end

        local attrs = {}
        for k, v in pairs(obj) do
            attrs[v] = k
        end
        for child in children(obj) do
            if matches(child, selector, attrs[child]) then
                -- print("FOUND", obj:GetName(), selector, '=', child:GetObjectType(), child:GetName())
                if remainder == '' then
                    found[child] = true
                else
                    query(child, remainder, constructor, found)
                end
            end
        end
    else
        local selector, remainder = split_at_find(pattern, '[%.%s]')
        remainder = strtrim(remainder)
        if #remainder > 0 then
            query(_G[selector], remainder, constructor, found)
            -- return _G[selector](remainder, constructor)
        elseif _G[selector] then
            found[_G[selector]] = true
        end
    end
    if root then
        return lqt_result(order_keys_by_anchors(obj, found))
    end
end


for v in values({
    UIParent,
    GossipGreetingScrollFrame,
    QuestProgressItem1,
    QuestRewardScrollFrameScrollBar,
    ActionButton1,
    Minimap,
    PlayerFrameHealthBar,
    CreateFrame('Cooldown'),
    GameTooltip,
    CreateFrame('SimpleHTML'),
    CreateFrame('Frame'):CreateTexture(),
}) do
    getmetatable(v).__call = query
    getmetatable(v).__index.has_lqt = true
end

