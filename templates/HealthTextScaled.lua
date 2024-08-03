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
local FontString = LQT.FontString

local GetTime = GetTime

local color = Addon.util.color
local HealthDynamicScale = Addon.util.HealthDynamicScale

local PixelSizex2 = Addon.Templates.PixelSizex2
local PixelSizeH2 = Addon.Templates.PixelSizeH2

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


Addon.Templates.HealthTextScaled = Frame { LQT.UnitEventBase, PixelSizex2 }
    :FlattensRenderLayers(true)
    :IsFrameBuffer(true)
{
    healthScale = 1,
    healthPrev = 0,
    health = 0,
    healthMax = 0,
    textColor = nil,

    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
        self.health = UnitHealth(unit)
        self.healthMax = 0
        self.healthCombat = UnitHealth(unit)
        self:SetValue(UnitHealth(unit), UnitHealthMax(unit), true)
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
        self.textColor = { r, g, b }
        self.Text:SetTextColor(r, g, b)
    end,
    [Event.PLAYER_REGEN_DISABLED] = SELF.UpdateColor,
    [Event.PLAYER_REGEN_ENABLED] = SELF.UpdateColor,
    [UnitEvent.UNIT_FACTION] = SELF.UpdateColor,
    [UnitEvent.UNIT_THREAT_LIST_UPDATE] = SELF.UpdateColor,
    -- [Script.OnUpdate] = function(self)
    --     self:SetAlpha(self:GetParent():GetEffectiveAlpha())
    -- end,

    SetValue = function(self, value, max, reset)
        local width = self:GetWidth()

        if max ~= self.healthMax then
            local scale = HealthDynamicScale(self.unit)
            self.healthScale = scale
            self.Text:SetScale(2.5*scale)
        end
        local text = ceil(value / max * 99)
        if text ~= self.health then
            self.health = text
            if reset then
                self.healthPrev = text
                self.Text:SetText(text)
            end
        end
    end,

    [UnitEvent.UNIT_HEALTH] = function(self, unit)
        if not self:IsVisible() then return end
        self.healthMax = UnitHealthMax(unit)
        self:SetValue(UnitHealth(unit), self.healthMax)
    end,

    [Script.OnUpdate] = function(self, dt)
        if self.healthPrev ~= self.health then
            if self.healthPrev > self.health then
                self.healthPrev = math.max(self.healthPrev - dt*50, self.health)
            else
                self.healthPrev = math.min(self.healthPrev + dt*50, self.health)
            end
            self.Text:SetText(ceil(self.healthPrev))
            local diff = math.min(1, (self.healthPrev - self.health) / (self.healthMax/10))
            local r, g, b = unpack(self.textColor)
            self.Text:SetTextColor(math.max(r, diff), math.max(g, diff), math.max(b, diff))
        end
    end,

    Text = FontString
        .TOP:TOP()
        -- :Font('Fonts/ARIALN.TTF', 11, '')
        :Font('Fonts/FRIZQT__.ttf', 11, '')
        -- :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
        :ShadowColor(0, 0, 0, 0.7)
        :ShadowOffset(1, -1)

}

