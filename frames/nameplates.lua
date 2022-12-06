


local
    Frame,
    CheckButton,
    FontString,
    Style,
    Texture
    =   LQT.Frame,
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


local function WithUnitFrame(fn)
    return function(self, unit, ...)
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if plate and plate.UnitFrame then
            return fn(self, unit, plate.UnitFrame, ...)
        end
    end
end


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
                uf.name:SetShadowColor(0, 0, 0, 0.5)
                uf.classificationIndicator:SetVertexColor(0,0,0,0)
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
                self:updateThreat(unit, uf)
            end),
            updateHpScale = function(self, uf)
                uf.healthBar:ClearAllPoints()
                uf.healthBar:SetPoint('CENTER', uf, 'CENTER')
                uf.healthBar:SetWidth(4+100/2*uf.healthBar.CachedScale)
            end,
            updateThreat = function(self, unit, uf)
                if UnitAffectingCombat('player') then
                    local threat = UnitThreatSituation('player', unit) or 0
                    local r, g, b, a = uf.healthBar.barTexture:GetVertexColor()
                    uf.healthBar.barTexture:SetVertexColor(r, 0.3-threat/10, b, a)
                end
            end
        }
        :EventHooks {
            NAME_PLATE_UNIT_ADDED = function(self, unit) self:initPlate(unit) end,
            UNIT_HEALTH = function(self, unit) self:adjustHealthbar(unit) end,
            PLAYER_TARGET_CHANGED = function(self) self:adjustHealthbar('target') end,
            UNIT_THREAT_LIST_UPDATE = function(self, unit)
                local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
                if nameplate and nameplate.UnitFrame then
                    self:updateThreat(unit, nameplate.UnitFrame)
                end
            end
        }
        .new()

    hooksecurefunc(NamePlateBaseMixin, 'OnSizeChanged', function(self)
        if self.UnitFrame.unit and self.UnitFrame.healthBar.CachedScale then
            healthBarManager:updateHpScale(self.UnitFrame)
        end
    end)


    Frame -- Cast bar over health bar
        .data {
            initPlate = WithUnitFrame(function(self, unit, uf)
                if UnitCastingInfo(unit) or UnitChannelInfo(unit) then
                    self:castStart(unit)
                end
            end),
            castStart = WithUnitFrame(function(self, unit, uf, channel)
                local notInterruptible
                if channel then
                    notInterruptible = select(7, UnitChannelInfo(unit))
                else
                    notInterruptible = select(8, UnitCastingInfo(unit))
                end

                local castBar = uf.castBar
                uf.healthBar:ClearAllPoints()
                uf.healthBar:SetPoint('CENTER', uf, 'CENTER')
                castBar:ClearAllPoints()
                castBar:SetPoint('CENTER', uf, 'CENTER')
                castBar:SetSize(uf.healthBar:GetSize())
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
                    local r, g, b, a = uf.name:GetTextColor()
                    castBar.Text:SetTextColor(r, g, b, 1)
                else
                    castBar.Spark:SetVertexColor(1, 1, 1, 1) 
                    castBar.Text:SetTextColor(1, 1, 1, 1)
                end
                castBar.Text:SetFont(uf.name:GetFont())
                uf.name:SetAlpha(0)
            end),
            castStop = WithUnitFrame(function(self, unit, uf)
                uf.name:SetAlpha(1)
                uf.castBar:Hide()
            end)
        }
        :EventHooks {
            NAME_PLATE_UNIT_ADDED = function(self, unit) self:initPlate(unit) end,
            UNIT_SPELLCAST_START = function(self, unit) self:castStart(unit) end,
            UNIT_SPELLCAST_STOP = function(self, unit) self:castStop(unit) end,
            UNIT_SPELLCAST_CHANNEL_START = function(self, unit) self:castStart(unit, true) end,
            UNIT_SPELLCAST_CHANNEL_STOP = function(self, unit) self:castStop(unit, true) end,
            PLAYER_TARGET_CHANGED = function(self) self:initPlate('target') end,
        }
        .new()

end