---@class Addon
local Addon = select(2, ...)

Addon.Nameplates = Addon.Nameplates or {}

local LQT = Addon.LQT
local Hook = LQT.Hook
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local Script = LQT.Script
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Style = LQT.Style
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture

local GetTime = GetTime

local color = Addon.util.color
local HealthDynamicScale = Addon.util.HealthDynamicScale


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


Addon.Nameplates.HealthBar = Frame .. Addon.Templates.PixelSizex2 {
    parent = PARENT,
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
        self.Bar.Bar:SetVertexColor(r, g, b)
    end,
    [Event.PLAYER_REGEN_DISABLED] = SELF.UpdateColor,
    [Event.PLAYER_REGEN_ENABLED] = SELF.UpdateColor,
    [UnitEvent.UNIT_FACTION] = SELF.UpdateColor,
    [UnitEvent.UNIT_THREAT_LIST_UPDATE] = SELF.UpdateColor,

    SetValue = function(self, value, max)
        local width = self:GetWidth()

        if max ~= self.healthMax then
            if max < self.healthMax then
                table.insert(self.animations, {
                    max - self.healthMax,
                    GetTime(),
                    0.2 + (max-self.healthMax)/max*0.5
                })
                self.Animation:Show()
            end

            local scale = HealthDynamicScale(self.unit)

            self:SetSize(4+100/2*scale, 5)

            width = self:GetWidth()
            local height = self:GetHeight()

            local MASK_WIDTH_RATIO = 4096 / 64
            local huge_width = math.max(0.01, self:GetHeight()) * MASK_WIDTH_RATIO
            PixelUtil.SetSize(self.Shadow.Left, width/2+height*0.35, height*2)
            PixelUtil.SetSize(self.Shadow.Right, width/2+height*0.35, height*2)
            self.Shadow.Left:SetTexCoord(0, width/2/huge_width, 0, 1)
            self.Shadow.Right:SetTexCoord(1 - width/2/huge_width, 1, 0, 1)
        end
        self.Bar:SetValue(value, max)
    end,

    [UnitEvent.UNIT_HEALTH] = function(self, unit)
        if not self:IsVisible() then return end
        assert(unit == self.unit, self.unit .. ' ' .. unit)
        local health = UnitHealth(self.unit)
        local healthMax = UnitHealthMax(self.unit)

        self:SetValue(health, healthMax)
        -- print(self.unit, 'UNIT_HEALTH', health - self.health, health)

        if IsRetail and health < self.health and (self.health - health)/healthMax > 0.005 then
            table.insert(self.animations, {
                self.health - health,
                GetTime(),
                0.2 + (self.health-health)/healthMax*0.5
            })
            self.Animation:Show()
        end

        self.health = health
        self.healthMax = healthMax
    end,

    [UnitEvent.UNIT_COMBAT] = function(self, unit, type, crit, damage, class)
        if not self:IsVisible() then return end
        if not IsRetail and type == 'WOUND' then
            self.healthCombat = self.healthCombat - damage
            -- self:SetValue(self.healthCombat, self.healthMax) -- sync healthbar in classic with player animation? inconsistent values and event order though
            table.insert(self.animations, {
                damage,
                GetTime(),
                0.2 + damage/UnitHealthMax(self.unit)*0.5
            })
            self.Animation:Show()
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
            self.Animation:Hide()
        else
            self.Animation:SetValue(self.health+loss, self.healthMax)
        end
    end,

    Background = Addon.Templates.BarShaped
        :AllPoints()
        :Texture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
        :Value(1, 1)
        :FrameLevel(0)
    {
        ['.Bar'] = Style
            :VertexColor(0.1, 0.1, 0.1, 0.7)
    },

    Animation = Addon.Templates.BarShaped
        :AllPoints(),

    Bar = Addon.Templates.BarShaped
        :AllPoints()
        :Texture 'Interface/AddOns/silver-ui/art/bar-bright',

    Shadow = Frame:AllPoints() { -- framebuffer children need a container
        Left = Texture
            .RIGHT:CENTER()
            :Texture 'Interface/AddOns/silver-ui/art/hp-sharp-shadow'
            :Alpha(0.8),

        Right = Texture
            .LEFT:CENTER()
            :Texture 'Interface/AddOns/silver-ui/art/hp-sharp-shadow'
            :Alpha(0.7),
    },

}

