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


local newaction = nil
local get_context = nil


local ops = {
    [CALLMETHOD] = function(object, args)
        local setter = object['Set'..args[1]]
        if setter then
            setter(object, unpack(args[2]))
        else
            setter = object[args[1]]
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
                object[k] = v
            end
        end
    end
}


local function run_single(action, object, constructed)
    ops[action[ACTION]](object or action[BOUND_FRAME], action[ARGS], constructed)
end


local style_actions = {}

function style_actions:apply(frame)
    local name = self[NAME]
    local construct = self[CONSTRUCTOR]
    local frame = frame or self[BOUND_FRAME]

    local current = self
    local actions = {}
    while current do
        table.insert(actions, current)
        current = current[PARENT]
    end

    if name and construct then
        local constructed = {}
        local constructor = function(parent)
            local obj = construct(parent)
            -- obj:SetAllPoints(parent)
            constructed[obj] = parent
            return obj
        end
        for result in frame(name, constructor) do
            for i=#actions, 1, -1 do
                run_single(actions[i], result, constructed[result])
            end
        end
        return self
    elseif name then
        for result in frame(name) do
            for i=#actions, 1, -1 do
                run_single(actions[i], result)
            end
        end
        return self
    else
        for i=#actions, 1, -1 do
            run_single(actions[i], frame)
        end
        return self
    end
end

function style_actions:with_constructor(fn)
    return newaction(self, { [CONSTRUCTOR]=fn })
end

function style_actions:init(arg)
    return newaction(self, { [ACTION]=INIT, [ARGS]=arg })
end

function style_actions:data(data)
    return newaction(self, { [ACTION]=SETDATA, [ARGS]=data })
end

function style_actions:new(...)
    local obj = self[CONSTRUCTOR](UIParent, ...)
    self.apply(obj)
    return obj
end


local action_chain_meta = {}

function action_chain_meta:__index(attr)
    if type(attr) == 'number' then
        return rawget(self, attr)
    else
        return function(arg1, ...)
            if arg1 == self then
                local action = newaction(self, { [ACTION]=CALLMETHOD, [ARGS]={ attr, { ... }, get_context() } })
                if action[BOUND_FRAME] then
                    run_single(action)
                end
                return action
            else
                return style_actions[attr](self, arg1, ...)
            end
        end
    end
end

function action_chain_meta:__call(arg)
    if type(arg) == 'table' and arg.GetObjectType then
        self.apply(arg)
        return newaction(self, { [BOUND_FRAME]=arg })
    elseif type(arg) == 'string' then
        return newaction(self, { [NAME]=arg })
    elseif type(arg) == 'function' then
        return newaction(self, { [ACTION]=FN, [ARGS]=arg })
    else
        local action = newaction(self, { [ACTION]=TABLE, [ARGS]=arg })
        if action[BOUND_FRAME] then
            run_single(action)
        end
        return action
    end
end

function action_chain_meta:__tostring()
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
        [BOUND_FRAME]  = new[BOUND_FRAME]  or parent and parent[BOUND_FRAME]
    }
    setmetatable(action, action_chain_meta)
    return action
end


-- local t = "[string \"@Interface\\AddOns\\Silver-ui\\frames/player.lua\""
-- print(
-- strmatch(t, ".lua"),
-- strmatch(t, "lqt.lua"),
-- strmatch(t, "uiext.lua"),
-- strmatch(t, "lqt_style.lua")
-- )
get_context = function()
    return strsplittable('\n', debugstack(3,0,1))[1]
    -- local stack = strsplittable('\n', debugstack())
    -- for i = #stack, 1, -1 do
    --     if strmatch(stack[i], ".lua")
    --        and not strmatch(stack[i], "lqt.lua")
    --        and not strmatch(stack[i], "uiext.lua")
    --        and not strmatch(stack[i], "lqt_style.lua")
    --     then
    --         print('C ', i, ' ', stack[i], '\nF', stack[3])
    --         return stack[i]
    --     end
    -- end
end


lqt.Style = newaction(nil, {})


lqt.Frame = lqt.Style
    .with_constructor(function(obj, ...) return CreateFrame('Frame', nil, obj, ...) end)


lqt.Button = lqt.Style
    .with_constructor(function(obj, ...) return CreateFrame('Button', nil, obj, ...) end)


lqt.Cooldown = lqt.Style
    .with_constructor(function(obj, ...) return CreateFrame('Cooldown', nil, obj, ...) end)


lqt.Texture = lqt.Style
    .with_constructor(function(obj, ...) return obj:CreateTexture(...) end)


lqt.FontString = lqt.Style
    .with_constructor(function(obj, ...) return obj:CreateFontString(...) end)


lqt.MaskTexture = lqt.Style
    .with_constructor(function(obj, ...) return obj:CreateMaskTexture(...) end)



