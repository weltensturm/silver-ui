---@class Addon
local Addon = select(2, ...)


---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


local LQT = Addon.LQT
local Override = LQT.Override
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture

local color = Addon.util.color
local HealthDynamicScale = Addon.util.HealthDynamicScale


Addon.Templates.FrameHealthDiamond = Frame { LQT.UnitEventBase, Addon.Templates.PixelSizex2, Addon.Templates.PixelAnchor }
    .BOTTOM:BOTTOM(0, 4)
    :Size(32, 32)
{
    parent = PARENT,

    [Override.SetEventUnit] = function(self, orig, unit, _)
        self.unit = unit
        orig(self, unit, true)

        local r, g, b, a = UnitSelectionColor(unit)
        self.Health:SetVertexColor(r, g, b, a)
        self:UpdateHealth()
        self:UpdateTarget()
    end,

    UpdateTarget = function(self)
        if UnitIsUnit(self.unit, 'target') then
            -- self:Hide()
            self.Border:SetAlpha(0.3)
            self.Target:Show()
            self.TargetBackground:Show()
        else
            -- self:Show()
            self.Border:SetAlpha(1)
            self.Target:Hide()
            self.TargetBackground:Hide()
        end
    end,

    UpdateHealth = function(self)
        local unit = self.unit
        local healthMax = UnitHealthMax(unit)
        local scale = math.sqrt(HealthDynamicScale(unit))
        self:SetPoint('BOTTOM', self:GetParent(), 'BOTTOM', 0, 4*scale)
        self:SetSize(32*scale, 32*scale)
        self.Target:SetSize(32*scale + 4*scale, 32*scale + 4*scale)

        local r, g, b, a = UnitSelectionColor(unit)
        local threat = UnitThreatSituation('player', self.unit) or 0
        r, g, b = color(r, g, b, 1, 0.75 + threat/3/4, 0.75 + threat/3/4)
        self.Health:SetVertexColor(r, g, b, a)
        self.Background:SetVertexColor(r/3, g/3, b/3, a)

        self.Health:SetHeight((self:GetHeight()-1) * sqrt(UnitHealth(unit) / healthMax) + 1)
    end,

    [UnitEvent.UNIT_HEALTH] = SELF.UpdateHealth,

    [Event.PLAYER_TARGET_CHANGED] = SELF.UpdateTarget,

    HealthClip = MaskTexture
        :AllPoints(PARENT)
        -- .BOTTOMLEFT:BOTTOMLEFT()
        -- .BOTTOMRIGHT:BOTTOMRIGHT()
        :Texture 'Interface/AddOns/silver-ui/art/diamond',

    Border = Texture
        :AllPoints(PARENT)
        :Texture 'Interface/AddOns/silver-ui/art/diamond-bg'
        :DrawLayer('BACKGROUND', 0),

    Background = Texture
        :AllPoints(PARENT)
        :Texture 'Interface/AddOns/silver-ui/art/diamond'
        :VertexColor(0.2, 0.2, 0.2)
        :DrawLayer('BACKGROUND', 1),

    Health = Texture
        -- :AllPoints(PARENT)
        .BOTTOMLEFT:BOTTOMLEFT()
        .BOTTOMRIGHT:BOTTOMRIGHT()
        :Texture 'Interface/AddOns/silver-ui/art/diamond'
        :VertexColor(1, 0, 0)
        :AddMaskTexture(PARENT.HealthClip),

    Target = Texture { Addon.Templates.PixelSizex2, Addon.Templates.PixelAnchor }
        .CENTER:CENTER(0, -2)
        :Texture 'Interface/AddOns/silver-ui/art/diamond'
        :DrawLayer('BACKGROUND', -1)
        :Alpha(0.8)
        :Hide(),

    TargetBackground = Texture
        :AllPoints(PARENT.Target)
        :Texture 'Interface/AddOns/silver-ui/art/diamond-bg'
        :DrawLayer('BACKGROUND', -2)
        :Hide(),
}

