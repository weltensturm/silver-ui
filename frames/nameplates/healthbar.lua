---@class Addon
local Addon = select(2, ...)

Addon.Nameplates = Addon.Nameplates or {}

local LQT = Addon.LQT
local Override = LQT.Override
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local Script = LQT.Script
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture

local GetTime = GetTime

local color = Addon.util.color
local HealthDynamicScale = Addon.util.HealthDynamicScale


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


local function Pixel2Align(widget, size)
    local pixelFactor = PixelUtil.GetPixelToUIUnitFactor()
    local pixels = math.floor(size * widget:GetEffectiveScale() / pixelFactor)
    if pixels % 2 ~= 0 then
        pixels = pixels + 1
    end
    return pixels / widget:GetEffectiveScale() * pixelFactor
end


Addon.Nameplates.FrameHealthBar = Frame
    .BOTTOM:BOTTOM()
    :Size(128, 16)
    :FlattensRenderLayers(true)
    :IsFrameBuffer(true)
{
    parent = PARENT,
    animations = {}, -- { { lost health, start, duration }, }
    health = 0,
    healthMax = 0,

    [Override.SetEventUnit] = function(self, orig, unit, _)
        self.unit = unit
        self.animations = {}
        self.health = UnitHealth(unit)
        self.healthMax = 0
        self.healthCombat = UnitHealth(unit)
        self:SetValue(UnitHealth(unit), UnitHealthMax(unit))
        self.MaskAnimLeft:SetPoint('LEFT', self.MaskLeft, 'LEFT')
        self.MaskAnimRight:SetPoint('RIGHT', self.MaskRight, 'RIGHT')
        self:UpdateColor()
        orig(self, unit)
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
        self.Textures.Bar:SetVertexColor(r, g, b)
    end,
    [Event.PLAYER_REGEN_DISABLED] = SELF.UpdateColor,
    [Event.PLAYER_REGEN_ENABLED] = SELF.UpdateColor,
    [UnitEvent.UNIT_FACTION] = SELF.UpdateColor,
    [UnitEvent.UNIT_THREAT_LIST_UPDATE] = SELF.UpdateColor,

    -- [Event.PLAYER_TARGET_CHANGED] = function(self)
    --     if UnitIsUnit(self.unit, 'target') or UnitAffectingCombat(self.unit) then
    --         self:Show()
    --     else
    --         self:Hide()
    --     end
    -- end,

    SetValue = function(self, value, max)
        local width = self:GetWidth()

        if max ~= self.healthMax then
            if max < self.healthMax then
                table.insert(self.animations, {
                    max - self.healthMax,
                    GetTime(),
                    0.2 + (max-self.healthMax)/max*0.5
                })
                self.Textures.BarAnimation:Show()
            end

            local scale = HealthDynamicScale(self.unit)

            self:SetSize(Pixel2Align(self, 4+100/2*scale), Pixel2Align(self, 5))

            width = self:GetWidth()
            local height = self:GetHeight()

            local MASK_WIDTH_RATIO = 4096 / 64
            local huge_width = math.max(0.01, self:GetHeight()) * MASK_WIDTH_RATIO
            for _, v in pairs { self.MaskLeft, self.MaskRight, self.MaskBgLeft, self.MaskBgRight,
                                self.MaskAnimLeft, self.MaskAnimRight } do
                PixelUtil.SetWidth(v, huge_width)
            end
            PixelUtil.SetSize(self.Textures.ShadowLeft, width/2+height*0.35, height*2)
            PixelUtil.SetSize(self.Textures.ShadowRight, width/2+height*0.35, height*2)
            self.Textures.ShadowLeft:SetTexCoord(0, width/2/huge_width, 0, 1)
            self.Textures.ShadowRight:SetTexCoord(1 - width/2/huge_width, 1, 0, 1)

            self.endcapWidth = height/2
            self.endcapHP = max/(self.endcapWidth*height + width*height)*self.endcapWidth*height
        end

        local shapeWidth = 0
        if value > self.endcapHP*2 then
            shapeWidth = self.endcapWidth*2 + (value-self.endcapHP*2)
                                                /(max-self.endcapHP*2)*(width-self.endcapWidth*2)
        else
            shapeWidth = math.sqrt(value/self.endcapHP/2) * self.endcapWidth*2
        end
        local offset = PixelUtil.GetNearestPixelSize((width-shapeWidth)/2, self:GetEffectiveScale())
        self.MaskLeft:SetPoint('LEFT', self, 'LEFT', offset, 0)
        self.MaskRight:SetPoint('RIGHT', self, 'RIGHT', -offset, 0)

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
            self.Textures.BarAnimation:Show()
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
            self.Textures.BarAnimation:Show()
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
            self.Textures.BarAnimation:Hide()
        else
            local width = self:GetWidth()
            local healthMax = self.healthMax
            local endcapHP = self.endcapHP
            local endcapWidth = self.endcapWidth

            local shapeWidth = 0
            local health = self.health+loss
            if health > endcapHP*2 then
                shapeWidth = endcapWidth*2 + (health-endcapHP*2)/(healthMax-endcapHP*2)*(width-endcapWidth*2)
            else
                shapeWidth = math.sqrt(health/endcapHP/2) * endcapWidth*2
            end
            local offset = PixelUtil.GetNearestPixelSize((width-shapeWidth)/2, self:GetEffectiveScale())
            self.MaskAnimLeft:SetPoint('LEFT', self, 'LEFT', offset, 0)
            self.MaskAnimRight:SetPoint('RIGHT', self, 'RIGHT', -offset, 0)
        end
    end,

    MaskLeft = MaskTexture
        .TOP:TOP()
        .BOTTOM:BOTTOM()
        .LEFT:LEFT()
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),

    MaskRight = MaskTexture
        .TOP:TOP()
        .BOTTOM:BOTTOM()
        .RIGHT:RIGHT()
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),

    MaskAnimLeft = MaskTexture
        .TOP:TOP()
        .BOTTOM:BOTTOM()
        .LEFT:LEFT()
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp-solid-anim', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),

    MaskAnimRight = MaskTexture
        .TOP:TOP()
        .BOTTOM:BOTTOM()
        .RIGHT:RIGHT()
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp-solid-anim', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),

    MaskBgLeft = MaskTexture
        .TOPLEFT:TOPLEFT()
        .BOTTOMLEFT:BOTTOMLEFT()
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp-solid', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),

    MaskBgRight = MaskTexture
        .TOPRIGHT:TOPRIGHT()
        .BOTTOMRIGHT:BOTTOMRIGHT()
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp-solid', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),

    Textures = Frame:AllPoints(PARENT) { -- for whatever reason framebuffer children need another container
        ShadowLeft = Texture
            .RIGHT:CENTER()
            :Texture 'Interface/AddOns/silver-ui/art/hp-sharp-shadow'
            :Alpha(0.8),

        ShadowRight = Texture
            .LEFT:CENTER()
            :Texture 'Interface/AddOns/silver-ui/art/hp-sharp-shadow'
            :Alpha(0.7),

        Bar = Texture
            -- .TOPLEFT:TOPLEFT(-4, 0)
            -- .BOTTOMRIGHT:BOTTOMRIGHT(4, 0)
            -- .TOP:TOP()
            -- .BOTTOM:BOTTOM()
            :AllPoints(PARENT)
            -- :ColorTexture(1, 0, 0, 1)
            -- :Texture 'Interface/BUTTONS/GreyscaleRamp64'
            -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar'
            -- :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
            -- :Texture 'Interface/AddOns/silver-ui/art/healthbar'
            :Texture 'Interface/AddOns/silver-ui/art/UI-StatusBar'
            :TexCoord(0.3, 0.7, 0.1, 0.9)
            :DrawLayer('ARTWORK', 2)
            :AddMaskTexture(PARENT:GetParent().MaskLeft)
            :AddMaskTexture(PARENT:GetParent().MaskRight),

        BarAnimation = Texture
            :AllPoints(PARENT)
            :ColorTexture(1, 1, 1, 1)
            :DrawLayer('BORDER')
            :AddMaskTexture(PARENT:GetParent().MaskAnimLeft)
            :AddMaskTexture(PARENT:GetParent().MaskAnimRight),

        Background = Texture
            :AllPoints(PARENT)
            :Texture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
            -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar-Glow'
            :VertexColor(0.1, 0.1, 0.1, 0.7)
            :DrawLayer 'BACKGROUND'
            :AddMaskTexture(PARENT:GetParent().MaskBgLeft)
            :AddMaskTexture(PARENT:GetParent().MaskBgRight),
    },

}

