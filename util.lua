---@class Addon
local Addon = select(2, ...)

---@class Addon.util
Addon.util = {}
---@class Addon.util
local util = Addon.util


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


function util.rtrim(s)
    local n = #s
    while n > 0 and s:find("^%s", n) do n = n - 1 end
    return s:sub(1, n)
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
            if pcall(v.GetObjectType, v) then
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


---@class SilverUI.LIFO
local LIFO = {}

---@param value any
function LIFO:push(value)
    self[#self+1] = value
end

---@param default fun(): any
---@return any
function LIFO:pop(default)
    local value = self[#self]
    if value then
        self[#self] = nil
        return value
    elseif default then
        return default()
    end
end

function LIFO:has()
    return #self > 0
end

local m_LIFO = { __index = LIFO }

---@return SilverUI.LIFO
---Last In, First Out / Stack
function util.LIFO()
    return setmetatable({}, m_LIFO)
end


do
    local colorSelect = CreateFrame('ColorSelect') -- Convert RGB <-> HSV (:
    function util.color(r, g, b, hue, saturation, brightness)
        colorSelect:SetColorRGB(r, g, b)
        local h, s, v = colorSelect:GetColorHSV()
        h = h * hue
        s = s * saturation
        v = v * brightness
        colorSelect:SetColorHSV(h, s, v)
        return colorSelect:GetColorRGB()
    end
end


local UnitEffectiveLevel = UnitEffectiveLevel or UnitLevel

function util.HealthDynamicScale(unit)
    local healthMax = UnitHealthMax(unit)
    local diminish = max(1,  UnitEffectiveLevel("player") - UnitLevel(unit) - 9)
    diminish = diminish + (max(1, GetNumGroupMembers()) - 1)
    if UnitLevel(unit) < 0 or UnitIsPlayer(unit) or UnitIsPVP(unit) then
        diminish = 1
    end
    -- if not IsRetail and not UnitIsPlayer(unit) then
    --     diminish = diminish / math.max(1, 1+(UnitLevel(unit) - UnitEffectiveLevel("player"))/10)
    -- end
    local x =  healthMax / UnitHealthMax("player") / diminish / 1.75
    return max(0.02, (1.0 - 1 / (x + 1)) * 4)
end
