---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Override = LQT.Override
local Style = LQT.Style


---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


Addon.Templates.PixelSize = Style {

    [Override.SetSize] = function(self, orig, width, height)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale();
        orig(
            self,
            Round(width/pixelToUnit)*pixelToUnit,
            Round(height/pixelToUnit)*pixelToUnit
        )
    end,

    [Override.SetWidth] = function(self, orig, width)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale();
        orig(self, Round(width/pixelToUnit)*pixelToUnit)
    end,

    [Override.SetHeight] = function(self, orig, height)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale();
        orig(self, Round(height/pixelToUnit)*pixelToUnit)
    end,

}


local function Roundx2(value)
    value = math.floor(value)
    return value % 2 ~= 0
        and value + 1
         or value
end


-- Ensures size is a multiple of 2 pixels. Useful for "half-anchors" such as CENTER, LEFT etc.
Addon.Templates.PixelSizex2 = Style {

    [Override.SetSize] = function(self, orig, width, height)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale();
        orig(
            self,
            Roundx2(width/pixelToUnit)*pixelToUnit,
            Roundx2(height/pixelToUnit)*pixelToUnit
        )
    end,

    [Override.SetWidth] = function(self, orig, width)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale();
        orig(self, Roundx2(width/pixelToUnit)*pixelToUnit)
    end,

    [Override.SetHeight] = function(self, orig, height)
	    local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale();
        orig(self, Roundx2(height/pixelToUnit)*pixelToUnit)
    end,

}
