
local Frame, Style, Texture, Cooldown = LQT.Frame, LQT.Style, LQT.Texture, LQT.Cooldown

local PARENT = LQT.PARENT


local addon = Frame.new()


local StyleTargetFrameThreat = Style {
    Style'.threatIndicator'
        :DrawLayer 'BACKGROUND'
        :Alpha(0.1)
        :Texture 'Interface/Masks/CircleMaskScalable'
        :TexCoord(0, 1, 0, 1)
        :Points { CENTER = TargetFrame:CENTER() }
        :Size(84, 84)
}

local StyleTargetFrameRetail = Style {
    Style'.TargetFrameContainer' {
        Style'.Texture':Texture '':Alpha(0),
        Style'.Portrait'
            :Show()
            :DrawLayer 'ARTWORK'
            :Points { CENTER = PARENT:CENTER() },
    },
    Style'.TargetFrameContent' {
        Style'.TargetFrameContentMain' {
            Style'.LevelText':Points { TOP = PARENT:TOP() },
            Style'.Name':JustifyH 'MIDDLE':Points { BOTTOM = PARENT:BOTTOM() },
            Style'.ReputationColor':Texture '':Alpha(0),
        }
    }
}

addon:SetEventHooks {
    PLAYER_ENTERING_WORLD = function()

        Style(TargetFrame)
            :Size(100, 100)
            :HitRectInsets(0, 0, 0, 0)
        {
            StyleTargetFrameRetail,
            Style'.textureFrame' {
                Style'.Texture':Texture '',
                Style'.texture':Texture 'Interface/TARGETINGFRAME/UI-TARGETINGFRAME-MINUS',
                Style'.*LevelText' .. function(self)
                    self:SetPoints {
                        BOTTOM = self:GetParent():BOTTOM(0, 10)
                    }
                end,
                Style'.TargetFrameTextureFrameName'
                .. function(self)
                    self:SetPoints { TOP = self:GetParent():TOP() }
                end
            },
            Style'.nameBackground':Texture '',
            Style'.Background':Texture '',

            Style'.portrait'
                :DrawLayer 'ARTWORK'
                .. function(self) self:SetPoints { CENTER = self:GetParent():CENTER() } end,

            Frame'.BgContainer'
                :FrameStrata 'BACKGROUND'
                :FrameLevel(0)
                :Size(92, 92)
                .init(function(self, parent) self:SetAllPoints(parent) end)
            {
                Texture'.BarCircularBgBlack'
                    :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                    :Size(88, 88)
                    :SetDrawLayer('BACKGROUND', 0)
                    :VertexColor(0, 0, 0, 0.7)
                    .init(function(self, parent)
                        self:SetPoints { CENTER = parent:CENTER() }
                    end),
                -- Texture'.BarCircularBg'
                --     -- :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                --     :Texture 'Interface/Masks/CircleMaskScalable'
                --     :Size(84, 84)
                --     :SetDrawLayer('BACKGROUND', 1)
                --     :VertexColor(0, 0, 0, 0.7)
                --     .init(function(self, parent)
                --         self:SetPoints { CENTER = parent:CENTER() }
                --     end),
            },

            Cooldown'.HealthBarCircular'
                :UseCircularEdge(true)
                :SwipeTexture('Interface/GUILDFRAME/GuildLogoMask_L')
                -- :SwipeTexture('Interface/Masks/CircleMaskScalable')
                :Size(88, 88)
                :SwipeColor(1, 1, 1, 1)
                :DrawEdge(false)
                :FrameStrata 'BACKGROUND'
                :FrameLevel(1)
                :Rotation(math.rad(90))
                :HideCountdownNumbers(true)
                :Reverse(true)
                .init(function(self, parent)
                    self:SetPoints { CENTER = parent:CENTER() }
                end)
                :Show()
                :CooldownDuration(1)
                :Pause()
                :Hooks {
                    OnUpdate = function(self)
                        local parent = self:GetParent()
                        if parent.unit then
                            local hp = UnitHealth(parent.unit) / math.max(UnitHealthMax(parent.unit), 1)
                            self:SetSwipeColor(0, 0.8, 0, 1)
                            self:SetRotation(math.rad(90)+math.rad(90)*(1-hp))
                            -- self:SetSwipeColor(parent.HealthBar:GetStatusBarColor())
                            self:SetCooldown(GetTime()-hp, 2)
                            self:Pause()
                        end
                    end
                },

            Cooldown'.PowerBarCircular'
                :UseCircularEdge(true)
                :SwipeTexture('Interface/GUILDFRAME/GuildLogoMask_L')
                -- :SwipeTexture('Interface/Masks/CircleMaskScalable')
                :SwipeColor(1, 1, 1, 1)
                :Size(88, 88)
                :DrawEdge(false)
                :FrameStrata 'BACKGROUND'
                :FrameLevel(2)
                :Rotation(math.rad(-90))
                :HideCountdownNumbers(true)
                :Reverse(true)
                .init(function(self, parent)
                    self:SetPoints { CENTER = parent:CENTER() }
                end)
                :Show()
                :CooldownDuration(1)
                :Pause()
                :Hooks {
                    OnUpdate = function(self)
                        local parent = self:GetParent()
                        if parent.unit then
                            local power = UnitPower(parent.unit) / math.max(UnitPowerMax(parent.unit), 0.1)
                            -- self:SetSwipeColor(parent.PowerBar:GetStatusBarColor())
                            -- self:SetSwipeColor(0.2, 0.2, 1, 1)
                            self:SetRotation(math.rad(-90)+math.rad(90)*(1-power))
                            self:SetCooldown(GetTime()-power, 2)
                            self:Pause()
                        else
                            self:SetCooldownDuration(0)
                        end
                    end
                },


            Frame'.BgOverlay'
                :AllPoints(TargetFrame)
                :FrameStrata 'BACKGROUND'
                :FrameLevel(3)
            {
                Texture'.BarCircularBg'
                    -- :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                    :Texture 'Interface/Masks/CircleMaskScalable'
                    :Size(80, 80)
                    :SetDrawLayer('BORDER', 1)
                    :VertexColor(0, 0, 0, 0.4)
                    .init(function(self, parent)
                        self:SetPoints { CENTER = parent:CENTER() }
                    end),

                Texture'.HealthBarCircularBgInner'
                    :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                    :Size(82, 82)
                    -- :SwipeTexture('Interface/Masks/CircleMaskScalable')
                    :VertexColor(0.1, 0.1, 0.1, 1)
                    -- :FrameStrata('BACKGROUND', 1)
                    :DrawLayer 'BORDER'
                    .init(function(self, parent)
                        self:SetPoints { CENTER = parent:CENTER() }
                    end),
            }

        }
        
        -- TargetFrame.nameBackground:SetColorTexture(0.2,0.2,0.2,1)
    end,

    PLAYER_TARGET_CHANGED = function()
        -- TargetFrame.textureFrame.texture:SetTexture('Interface/TARGETINGFRAME/UI-TARGETINGFRAME-MINUS')
        -- TargetFrame.textureFrame.texture:SetTexture('Interface/TARGETINGFRAME/PlayerFrame')

        -- TargetFrame.textureFrame.texture:Hide()
        -- TargetFrame.textureFrame.texture:SetTexture('Interface/TARGETINGFRAME/PlayerFrame')
        -- TargetFrame.textureFrame.texture:SetPoints {
        --     TOPLEFT = TargetFrame.portrait:TOPLEFT(-5, 5),
        --     BOTTOMRIGHT = TargetFrame.portrait:BOTTOMRIGHT(5, -5)
        -- }
        -- TargetFrame.textureFrame.texture:SetTexCoord(0.01,0.73,0.02,0.75)

        Style(TargetFrame) {
            StyleTargetFrameThreat,
            StyleTargetFrameRetail,
            Style'.textureFrame' {
                Style'.*LevelText'
                    :Points {
                        BOTTOM = TargetFrame:BOTTOM()
                    },
                Style'.*DeadText':Points { BOTTOM = TargetFrame:BOTTOM(0, 18) },
                Style'.texture':Texture '':Alpha(0),
            },
            Style'.manabar':Alpha(0),
            Style'.HealthBar':Alpha(0),
            Style'.healthbar':Alpha(0),
            Style'.spellbarAnchor':Points { TOP = TargetFrame:BOTTOM() },
            Style'.TargetFrameDebuff#':Alpha(0),
            Style'.TargetFrameBuff#':Alpha(0),
        }

    end,

    UNIT_THREAT_SITUATION_UPDATE = function(self, unit)
        StyleTargetFrameThreat(TargetFrame)
    end

}