
PlayerFrameTexture:SetTexture('')
PlayerPortrait:Hide()
PlayerStatusTexture:SetTexture('')


local function update()

    local topright = 
        MultiBarBottomRight:IsVisible() and MultiBarBottomRight or
        (MultiBarBottomLeft:IsVisible() and MultiBarBottomLeft or
        MainMenuBar)

    local topleft = 
        (MultiBarBottomLeft:IsVisible() and MultiBarBottomLeft or
        MainMenuBar)

    PlayerFrame {
        UserPlaced = true,
        Points = {{ BOTTOMLEFT = MainMenuBar:TOPLEFT(8, 0),
                    BOTTOMRIGHT = MainMenuBar:TOPRIGHT(-8, 0) }},
        FrameStrata = 'HIGH',
        Height = 18,
        HitRectInsets = { 0, 0, 0, 0 },

        ['.threatIndicator'] = {
            Texture = ''
        },

        ['.PlayerFrameBackground'] = {
            Texture = ''
        },
        
        ['.classPowerBar'] = PlayerFrame.classPowerBar and {
            Points = {{ BOTTOM = PlayerFrame:BOTTOM() }},
            ['.Background'] = {
                TexCoord = { 0, 1, 1, 0 },
                Points = {{ BOTTOM = PlayerFrame.classPowerBar:BOTTOM(0, -6) }}
            },
        } or {},

        ['.ComboPointPlayerFrame'] = {
            Points = {{ BOTTOM = PlayerFrame:BOTTOM(0, 2) }},
            ['.Background'] = {
                TexCoord = { 0, 1, 1, 0 },
                Points = {{ BOTTOM = ComboPointPlayerFrame:BOTTOM(0, -6) }}
            },
        },

        ['.PlayerFrameAlternateManaBar'] = {
            StatusBarTexture = 'Interface/Destiny/EndscreenBG',
            Points = {{ BOTTOM = PlayerFrame:BOTTOM(0, -2) }},
            ['.DefaultBorder'] = {
                TexCoord = { 0.125, 0.59375, 0, 1 },
                Points = {{ BOTTOMLEFT = PlayerFrameAlternateManaBar:BOTTOMLEFT(5.1, 0),
                            BOTTOMRIGHT = PlayerFrameAlternateManaBar:BOTTOMRIGHT(-5.1, 0) }}
            },
            ['.DefaultBorderLeft'] = {
                TexCoord = { 0, 0.125, 0, 1 },
                Points = {{ BOTTOMRIGHT = PlayerFrameAlternateManaBar:BOTTOMLEFT(5.1, 0) }}
            },
            ['.DefaultBorderRight'] = {
                TexCoord = { 0.59375, 0.71875, 0, 1 },
                Points = {{ BOTTOMLEFT = PlayerFrameAlternateManaBar:BOTTOMRIGHT(-5.1, 0) }}
            }
        },
        
        ['.healthbar'] = {
            -- StatusBarTexture = 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill',
            -- StatusBarTexture = 'Interface/AddOns/ElvUI/Media/Textures/Melli',
            -- StatusBarTexture = 'Interface/Destiny/EndscreenBG',
            StatusBarTexture = 'Interface/LoadScreens/LoadScreen-Gradient',
            Points = {{ TOPLEFT = PlayerFrame:TOPLEFT(8, 0),
                        RIGHT = PlayerFrame:CENTER(-100, 0),
                        BOTTOM = PlayerFrame:BOTTOM() }},

            ['.Bg=Texture'] = {
                --Texture = 'Interface/RAIDFRAME/UI-RaidFrame-GroupBg', true, true,
                Texture = 'Interface/LoadScreens/LoadScreen-Gradient',
                -- Texture = { 'Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment-Horizontal-Desaturated', true, true },
                VertexColor = { 0.1, 0.1, 0.1 },
                AllPoints = PlayerFrame.healthbar,
                DrawLayer = 'BACKGROUND',
                BlendMode = 'DISABLE',
                -- VertTile = true,
                -- HorizTile = true,
            },

            ['.BorderLeft=Texture'] = {
                Texture = 'Interface/AddOns/custom-gossip/bar-border-left',
                DrawLayer = 'OVERLAY',
                Size = { 38.65, 38.65 },
                Points = {{ BOTTOMLEFT = PlayerFrame.healthbar:BOTTOMLEFT(-20.5, -2) }}
            },

            ['.BorderMiddle=Texture'] = {
                Texture = { 'Interface/AddOns/custom-gossip/bar-border-middle', true, false },
                TexCoord = { 0, 5, 0, 1 },
                DrawLayer = { 'OVERLAY', -1 },
                Size = { 38.65, 38.65 },
                Points = {{ BOTTOMLEFT = PlayerFrame.healthbar:BOTTOMLEFT(2, -2),
                            BOTTOMRIGHT = PlayerFrame.healthbar:BOTTOMRIGHT(-2, -2) }}
            },

            ['.BorderRight=Texture'] = {
                Texture = 'Interface/AddOns/custom-gossip/bar-border-right',
                DrawLayer = 'OVERLAY',
                Size = { 38.65, 38.65 },
                Points = {{ BOTTOMRIGHT = PlayerFrame.healthbar:BOTTOMRIGHT(20.5, -2) }}
            },

            ['.AnimatedLossBar'] = {
                StatusBarTexture = 'Interface/LoadScreens/LoadScreen-Gradient'
            },
        
        },

        
        ['.manabar'] = {
            -- :SetStatusBarTexture('Interface/RAIDFRAME/Raid-Bar-Hp-Fill')
            -- :SetStatusBarTexture('Interface/AddOns/ElvUI/Media/Textures/Melli')
            Points = {{ TOPRIGHT = PlayerFrame:TOPRIGHT(-8, 0),
                        LEFT = PlayerFrame:CENTER(100, 0),
                        BOTTOM = PlayerFrame:BOTTOM() }},

            ['.Bg=Texture'] = {
                --Texture = 'Interface/RAIDFRAME/UI-RaidFrame-GroupBg', true, true,
                Texture = 'Interface/LoadScreens/LoadScreen-Gradient',
                -- Texture = { 'Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment-Horizontal-Desaturated', true, true },
                VertexColor = { 0.1, 0.1, 0.1 },
                AllPoints = PlayerFrame.healthbar,
                DrawLayer = 'BACKGROUND',
                BlendMode = 'DISABLE',
                -- VertTile = true,
                -- HorizTile = true,
            },

            ['.BorderLeft=Texture'] = {
                Texture = 'Interface/AddOns/custom-gossip/bar-border-left',
                DrawLayer = 'OVERLAY',
                Size = { 38.65, 38.65 },
                Points = {{ BOTTOMLEFT = PlayerFrame.manabar:BOTTOMLEFT(-20.5, -2) }}
            },

            ['.BorderMiddle=Texture'] = {
                Texture = { 'Interface/AddOns/custom-gossip/bar-border-middle', true, false },
                TexCoord = { 0, 5, 0, 1 },
                DrawLayer = { 'OVERLAY', -1 },
                Size = { 38.65, 38.65 },
                Points = {{ BOTTOMLEFT = PlayerFrame.manabar:BOTTOMLEFT(2, -2),
                            BOTTOMRIGHT = PlayerFrame.manabar:BOTTOMRIGHT(-2, -2) }},
            },

            ['.BorderRight=Texture'] = {
                Texture = 'Interface/AddOns/custom-gossip/bar-border-right',
                DrawLayer = 'OVERLAY',
                Size = { 38.65, 38.65 },
                Points = {{ BOTTOMRIGHT = PlayerFrame.manabar:BOTTOMRIGHT(20.5, -2) }}
            }
        },


    }

    -- PlayerFrameManaCostPredictionBar:SetDrawLayer('BACKGROUND')


    -- MainMenuBar'.ArtLeft=Texture' {
    --     Texture = 'Interface/AddOns/custom-gossip/actionbar-art-left',
    --     Point = { 'TOPRIGHT', MainMenuBar, 'TOPLEFT', 0, 33.1 },
    --     Size = { 90, 90 },
    --     DrawLayer = 'OVERLAY'
    -- }

    -- local artleft = MainMenuBar.ArtLeft

    -- MainMenuBar'.ArtLeftBottom=Texture' {
    --     ColorTexture = { 0.376, 0.376, 0.376 },
    --     Size = { 65.75, 45 },
    --     Point = { 'TOPRIGHT', artleft, 'BOTTOMRIGHT' }
    -- }

    -- MainMenuBar'.PlayerPortrait=Texture' {
    --     Point = { 'RIGHT', artleft, 'RIGHT', 18, -10 },
    --     Size = { 85, 85 }
    -- }

    -- MainMenuBar'.portraitWatcher=Frame':Event {
    --     UNIT_PORTRAIT_UPDATE = function(self, unit)
    --         if unit == 'player' then
    --             SetPortraitTexture(MainMenuBar.PlayerPortrait, unit)
    --         end
    --     end
    -- }

    -- if not PlayerFrame.PortraitMask then
    --     local portraitmask = PlayerFrame:CreateMaskTexture()
    --     portraitmask:SetAllPoints(artleft)
    --     portraitmask:SetTexture('Interface/AddOns/custom-gossip/actionbar-art-left-portraitmask')
    --     MainMenuBar.PlayerPortrait:AddMaskTexture(portraitmask)
    --     PlayerFrame.PortraitMask = portraitmask
    -- end

    -- PlayerRestIcon:Points { BOTTOM = PlayerLevelText:TOP(-5, 5) }

    -- PlayerLevelText:Points { TOPRIGHT = artleft:TOPRIGHT(-4, -25) }

    -- PlayerStatusGlow:Points { CENTER = PlayerRestIcon:CENTER(0, -2) }

    -- PlayerName:SetWidth(63)
    -- PlayerName:Points { BOTTOMRIGHT = artleft:BOTTOMRIGHT(0, 5) }

    -- PlayerPrestigeBadge:Points { CENTER = artleft:CENTER(-25, -20) }
    -- PlayerPrestigePortrait:Points { CENTER = artleft:CENTER(-25, -20) }
    -- PlayerPVPIcon:Points { CENTER = artleft:CENTER(-25, -20) }

    PlayerFrame.healthbar'.LeftText'
        :Points { LEFT = PlayerFrame.healthbar:LEFT() }
    PlayerFrame.healthbar'.RightText'
        :Points { RIGHT = PlayerFrame.healthbar:RIGHT() }

    CastingBarFrame {
        Points = {{
            TOPLEFT = PlayerFrame.manabar:TOPLEFT(),
            BOTTOMRIGHT = PlayerFrame.manabar:BOTTOMRIGHT(0, -5)
        }},
        ['.Text'] = {
            Points = {{ BOTTOM = CastingBarFrame:TOP() }}
        }
    }

    CastingBarFrame.Border:Hide()
    CastingBarFrame.ignoreFramePositionManager = true
    for tex in CastingBarFrame'.Texture' do
        if tex ~= CastingBarFrame.Spark then
            tex:SetTexture('')
        end
    end


    -- PlayerFrameManaBar:SetFrameStrata('MEDIUM')

    -- ComboPointPlayerFrame.SetPoint = function(...) assert(false, tostring(...)) end
    -- ComboPointPlayerFrame:ClearAllPoints()
    -- ComboPointPlayerFrame:SetPoint('TOPRIGHT', PlayerFrame, 'BOTTOMRIGHT')

    -- PlayerFrameHealthBar:SetStatusBarTexture('Interface/CHARACTERFRAME/BarFill')
end

local addon = CreateFrame('Frame')

addon:Event {
    UNIT_DISPLAYPOWER = update,
    PLAYER_ENTERING_WORLD = update
}


MultiBarBottomRight:Hook {
    OnShow = update,
    OnHide = update
}



MultiBarBottomLeft:Hook {
    OnShow = update,
    OnHide = update
}

