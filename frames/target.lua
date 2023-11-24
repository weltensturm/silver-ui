---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Frame, Style, Texture, Cooldown = LQT.Frame, LQT.Style, LQT.Texture, LQT.Cooldown

local PARENT = LQT.PARENT


local StyleTargetFrameThreat = Style {
    ['.threatIndicator, .TargetFrameContainer.Flash'] = Style
        :DrawLayer 'BACKGROUND'
        :Alpha(0.1)
        :Texture 'Interface/Masks/CircleMaskScalable'
        :TexCoord(0, 1, 0, 1)
        .CENTER:CENTER(TargetFrame)
        :Size(84, 84),
}

local StyleTargetFrameRetail = Style {
    ['.TargetFrameContainer'] = Style {
        ['.FrameTexture'] = Style:Texture '':Alpha(0):Atlas '',
        ['.BossPortraitFrameTexture'] = Style:Texture '':Alpha(0):Atlas '',
        ['.Portrait'] = Style
            :Show()
            :DrawLayer 'ARTWORK'
            .CENTER:CENTER()
            :Size(64, 64),
    },
    ['.TargetFrameContent'] = Style {
        ['.TargetFrameContentMain'] = Style {
            ['.LevelText'] = Style.TOP:TOP(),
            ['.Name'] = Style:JustifyH 'MIDDLE'.BOTTOM:BOTTOM(0, 4):Width(500),
            ['.ReputationColor'] = Style:Texture '':Alpha(0),
        },
        ['.TargetFrameContentContextual'] = Style {
            ['.NumericalThreat'] = Style {
                ['.FontString'] = Style:Alpha(0),
                ['.Texture'] = Style:Alpha(0)
            },
            ['.BossIcon'] = Style
                .LEFT:RIGHT(PARENT:GetParent().TargetFrameContentMain.LevelText)
        }
    },
    ['.totFrame'] = Style {
        ['.Texture'] = Style:Hide(),
        ['.HealthBar'] = Style
            .TOPLEFT:TOPLEFT(0, -20)
            .BOTTOMRIGHT:TOPRIGHT(0, -22)
        {
            ['.HealthBarMask'] = Style:Hide()
        },
        ['.ManaBar'] = Style:Hide(),
        ['.Name'] = Style
            .TOPLEFT:TOPLEFT(0, -6)
            .BOTTOMRIGHT:TOPRIGHT(0, -19)
            :JustifyH 'MIDDLE'
    },
    ['.spellbar'] = Style
        .TOP:BOTTOM()
}


local StyleTargetFrameClassic = Style {
    ['.healthbar'] = Style:Alpha(0),
    ['.manabar'] = Style:Alpha(0),
}


Frame
    :EventHooks {
        PLAYER_ENTERING_WORLD = function()

            Style(TargetFrame)
                :Size(100, 100)
                :HitRectInsets(0, 0, 0, 0)
            {
                StyleTargetFrameRetail,
                StyleTargetFrameClassic,
                ['.textureFrame'] = Style {
                    ['.Texture'] = Style:Texture '',
                    ['.texture'] = Style:Texture 'Interface/TARGETINGFRAME/UI-TARGETINGFRAME-MINUS',
                    ['.*LevelText'] = Style.BOTTOM:BOTTOM(0, 10),
                    ['.TargetFrameTextureFrameName'] = Style.TOP:TOP()
                },
                ['.nameBackground'] = Style:Texture '',
                ['.Background'] = Style:Texture '',

                ['.portrait'] = Style
                    :DrawLayer 'ARTWORK'.CENTER:CENTER(),

                BgContainer = Frame
                    :FrameStrata 'BACKGROUND'
                    :FrameLevel(0)
                    :Size(92, 92)
                    :AllPoints(PARENT)
                {
                    BarCircularBgBlack = Texture
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

                HealthBarCircular = Cooldown
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

                PowerBarCircular = Cooldown
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


                BgOverlay = Frame
                    :AllPoints(TargetFrame)
                    :FrameStrata 'BACKGROUND'
                    :FrameLevel(3)
                {
                    BarCircularBg = Texture
                        .CENTER:CENTER()
                        -- :Texture('Interface/GUILDFRAME/GuildLogoMask_L')
                        :Texture 'Interface/Masks/CircleMaskScalable'
                        :Size(80, 80)
                        :SetDrawLayer('BORDER', 1)
                        :VertexColor(0, 0, 0, 0.4),

                    HealthBarCircularBgInner = Texture
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
                StyleTargetFrameClassic,
                ['.textureFrame'] = Style {
                    ['.*LevelText'] = Style.BOTTOM:BOTTOM(TargetFrame),
                    ['.*DeadText'] = Style.BOTTOM:BOTTOM(TargetFrame, 0, 18),
                    ['.texture'] = Style:Texture '':Alpha(0),
                },
                ['.TargetFrameContent.TargetFrameContentMain'] = Style {
                    ['.ManaBar'] = Style:Alpha(0),
                    ['.HealthBar'] = Style:Alpha(0),
                    ['.healthbar'] = Style:Alpha(0),
                    ['.spellbarAnchor'] = Style.TOP:BOTTOM(TargetFrame),
                    ['.TargetFrameDebuff#'] = Style:Alpha(0),
                    ['.TargetFrameBuff#'] = Style:Alpha(0),
                }
            }

        end,

        UNIT_THREAT_SITUATION_UPDATE = function(self, unit)
            StyleTargetFrameThreat(TargetFrame)
        end

    }
    .new()
