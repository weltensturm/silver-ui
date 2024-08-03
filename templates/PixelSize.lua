---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Override = LQT.Override
local Style = LQT.Style


---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


local HOOKED = setmetatable({}, {__mode='k'})
local TARGETSIZE = setmetatable({}, {__mode='k'})


local function PixelSizeT(roundWidth, roundHeight)
    return Style {

        function(self)
            TARGETSIZE[self] = {}
        end,

        [Override.SetSize] = function(self, OrigSetSize, width, height)
            local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale()
            OrigSetSize(
                self,
                roundWidth(width/pixelToUnit)*pixelToUnit,
                roundHeight(height/pixelToUnit)*pixelToUnit
            )
            TARGETSIZE[self][1] = width
            TARGETSIZE[self][2] = height
        end,

        [Override.SetWidth] = function(self, orig, width)
            local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale()
            orig(self, roundWidth(width/pixelToUnit)*pixelToUnit)
            TARGETSIZE[self][1] = width
        end,

        [Override.SetHeight] = function(self, orig, height)
            local pixelToUnit = 768.0 / select(2, GetPhysicalScreenSize()) / self:GetEffectiveScale()
            orig(self, roundHeight(height/pixelToUnit)*pixelToUnit)
            TARGETSIZE[self][2] = height
        end,

        function(self, parent)
            -- hacky way to react to scale changes
            local hookedFrame = self:HasScript('OnSizeChanged') and self or parent
            if not HOOKED[self] then
                HOOKED[self] = hookedFrame
                hookedFrame:HookScript('OnSizeChanged', function(_self, w, h)
                    if self:GetEffectiveScale() < 0.3 then
                        return -- otherwise width or height gets set to 0 -> no more events
                    end
                    if TARGETSIZE[self][1] then
                        self:SetWidth(TARGETSIZE[self][1])
                    end
                    if TARGETSIZE[self][2] then
                        self:SetHeight(TARGETSIZE[self][2])
                    end
                end)
            end
        end,
    }
end


local function Roundx2(value)
    value = math.floor(value)
    return value % 2 ~= 0
        and value + 1
         or value
end


Addon.Templates.PixelSize = PixelSizeT(Round, Round)

-- Ensures size is a multiple of 2 pixels. Useful for "half-anchors" such as CENTER, LEFT etc.
Addon.Templates.PixelSizex2 = PixelSizeT(Roundx2, Roundx2)

-- Ensures width is pixel aligned, and height is a multiple of 2 pixels.
-- Useful for "half-anchors" such as CENTER, LEFT etc.
Addon.Templates.PixelSizeH2 = PixelSizeT(Round, Roundx2)

-- Ensures height is pixel aligned, and width is a multiple of 2 pixels.
-- Useful for "half-anchors" such as CENTER, LEFT etc.
Addon.Templates.PixelSizeW2 = PixelSizeT(Roundx2, Round)
