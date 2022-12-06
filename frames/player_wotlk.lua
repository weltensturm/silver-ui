
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

local Style, Frame, Texture, AnimationGroup, Animation = LQT.Style, LQT.Frame, LQT.Texture, LQT.AnimationGroup, LQT.Animation


PlayerFrameTexture:SetTexture('')
PlayerPortrait:Hide()
PlayerStatusTexture:SetTexture('')


StanceBarFrame.ignoreFramePositionManager = true
StanceBarFrame:Hide()
StanceBarFrame:ClearAllPoints()
StanceBarFrame:SetPoint('TOP', UIParent, 'BOTTOM', 0, -10)


local EndCap = Texture
    :Texture 'Interface/MAINMENUBAR/UI-MainMenuBar-EndCap-Dwarf'
    :DrawLayer 'ARTWORK'
    :VertexColor(0.7, 0.7, 0.7)


local Separator = Texture
    :Texture 'Interface/MAINMENUBAR/UI-MainMenuBar-MaxLevel'
    :VertexColor(0.5, 0.5, 0.5)
    :TexCoord(0, 1, 0.82, 0.97)
    :Height(4)


local HideTexture = Style:Texture ''


Style(PlayerFrame)
    :Points { BOTTOM = UIParent:BOTTOM(0, 64) }
    :Size(300, 42)
    :FrameStrata 'MEDIUM'
    :HitRectInsets(0, 0, 0, 0)
    :UserPlaced(true)


