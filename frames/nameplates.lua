


local
    SELF,
    PARENT,
    Frame,
    CheckButton,
    FontString,
    Style,
    Texture
    =   LQT.SELF,
        LQT.PARENT,
        LQT.Frame,
        LQT.CheckButton,
        LQT.FontString,
        LQT.Style,
        LQT.Texture


local db
local load


SilverUI.Storage {
    name = 'Nameplates',
    character = {
        enabled = true
    },
    onload = function(account, character)
        db = character
        if character.enabled then
            load()
        end
    end
}


SilverUI.Settings 'Nameplates' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Nameplates',

    CheckButton
        :Size(24, 24)
        :NormalTexture 'Interface/Buttons/UI-CheckBox-Up'
        :PushedTexture 'Interface/Buttons/UI-CheckBox-Down'
        :HighlightTexture 'Interface/Buttons/UI-CheckBox-Highlight'
        :CheckedTexture 'Interface/Buttons/UI-CheckBox-Check'
        :DisabledCheckedTexture 'Interface/Buttons/UI-CheckBox-Check-Disabled'
        :HitRectInsets(-4, -100, -4, -4)
        :Hooks {
            OnClick = function(self)
                db.enabled = self:GetChecked()
            end
        }
    {
        function(self)
            self:SetChecked(db.enabled)
        end,
        FontString'.Label'
            .LEFT:RIGHT()
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            :Text 'Enable'
    }

}


