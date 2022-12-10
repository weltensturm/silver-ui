local _, namespace = ...
local LQT = namespace.LQT

local query, FrameProxyMt, ApplyFrameProxy, FrameExtensions = LQT.query, LQT.FrameProxyMt, LQT.ApplyFrameProxy, LQT.FrameExtensions


local CALLMETHOD = 1
local CALLMETHOD_FRAMEPROXY_ARGS = 2
local NOOP = 3
local TABLE = 4
local FN = 5
local SETDATA = 6
local INIT = 7
local ACTION_COMPILED = 8


local PARENT = 1
local ACTION = 2
local ARGS = 3
local NAME = 4
local CONSTRUCTOR = 5
local BOUND_FRAME = 6
local FILTER = 7
local COMPILED = 8
local CONTEXT = 9
local CLEARS_POINTS = 10


local newaction = nil
local get_context = nil


local function isWithContext(name, set)
    name = set and name or 'Set' .. name
    return
        name == 'SetHooks'
        or name == 'SetEvents'
        or name == 'SetEventHooks'
end

local function hasFrameProxy(...)
    for i=1, select('#', ...) do
        if getmetatable(select(i, ...)) == FrameProxyMt then
            return true
        end
    end
end

local function resolveFrameProxiesArray(object, table)
    local result = {}
    for i=1, #table do
        if getmetatable(table[i]) == FrameProxyMt then
            result[i] = ApplyFrameProxy(object, table[i])
        else
            result[i] = table[i]
        end
    end
    return result
end

local function checkChildName(name)
    assert(name:sub(1, 1) == '.', 'Invalid child name ' .. name)
    name = name:sub(2)
    for part in name:gmatch('[^\.^,^:^#]+') do
        assert(name == part, 'Invalid child name' .. name)
    end
    return name
end