local function update()

    -- StanceBarFrame:Hide()

    Style(MainMenuBarVehicleLeaveButton)
        :Points {
            BOTTOM = PlayerFrame:TOP()
        }

    Style(PlayerFrame) {
        HideTexture'.threatIndicator',
        HideTexture'.PlayerFrameBackground',
        
        Frame'.OverlayArt'
            :AllPoints(PlayerFrame)
            :FrameStrata 'HIGH'
        {
            Separator'.Top'
                :TexCoord(0, 1, 0.79, 0.92)
                :Height(4)
                -- Texture = 'Interface/BUTTONS/ScrollBarProportionalHorizontal',
                -- TexCoord = { 0, 1, 0, 0.205 },
                -- Points = {{ TOPLEFT = PlayerFrame:TOPLEFT(0, 2),
                --             TOPRIGHT = PlayerFrame:TOPRIGHT(0, 2) }},
                -- Height = 17
                .TOPLEFT:TOPLEFT(0, 2)
                .TOPRIGHT:TOPRIGHT(0, 2),

            Separator'.Middle'
                .LEFT:TOPLEFT(0, -15)
                .RIGHT:TOPRIGHT(0, -15),

            Separator'.Bottom'
                .LEFT:BOTTOMLEFT(0, 1)
                .RIGHT:BOTTOMRIGHT(0, 1),
            
            EndCap'.Left'
                .BOTTOMRIGHT:BOTTOMLEFT(30.5, -1),

            EndCap'.Right'
                :TexCoord(1, 0, 0, 1)
                .BOTTOMLEFT:BOTTOMRIGHT(-30.5, -1)
        },

        Style'.classPowerBar'
            .BOTTOM:TOP()
        {
            Style'.Background'
                :TexCoord(0, 1, 1, 0)
                .BOTTOM:BOTTOM(0, -6)
        },

        Style'.ComboPointPlayerFrame'
            .BOTTOM:TOP(0, 5)
            :FrameStrata 'BACKGROUND'
        {
            Style'.Background'
                :Desaturated(true)
                :TexCoord(0, 1, 1, 0)
                .BOTTOM:BOTTOM(0, -6)
        },

        Style'.MageArcaneChargesFrame'
            .BOTTOM:TOP(0, -10)
            :FrameStrata 'BACKGROUND'
        {
            Style'.Background'
                .BOTTOM:BOTTOM(0, 10)
        },

        Style'.RuneFrame'
            .BOTTOM:TOP(0, 2)
            :FrameStrata 'BACKGROUND',

        Style'.PlayerFrameAlternateManaBar'
            :StatusBarTexture 'Interface/Destiny/EndscreenBG'
            .BOTTOM:TOP(0, 2)
        {
            Style'.DefaultBorder'
                :TexCoord(0.125, 0.59375, 0, 1)
                :VertexColor(0.5, 0.5, 0.5)
                .BOTTOMLEFT:BOTTOMLEFT(5.1, 0)
                .BOTTOMRIGHT:BOTTOMRIGHT(-5.1, 0),
            
            Style'.DefaultBorderLeft'
                :TexCoord(0, 0.125, 0, 1)
                :VertexColor(0.5, 0.5, 0.5)
                .BOTTOMRIGHT:BOTTOMLEFT(5.1, 0),

            Style'.DefaultBorderRight'
                :TexCoord(0.59375, 0.71875, 0, 1)
                :VertexColor(0.5, 0.5, 0.5)
                .BOTTOMLEFT:BOTTOMRIGHT(-5.1, 0)
        },
        
        Style'.healthbar'
            -- :StatusBarTexture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
            -- :StatusBarTexture 'Interface/Destiny/EndscreenBG'
            -- :StatusBarTexture 'Interface/LoadScreens/LoadScreen-Gradient'
            -- :StatusBarTexture 'Interface/TARGETINGFRAME/BarFill2'
            -- :StatusBarTexture 'Interface/Artifact/_Artifacts-DependencyBar-Fill'
            -- :StatusBarTexture 'Interface/BUTTONS/GreyscaleRamp64'
            .TOPLEFT:TOPLEFT(0, -17)
            .BOTTOMRIGHT:BOTTOMRIGHT(0, 3)
            :FrameStrata 'LOW'
            :FrameLevel(2),

        Style'.PlayerFrameHealthBarAnimatedLoss'
            -- :StatusBarTexture 'Interface/LoadScreens/LoadScreen-Gradient'
            :FrameStrata('LOW')
            :FrameLevel(1),
        
        Style'.manabar'
            -- :SetStatusBarTexture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
            -- :SetStatusBarTexture 'Interface/AddOns/ElvUI/Media/Textures/Melli'
            -- :StatusBarTexture 'Interface/Destiny/EndscreenBG'
            .TOPLEFT:TOPLEFT(0, -1)
            .BOTTOMRIGHT:TOPRIGHT(0, -13)
            :FrameStrata 'LOW'
            :FrameLevel(2),

        Frame'.BarBackgrounds'
            :AllPoints(PlayerFrame)
            :FrameStrata 'LOW'
            :FrameLevel(0)
        {

            Texture'.HealthbarBg'
                :Texture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
                -- :Texture 'Interface/LoadScreens/LoadScreen-Gradient'
                :VertexColor(0.1, 0.1, 0.1)
                :AllPoints(PlayerFrame.healthbar)
                :DrawLayer 'BACKGROUND'
                :BlendMode 'DISABLE',

            Texture'.ManabarBg'
                --Texture = 'Interface/RAIDFRAME/UI-RaidFrame-GroupBg', true, true,
                --:Texture 'Interface/LoadScreens/LoadScreen-Gradient'
                :Texture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
                -- Texture = { 'Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment-Horizontal-Desaturated', true, true },
                :VertexColor(0.1, 0.1, 0.1)
                :AllPoints(PlayerFrame.manabar)
                :DrawLayer 'BACKGROUND'
                :BlendMode 'DISABLE',
        },

        Frame'.Gcd'
            .TOPLEFT:TOPLEFT(0, -1)
            .BOTTOMLEFT:TOPLEFT(0, -13)
            :Scripts {
                OnUpdate = function(self)
                    local gcdStart, gcdDuration = GetSpellCooldown(61304)
                    local gcdNow = gcdStart + gcdDuration - GetTime()
                    local endCast = select(5, UnitCastingInfo('player')) or select(5, UnitChannelInfo('player'))
                    if gcdNow > 0 and (not endCast or endCast/1000 < gcdStart + gcdDuration) then
                        local parent = self:GetParent()
                        self:SetWidth((1 - gcdNow/gcdDuration)*parent:GetWidth())
                    else
                        self:SetWidth(0)
                        self:Hide()
                    end
                end
            }
            :Events {
                UNIT_SPELLCAST_SENT = function(self, ...)
                    local gcdStart, gcdDuration = GetSpellCooldown(61304)
                    if gcdStart + gcdDuration > GetTime() then
                        local endCast = select(5, UnitCastingInfo('player')) or select(5, UnitChannelInfo('player'))
                        if not endCast or endCast/1000 < gcdStart + gcdDuration then
                            self:Show()
                        end
                    end
                end
            }
        {
            Texture'.GcdSpark'
                -- :Texture 'Interface/CastingBar/UI-CastingBar-Spark'
                :Texture 'Interface/UNITPOWERBARALT/Generic1Target_Horizontal_Spark'
                :Width(20)
                :BlendMode 'ADD'
                .TOP:TOPRIGHT(0, 5)
                .BOTTOM:BOTTOMRIGHT(0, -5)
        }
    }

    local PlayerInfo = PlayerName:GetParent()
    PlayerInfo:SetFrameStrata('HIGH', 1)

    PlayerPrestigePortrait:SetPoints { RIGHT = PlayerInfo:LEFT() }
    PlayerPVPIcon:SetPoints { RIGHT = PlayerInfo:LEFT() }

    PlayerFrameGroupIndicator:SetPoints {
        BOTTOMRIGHT = PlayerFrame:TOPRIGHT()
    }
    if PlayerFrameRoleIcon then
        PlayerFrameRoleIcon:SetPoints { BOTTOMLEFT = PlayerFrame:TOPLEFT(50, -3) }
    end
    PlayerLeaderIcon:SetPoints { BOTTOMLEFT = PlayerFrame:TOPLEFT(30, -3) }

    PlayerHitIndicator:SetPoints { CENTER=PlayerFrame.healthbar:CENTER() }
    
    -- PlayerFrame.OverlayArt:SetFrameStrata 'HIGH'

    Style(PlayerStatusGlow)
        :FrameStrata('HIGH', 1)
        :Points { RIGHT = PlayerInfo:TOPLEFT(-17, 7) }

    PlayerRestIcon:SetPoints { CENTER = PlayerStatusGlow:CENTER(0, 2) }

    PlayerLevelText:Hide()
    PlayerName:Hide()

    -- Style(PaladinPowerBarFrame) {
    --     AnimationGroup'.flip'
    --     {
    --         Animation.Rotation'.flip'
    --             :Origin('CENTER', 0, 0)
    --             :Degrees(180)
    --             :Duration(1)
    --     }
    --         :Play(true)
    --         :Pause()
    -- }

    local _, sparkTo, _, _, _ = CastingBarFrame.Spark:GetPoint()

    Style(CastingBarFrame)
        :Points {
            TOPLEFT = PlayerFrame.manabar:TOPLEFT(),
            BOTTOMRIGHT = PlayerFrame.manabar:BOTTOMRIGHT(0, -5)
        }
    {
        Style'.Text':Points { CENTER = CastingBarFrame:CENTER(0, -6) },
        Style'.Border':Hide(),
    }

    CastingBarFrame.ignoreFramePositionManager = true
    for tex in CastingBarFrame'.Texture' do
        if tex ~= CastingBarFrame.Spark and tex ~= CastingBarFrame.Spark2 then
            tex:SetTexture('')
        end
        if tex:GetNumPoints() == 4 then -- channel bar
            Style(CastingBarFrame){
                Texture('.Spark2')
                    :SetTexture 'Interface/CastingBar/UI-CastingBar-Spark'
                    :Points { CENTER = tex:RIGHT() }
                    :BlendMode 'ADD'
            }
        end
    end

    PetFrame:SetPoints { BOTTOM = PlayerFrame:TOP(0, 5) }

    Style(PlayerFrameVehicleTexture)
        :Hide()

    Style(OverrideActionBar)
    {
        Style'.Texture':Hide(),
        Style'.xpBar':Hide():Alpha(0)
    }

    -- PlayerFrameHealthBar:SetStatusBarTexture('Interface/CHARACTERFRAME/BarFill')