local darken
do
    local colorSelect = CreateFrame('ColorSelect') -- Convert RGB <-> HSV (:
    darken = function(r, g, b, darken)
        colorSelect:SetColorRGB(r, g, b)
        local h, s, v = colorSelect:GetColorHSV()
        v = v * darken
        colorSelect:SetColorHSV(h, s, v)
        return colorSelect:GetColorRGB()
    end
end


local function WithUnitFrame(fn)
    return function(self, unit, ...)
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if plate and plate.UnitFrame then
            return fn(self, unit, plate.UnitFrame, ...)
        end
    end
end


local StyleUnitFrame = Style {
    Frame'.SilverUI'
        :AllPoints(PARENT)
        :RegisterEvent 'PLAYER_REGEN_DISABLED'
        :RegisterEvent 'PLAYER_REGEN_ENABLED'
        .init {
            UpdateUnit = function(self)
                self:UnregisterEvent('UNIT_THREAT_LIST_UPDATE')
                self:RegisterUnitEvent('UNIT_THREAT_LIST_UPDATE', self.uf.unit)
                self:UpdateThreat()
            end,

            UpdateThreat = function(self)
                local r, g, b = self.uf.healthBar.r, self.uf.healthBar.g, self.uf.healthBar.b
                if UnitAffectingCombat('player') then
                    local threat = UnitThreatSituation('player', self.uf.unit) or 0
                    local r, g, b = self.uf.healthBar.r, self.uf.healthBar.g, self.uf.healthBar.b
                    r, g, b = darken(r, g, b, 0.75 + threat/3/4)
                    self.uf.healthBar.barTexture:SetVertexColor(r, g, b)
                else
                    self.uf.healthBar.barTexture:SetVertexColor(r, g, b)
                end
            end
        }
        .init {
            function(self, uf)
                self.uf = uf
                if uf.unit then
                    self:UpdateUnit()
                end
            end
        }
        :Hooks {
            OnShow = SELF.UpdateThreat,
            OnEvent = SELF.UpdateThreat
        },
    
    Style'.name'
        :ShadowColor(0, 0, 0, 0.5),
    Style'.ClassificationFrame'
        :Alpha(0)
}


local StyleUnitFrameCastBar = Style {
    
    Frame'.SilverUICast'
        :AllPoints(PARENT)
        :RegisterEvent 'PLAYER_TARGET_CHANGED'
        .data {
            UpdateUnit = function(self)
                self:UnregisterEvent 'UNIT_SPELLCAST_START'
                self:UnregisterEvent 'UNIT_SPELLCAST_STOP'
                self:UnregisterEvent 'UNIT_SPELLCAST_CHANNEL_START'
                self:UnregisterEvent 'UNIT_SPELLCAST_CHANNEL_STOP'

                if self.uf.unit then
                    self:RegisterUnitEvent('UNIT_SPELLCAST_START', self.uf.unit)
                    self:RegisterUnitEvent('UNIT_SPELLCAST_STOP', self.uf.unit)
                    self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_START', self.uf.unit)
                    self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_STOP', self.uf.unit)
                    self:UpdateCastBar()
                end
            end,
            UpdateCastBar = function(self)
                if not self.uf.unit then return end
                
                local casting = UnitCastingInfo(self.uf.unit)
                local channeling = UnitChannelInfo(self.uf.unit)

                if casting or channeling then
                    local notInterruptible
                    if channeling then
                        notInterruptible = select(7, UnitChannelInfo(self.uf.unit))
                    else
                        notInterruptible = select(8, UnitCastingInfo(self.uf.unit))
                    end

                    local castBar = self.uf.castBar
                    self.uf.healthBar:ClearAllPoints()
                    self.uf.healthBar:SetPoint('CENTER', self.uf, 'CENTER')
                    castBar:ClearAllPoints()
                    castBar:SetPoint('CENTER', self.uf, 'CENTER')
                    castBar:SetSize(self.uf.healthBar:GetSize())
                    castBar.Text:ClearAllPoints()
                    castBar.Text:SetPoint('BOTTOM', castBar, 'TOP')

                    -- castBar.Icon:SetAlpha(0)
                    -- castBar.Icon:SetAtlas('')
                    -- castBar.Icon:SetScale(0)
                    castBar.Icon:SetMask 'Interface/AddOns/silver-ui/art/force-hide'
                    castBar.BorderShield:SetTexture('')

                    local bg = castBar.background or castBar.Background
                    bg:SetTexture('')
                    bg:SetAlpha(0)
                    castBar:SetStatusBarColor(0, 0, 0, 0)

                    local texture = castBar:GetStatusBarTexture()
                    castBar.Spark:SetPoint('TOP',texture,'TOPRIGHT',-1,4)
                    castBar.Spark:SetPoint('BOTTOM',texture,'BOTTOMRIGHT',-1,-4)
                    castBar.Spark:Show()

                    if notInterruptible then
                        castBar.Spark:SetVertexColor(1, 0, 0, 0.7) 
                        local r, g, b, a = self.uf.name:GetTextColor()
                        castBar.Text:SetTextColor(r, g, b, 1)
                    else
                        castBar.Spark:SetVertexColor(1, 1, 1, 1) 
                        castBar.Text:SetTextColor(1, 1, 1, 1)
                    end
                    castBar.Text:SetFont(self.uf.name:GetFont())
                    self.nameAlpha = 0
                    self:UpdateName()
                else
                    self.uf.castBar:Hide()
                    self.nameAlpha = 1
                    self:UpdateName()
                end

            end,
            UpdateName = function(self)
                self.uf.name:SetAlpha(self.nameAlpha)
            end
        }
        .init {
            function(self, uf)
                self.uf = uf
                if uf.unit then
                    self:UpdateUnit()
                end
            end
        }
        :Hooks {
            OnEvent = SELF.UpdateCastBar,
            OnShow = SELF.UpdateCastBar
        }


}


hooksecurefunc('CompactUnitFrame_SetUnit', function(self, unit)
    if self.SilverUI then
        self.SilverUI:UpdateUnit()
        self.SilverUICast:UpdateUnit()
    end
end)

hooksecurefunc('CompactUnitFrame_UpdateName', function(self)
    if self.SilverUICast then
        self.SilverUICast:UpdateName()
    end
end)

load = function()

    Frame -- Enable all plates in combat
        :Scripts {
            OnEvent = function(self, event)
                SetCVar("nameplateShowAll", event=="PLAYER_REGEN_DISABLED" and 1 or 0)
            end
        }
        :RegisterEvent("PLAYER_REGEN_ENABLED")
        :RegisterEvent("PLAYER_REGEN_DISABLED")
        .new()


    local healthBarManager = Frame -- Dynamic health bar size
        .data {
            initPlate = WithUnitFrame(function(self, unit, uf)
                StyleUnitFrame(uf)
                StyleUnitFrameCastBar(uf)
                self:adjustHealthbar(unit)
            end),
            adjustHealthbar = WithUnitFrame(function(self, unit, uf)
                local healthMax = UnitHealthMax(unit)
                local diminish = max(1,  UnitEffectiveLevel("player") - UnitLevel(unit) - 9)
                diminish = diminish + (max(1, GetNumGroupMembers()) - 1)
                if UnitLevel(unit) < 0 or UnitIsPlayer(unit) or UnitIsPVP(unit) then
                    diminish = 1
                end
                local x =  healthMax / UnitHealthMax("player") / diminish / 1.75
                uf.healthBar.CachedScale = max(0.02, (1.0 - 1 / (x + 1)) * 4)
                self:updateHpScale(uf)
            end),
            updateHpScale = function(self, uf)
                uf.healthBar:ClearAllPoints()
                uf.healthBar:SetPoint('CENTER', uf, 'CENTER')
                uf.healthBar:SetWidth(4+100/2*uf.healthBar.CachedScale)
            end
        }
        :EventHooks {
            NAME_PLATE_UNIT_ADDED = function(self, unit) self:initPlate(unit) end,
            UNIT_HEALTH = function(self, unit) self:adjustHealthbar(unit) end,
            PLAYER_TARGET_CHANGED = function(self) self:adjustHealthbar('target') end
        }
        .new()

    hooksecurefunc(NamePlateBaseMixin, 'OnSizeChanged', function(self)
        if self.UnitFrame.unit and self.UnitFrame.healthBar.CachedScale then
            healthBarManager:updateHpScale(self.UnitFrame)
        end
    end)

end
