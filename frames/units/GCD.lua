---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Event = LQT.Event
local Script = LQT.Script
local Frame = LQT.Frame
local Texture = LQT.Texture


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


Addon.Units.GCD = Frame {
    gcdSpell = 0,
    gcdStart = 0,
    gcdDuration = 0,

    [Event.SPELL_UPDATE_COOLDOWN] = function(self, ...)
        local gcdStart, gcdDuration = GetSpellCooldown(61304)
        if gcdStart + gcdDuration > GetTime() then
            local endCast = select(5, UnitCastingInfo('player')) or select(5, UnitChannelInfo('player'))
            if not endCast or endCast/1000 < gcdStart + gcdDuration then
                self:Show()
            end
        end
    end,

    [Event.UNIT_SPELLCAST_SUCCEEDED] = function(self, unit, _, spell)
        local gcdStart, gcdDuration = GetSpellCooldown(IsRetail and 61304 or spell)
        if gcdDuration < 2 then
            if gcdStart + gcdDuration > GetTime() then
                self.gcdStart = gcdStart
                self.gcdDuration = gcdDuration
                self.gcdSpell = IsRetail and 61304 or spell
                local endCast = select(5, UnitCastingInfo('player')) or select(5, UnitChannelInfo('player'))
                if not endCast or endCast/1000 < gcdStart + gcdDuration then
                    self:Show()
                end
            end
        end
    end,

    [Script.OnUpdate] = function(self)
        local gcdNow = self.gcdStart + self.gcdDuration - GetTime()
        local endCast = select(5, UnitCastingInfo('player')) or select(5, UnitChannelInfo('player'))
        if gcdNow > 0 and (not endCast or endCast/1000 < self.gcdStart + self.gcdDuration) then
            self.GcdSpark:SetPoint('LEFT', self, 'LEFT', (1 - gcdNow/self.gcdDuration)*self:GetWidth(), 0)
        else
            self:SetWidth(0)
            self:Hide()
        end
    end,

    GcdSpark = Texture
        .TOP:TOP()
        .BOTTOM:BOTTOM()
        :Width(20)
        :DrawLayer 'OVERLAY'
        :Texture 'Interface/CastingBar/UI-CastingBar-Spark'
        -- :Texture 'Interface/UNITPOWERBARALT/Generic1Target_Horizontal_Spark'
        :BlendMode 'ADD'
}