end

hooksecurefunc('TotemFrame_Update', function()
    Style(TotemFrame)
        .BOTTOM:TOP(PlayerFrame, 0, 8)
end)

hooksecurefunc('PlayerFrame_ToVehicleArt', update)
hooksecurefunc('PlayerFrame_ToPlayerArt', update)
hooksecurefunc('PlayerFrame_UpdateArt', update)
hooksecurefunc('PlayerFrame_AnimateOut', update)


Frame
    -- :RegisterEvent('PLAYER_ENTERING_WORLD')
--  :RegisterEvent('UPDATE_VEHICLE_ACTIONBAR')
    -- :RegisterEvent 'UNIT_ENTERED_VEHICLE'
    -- :RegisterEvent('UNIT_EXITED_VEHICLE')
    :RegisterEvent('UNIT_DISPLAYPOWER')
--  :RegisterEvent('UPDATE_ALL_UI_WIDGETS')
    :Hooks {
        OnEvent = function(e)
            if e == 'UNIT_DISPLAYPOWER' then

                Style(PlayerFrame){
                    Style'.ComboPointPlayerFrame'
                        .BOTTOM:TOP(PlayerFrame, 0, 5)
                        :FrameStrata 'BACKGROUND'
                    {
                        Style'.Background'
                            :Desaturated(true)
                            :TexCoord(0, 1, 1, 0)
                            .BOTTOM:BOTTOM(ComboPointPlayerFrame, 0, -6)
                    }
                }

            else

                -- update()

            end
        end
    }
    .new()

