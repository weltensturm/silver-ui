local _, ns = ...

ns.lqt = {}
local lqt = ns.lqt

local keys = ns.util.keys
local values = ns.util.values
local split_at_find = ns.util.split_at_find


local CLASSES = {

    TalkWindow = {
        QuestFrame,
        GossipFrame,
        ItemTextFrame,
    },

    Name = {
        GossipNpcNameFrame,
        QuestNpcNameFrame,
    },

    Portrait = {
        QuestFramePortrait,
        GossipFramePortrait,
    },

    ScrollContent = {
        QuestFrameDetailPanel,
        QuestFrameGreetingPanel,
        QuestFrameProgressPanel,
        QuestFrameRewardPanel,
    },

    QuestProgressItem = {
        QuestProgressItem1,
        QuestProgressItem2,
        QuestProgressItem3,
        QuestProgressItem4,
        QuestProgressItem5,
        QuestProgressItem6,
    },

    QuestRewardItem = {
        QuestInfoRewardsFrameQuestInfoItem1,
        QuestInfoRewardsFrameQuestInfoItem2,
        QuestInfoRewardsFrameQuestInfoItem3,
    },

    ItemBackground = {
        QuestProgressItem1NameFrame,
        QuestProgressItem2NameFrame,
        QuestProgressItem3NameFrame,
        QuestProgressItem4NameFrame,
        QuestProgressItem5NameFrame,
        QuestProgressItem6NameFrame,

        QuestInfoRewardsFrameQuestInfoItem1NameFrame,
        QuestInfoRewardsFrameQuestInfoItem2NameFrame,
        QuestInfoRewardsFrameQuestInfoItem3NameFrame,

    },

    Count = {
        QuestProgressItem1Count,
        QuestProgressItem2Count,
        QuestProgressItem3Count,
        QuestProgressItem4Count,
        QuestProgressItem5Count,
        QuestProgressItem6Count
    }

}


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
    return
        selector == '*' or
        selector == attr_name or
        selector == obj:GetObjectType() or
        selector == obj:GetName() or
        has_value(CLASSES[selector] or {}, obj)
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


local function parent_anchor_value(t, obj, positions)
    if positions[obj] then
        return positions[obj]
    end
    local from, toF, to, x, y = obj:GetPoint()
    if not t[toF] then
        local pos = 10001
        positions[obj] = pos
        return pos
    end
    local pos = parent_anchor_value(t, toF, positions)
    if to == 'RIGHT' or to == 'TOPRIGHT' then
        pos = pos + 1
    elseif to == 'LEFT' or to == 'TOPLEFT' then
        pos = pos - 1
    elseif to == 'BOTTOMLEFT' then
        pos = pos + (10000 - 1)
    elseif to == 'BOTTOMRIGHT' then
        pos = pos + (10000 + 1)
    end
    positions[obj] = pos
    return pos
end


local function order_keys_by_anchors(parent, t)
    local result = {}
    local positions = {}
    for obj, _ in pairs(t) do
        if not positions[obj] then
            parent_anchor_value(t, obj, positions)
        end
        table.insert(result, obj)
    end
    table.sort(result, function(a, b) return positions[a] < positions[b] end)
    return result
end


local function query_proxy(table)
    local k, v = nil, nil
    local and_then = nil
    local meta = {
        __call = function(self)
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
            for _, entry in pairs(self) do
                local name = entry:GetName()
                assert(entry[i], entry:GetObjectType() .. (name and (' ' .. name) or '') .. ' has no function named ' .. i)
            end
            return function(self, ...)
                for _, entry in pairs(self) do
                    entry[i](entry, ...)
                end
                return self
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


local function query(obj, pattern, found)
    local found = found or {}
    local shallow = strsub(pattern, 1, 1) == '.'
    if shallow then
        pattern = strsub(pattern, 2)
    end

    local selector, remainder = split_at_find(pattern, '[%.%s]')
    remainder = strtrim(remainder)

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
                query(child, remainder, found)
            end
        end
        if not shallow then
            query(child, pattern, found)
        end
    end

    return query_proxy(order_keys_by_anchors(obj, found))
end


for v in values({ UIParent, GossipGreetingScrollFrame, QuestProgressItem1, QuestRewardScrollFrameScrollBar, ActionButton1 }) do
    getmetatable(v).__call = query
end

