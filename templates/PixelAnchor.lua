---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Override = LQT.Override
local SELF = LQT.SELF
local Style = LQT.Style


---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


local HOOKED = setmetatable({}, {__mode='k'})
local ANCHORS = setmetatable({}, {__mode='k'})


Addon.Templates.PixelAnchor = Style {

    function(self)
        ANCHORS[self] = {}
    end,

    [Override.SetPoint] = function(self, orig, from, toF, to, x, y)
        x = x or 0
        y = y or 0
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale()
        orig(
            self,
            from,
            toF,
            to,
            Round(x/pixelToUnit)*pixelToUnit,
            Round(y/pixelToUnit)*pixelToUnit
        )
        ANCHORS[self][from] = {
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
        ANCHORS[self] = {}
    end,

    function(self, parent)
        -- hacky way to react to scale changes
        if not HOOKED[self] then
            local hookedFrame = self:HasScript('OnSizeChanged') and self or parent
            HOOKED[self] = hookedFrame
            hookedFrame:HookScript('OnSizeChanged', function()
                for k, v in pairs(ANCHORS[self]) do
                    self:SetPoint(k, v[1], v[2], v[3], v[4])
                end
            end)
        end
    end,
}
