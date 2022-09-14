local _, ns = ...
local lqt = ns.lqt



local CALLMETHOD = 1
local NOOP = 2
local TABLE = 3
local FN = 4
local SETDATA = 5
local INIT = 6


local PARENT = 1
local ACTION = 2
local ARGS = 3
local NAME = 4
local CONSTRUCTOR = 5
local BOUND_FRAME = 6
local FILTER = 7


local newaction = nil
local get_context = nil


local ops = {
    [CALLMETHOD] = function(object, args)
        local setter = object['Set'..args[1]]
        if setter then
            setter(object, unpack(args[2]))
        else
            setter = object[args[1]]
            if not setter then
                print_table(object)
            end
            assert(setter, args[3] .. ':\n' .. object:GetObjectType() .. ' has no function ' .. args[1])
            if args[1] == 'Hooks' then
                setter(object, unpack(args[2]), args[3])
            else
                setter(object, unpack(args[2]))
            end
        end
    end,
    [NOOP] = function() end,
    [TABLE] = function(object, substyles)
        for _, v in pairs(substyles) do
            if type(v) == 'function' then
                v(object)
            else
                v.apply(object)
            end
        end
    end,
    [FN] = function(object, fn)
        fn(object)
    end,
    [SETDATA] = function(object, data)
        for k, v in pairs(data) do
            object[k] = v
        end
    end,
    [INIT] = function(object, arg, parent)
        if parent and type(arg) == 'function' then
            arg(object, parent)
        elseif parent and arg then
            for k, v in pairs(arg) do
                if type(k) == 'number' then
                   v(object, parent) 
                else
                    object[k] = v
                end
            end
        end
    end
}


local function run_single(action, object, constructed)
    ops[action[ACTION]](object or action[BOUND_FRAME], action[ARGS], constructed)
end


local function run_all(action, frame, constructed)
    if action[PARENT] then
        run_all(action[PARENT], frame, constructed)
    end
    run_single(action, frame, constructed)
end


local StyleActions = {}

function StyleActions:apply(frame, parent_from_new)
    local name = self[NAME]
    local construct = self[CONSTRUCTOR]
    local frame = frame or self[BOUND_FRAME]
    local filter = self[FILTER]

    if parent_from_new then
        if not filter or filter(frame) then
            run_all(self, frame, parent_from_new)
        end
        return self
    elseif name and construct then
        local constructed = {}
        local constructor = function(parent)
            local obj = construct(parent)
            constructed[obj] = parent
            return obj
        end
        for result in frame(name, constructor) do
            run_all(self, result, constructed[result])
        end
        return self
    elseif name then
        for result in frame(name) do
            if not filter or filter(result) then
                run_all(self, result)
            end
        end
        return self
    else
        if not filter or filter(frame) then
            run_all(self, frame)
        end
        return self
    end
end

function StyleActions:constructor(fn)
    if self[CONSTRUCTOR] then
        local old = self[CONSTRUCTOR]
        local new = function(...)
            fn(old, ...)
        end
        return newaction(self, { [CONSTRUCTOR]=new })
    else
        return newaction(self, { [CONSTRUCTOR]=fn })
    end
end

function StyleActions:init(arg)
    return newaction(self, { [ACTION]=INIT, [ARGS]=arg })
end

function StyleActions:data(data)
    return newaction(self, { [ACTION]=SETDATA, [ARGS]=data })
end

function StyleActions:new(...)
    local obj = self[CONSTRUCTOR](UIParent, ...)
    self.apply(obj, UIParent)
    return obj
end

function StyleActions:filter(fn)
    return newaction(self, { [FILTER]=fn })
end


local StyleChainMeta = {}

function StyleChainMeta:__index(attr)
    if type(attr) == 'number' then
        return rawget(self, attr)
    else
        return function(arg1, ...)
            if arg1 == self then -- called with :
                local action = newaction(self, { [ACTION]=CALLMETHOD, [ARGS]={ attr, { ... }, get_context() } })
                if action[BOUND_FRAME] then
                    run_single(action)
                end
                return action
            else -- called with .
                return StyleActions[attr](self, arg1, ...)
            end
        end
    end
