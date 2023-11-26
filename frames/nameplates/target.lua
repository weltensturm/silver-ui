---@class Addon
local Addon = select(2, ...)


Addon.Nameplates = Addon.Nameplates or {}


local LQT = Addon.LQT
local Hook = LQT.Hook
local Event = LQT.Event
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture



Addon.Nameplates.FrameTarget = Frame
    :FrameLevel(0)
    :Alpha(0.8)
{
    [Hook.SetEventUnit] = function(self, unit)
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
        :AllPoints()
        :Texture 'Interface/AddOns/silver-ui/art/target-blob',

}
