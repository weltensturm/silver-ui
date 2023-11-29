---@class Addon
local Addon = select(2, ...)

Addon.Nameplates = Addon.Nameplates or {}

local LQT = Addon.LQT
local Hook = LQT.Hook
local UnitEvent = LQT.UnitEvent
local Script = LQT.Script

local GetTime = GetTime


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


Addon.Nameplates.HealthLoss = Addon.Templates.BarShaped {
    animations = {}, -- { { lost health, start, duration }, }
    health = 0,
    healthMax = 0,

    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
        self.animations = {}
        self.health = UnitHealth(unit)
        self.healthMax = 0
        self.healthCombat = UnitHealth(unit)
        self:SetValue(UnitHealth(unit), UnitHealthMax(unit))
    end,

    [UnitEvent.UNIT_HEALTH] = function(self, unit)
        if not self:GetParent():IsVisible() then return end
        assert(unit == self.unit, self.unit .. ' ' .. unit)
        local health = UnitHealth(self.unit)
        local healthMax = UnitHealthMax(self.unit)
        if healthMax ~= self.healthMax then
            if healthMax < self.healthMax then
                table.insert(self.animations, {
                    healthMax - self.healthMax,
                    GetTime(),
                    0.2 + (healthMax-self.healthMax)/healthMax*0.5
                })
                self:Show()
            end
        end
        self:SetValue(health, healthMax)
        if IsRetail and health < self.health and (self.health - health)/healthMax > 0.005 then
            table.insert(self.animations, {
                self.health - health,
                GetTime(),
                0.2 + (self.health-health)/healthMax*0.5
            })
            self:Show()
        end

        self.health = health
        self.healthMax = healthMax
    end,

    [UnitEvent.UNIT_COMBAT] = function(self, unit, type, crit, damage, class)
        if not self:GetParent():IsVisible() then return end
        if not IsRetail and type == 'WOUND' then
            self.healthCombat = self.healthCombat - damage
            -- self:SetValue(self.healthCombat, self.valueMax) -- sync healthbar in classic with player animation? inconsistent values and event order though
            table.insert(self.animations, {
                damage,
                GetTime(),
                0.2 + damage/UnitHealthMax(self.unit)*0.5
            })
            self:Show()
        end
    end,

    [Script.OnUpdate] = function(self, dt)
        local time = GetTime()
        local loss = 0
        for i=#self.animations, 1, -1 do
            local anim = self.animations[i]
            if anim[2]+anim[3] < time then
                table.remove(self.animations, i)
            else
                local progress = (time - anim[2])/anim[3]
                loss = loss + anim[1] * (1-progress^2)
            end
        end
        if loss == 0 then
            self:Hide()
        else
            self:SetValue(self.health+loss, self.healthMax)
        end
    end
}