end

function StyleChainMeta:__call(arg)
    if type(arg) == 'table' then
        if arg.GetObjectType then
            self.apply(arg)
            return newaction(self, { [BOUND_FRAME]=arg })
        else
            local action = newaction(self, { [ACTION]=TABLE, [ARGS]=arg })
            if action[BOUND_FRAME] then
                run_single(action)
            end
            return action
        end
    elseif type(arg) == 'string' then
        return newaction(self, { [NAME]=arg })
    elseif type(arg) == 'function' then
        return newaction(self, { [ACTION]=FN, [ARGS]=arg })
    elseif arg == nil then
        return self
    end
    assert(false, 'Style: cannot call with ' .. type(arg))
end


function StyleChainMeta:__concat(arg)
    if type(arg) == 'table' then
        local action = newaction(self, { [ACTION]=TABLE, [ARGS]={ arg } })
        if action[BOUND_FRAME] then
            run_single(action)
        end
        return action
    elseif type(arg) == 'function' then
        return newaction(self, { [ACTION]=FN, [ARGS]=arg })
    end
    assert(false, 'Style: cannot concat ' .. type(arg))
end


function StyleChainMeta:__tostring()
    local name = self[NAME]
    local construct = self[CONSTRUCTOR]
    local frame = self[BOUND_FRAME]

    local text = 'style'
        .. (name and (' '..name) or '')
        .. (construct and ' C' or '')
        .. (frame and ' B ' .. frame:GetObjectType() .. ' ' .. frame:GetName() or '')
        .. '\n'

    local current = self

    local actions = {}
    while current do
        table.insert(actions, current)
        current = current[PARENT]
    end

    for i=#actions, 1, -1 do
        current = actions[i]
        if current[ACTION] ~= NOOP then
            text = text .. '    '
                .. (current[ACTION] == CALLMETHOD and ':' or
                    current[ACTION] == TABLE and 'TABLE ' or
                    current[ACTION] == FN and 'FN ' or '? ')
                .. (#current[ARGS] > 0 and tostring(unpack(current[ARGS])) or '') .. ' '
                .. '\n'
        end
    end
    return text
end


newaction = function(parent, new)
    local action = {
        [PARENT]       = parent,
        [ACTION]       = new[ACTION]       or NOOP,
        [ARGS]         = new[ARGS]         or {},
        [NAME]         = new[NAME]         or parent and parent[NAME],
        [CONSTRUCTOR]  = new[CONSTRUCTOR]  or parent and parent[CONSTRUCTOR],
        [BOUND_FRAME]  = new[BOUND_FRAME]  or parent and parent[BOUND_FRAME],
        [FILTER]       = new[FILTER] and (parent and parent[FILTER] and function(obj) return parent[FILTER](obj) and new[FILTER](obj) end
                                                                     or new[FILTER])
                                      or parent and parent[FILTER]
    }                   
    setmetatable(action, StyleChainMeta)
    return action
end


get_context = function()
    return strsplittable('\n', debugstack(3,0,1))[1]
end


lqt.Style = newaction(nil, {})


lqt.Frame = lqt.Style
    .constructor(function(obj, ...) return CreateFrame('Frame', nil, obj, ...) end)


lqt.Button = lqt.Style
    .constructor(function(obj, ...) return CreateFrame('Button', nil, obj, ...) end)


lqt.Cooldown = lqt.Style
    .constructor(function(obj, ...) return CreateFrame('Cooldown', nil, obj, ...) end)


lqt.Texture = lqt.Style
    .constructor(function(obj, ...) return obj:CreateTexture(...) end)


lqt.FontString = lqt.Style
    .constructor(function(obj, ...) return obj:CreateFontString(...) end)


lqt.MaskTexture = lqt.Style
    .constructor(function(obj, ...) return obj:CreateMaskTexture(...) end)



