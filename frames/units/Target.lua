---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local Hook = LQT.Hook
local Script = LQT.Script
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

local SettingsWidgets = Addon.SettingsWidgets

local load

local _, db = SilverUI.Storage {
    name = 'Target',
    character = {
        enabled = true
    },
    onload = function(account, character)
        if character.enabled then
            load()
        end
    end
}


SilverUI.Settings 'Tarrget Frame' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Target Frame',

    SettingsWidgets.CheckBox
        :Label 'Enable'
        :Get(function(self) return db.enabled end)
        :Set(function(self, value) db.enabled = value end),

}


local UnitButton = Addon.Templates.UnitButton


local UnitTarget = UnitButton { LQT.UnitEventBase }
    :Size(300, 20)
    :Attribute('unit', 'target')
    :Alpha(0.75)
{
    [Event.PLAYER_TARGET_CHANGED] = function(self)
        self:UpdateName()
        self.HpText:SetText(UnitHealth('target'))
        self.PowerText:SetText(UnitPower('target'))
    end,
    [UnitEvent.UNIT_HEALTH] = function(self)
        self.HpText:SetText(UnitHealth('target'))
        self:UpdateName()
    end,
    [UnitEvent.UNIT_POWER_FREQUENT] = function(self)
        self.PowerText:SetText(UnitPower('target'))
    end,

    [Script.OnEnter] = function(self)
        self.HpText:SetAlpha(1)
        self.PowerText:SetAlpha(1)
    end,
    [Script.OnLeave] = function(self)
        self.HpText:SetAlpha(0)
        self.PowerText:SetAlpha(0)
    end,

    [Hook.SetEventUnit] = function(self, unit)
        self.Auras:SetEventUnit(unit)
    end,

    UpdateName = function(self)
        self.Name:SetText(
            string.format(
                '%s |cffbb3333%d',
                UnitName('target') or '',
                UnitHealth('target')/math.max(1, UnitHealthMax('target')) * 100
            )
        )
    end,

    Background = Texture
        :AllPoints(PARENT)
        :Texture 'Interface/AddOns/silver-ui/art/target-shadow',

    Name = FontString
        .CENTER:CENTER(0, 2)
        :Font('Fonts/FRIZQT__.ttf', 11, ''),

    HpText = FontString
        .LEFT:LEFT(30, 2)
        :Alpha(0)
        :Font('Fonts/FRIZQT__.ttf', 11, ''),

    PowerText = FontString
        .RIGHT:RIGHT(-30, 2)
        :Alpha(0)
        :Font('Fonts/FRIZQT__.ttf', 11, ''),

    Auras = Addon.Units.Auras
        :AllPoints(),
    [Event.PLAYER_TARGET_CHANGED] = function(self)
        self.Auras:SetEventUnit('target')
    end,
}


load = function()

    local Hider = Frame
        :Hide()
        .new()

    Style
        :UnregisterAllEvents()
        :Parent(Hider)(TargetFrame)

    UnitTarget
        .TOP:BOTTOM(SilverUIPlayerFrame, 0, 25.85)
        :EventUnit 'target'
        .new(UIParent, 'SilverUITargetFrame')
end
