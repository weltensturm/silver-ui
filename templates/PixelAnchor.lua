---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Override = LQT.Override
local SELF = LQT.SELF
local Style = LQT.Style


---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


Addon.Templates.PixelAnchor = Style {

    ['PixelAnchor.TargetAnchors'] = {},

    [Override.SetPoint] = function(self, orig, from, toF, to, x, y)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale()
        orig(
            self,
            from,
            toF,
            to,
            Round(x/pixelToUnit)*pixelToUnit,
            Round(y/pixelToUnit)*pixelToUnit
        )
        self['PixelAnchor.TargetAnchors'][from] = {
            toF,
            to,
            x,
            y
        }
    end,

    [Override.AdjustPointsOffset] = function(self, orig, x, y)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale()
        orig(
            Round(x/pixelToUnit)*pixelToUnit,
            Round(y/pixelToUnit)*pixelToUnit
        )
        -- TODO: react to scaling
    end,

    [Override.ClearAllPoints] = function(self)
        self['PixelAnchor.TargetAnchors'] = {}
    end,

    function(self, parent)
        -- hacky way to react to scale changes
        if not self['PixelAnchor.Hooked'] then
            local hookedFrame = self:HasScript('OnSizeChanged') and self or parent
            self['PixelAnchor.Hooked'] = hookedFrame
            hookedFrame:HookScript('OnSizeChanged', function()
                for k, v in pairs(self['PixelAnchor.TargetAnchors']) do
                    self:SetPoint(k, v[1], v[2], v[3], v[4])
                end
            end)
        end
    end,
}
