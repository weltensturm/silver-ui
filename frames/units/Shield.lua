---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local Hook = LQT.Hook
local Script = LQT.Script
local UnitEvent = LQT.UnitEvent
local SELF = LQT.SELF
local Style = LQT.Style


Addon.Units.Shield = Addon.Templates.BarShaped {
    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
        self:Update()
    end,

    Update = function(self)
        self:SetValue(UnitGetTotalAbsorbs(self.unit), UnitHealthMax(self.unit))
    end,

    [Script.OnSizeChanged] = SELF.Update,
    [UnitEvent.UNIT_ABSORB_AMOUNT_CHANGED] = SELF.Update,

    ['.Bar'] = Style
        :Texture 'Interface/AddOns/silver-ui/art/bar-absorb'
        -- :VertexColor(0.5, 0.5, 1, 0.8)
        :BlendMode 'ADD'
}
