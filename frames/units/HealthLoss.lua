---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local Override = LQT.Override
local Script = LQT.Script
local Style = LQT.Style


Addon.Units.HealthLoss = Addon.Units.HealthBar {
    animations = {},
    health = 0,

    [Override.Update] = function(self)
        local health = UnitHealth(self.unit)
        local healthMax = UnitHealthMax(self.unit)

        table.insert(self.animations, {
            self.health - health,
            GetTime(),
            0.2 + (self.health-health)/healthMax*0.5
        })
        self.health = health
        self.Bar:Show()
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
            self.Bar:Hide()
        else
            local width = self:GetWidth()
            local max = UnitHealthMax(self.unit)
            local ratio = 1 - (self.health + loss) / math.max(0.1, max)

            self.MaskLeft:SetPoint('BOTTOMLEFT', self:GetParent(), 'BOTTOMLEFT', width*ratio/2, 0)
            self.MaskRight:SetPoint('BOTTOMRIGHT', self:GetParent(), 'BOTTOMRIGHT', -width*ratio/2, 0)
        end
    end,

    ['.Bar'] = Style
        :VertexColor(1, 0, 0)
        :BlendMode 'ADD'
}
