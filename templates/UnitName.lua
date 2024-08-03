---@class Addon
local Addon = select(2, ...)

local SELF = Addon.LQT.SELF

---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


local LQT = Addon.LQT
local Hook = LQT.Hook
local Frame = LQT.Frame
local UnitEvent = LQT.UnitEvent
local FontString = LQT.FontString

local PixelSizex2 = Addon.Templates.PixelSizex2
local PixelAnchor = Addon.Templates.PixelAnchor

local color = Addon.util.color

Addon.Templates.UnitName = Frame { LQT.UnitEventBase, PixelAnchor, PixelSizex2 } {

    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
        self:UpdateName()
        self:UpdateColor()
    end,

    UpdateColor = function(self)
        local r, g, b = UnitSelectionColor(self.unit)
        if not UnitIsFriend('player', self.unit) then
            local threat = UnitThreatSituation('player', self.unit) or 0
            if threat > 1 then
                r, g, b = 1, 0.15, 0.15
            end
            if UnitAffectingCombat('player') and threat <= 1 then
                g = math.max(g, 0.35)
            end
            local tapped = UnitIsTapDenied(self.unit) and 1 or 0
            r, g, b = color(
                r, g, b,
                1,
                0.75 - tapped/2 + threat/3/4,
                0.75 - tapped/4 + threat/3/4
            )
        else
            r, g, b = color(r+1/3, g+1/3, b+1/3, 1, 1, 1)
        end
        self.Text:SetTextColor(r, g, b)
    end,
    [UnitEvent.UNIT_FACTION] = SELF.UpdateColor,
    [UnitEvent.UNIT_THREAT_LIST_UPDATE] = SELF.UpdateColor,

    UpdateName = function(self)
        local name = UnitName(self.unit)
        local level = UnitLevel(self.unit);
        if UnitCanAttack('player', self.unit) then
            local color = GetCreatureDifficultyColor(level);
            name = name .. string.format('|cff%02x%02x%02x %s', color.r*255, color.g*255, color.b*255, level ~= -1 and level or '?')
        else
            name = name .. string.format('|cff%02x%02x%02x %s', 1.0*255, 0.82*255, 0.0, level)
        end
        self.Text:SetText(name)
    end,
    [UnitEvent.UNIT_NAME_UPDATE] = SELF.UpdateName,

    Text = FontString
        :AllPoints()
        :Font('Fonts/FRIZQT__.ttf', 11, '')
        :TextColor(0.9, 0.9, 0.9, 1)
        :ShadowColor(0, 0, 0, 0.7)
        :ShadowOffset(1, -1)
}
