---@class Addon
local Addon = select(2, ...)

---@class Addon.Templates
Addon.Templates = Addon.Templates or {}

local LQT = Addon.LQT
local Hook = LQT.Hook
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local Script = LQT.Script
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Style = LQT.Style
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture

local GetTime = GetTime

local color = Addon.util.color
local HealthDynamicScale = Addon.util.HealthDynamicScale

local PixelSizex2 = Addon.Templates.PixelSizex2
local PixelSizeH2 = Addon.Templates.PixelSizeH2

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


Addon.Templates.HealthBarScaled = Frame { LQT.UnitEventBase, PixelSizex2 } {
    healthMax = 0,

    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
        self.health = UnitHealth(unit)
        self.healthMax = 0
        self.healthCombat = UnitHealth(unit)
        self:SetValue(UnitHealth(unit), UnitHealthMax(unit))
        self:UpdateColor()
    end,

    UpdateColor = function(self)
        local r, g, b = UnitSelectionColor(self.unit)
        if not UnitIsFriend('player', self.unit) then
            local threat = UnitThreatSituation('player', self.unit) or 0
            if threat > 1 then
                r, g, b = 1, 0.15, 0.15
            end
            if UnitAffectingCombat('player') and threat <= 1 then
                g = math.max(g, 0.35)
            end
            local tapped = UnitIsTapDenied(self.unit) and 1 or 0
            r, g, b = color(
                r, g, b,
                1,
                0.75 - tapped/2 + threat/3/4,
                0.75 - tapped/4 + threat/3/4
            )
        else
            r, g, b = color(r+1/3, g+1/3, b+1/3, 1, 1, 1)
        end
        self.Bar.Bar:SetVertexColor(r, g, b)
    end,
    [Event.PLAYER_REGEN_DISABLED] = SELF.UpdateColor,
    [Event.PLAYER_REGEN_ENABLED] = SELF.UpdateColor,
    [UnitEvent.UNIT_FACTION] = SELF.UpdateColor,
    [UnitEvent.UNIT_THREAT_LIST_UPDATE] = SELF.UpdateColor,

    SetValue = function(self, value, max)
        local width = self:GetWidth()

        if max ~= self.healthMax then
            local scale = HealthDynamicScale(self.unit)

            self:SetWidth(4+100/2*scale)

            width = self:GetWidth()
            local height = self:GetHeight()

            local MASK_WIDTH_RATIO = 4096 / 64
            local huge_width = math.max(0.01, self:GetHeight()) * MASK_WIDTH_RATIO
            self.Shadow.Left:SetSize(width/2+height*0.35, height*2)
            self.Shadow.Right:SetSize(width/2+height*0.35, height*2)
            self.Shadow.Left:SetTexCoord(0, width/2/huge_width, 0, 1)
            self.Shadow.Right:SetTexCoord(1 - width/2/huge_width, 1, 0, 1)
        end
        self.Bar:SetValue(value, max)
    end,

    [UnitEvent.UNIT_HEALTH] = function(self, unit)
        if not self:IsVisible() then return end
        self.healthMax = UnitHealthMax(unit)
        self:SetValue(UnitHealth(unit), self.healthMax)
    end,

    Bar = Addon.Templates.BarShaped
        :AllPoints()
        :Texture 'Interface/AddOns/silver-ui/art/bar-shaded',

    Shadow = Frame:AllPoints() { -- framebuffer children need a container
        Left = Texture { PixelSizeH2 }
            .RIGHT:CENTER()
            :Texture 'Interface/AddOns/silver-ui/art/hp-sharp-shadow'
            :Alpha(0.7),

        Right = Texture { PixelSizeH2 }
            .LEFT:CENTER()
            :Texture 'Interface/AddOns/silver-ui/art/hp-sharp-shadow'
            :Alpha(0.7),
    },

}

