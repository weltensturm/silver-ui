---@class Addon
local Addon = select(2, ...)


Addon.Nameplates = Addon.Nameplates or {}


local LQT = Addon.LQT
local Override = LQT.Override
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local FontString = LQT.FontString

local PixelSizex2 = Addon.Templates.PixelSizex2


Addon.Nameplates.FrameUnitName = Frame .. PixelSizex2 {

    [Override.SetEventUnit] = function(self, oldfn, unit, ...)
        self.unit = unit
        oldfn(self, unit, true)
        if UnitIsUnit(self.unit, 'target') then
            self.Name:SetAlpha(1)
        else
            self.Name:SetAlpha(0.85)
        end
    end,

    [UnitEvent.UNIT_NAME_UPDATE] = function(self)
        local name = UnitName(self.unit)
        local level = UnitLevel(self.unit);
        if UnitCanAttack('player', self.unit) then
            local color = GetCreatureDifficultyColor(level);
            name = name .. string.format('|cff%02x%02x%02x %s', color.r*255, color.g*255, color.b*255, level)
        else
            name = name .. string.format('|cff%02x%02x%02x %s', 1.0*255, 0.82*255, 0.0, level)
        end
        self.Name:SetText(name)
    end,

    [Event.PLAYER_TARGET_CHANGED] = function(self, target)
        if self.unit and UnitIsUnit(self.unit, 'target') then
            self.Name:SetAlpha(1)
        else
            self.Name:SetAlpha(0.85)
        end
    end,

    Name = FontString .. PixelSizex2
        :AllPoints()
        :Font('Fonts/FRIZQT__.ttf', 8.5, '')
        :TextColor(0.9, 0.9, 0.9, 0)
        :ShadowColor(0, 0, 0, 0.7)
        :ShadowOffset(1, -1)
        :Size(300, 10),
}
