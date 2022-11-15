local _, namespace = ...
local LQT = namespace.LQT


local FrameProxy = nil
local FrameProxyMt = nil
local ApplyFrameProxy


local get_context = function()
    return strsplittable('\n', debugstack(3,0,1))[1]
end


local FN = '__FrameProxy_fn'
local CONTEXT = '__FrameProxy_context'
local TEXT =  '__FrameProxy_text'


FrameProxyMt = {
    __call = function(proxy, selfMaybe, ...)
        if getmetatable(selfMaybe) == FrameProxyMt then
            local fn = rawget(proxy, FN)
            local args = { ... }
            return FrameProxy(
                function(root)
                    local result, frame = fn(root)
                    assert(result ~= nil, rawget(proxy, CONTEXT) .. rawget(proxy, TEXT) .. ' is nil')
                    return result(frame, unpack(args))
                end,
                get_context(),
                rawget(proxy, TEXT) .. '(self, ...)'
            )
        else
            local fn = rawget(proxy, FN)
            local args = { selfMaybe, ... }
            return FrameProxy(
                function(root)
                    local result = fn(root)
                    assert(result ~= nil, rawget(proxy, CONTEXT) .. ' ' .. rawget(proxy, TEXT) .. ' is nil')
                    return result(unpack(args))
                end,
                get_context(),
                rawget(proxy, TEXT) .. '(...)'
            )
        end
    end,
    __index = function(self, attr)
        if attr == CONTEXT
            or attr == FN
            or attr == TEXT
        then
            return rawget(self, attr)
        end
        local fn = rawget(self, FN)
        return FrameProxy(
            function(root)
                local result = fn(root)
                return result[attr], result
            end,
            get_context(),
            rawget(self, TEXT) .. '.' .. attr
        )
    end,
    __tostring = function(self)
        return rawget(self, TEXT)
    end,
    __add = function(self, num)
        local fn = rawget(self, FN)
        if getmetatable(num) == FrameProxyMt then
            return FrameProxy(
                function(root)
                    return fn(root) + ApplyFrameProxy(root, num)
                end,
                get_context(),
                rawget(self, TEXT) .. ' + ' .. tostring(num)
            )
        else
            return FrameProxy(
                function(root)
                    return fn(root) + num
                end,
                get_context(),
                rawget(self, TEXT) .. ' + ' .. num
            )
        end
    end
}

FrameProxy = function(fn, context, text)
    return setmetatable(
        {
            __FrameProxy_fn = fn or function(root) return root end,
            __FrameProxy_context = context or get_context(),
            __FrameProxy_text = text or 'self'
        },
        FrameProxyMt
    )
end

ApplyFrameProxy = function(frame, proxy)
    return rawget(proxy, FN)(frame, frame)
end

LQT.ApplyFrameProxy = ApplyFrameProxy
LQT.FrameProxy = FrameProxy
LQT.FrameProxyMt = FrameProxyMt

LQT.SELF = FrameProxy()
LQT.PARENT = FrameProxy():GetParent()


--# Tests

local frame = CreateFrame('Frame', nil, UIParent)
frame:SetSize(20, 32)
assert(ApplyFrameProxy(frame, LQT.PARENT) == frame:GetParent())
assert(ApplyFrameProxy(frame, LQT.PARENT:GetName()) == 'UIParent')
assert(ApplyFrameProxy(frame, LQT.SELF:GetWidth() + LQT.SELF:GetHeight()) == 52)
