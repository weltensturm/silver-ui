---@class Addon
local Addon = select(2, ...)


local EventMt = {
    lqtKeyCompile = function(self, cb)
        return function(widget)
            self:Hook(function(...) cb(widget, ...) end)
        end
    end,
    __index = {
        Hook = function(self, fn)
            table.insert(self, fn)
        end,
        Unhook = function(self, fn)
            for i=#self, 1, -1 do
                if self[i] == fn then
                    table.remove(self, i)
                end
            end
        end
    },
    __call = function(self, ...)
        for i=1, #self do
            self[i](...)
        end
    end
}

function Addon.Event()
    return setmetatable({}, EventMt)
end
