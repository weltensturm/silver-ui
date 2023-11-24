---@class Addon
local Addon = select(2, ...)


Addon.Nameplates = Addon.Nameplates or {}


local LQT = Addon.LQT
local Override = LQT.Override
local Hook = LQT.Hook
local Script = LQT.Script
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local FontString = LQT.FontString
local MaskTexture = LQT.MaskTexture
local Texture = LQT.Texture
local Animation = LQT.Animation
local AnimationGroup = LQT.AnimationGroup


local Aura = Frame
    :Size(12, 12)
    :Alpha(0.9)
    :EnableMouse(true)
{
    Mask = MaskTexture
        :AllPoints(PARENT)
        :TexelSnappingBias(0)
        :SnapToPixelGrid(false)
        :Texture 'Interface/AddOns/silver-ui/art/circle',

    Texture = Texture
        :AllPoints(PARENT)
        :TexCoord(0.1, 0.9, 0.1, 0.9)
        :TexelSnappingBias(0)
        :SnapToPixelGrid(false)
        :AddMaskTexture(PARENT.Mask),

    Ring = Texture
        :AllPoints(PARENT)
        :SnapToPixelGrid(false)
        :TexelSnappingBias(0)
        :DrawLayer('OVERLAY', 0)
        :Texture 'Interface/AddOns/silver-ui/art/ring-thick',

    SecondsHand = Texture
        .TOPLEFT:TOPLEFT(-10, 10)
        .BOTTOMRIGHT:BOTTOMRIGHT(10, -10)
        :SnapToPixelGrid(false)
        :TexelSnappingBias(0)
        :Texture 'Interface/AddOns/silver-ui/art/edge'
        :DrawLayer('OVERLAY', 1)
    {
        Animation = AnimationGroup {
            Rotation = Animation.Rotation
        },
    },

    Count = FontString
        .BOTTOMRIGHT:BOTTOMRIGHT(1.5, -1)
        :Font('Fonts/ARIALN.ttf', 8, 'OUTLINE')
        :DrawLayer('OVERLAY', 2)
        :ShadowOffset(1, -1),

    SetAura = function(self, unit, aura)
        self.unit = unit
        self.aura = aura
        -- print(name, icon, count, duration, castByPlayer)
        self:Show()

        self.Texture:SetTexture(aura.icon)

        if aura.duration and aura.duration > 0 then
            if aura.expirationTime > GetTime() then
                self.SecondsHand.Animation.Rotation:SetRadians(math.pi*2 * (aura.expirationTime-GetTime())/60)
                self.SecondsHand.Animation.Rotation:SetDuration(aura.expirationTime-GetTime())
            end
        else
            self.SecondsHand.Animation.Rotation:SetRadians(math.pi*2)
            self.SecondsHand.Animation.Rotation:SetDuration(60)
        end
        self.Count:SetText(aura.applications > 0 and aura.applications or '')
        self.SecondsHand.Animation:Restart(true)

        if aura.isHelpful then
            self.Ring:SetVertexColor(1, 1, 1, 1)
        else
            self.Ring:SetVertexColor(0.7, 0.1, 0.1, 1)
        end
    end,

    Update = function(self, aura)
        self.aura = aura
        self.Count:SetText(aura.applications > 0 and aura.applications or '')
        if aura.duration and aura.duration > 0 then
            self.SecondsHand.Animation.Rotation:SetRadians(math.pi*2 * (aura.expirationTime-GetTime())/60)
            self.SecondsHand.Animation.Rotation:SetDuration(aura.expirationTime-GetTime())
        end
        self.SecondsHand.Animation:Restart(true)
		if GameTooltip:IsOwned(self) then
            GameTooltip:SetUnitAura(self.unit, self.aura.index, self.filter);
        end
    end,

    [Script.OnEnter] = function(self)
        if GameTooltip:IsForbidden() then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetUnitAura(self.unit, self.aura.index, self.filter);
    end,
    [Script.OnLeave] = function(self)
        if GameTooltip:IsForbidden() then return end
        GameTooltip:Hide()
    end,
}


local AuraBin = Addon.util.LIFO()

Addon.Nameplates.Auras = Frame .. Addon.Templates.AuraTracker {

    buffs = {},
    debuffs = {},

    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
    end,

    Layout = function(self)
        for i=1, #self.buffs do
            self.buffs[i]:SetPoint('LEFT', self, 'CENTER', (i-0.33)*14, 24)
        end
        for i=1, #self.debuffs do
            self.debuffs[i]:SetPoint('RIGHT', self, 'CENTER', -(i-0.33)*14, 24)
        end
    end,

    AddBuff = function(self, aura)
        local frame = AuraBin:pop(function() return Aura.new(self) end)
        frame:SetParent(self)
        self.buffs[#self.buffs+1] = frame
        frame:SetAura(self.unit, aura)
        frame:ClearAllPoints()
        frame:SetPoint('LEFT', self, 'CENTER', (#self.buffs-0.33)*14, 24)
    end,

    AddDebuff = function(self, aura)
        local frame = AuraBin:pop(function() return Aura.new(self) end)
        frame:SetParent(self)
        self.debuffs[#self.debuffs+1] = frame
        frame:SetAura(self.unit, aura)
        frame:ClearAllPoints()
        frame:SetPoint('RIGHT', self, 'CENTER', -(#self.debuffs-0.33)*14, 24)
    end,

    [Hook.AuraAdd] = function(self, instance, aura)
        if aura.isHelpful and aura.isStealable then
            self:AddBuff(aura)
        elseif aura.isHarmful and aura.source == 'player' then
            self:AddDebuff(aura)
        end
    end,

    [Hook.AuraUpdate] = function(self, instance, aura)
        for i=1, #self.buffs do
            if self.buffs[i].aura.auraInstanceID == instance then
                self.buffs[i]:Update(aura)
            end
        end
        for i=1, #self.debuffs do
            if self.debuffs[i].aura.auraInstanceID == instance then
                self.debuffs[i]:Update(aura)
            end
        end
    end,

    [Hook.AuraRemove] = function(self, instance, aura)
        local needsLayout = false
        for i=#self.buffs, 1, -1 do
            if self.buffs[i].aura.auraInstanceID == instance then
                self.buffs[i]:Hide()
                self.buffs[i]:ClearAllPoints()
                self.buffs[i]:SetParent(nil)
                AuraBin:push(self.buffs[i])
                table.remove(self.buffs, i)
                needsLayout = true
            end
        end
        for i=#self.debuffs, 1, -1 do
            if self.debuffs[i].aura.auraInstanceID == instance then
                self.debuffs[i]:Hide()
                self.debuffs[i]:ClearAllPoints()
                self.debuffs[i]:SetParent(nil)
                AuraBin:push(self.debuffs[i])
                table.remove(self.debuffs, i)
                needsLayout = true
            end
        end
        if needsLayout then
            self:Layout()
        end
    end,

}