local ops = {
    [CALLMETHOD] = function(object, args)
        local SetFn = object['Set'..args[1]]
        if SetFn then
            if isWithContext(args[1], false) then
                SetFn(object, unpack(args[2]), args[3])
            else
                SetFn(object, unpack(args[2]))
            end
        else
            SetFn = object[args[1]]
            -- assert(SetFn, args[3] .. ':\n' .. object:GetObjectType() .. ' has no function ' .. args[1])
            if isWithContext(args[1], true) then
                SetFn(object, unpack(args[2]), args[3])
            else
                SetFn(object, unpack(args[2]))
            end
        end
    end,
    [CALLMETHOD_FRAMEPROXY_ARGS] = function(object, args)
        local newargs = {}
        for k, v in pairs(args[2]) do
            if getmetatable(v) == FrameProxyMt then
                newargs[k] = ApplyFrameProxy(object, v)
            else
                newargs[k] = v
            end
        end
        local setter = object['Set'..args[1]]
        if setter then
            if isWithContext(args[1], false) then
                setter(object, unpack(newargs), args[3])
            else
                setter(object, unpack(newargs))
            end
        else
            setter = object[args[1]]
            assert(setter, args[3] .. ':\n' .. object:GetObjectType() .. ' has no function ' .. args[1])
            if isWithContext(args[1], true) then
                setter(object, unpack(newargs), args[3])
            else
                setter(object, unpack(newargs))
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
            if type(v) == 'table' and next(v) == nil then
                object[k] = {}
            else
                object[k] = v
            end
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
    end,
    [ACTION_COMPILED] = function(object, fn, constructed)
        fn(object, constructed)
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


local function compile(style)
    local compiled = style[COMPILED]
    if compiled then
        return compiled
    end
    local chain = {}
    local parent = style
    while parent do
        if parent[ACTION] ~= NOOP then
            table.insert(chain, 1, parent)
        end
        parent = parent[PARENT]
    end
    local compiled = function(action, frame, constructed)
        for _, s in ipairs(chain) do
            ops[s[ACTION]](frame or s[BOUND_FRAME], s[ARGS], constructed)
        end
    end
    style[COMPILED] = compiled
    return compiled
end


local StyleActions = {}

function StyleActions:apply(frame, parent_from_new)
    -- print(get_context(5))
    debugprofilestart()
    local name = self[NAME]
    local construct = self[CONSTRUCTOR]
    local frame = frame or self[BOUND_FRAME]
    local filter = self[FILTER]
    local compiled = compile(self)

    if parent_from_new then
        if not filter or filter(frame) then
            compiled(self, frame, parent_from_new)
        end
    elseif name and construct then
        name = checkChildName(name)
        local constructed = nil
        if not frame[name] then
            frame[name] = construct(frame)
            constructed = frame
        end
        compiled(self, frame[name], constructed)
    elseif name then
        for result in query(frame, name) do
            if not filter or filter(result) then
                compiled(self, result)
            end
        end
    else
        if not filter or filter(frame) then
            compiled(self, frame)
        end
    end

    local time = debugprofilestop()
    if time > 1 then
        print(time, self[CONTEXT])
    end
    return self
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
    local action = newaction(self, { [ACTION]=SETDATA, [ARGS]=data })
    if action[BOUND_FRAME] then
        run_single(action)
    end
    return action
end

function StyleActions:new(...)
    local obj = self[CONSTRUCTOR](UIParent, ...)
    self.apply(obj, UIParent)
    return obj
end

function StyleActions:filter(fn)
    return newaction(self, { [FILTER]=fn })
end

function StyleActions:reapply(arg1, arg2, arg3)
    local context = get_context(4)
    -- local action = newaction(self, { [ACTION]=CALLMETHOD, [ARGS]={ 'RegisterReapply', { self.clear_name(), arg1, arg2, arg3 or function() end, context }, context } })
    local action = self:RegisterReapply(self.clear_name(), arg1, arg2, arg3 or function() end, context)
    if action[BOUND_FRAME] then
        run_single(action)
    end
    return action
end

function StyleActions:clear_name()
    local action = newaction(self, {})
    action[NAME] = nil
    return action
end


local PointsMagicMt = {
    __index = function(self, attr)
        local point, style = self[1], self[2]
        return function(self1, target, x, y)
            assert(self == self1, 'Cannot call .' .. attr .. ', use ' .. attr .. ':')
            if not style[CLEARS_POINTS] then
                style = newaction(style, { [CLEARS_POINTS]=true })
                    :ClearAllPoints()
            end
            if type(target) ~= 'table' then
                y = x
                x = target
                target = LQT.PARENT
            end
            return style:Point(self[1], target, attr, x, y)
        end
    end,
    __call = function(self, ...)
        assert(false, 'Style:' .. self[1] .. '() is reserved - sorry')
    end
}


local StyleIndex = {}
function StyleIndex:TOP() return setmetatable({ 'TOP', self }, PointsMagicMt) end
function StyleIndex:TOPRIGHT() return setmetatable({ 'TOPRIGHT', self }, PointsMagicMt) end
function StyleIndex:RIGHT() return setmetatable({ 'RIGHT', self }, PointsMagicMt) end
function StyleIndex:BOTTOMRIGHT() return setmetatable({ 'BOTTOMRIGHT', self }, PointsMagicMt) end
function StyleIndex:BOTTOM() return setmetatable({ 'BOTTOM', self }, PointsMagicMt) end
function StyleIndex:BOTTOMLEFT() return setmetatable({ 'BOTTOMLEFT', self }, PointsMagicMt) end
function StyleIndex:LEFT() return setmetatable({ 'LEFT', self }, PointsMagicMt) end
function StyleIndex:TOPLEFT() return setmetatable({ 'TOPLEFT', self }, PointsMagicMt) end
function StyleIndex:CENTER() return setmetatable({ 'CENTER', self }, PointsMagicMt) end


local StyleChainMeta = {}

function StyleChainMeta:__index(attr)
    if type(attr) == 'number' then
        return rawget(self, attr)
    elseif StyleIndex[attr] then
        return StyleIndex[attr](self)
    else
        return function(arg1, ...)
            if arg1 == self then -- called with :
                local action
                local context = get_context():gsub('%[string "(@.*)"%]:(%d+).*', '%1:%2')
                local args = { ... }

                local argsIn = ''
                local argsOut = ''
                local nextArg = 1

                if isWithContext(attr) then
                    table.insert(args, context)
                end

                for i=1, #args do
                    local comma = nextArg > 1 and ', ' or ''
                    argsIn = argsIn .. ', arg' .. nextArg
                    if getmetatable(args[i]) == FrameProxyMt then
                        argsOut = argsOut .. comma .. 'ApplyFrameProxy(self, arg' .. nextArg .. ')'
                    else
                        argsOut = argsOut .. comma .. 'arg' .. nextArg
                    end
                    nextArg = nextArg + 1
                end

                local callmethod_text
                if FrameExtensions[attr] then
                    callmethod_text = [[
                        return function(self, ApplyFrameProxy, FrameExtensions{argsIn})
                            if self.Set{Fn} then
                                self:Set{Fn}({argsOut})
                            elseif self.{Fn} then
                                self:{Fn}({argsOut})
                            else
                                FrameExtensions.{Fn}(self{argsOutComma})
                            end
                        end
                    ]]
                else
                    callmethod_text = [[
                        return function(self, ApplyFrameProxy{argsIn})
                            if self.Set{Fn} then
                                self:Set{Fn}({argsOut})
                            else
                                self:{Fn}({argsOut})
                            end
                        end
                    ]]
                end
                local callmethod = assert(
                    loadstring(
                        callmethod_text
                            :gsub('{Fn}', attr)
                            :gsub('{argsIn}', argsIn)
                            :gsub('{argsOut}', argsOut)
                            :gsub('{argsOutComma}', (#args > 0 and ', ' or '') .. argsOut),
                        context
                    )
                )()

                local wrapper
                if FrameExtensions[attr] then
                    wrapper = function(obj)
                        callmethod(obj, ApplyFrameProxy, FrameExtensions, unpack(args))
                    end
                else
                    wrapper = function(obj)
                        callmethod(obj, ApplyFrameProxy, unpack(args))
                    end
                end

                action = newaction(self, { [ACTION]=ACTION_COMPILED, [ARGS]=wrapper, [CONTEXT]=context })
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


local function StyleToString(style, level, notHead)
    level = level or 1
    local name = style[NAME]
    local construct = style[CONSTRUCTOR]
    local frame = style[BOUND_FRAME]

    local text = ''
    if not notHead then
        text =
            string.rep('    ', level-1)
            .. 'style'
            .. (name and (' '..name) or '')
            .. (construct and ' C' or '')
            .. (frame and ' Bound: ' .. frame:GetObjectType() .. ' ' .. frame:GetName() or '')
            .. '\n'
    end
    if style[PARENT] then
        text = text .. StyleToString(style[PARENT], level, true) or ''
    end

    if style[ACTION] == TABLE then
        for _, style in ipairs(style[ARGS]) do
            if type(style) == 'table' then
                text = text .. StyleToString(style, level+1, false)
            else
                text = text .. string.rep('    ', level+1) .. 'function\n'
            end
        end
    else
        if style[ACTION] ~= NOOP then
            text = text
                .. string.rep('    ', level)
                .. (style[ACTION] == CALLMETHOD and ':' or
                    style[ACTION] == FN and 'FN ' or
                    style[ACTION] == NOOP and 'NOOP' or '? ')
                .. (#style[ARGS] > 0 and tostring(unpack(style[ARGS])) or '') .. '\n'
        end
    end
    return text
end


function StyleChainMeta:__tostring()
    return StyleToString(self)
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
                                      or parent and parent[FILTER],
        [COMPILED] = nil,
        [CONTEXT] = get_context(4),
        [CLEARS_POINTS] = new[CLEARS_POINTS] or parent and parent[CLEARS_POINTS]
    }                   
    setmetatable(action, StyleChainMeta)
    return action
end


get_context = function(level)
    return strsplittable('\n', debugstack(level or 3, 99, 99))[1]
end


LQT.Style = newaction(nil, {})


LQT.Frame = LQT.Style
    .constructor(function(obj, ...) return CreateFrame('Frame', nil, obj, ...) end)


LQT.Button = LQT.Style
    .constructor(function(obj, ...) return CreateFrame('Button', nil, obj, ...) end)


LQT.ItemButton = LQT.Style
    .constructor(function(obj, ...) return CreateFrame('ItemButton', nil, obj, ...) end)

    
LQT.CheckButton = LQT.Style
    .constructor(function(obj, ...) return CreateFrame('CheckButton', nil, obj, ...) end)


LQT.Cooldown = LQT.Style
    .constructor(function(obj, ...) return CreateFrame('Cooldown', nil, obj, 'CooldownFrameTemplate', ...) end)


LQT.Texture = LQT.Style
    .constructor(function(obj, ...) return obj:CreateTexture(...) end)


LQT.FontString = LQT.Style
    .constructor(function(obj, ...) return obj:CreateFontString(...) end)


LQT.MaskTexture = LQT.Style
    .constructor(function(obj, ...) return obj:CreateMaskTexture(...) end)


LQT.EditBox = LQT.Style
    .constructor(function(obj, ...) return CreateFrame('EditBox', nil, obj, ...) end)


LQT.ScrollFrame = LQT.Style
    .constructor(function(obj, ...) return CreateFrame('ScrollFrame', nil, obj, ...) end)


LQT.AnimationGroup = LQT.Style
    .constructor(function(obj, ...) return obj:CreateAnimationGroup(...) end)


LQT.Animation = {
    Alpha           = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Alpha', ...) end),
    Rotation        = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Rotation', ...) end),
    Translation     = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Translation', ...) end),
    Scale           = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Scale', ...) end),
    LineScale       = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('LineScale', ...) end),
    LineTranslation = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('LineTranslation', ...) end),
    FlipBook        = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('FlipBook', ...) end),
    Path            = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Path', ...) end),
}

