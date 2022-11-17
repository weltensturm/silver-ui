

SilverUI.RegisterScript (
    'Silver UI',
    'Nameplates',
    {
        enabled = false
    },
    [[

local Frame, Style, Texture = LQT.Frame, LQT.Style, LQT.Texture


local function WithUnitFrame(fn)
    return function(self, unit, ...)
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if plate and plate.UnitFrame then
            return fn(self, unit, plate.UnitFrame, ...)
        end
    end
end


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
            local x =  healthMax / UnitHealthMax("player") / diminish / 2
            uf.healthBar.CachedScale = max(0.02, (1.0 - 1 / (x + 1)) * 4)
            self:updateHpScale(uf)
        end),
        updateHpScale = function(self, uf)
            uf.healthBar:SetPoints { CENTER = uf:CENTER() }
            uf.healthBar:SetWidth(4+80/2*uf.healthBar.CachedScale)
        end
    }
    :EventHooks {
        NAME_PLATE_UNIT_ADDED = function(self, unit) self:initPlate(unit) end,
        UNIT_HEALTH = function(self, unit) self:adjustHealthbar(unit) end,
        PLAYER_TARGET_CHANGED = function(self) self:adjustHealthbar('target') end,
    }
    .new()

hooksecurefunc(NamePlateBaseMixin, 'OnSizeChanged', function(self)
    if self.UnitFrame.unit then
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
            uf.healthBar:SetPoints { CENTER = uf:CENTER() }
            castBar:SetPoints { CENTER = uf:CENTER() }
            castBar:SetSize(uf.healthBar:GetSize())
            castBar.Text:SetPoints { BOTTOM = castBar:TOP() }

            castBar.Icon:SetAlpha(0)
            castBar.Icon:Hide()
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

]]
)