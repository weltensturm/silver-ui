---@class Addon
local Addon = select(2, ...)

---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


local LQT = Addon.LQT
local Override = LQT.Override
local Hook = LQT.Hook
local UnitEvent = LQT.UnitEvent
local Script = LQT.Script
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local FontString = LQT.FontString
local Texture = LQT.Texture


Addon.Templates.CastSparkOnly = Frame { LQT.UnitEventBase }
    :IgnoreParentAlpha(true)
{

    startTime = 0,
    endTime = 0,

    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
        self:SetAlpha(0)
        self:UpdateCastBar()
    end,

    UpdateCastBar = function(self)
        local channeling, casting
        local castID
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId
            = UnitChannelInfo(self.unit)
        channeling = name
        if not name then
            name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId
                = UnitCastingInfo(self.unit)
            casting = name
        end

        if casting or channeling then
            self.Text:SetText(text)
            self.Bar:Show()
            if notInterruptible then
                self.Text:SetTextColor(1, 0.5, 0.5, 1)
                self.Bar.Spark:SetVertexColor(1, 0.2, 0.2, 1)
            else
                self.Text:SetTextColor(1, 1, 1, 1)
                self.Bar.Spark:SetVertexColor(1, 1, 1, 1)
            end
            self.startTime = startTimeMS/1000
            self.endTime = endTimeMS/1000
            self.channeling = channeling
            self:SetAlpha(1)
        else
            self.Bar:Hide()
            self.Bar:SetWidth(1)
            self.endTime = GetTime()
        end

    end,

    [UnitEvent.UNIT_SPELLCAST_START] = SELF.UpdateCastBar,
    [UnitEvent.UNIT_SPELLCAST_DELAYED] = SELF.UpdateCastBar,
    [UnitEvent.UNIT_SPELLCAST_STOP] = SELF.UpdateCastBar,
    [UnitEvent.UNIT_SPELLCAST_CHANNEL_START] = SELF.UpdateCastBar,
    [UnitEvent.UNIT_SPELLCAST_CHANNEL_UPDATE] = SELF.UpdateCastBar,
    [UnitEvent.UNIT_SPELLCAST_CHANNEL_STOP] = SELF.UpdateCastBar,

    [UnitEvent.UNIT_SPELLCAST_INTERRUPTED] = function(self)
        self.Text:SetText 'Interrupted'
        self.endTime = GetTime()
    end,

    [Script.OnUpdate] = function(self)
        if self:GetAlpha() == 0 then return end
        local time = GetTime()
        if self.Bar:IsShown() then
            local progress = (time - self.startTime)/(self.endTime - self.startTime)
            if self.channeling then
                self.Bar:SetWidth(1 + (1 - progress) * self:GetWidth())
            else
                self.Bar:SetWidth(1 + progress * self:GetWidth())
            end
        end
        self:SetAlpha(1 - Clamp((time - self.endTime)*2, 0, 1)^2)
    end,

    Bar = Frame
        .TOPLEFT:TOPLEFT(-1, 0)
        .BOTTOMLEFT:BOTTOMLEFT(-1, 0)
        :Hide()
    {
        Spark = Texture
            .CENTER:RIGHT()
            :Size(7, 14)
            :Texture 'Interface/CastingBar/UI-CastingBar-Spark'
            :BlendMode 'ADD'
    },
    Text = FontString
        .TOP:CENTER()
        :Font('Fonts/FRIZQT__.ttf', 10, '')
        :Alpha(0.7)
        :ShadowOffset(1, -1)
}
