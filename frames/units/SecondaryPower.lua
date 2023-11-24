---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local UnitEvent = LQT.UnitEvent
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture


local color
do
    local colorSelect = CreateFrame('ColorSelect') -- Convert RGB <-> HSV (:
    color = function(r, g, b, hue, saturation, value)
        colorSelect:SetColorRGB(r, g, b)
        local h, s, v = colorSelect:GetColorHSV()
        h = h * hue
        s = s * saturation
        v = v * value
        colorSelect:SetColorHSV(h, s, v)
        return colorSelect:GetColorRGB()
    end
end


local SecondaryPowerPip = Frame {
    border = Texture
        :Texture 'Interface/AddOns/silver-ui/art/power-pip'
        :AllPoints(PARENT)
        :VertexColor(0.1, 0.1, 0.1, 0.7),
    bar = Texture
        :AllPoints(PARENT)
        :Texture 'Interface/AddOns/silver-ui/art/power-pip-bar'
        :Hide(),
    glow = Texture
        :AllPoints(PARENT)
        :Texture 'Interface/AddOns/silver-ui/art/power-pip-glow'
        :BlendMode 'ADD'
        :Hide(),
    Set = function(self, value, rgb)
        self.bar:SetShown(value > 0)
        self.bar:SetAlpha(value < 1 and value*0.5 or 1)
        self.glow:SetShown(value > 0)
        self.glow:SetAlpha(value < 1 and value*0.5 or 1)
        if rgb then
            local r, g, b = rgb.r, rgb.g, rgb.b
            r, g, b = color(r, g, b, 1, 1, 0.75)
            self.bar:SetVertexColor(r, g, b)
        end
    end
}


local MANA_PAIR_POWER = {
    [Enum.PowerType.LunarPower] = true,
    [Enum.PowerType.Insanity] = true,
    [Enum.PowerType.Maelstrom] = true,
}

local COMBO_PAIR_POWER = {
    [Enum.PowerType.Energy] = true
}

local ARCANECHARGES_SPEC = {
    [1] = true
}

local function UnitSecondaryPowerType(unit)
    local mainPower = UnitPowerType(unit)
    for _, power in pairs(Enum.PowerType) do
        if
            power >= 0
            and power ~= Enum.PowerType.NumPowerTypes
            and power ~= mainPower
            and (power ~= Enum.PowerType.Mana or MANA_PAIR_POWER[mainPower])
            and (power ~= Enum.PowerType.ComboPoints or COMBO_PAIR_POWER[mainPower])
            and (not GetSpecialization
                 or power ~= Enum.PowerType.ArcaneCharges or ARCANECHARGES_SPEC[GetSpecialization()])
            and UnitPowerMax(unit, power) > 0
        then
            return power
        end
    end
end


Addon.Units.SecondaryPower = Frame
    :FlattensRenderLayers(true)
    :IsFrameBuffer(true)
{

    pips = {},
    power = nil,
    discrete = false,

    bar = Texture
        :ColorTexture(1, 1, 1, 1)
        :Height(8)
        .TOP:TOP()
        :Hide(),

    SetUnit = function(self, unit)
        self:SetEventUnit(unit)
        self.unit = unit
        self:UpdateType()
    end,

    Update = function(self)
        if self.power then
            local current = UnitPower(self.unit, self.power, true)
            local max = UnitPowerMax(self.unit, self.power)
            local mod = UnitPowerDisplayMod(self.power)
            if self.discrete then
                for i=1, math.min(max, #self.pips) do
                    self.pips[i]:Set(Clamp(1+current/mod-i, 0, 1), PowerBarColor[self.power] or PowerBarColor.MANA)
                end
            else
                self.bar:SetWidth(current/mod / max * self:GetWidth())
            end
        end
    end,

    UpdateType = function(self)
        local power = UnitSecondaryPowerType(self.unit)
        if power ~= self.power then
            self.power = power
            if power then
                local max = UnitPowerMax(self.unit, self.power)
                self.discrete = max < 15
                if self.discrete then
                    self.bar:Hide()
                    while max > #self.pips do
                        self.pips[#self.pips+1] = SecondaryPowerPip:Size(32, 32).new(self)
                    end
                    for i=1, #self.pips do
                        self.pips[i]:SetPoint('TOP', self, 'TOP', (i - 1 - (max-1)/2) * 24, -5.85)
                        self.pips[i]:SetShown(i <= max)
                    end
                else
                    for i=1, #self.pips do
                        self.pips[i]:Hide()
                    end
                    self.bar:Show()
                end
                self:Update()
            else
                for i=1, #self.pips do
                    self.pips[i]:Hide()
                end
                self.bar:Hide()
            end
        end
    end,

    -- [UnitEvent.UNIT_POWER_POINT_CHARGE] = SELF.Update,
    [UnitEvent.UNIT_POWER_FREQUENT] = SELF.Update,
    [UnitEvent.UNIT_MAXPOWER] = SELF.UpdateType,
    [UnitEvent.UNIT_DISPLAYPOWER] = SELF.UpdateType,

}
