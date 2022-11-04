local _, namespace = ...
local LQT = namespace.LQT

local FrameProxy = nil
local FrameProxyMt = nil

FrameProxyMt = {
    __call = function(proxy, self, ...)
        if getmetatable(self) == FrameProxyMt then
            return FrameProxy {
                __FrameProxy_parent = proxy,
                __FrameProxy_action = 'callmethod',
                __FrameProxy_args = { ... }
            }
        else
            return FrameProxy {
                __FrameProxy_parent = proxy,
                __FrameProxy_action = 'call',
                __FrameProxy_args = { self, ... }
            }
        end
    end,
    __index = function(self, attr)
        if attr == '__FrameProxy_attr' or attr == '__FrameProxy_parent' or attr == '__FrameProxy_action' or attr == '__FrameProxy_args' then
            return rawget(self, attr)
        end
        return FrameProxy {
            __FrameProxy_parent = self,
            __FrameProxy_action = 'index',
            __FrameProxy_attr = attr
        }
    end,
    __tostring = function(self)
        local parent = tostring(self.__FrameProxy_parent or '') or ''
        if self.__FrameProxy_action == 'index' then
            return parent .. '.' .. self.__FrameProxy_attr
        elseif self.__FrameProxy_action == 'call' then
            return parent .. '(...)'
        elseif self.__FrameProxy_action == 'callmethod' then
            return parent .. '(self, ...)'
        else
            return self.__FrameProxy_action
        end
    end
}

FrameProxy = function(table)
    return setmetatable(table or { __FrameProxy_parent=nil }, FrameProxyMt)
end

local function ApplyFrameProxy(frame, proxy)
    local result, this = nil, nil
    if proxy.__FrameProxy_parent then
        result, this = ApplyFrameProxy(frame, proxy.__FrameProxy_parent)
    else
        result = frame
    end
    -- print(proxy)
    if proxy.__FrameProxy_action == 'index' then
        return result[proxy.__FrameProxy_attr], result
    elseif proxy.__FrameProxy_action == 'call' then
        return result(unpack(proxy.__FrameProxy_args))
    elseif proxy.__FrameProxy_action == 'callmethod' then
        return result(this, unpack(proxy.__FrameProxy_args))
    end
    return frame
end

LQT.ApplyFrameProxy = ApplyFrameProxy
LQT.FrameProxy = FrameProxy
LQT.FrameProxyMt = FrameProxyMt

LQT.SELF = FrameProxy()
LQT.PARENT = FrameProxy():GetParent()

