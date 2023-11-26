---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local query = LQT.query
local Override = LQT.Override
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local Script = LQT.Script
local Hook = LQT.Hook
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Style = LQT.Style
local Frame = LQT.Frame
local CheckButton = LQT.CheckButton
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture
local FontString = LQT.FontString
local AnimationGroup = LQT.AnimationGroup
local Animation = LQT.Animation


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


Addon.Units.CastBar = Frame {
    SetUnit = function(self, unit)
        self.unit = unit
        self:SetEventUnit(unit)
        self:Update()
    end,

    Update = function(self)
        local channeling, casting
        local castID
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId, a, empower
            = UnitChannelInfo(self.unit)
        channeling = name
        if not name then
            name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId
                = UnitCastingInfo(self.unit)
            casting = name
        end

        if casting or channeling then
            self.Text.Text:SetText(text)
            if notInterruptible then
                self.Text.Text:SetTextColor(0.8, 0.8, 0.8, 0.8)
                self.Bar.Spark:SetVertexColor(1, 0.95, 0.95, 1)
            else
                self.Text.Text:SetTextColor(1, 1, 1, 1)
                self.Bar.Spark:SetVertexColor(1, 1, 1, 1)
            end
            self.Bar.channeling = channeling
            self.Bar.startTime = startTimeMS/1000
            self.Bar.endTime = endTimeMS/1000
            self.Bar:SetWidth(0.00001)
            self.Bar:Show()
            self.Text:Show()
        else
            self.Text:Hide()
            self.Bar:SetWidth(0)
            self.Bar:Hide()
        end
    end,

    [UnitEvent.UNIT_SPELLCAST_START] = SELF.Update,
    [UnitEvent.UNIT_SPELLCAST_DELAYED] = SELF.Update,
    [UnitEvent.UNIT_SPELLCAST_STOP] = SELF.Update,
    [UnitEvent.UNIT_SPELLCAST_CHANNEL_START] = SELF.Update,
    [UnitEvent.UNIT_SPELLCAST_CHANNEL_UPDATE] = SELF.Update,
    [UnitEvent.UNIT_SPELLCAST_CHANNEL_STOP] = SELF.Update,
    [UnitEvent.UNIT_SPELLCAST_EMPOWER_START] = IsRetail and SELF.Update,
    [UnitEvent.UNIT_SPELLCAST_EMPOWER_UPDATE] = IsRetail and SELF.Update,
    [UnitEvent.UNIT_SPELLCAST_EMPOWER_STOP] = IsRetail and SELF.Update,

    Mask = MaskTexture
        :Texture 'Interface/AddOns/silver-ui/art/playerframe-castbar-mask'
        :AllPoints(PARENT:GetParent()),

    Bar = Frame
        .TOPLEFT:TOPLEFT(-1, 0)
        .BOTTOMLEFT:BOTTOMLEFT(-1, 0)
        :Hide()
    {

        startTime = 0,
        endTime = 0,
        channeling = false,

        [Script.OnUpdate] = function(self)
            local time = GetTime()
            local progress
            if self.channeling then
                progress = (self.endTime - time)/(self.endTime - self.startTime)
            else
                progress = 1 - (self.endTime - time)/(self.endTime - self.startTime)
            end
            self:SetWidth(1 + progress * self:GetParent():GetWidth())
        end,

        Bar = Texture
            :AllPoints()
            :AddMaskTexture(PARENT:GetParent().Mask)
            :Texture'Interface/AddOns/silver-ui/art/bar'
            :TexCoord(0, 0.5, 0, 1),
            -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar',

        Spark = Texture
            .CENTER:RIGHT()
            :Size(16, 16)
            :Texture'Interface/AddOns/silver-ui/art/castbar-spark',

    },

    Text = Frame:AllPoints(PARENT) {
        Text = FontString
            .CENTER:BOTTOM()
            :Font('Fonts/FRIZQT__.ttf', 8.5)
            :ShadowColor(0, 0, 0, 0.7)
            :ShadowOffset(1, -1)

    }
}

