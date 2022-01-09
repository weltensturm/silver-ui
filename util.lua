local _, ns = ...

ns.util = {}
local util = ns.util


function util.partial_function(main_func, carry)
    return function(arg)
        if type(arg) == "function" then
            main_func(arg, unpack(carry))
        else
            table.insert(carry, arg)
            return partial_function(main_func, carry)
        end
    end
end


function util.iter(table, fn)
    local k, v = nil, nil
    return function()
        k, v = next(table, k)
        if k ~= nil then
            return fn(k, v)
        end
    end
end


function util.tuples(table)
    local k, v = nil, nil
    return function()
        k, v = next(table, k)
        if k ~= nil then
            return unpack(v)
        end
    end
end


function util.keys(table)
    local k, v = nil, nil
    return function()
        k, v = next(table, k)
        if k ~= nil then
            return k
        end
    end
end


function util.values(table)
    local k, v = nil, nil
    return function()
        k, v = next(table, k)
        if k ~= nil then
            return v
        end
    end
end


function util.split_at_find(str, pattern, after)
    after = after or 0
    local i = string.find(str, pattern)
    if i then
        return strsub(str, 1, i+after-1), strsub(str, i+after)
    end
    return str, ''
end


local method_chain_wrapper_meta = {
    __index = function(self, i)
        local obj = self[1]
        local fn = obj[i]
        assert(fn)
        return function(self, ...)
            fn(obj, ...)
            return self
        end
    end,
}

function util.method_chain_wrapper(obj)
    local wrapper = { obj }
    setmetatable(wrapper, method_chain_wrapper_meta)
    return wrapper
end

function print_table(t_o)
    local t = {}

    for k, v in pairs(t_o) do
        
        if type(v) == 'table' then
            if v.GetObjectType then
                table.insert(t,
                      '|cffffaaff' .. v:GetObjectType() .. ' ' ..
                      '|cffaaaaff' .. k .. ' ' ..
                      '|cffffffff' .. (v.GetName and (v:GetName() or '') .. ' ' or ''))
            else
                table.insert(t, '|cffaaaaff' .. k .. ' ' .. '|cffaaaaaa' .. tostring(v))
            end
        elseif type(v) ~= 'function' then
            table.insert(t, '|cffffafaa' .. type(v) .. ' |cffaaaaff' .. k .. ' ' .. '|cffff1111' .. tostring(v))
        else
            table.insert(t, '|cffffaaaa' .. type(v) .. ' |cffaaaaff' .. k .. ' ' .. '|cffaaaaaa' .. tostring(v))
        end

    end

    table.sort(t)

    for _, v in pairs(t) do
        print(v)
    end

end