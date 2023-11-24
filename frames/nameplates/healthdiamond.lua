---@class Addon
local Addon = select(2, ...)


Addon.Nameplates = Addon.Nameplates or {}


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


Addon.Nameplates.FrameHealthDiamond = Frame
    .CENTER:BOTTOM(0, 4)
    :Size(16, 16)
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
        -- if UnitIsUnit(self.unit, 'target') then
        --     self:Hide()
        --     -- self.Target:Show()
        --     -- self.TargetBackground:Show()
        -- else
        --     self:Show()
        --     -- self.Target:Hide()
        --     -- self.TargetBackground:Hide()
        -- end
    end,

    UpdateHealth = function(self)
        local unit = self.unit
        local healthMax = UnitHealthMax(unit)
        local scale = math.sqrt(HealthDynamicScale(unit))
        PixelUtil.SetSize(self, 16*scale, 16*scale)
        PixelUtil.SetSize(self.Target, 16*scale + 4, 16*scale + 4)

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
        :DrawLayer('BACKGROUND', -3),

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

    Target = Texture
        .CENTER:CENTER()
        :Texture 'Interface/AddOns/silver-ui/art/diamond'
        :DrawLayer('BACKGROUND', -1)
        :Hide(),

    TargetBackground = Texture
        :AllPoints(PARENT.Target)
        :Texture 'Interface/AddOns/silver-ui/art/diamond-bg'
        :DrawLayer('BACKGROUND', -2)
        :Hide(),
}

