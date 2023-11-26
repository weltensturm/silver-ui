---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local Hook = LQT.Hook
local Script = LQT.Script
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture


Addon.Units.HealthBar = Frame {
    SetUnit = function(self, unit)
        self.unit = unit
        self:SetEventUnit(unit, true)
    end,
    Update = function(self)
        local ratio = 1 - UnitHealth(self.unit) / math.max(0.1, UnitHealthMax(self.unit))
        -- self.Bar:SetWidth(ratio * self:GetWidth())
        -- self.Bar:SetTexCoord(0, ratio * 0.5, 0.1, 1)
        self.MaskLeft:SetPoint('BOTTOMLEFT', self:GetParent(), 'BOTTOMLEFT', self:GetWidth()*ratio/2, 0)
        self.MaskRight:SetPoint('BOTTOMRIGHT', self:GetParent(), 'BOTTOMRIGHT', -self:GetWidth()*ratio/2, 0)
    end,
    [UnitEvent.UNIT_HEALTH] = SELF.Update,
    [UnitEvent.UNIT_MAXHEALTH] = SELF.Update,
    [Event.PLAYER_ENTERING_WORLD] = SELF.Update,

    -- Mask = MaskTexture
    --     :Texture'Interface/AddOns/silver-ui/art/playerframe-hp-mask'
    --     :AllPoints(PARENT:GetParent()),

    MaskLeft = MaskTexture
        :Texture'Interface/AddOns/silver-ui/art/playerframe-hp-mask'
        .BOTTOMLEFT:BOTTOMLEFT(PARENT:GetParent()),

    MaskRight = MaskTexture
        :Texture'Interface/AddOns/silver-ui/art/playerframe-hp-mask'
        .BOTTOMRIGHT:BOTTOMRIGHT(PARENT:GetParent()),

    [Script.OnSizeChanged] = function(self, w, h)
        self.MaskLeft:SetSize(self:GetParent():GetSize())
        self.MaskRight:SetSize(self:GetParent():GetSize())
    end,

    Bar = Texture
        .TOPLEFT:TOPLEFT()
        .BOTTOMRIGHT:BOTTOMRIGHT()
        -- .TOPLEFT:TOPLEFT()
        -- .BOTTOMLEFT:BOTTOMLEFT()
        -- :ColorTexture(1, 0, 0, 1)
        -- :Texture 'Interface/BUTTONS/GreyscaleRamp64'
        -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar-Glow'
        -- :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar'

        :Texture 'Interface/AddOns/silver-ui/art/bar-bright'
        :VertexColor(0.3, 0.7, 0.1, 1)

        -- :Texture 'Interface/AddOns/silver-ui/art/bar'
        -- :VertexColor(0.3, 0.7, 0.1, 1)

        :AddMaskTexture(PARENT.MaskLeft)
        :AddMaskTexture(PARENT.MaskRight)
}


Addon.Units.HealthBarShaped = Addon.Templates.BarShaped {
    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
    end,
    Update = function(self)
        self:SetValue(UnitHealth(self.unit), UnitHealthMax(self.unit))
    end,
    [UnitEvent.UNIT_HEALTH] = SELF.Update,
    [UnitEvent.UNIT_MAXHEALTH] = SELF.Update,
    [Event.PLAYER_ENTERING_WORLD] = SELF.Update,
}
