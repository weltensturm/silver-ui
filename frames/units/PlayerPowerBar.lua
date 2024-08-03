---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local Script = LQT.Script
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture


local color = Addon.util.color


Addon.Units.PlayerPowerBar = Frame { LQT.UnitEventBase } {
    SetUnit = function(self, unit)
        self.unit = unit
        -- self:UpdateColor()
        self:SetEventUnit(unit)
        self:UpdateColor()
    end,

    UpdateColor = function(self)
        local r, g, b, _
        self.powerType, _, r, g, b = UnitPowerType(self.unit)
        if not r then
            local info = PowerBarColor[self.powerType]
            if info then
                r, g, b = info.r, info.g, info.b
            else
                r, g, b = 1, 0, 0
            end
        end
        r, g, b = color(r, g, b, 0.95, 0.85, 2)
        self.Bar:SetVertexColor(r, g, b, 1)
        self:UpdateValues()
    end,
    [UnitEvent.UNIT_DISPLAYPOWER] = SELF.UpdateColor,
    [Event.PLAYER_ENTERING_WORLD] = SELF.UpdateColor,

    UpdateValues = function(self)
        if Enum.PowerType.Rage == self.powerType then
            local power = UnitPower(self.unit, self.powerType)
            local r, g, b = 0.9, 0.1, 0.1
            if power < 10 then
                r = r * 0.5
                g = g + 0.3
                b = b + 0.3
            elseif power < 15 then
                g = g + 0.8
                b = b + 0.3
            end
            self.Bar:SetVertexColor(r, g, b, 1)
        end

        -- local ratio = UnitPower(self.unit, self.powerType) / math.max(UnitPowerMax(self.unit, self.powerType), 1)
        -- self.Bar:SetWidth(math.max(ratio * self:GetWidth(), 0.5))
        -- self.Bar:SetTexCoord(0, ratio, 0, 1)
        local ratio = 1 - UnitPower(self.unit, self.powerType) / math.max(UnitPowerMax(self.unit, self.powerType), 1)
        self.MaskLeft:SetPoint('BOTTOMLEFT', self:GetParent(), 'BOTTOMLEFT', self:GetWidth()*ratio/2, 0)
        self.MaskRight:SetPoint('BOTTOMRIGHT', self:GetParent(), 'BOTTOMRIGHT', -self:GetWidth()*ratio/2, 0)
    end,
    [UnitEvent.UNIT_MAXPOWER] = SELF.UpdateValues,
    [UnitEvent.UNIT_POWER_FREQUENT] = SELF.UpdateValues,

    [Script.OnSizeChanged] = function(self, w, h)
        self.MaskLeft:SetSize(self:GetParent():GetSize())
        self.MaskRight:SetSize(self:GetParent():GetSize())
    end,

    MaskLeft = MaskTexture
        :Texture 'Interface/AddOns/silver-ui/art/playerframe-power-mask'
        .BOTTOMLEFT:BOTTOMLEFT(PARENT:GetParent()),

    MaskRight = MaskTexture
        :Texture 'Interface/AddOns/silver-ui/art/playerframe-power-mask'
        .BOTTOMRIGHT:BOTTOMRIGHT(PARENT:GetParent()),

    Bar = Texture
        :AllPoints(PARENT)
        -- :Texture 'Interface/BUTTONS/GreyscaleRamp64'
        -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar-Glow'
        -- :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        -- :Texture 'Interface/AddOns/silver-ui/art/bar'
        :Texture 'Interface/AddOns/silver-ui/art/bar-shaded'
        -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar'
        :AddMaskTexture(PARENT.MaskLeft)
        :AddMaskTexture(PARENT.MaskRight)
}
