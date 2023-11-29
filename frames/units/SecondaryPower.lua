---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local UnitEvent = LQT.UnitEvent
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


local color = Addon.util.color


local EMPTY = {}


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

local BuffPowerEnum = {
    Icicles = 100000
}

local PowerInfo = {
    [BuffPowerEnum.Icicles] = {
        spellId=205473,
        max=5,
        mod=1,
        color={ r=0.4, g=0.7, b=1 }
    }
}

local BuffPowerMap = {
    [{ class='MAGE', spec=3 }] = IsRetail and BuffPowerEnum.Icicles or nil
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
	local _, class, _ = UnitClass("player")
    for filter, power in pairs(BuffPowerMap) do
        if filter.class == class and filter.spec == GetSpecialization() then
            return power
        end
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
    end,
    SetColor = function(self, rgb)
        local r, g, b = rgb.r, rgb.g, rgb.b
        r, g, b = color(r, g, b, 1, 1, 0.75)
        self.bar:SetVertexColor(r, g, b)
    end
}


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
        :Hide()
    {
        SetColor = function(self, rgb)
            self:SetVertexColor(rgb.r, rgb.g, rgb.b, 1)
        end
    },

    SetUnit = function(self, unit)
        self:SetEventUnit(unit)
        self.unit = unit
        self:UpdateType()
    end,

    Update = function(self)
        if self.power then
            local buffPower = PowerInfo[self.power] or EMPTY
            local current
            if buffPower.spellId then
                current = (C_UnitAuras.GetPlayerAuraBySpellID(buffPower.spellId) or EMPTY).applications or 0
            else
                current = UnitPower(self.unit, self.power, true)
            end
            local max = buffPower.max or UnitPowerMax(self.unit, self.power)
            local mod = buffPower.mod or UnitPowerDisplayMod(self.power)
            if self.discrete then
                for i=1, math.min(max, #self.pips) do
                    self.pips[i]:Set(Clamp(1+current/mod-i, 0, 1))
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
                local buffPower = PowerInfo[power] or EMPTY
                local max = buffPower.max or UnitPowerMax(self.unit, power)
                local color = buffPower.color or PowerBarColor[power] or PowerBarColor.MANA
                self.discrete = max < 15
                if self.discrete then
                    self.bar:Hide()
                    while max > #self.pips do
                        self.pips[#self.pips+1] = SecondaryPowerPip:Size(32, 32).new(self)
                    end
                    for i=1, #self.pips do
                        self.pips[i]:SetPoint('TOP', self, 'TOP', (i - 1 - (max-1)/2) * 24, -5.85)
                        self.pips[i]:SetShown(i <= max)
                        self.pips[i]:SetColor(color)
                    end
                else
                    for i=1, #self.pips do
                        self.pips[i]:Hide()
                    end
                    self.bar:Show()
                    self.bar:SetColor(color)
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
    [UnitEvent.UNIT_AURA] = SELF.Update,
    [UnitEvent.UNIT_MAXPOWER] = SELF.UpdateType,
    [UnitEvent.UNIT_DISPLAYPOWER] = SELF.UpdateType,

}
