local _, ns = ...
local lqt = ns.lqt

local Frame, Style, Texture = lqt.Frame, lqt.Style, lqt.Texture


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


Frame -- Dynamic health bar size
    .data {
        initPlate = WithUnitFrame(function(self, unit, uf)
            uf.healthBar:Points { CENTER = uf:CENTER() }
            uf.name:SetShadowColor(0, 0, 0, 0)
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
            local scale = max(0.02, (1.0 - 1 / (x + 1)) * 4)
            
            uf.healthBar:SetWidth(4+80/2*scale)
            -- Plater.SetNameplateSize (unitFrame, 4+settings.Width/2*scale, 4+settings.Height/8*sqrt(scale))
        end)
    }
    :EventHook {
        NAME_PLATE_UNIT_ADDED = function(self, unit) self:initPlate(unit) end,
        UNIT_HEALTH = function(self, unit) self:adjustHealthbar(unit) end,
    }
    .new()


Frame -- Cast bar over health bar
    .data {
        initPlate = WithUnitFrame(function(self, unit, uf)
            uf.healthBar:Points { CENTER = uf:CENTER() }
            uf.castBar:Points { CENTER = uf:CENTER() }
            uf.castBar:SetSize(uf.healthBar:GetSize())
            uf.castBar.background:SetTexture('')
            uf.castBar:SetStatusBarTexture('')
            uf.castBar.Text:Points { BOTTOM = uf.castBar:TOP() }
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
            castBar.Icon:SetAlpha(0)
            castBar.Icon:Hide()
            castBar.BorderShield:SetTexture('')

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
        end)
    }
    :EventHook {
        NAME_PLATE_UNIT_ADDED = function(self, unit) self:initPlate(unit) end,
        UNIT_SPELLCAST_START = function(self, unit) self:castStart(unit) end,
        UNIT_SPELLCAST_STOP = function(self, unit) self:castStop(unit) end,
        UNIT_SPELLCAST_CHANNEL_START = function(self, unit) self:castStart(unit, true) end,
        UNIT_SPELLCAST_CHANNEL_STOP = function(self, unit) self:castStop(unit, true) end,
    }
    .new()

