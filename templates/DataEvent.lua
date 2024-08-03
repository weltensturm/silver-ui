---@class Addon
local Addon = select(2, ...)


local DataEventMt = {
    lqtKeyCompile = function(self, cb)
        return function(widget)
            self:Hook(function(...) cb(widget, ...) end)
        end
    end,
    __index = {
        Get = function(self)
            return self[0]
        end,
        Set = function(self, value)
            self[0] = value
            for i=1, #self do
                self[i](value)
            end
        end,
        Hook = function(self, fn)
            table.insert(self, fn)
            fn(self[0])
        end,
        Unhook = function(self, fn)
            for i=#self, 1, -1 do
                if self[i] == fn then
                    table.remove(self, i)
                end
            end
        end
    },
    __call = function(self, value)
        self[0] = value
        for i=1, #self do
            self[i](value)
        end
    end
}

function Addon.DataEvent(default)
    return setmetatable({ default }, DataEventMt)
end
