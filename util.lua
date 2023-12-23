---@class Addon
local Addon = select(2, ...)

---@class Addon.util
Addon.util = {}
---@class Addon.util
local util = Addon.util


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
