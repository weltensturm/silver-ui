---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Override = LQT.Override
local Style = LQT.Style


---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


Addon.Templates.PixelAnchor = Style {

    [Override.SetPoint] = function(self, orig, from, fromF, to, x, y)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale();
        orig(
            self,
            from,
            fromF,
            to,
            Round(x/pixelToUnit)*pixelToUnit,
            Round(y/pixelToUnit)*pixelToUnit
        )
    end,

    [Override.AdjustPointsOffset] = function(self, orig, x, y)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale();
        orig(
            Round(x/pixelToUnit)*pixelToUnit,
            Round(y/pixelToUnit)*pixelToUnit
        )
    end,

}
