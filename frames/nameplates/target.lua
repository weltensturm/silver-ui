---@class Addon
local Addon = select(2, ...)


Addon.Nameplates = Addon.Nameplates or {}


local LQT = Addon.LQT
local Override = LQT.Override
local Event = LQT.Event
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture



Addon.Nameplates.FrameTarget = Frame
    :FrameLevel(0)
    :AllPoints(PARENT)
    :Alpha(0.8)
{
    [Override.SetEventUnit] = function(self, oldfn, unit, _)
        self.unit = unit
        if UnitIsUnit(self.unit, 'target') then
            self:SetAlpha(1)
        else
            self:SetAlpha(0)
        end
    end,

    [Event.PLAYER_TARGET_CHANGED] = function(self)
        if UnitIsUnit(self.unit, 'target') then
            self:SetAlpha(1)
        else
            self:SetAlpha(0)
        end
    end,

    TargetArrow = Texture
        .BOTTOMLEFT:TOPLEFT(PARENT:GetParent().Health.MaskAnimLeft, 2, 0)
        .BOTTOMRIGHT:TOPRIGHT(PARENT:GetParent().Health.MaskAnimRight, -2, 0)
        :Height(24)
        :Texture 'Interface/AddOns/silver-ui/art/target-blob',

}
