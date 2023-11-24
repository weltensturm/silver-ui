---@class Addon
local Addon = select(2, ...)


---@class Addon.SettingsWidgets
Addon.SettingsWidgets = {}


local LQT = Addon.LQT
local Style = LQT.Style
local Script = LQT.Script
local FontString = LQT.FontString
local CheckButton = LQT.CheckButton


Addon.SettingsWidgets.CheckBox = CheckButton
    :Size(24, 24)
    :NormalTexture 'Interface/Buttons/UI-CheckBox-Up'
    :PushedTexture 'Interface/Buttons/UI-CheckBox-Down'
    :HighlightTexture 'Interface/Buttons/UI-CheckBox-Highlight'
    :CheckedTexture 'Interface/Buttons/UI-CheckBox-Check'
    :DisabledCheckedTexture 'Interface/Buttons/UI-CheckBox-Check-Disabled'
    :HitRectInsets(-4, -100, -4, -4)
{

    SetLabel = function(self, text)
        self.Label:SetText(text)
    end,

    SetGet = function(self, fn)
        self.Get = fn
        self:SetChecked(self:Get())
    end,

    SetSet = function(self, fn)
        self.Set = fn
    end,

    [Script.OnClick] = function(self)
        self:Set(self:GetChecked())
    end,

    Label = FontString
        .LEFT:RIGHT()
        :Font('Fonts/FRIZQT__.ttf', 12, '')
        :Text 'Enable'
}

