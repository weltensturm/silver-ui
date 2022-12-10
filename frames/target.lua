
local Frame, Style, Texture, Cooldown = LQT.Frame, LQT.Style, LQT.Texture, LQT.Cooldown

local PARENT = LQT.PARENT


local StyleTargetFrameThreat = Style {
    Style'.threatIndicator, .TargetFrameContainer.Flash'
        :DrawLayer 'BACKGROUND'
        :Alpha(0.1)
        :Texture 'Interface/Masks/CircleMaskScalable'
        :TexCoord(0, 1, 0, 1)
        .CENTER:CENTER(TargetFrame)
        :Size(84, 84),
}

local StyleTargetFrameRetail = Style {
    Style'.TargetFrameContainer' {
        Style'.FrameTexture':Texture '':Alpha(0):Atlas '',
        Style'.BossPortraitFrameTexture':Texture '':Alpha(0):Atlas '',
        Style'.Portrait'
            :Show()
            :DrawLayer 'ARTWORK'
            .CENTER:CENTER()
            :Size(64, 64),
    },
    Style'.TargetFrameContent' {
        Style'.TargetFrameContentMain' {
            Style'.LevelText'.TOP:TOP(),
            Style'.Name':JustifyH 'MIDDLE'.BOTTOM:BOTTOM(0, 4),
            Style'.ReputationColor':Texture '':Alpha(0),
        },
        Style'.TargetFrameContentContextual' {
            Style'.NumericalThreat' {
                Style'.FontString':Alpha(0),
                Style'.Texture':Alpha(0)
            }
        }
    },
    Style'.totFrame' {
        Style'.Texture':Hide(),
        Style'.HealthBar'
            .TOPLEFT:TOPLEFT(0, -20)
            .BOTTOMRIGHT:TOPRIGHT(0, -22)
        {
            Style'.HealthBarMask':Hide()
        },
        Style'.ManaBar':Hide(),
        Style'.Name'
            .TOPLEFT:TOPLEFT(0, -6)
            .BOTTOMRIGHT:TOPRIGHT(0, -19)
            :JustifyH 'MIDDLE'
    }
}



Frame
    :EventHooks {
        PLAYER_ENTERING_WORLD = function()

            Style(TargetFrame)
                :Size(100, 100)
                :HitRectInsets(0, 0, 0, 0)
            {
                StyleTargetFrameRetail,
                Style'.textureFrame' {
                    Style'.Texture':Texture '',
                    Style'.texture':Texture 'Interface/TARGETINGFRAME/UI-TARGETINGFRAME-MINUS',
                    Style'.*LevelText'.BOTTOM:BOTTOM(0, 10),
                    Style'.TargetFrameTextureFrameName'.TOP:TOP()
                },
                Style'.nameBackground':Texture '',
                Style'.Background':Texture '',

                Style'.portrait'
                    :DrawLayer 'ARTWORK'.CENTER:CENTER(),

                Frame'.BgContainer'
                    :FrameStrata 'BACKGROUND'
                    :FrameLevel(0)
                    :Size(92, 92)
                    :AllPoints(PARENT)
                {
                    Texture'.BarCircularBgBlack'
                        :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                        :Size(88, 88)
                        :SetDrawLayer('BACKGROUND', 0)
                        :VertexColor(0, 0, 0, 0.7)
                        .CENTER:CENTER(),
                    -- Texture'.BarCircularBg'
                    --     -- :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                    --     :Texture 'Interface/Masks/CircleMaskScalable'
                    --     :Size(84, 84)
                    --     :SetDrawLayer('BACKGROUND', 1)
                    --     :VertexColor(0, 0, 0, 0.7)
                    --     .CENTER:CENTER()
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
                    .CENTER:CENTER()
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
                    .CENTER:CENTER()
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
                        .CENTER:CENTER()
                        -- :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                        :Texture 'Interface/Masks/CircleMaskScalable'
                        :Size(80, 80)
                        :SetDrawLayer('BORDER', 1)
                        :VertexColor(0, 0, 0, 0.4),

                    Texture'.HealthBarCircularBgInner'
                        .CENTER:CENTER()
                        :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                        :Size(82, 82)
                        -- :SwipeTexture('Interface/Masks/CircleMaskScalable')
                        :VertexColor(0.1, 0.1, 0.1, 1)
                        -- :FrameStrata('BACKGROUND', 1)
                        :DrawLayer 'BORDER',
                }

            }
            
            -- TargetFrame.nameBackground:SetColorTexture(0.2,0.2,0.2,1)
        end,

        PLAYER_TARGET_CHANGED = function()
            Style(TargetFrame) {
                StyleTargetFrameThreat,
                StyleTargetFrameRetail,
                Style'.textureFrame' {
                    Style'.*LevelText'
                        .BOTTOM:BOTTOM(TargetFrame),
                    Style'.*DeadText'.BOTTOM:BOTTOM(TargetFrame, 0, 18),
                    Style'.texture':Texture '':Alpha(0),
                },
                Style'.TargetFrameContent.TargetFrameContentMain' {
                    Style'.ManaBar':Alpha(0),
                    Style'.HealthBar':Alpha(0),
                    Style'.healthbar':Alpha(0),
                    Style'.spellbarAnchor'.TOP:BOTTOM(TargetFrame),
                    Style'.TargetFrameDebuff#':Alpha(0),
                    Style'.TargetFrameBuff#':Alpha(0),
                }
            }

        end,

        UNIT_THREAT_SITUATION_UPDATE = function(self, unit)
            StyleTargetFrameThreat(TargetFrame)
        end

    }
    .new()
