local _, ns = ...
local lqt = ns.lqt

local Style, Frame, Texture = lqt.Style, lqt.Frame, lqt.Texture

-- 3x [ADDON_ACTION_BLOCKED] AddOn 'custom-gossip' tried to call the protected function 'Boss1TargetFrame:SetPoint()'.
--     [string "@!BugGrabber\BugGrabber.lua"]:519: in function <!BugGrabber\BugGrabber.lua:519>
--     [string "=[C]"]: in function `SetPoint'
--     [string "@FrameXML\UIParent.lua"]:3425: in function `UIParentManageFramePositions'
--     [string "@FrameXML\UIParent.lua"]:2680: in function <FrameXML\UIParent.lua:2667>
--     [string "=[C]"]: in function `SetAttribute'
--     [string "@FrameXML\UIParent.lua"]:3476: in function `UIParent_ManageFramePositions'
--     [string "@FrameXML\MainMenuBar.lua"]:60: in function `SetPositionForStatusBars'
--     [string "@FrameXML\MainMenuBar.lua"]:109: in function <FrameXML\MainMenuBar.lua:65>
    
--     Locals:
--     Skipped (In Encounter)

PlayerFrameTexture:SetTexture('')
PlayerPortrait:Hide()
PlayerStatusTexture:SetTexture('')


StanceBarFrame.ignoreFramePositionManager = true
StanceBarFrame:Hide()
StanceBarFrame:ClearAllPoints()
StanceBarFrame:SetPoint('BOTTOM', UIParent, 'TOP')


PlayerFrame_ToVehicleArt = function() end
PlayerFrame_ToPlayerArt = function() end
PlayerFrame_UpdateArt = function() end
PlayerFrame_AnimateOut = function() end


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
    :Points { BOTTOM = ActionBarMiddle:TOP(0, 1.5) }
    :Size(300, 42)
    :FrameStrata 'MEDIUM'
    :HitRectInsets(0, 0, 0, 0)
    :UserPlaced(true)


local function update()

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
                :TOPLEFT(PlayerFrame:TOPLEFT(0, 2))
                :TOPRIGHT(PlayerFrame:TOPRIGHT(0, 2)),

            Separator'.Middle'
                :LEFT(PlayerFrame:TOPLEFT(0, -15))
                :RIGHT(PlayerFrame:TOPRIGHT(0, -15)),

            Separator'.Bottom'
                :LEFT(PlayerFrame:BOTTOMLEFT(0, 1))
                :RIGHT(PlayerFrame:BOTTOMRIGHT(0, 1)),
            
            EndCap'.Left'
                :BOTTOMRIGHT(PlayerFrame:BOTTOMLEFT(30, -1)),

            EndCap'.Right'
                :TexCoord(1, 0, 0, 1)
                :BOTTOMLEFT(PlayerFrame:BOTTOMRIGHT(-30, -1))
        },

        Style'.classPowerBar'
            :Points { BOTTOM = PlayerFrame:TOP() }
        {
            Style'.Background'
                :TexCoord(0, 1, 1, 0)
                :Points { BOTTOM = PlayerFrame.classPowerBar and PlayerFrame.classPowerBar:BOTTOM(0, -6) }
        },

        Style'.ComboPointPlayerFrame'
            :Points { BOTTOM = PlayerFrame:TOP(0, 5) }
            :FrameStrata 'BACKGROUND'
        {
            Style'.Background'
                :Desaturated(true)
                :TexCoord(0, 1, 1, 0)
                :Points { BOTTOM = ComboPointPlayerFrame:BOTTOM(0, -6) }
        },

        Style'.PlayerFrameAlternateManaBar'
            :StatusBarTexture 'Interface/Destiny/EndscreenBG'
            :Points { BOTTOM = PlayerFrame:TOP(0, 2) }
        {
            Style'.DefaultBorder'
                :TexCoord(0.125, 0.59375, 0, 1)
                :VertexColor(0.5, 0.5, 0.5)
                :Points { BOTTOMLEFT = PlayerFrameAlternateManaBar:BOTTOMLEFT(5.1, 0),
                            BOTTOMRIGHT = PlayerFrameAlternateManaBar:BOTTOMRIGHT(-5.1, 0) },
            
            Style'.DefaultBorderLeft'
                :TexCoord(0, 0.125, 0, 1)
                :VertexColor(0.5, 0.5, 0.5)
                :Points { BOTTOMRIGHT = PlayerFrameAlternateManaBar:BOTTOMLEFT(5.1, 0) },

            Style'.DefaultBorderRight'
                :TexCoord(0.59375, 0.71875, 0, 1)
                :VertexColor(0.5, 0.5, 0.5)
                :Points { BOTTOMLEFT = PlayerFrameAlternateManaBar:BOTTOMRIGHT(-5.1, 0) }
        },
        
        Style'.healthbar'
            -- :StatusBarTexture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
            -- :StatusBarTexture 'Interface/Destiny/EndscreenBG'
            -- :StatusBarTexture 'Interface/LoadScreens/LoadScreen-Gradient'
            -- :StatusBarTexture 'Interface/TARGETINGFRAME/BarFill2'
            -- :StatusBarTexture 'Interface/Artifact/_Artifacts-DependencyBar-Fill'
            -- :StatusBarTexture 'Interface/BUTTONS/GreyscaleRamp64'
            :Points { TOPLEFT = PlayerFrame:TOPLEFT(0, -17),
                    BOTTOMRIGHT = PlayerFrame:BOTTOMRIGHT(0, 3) }
            :FrameStrata 'LOW'
        {
            Texture'.Bg'
                :Texture 'Interface/LoadScreens/LoadScreen-Gradient'
                :VertexColor(0.1, 0.1, 0.1)
                :AllPoints(PlayerFrame.healthbar)
                :DrawLayer 'BACKGROUND'
                :BlendMode 'DISABLE',

            Style'.AnimatedLossBar'
                :StatusBarTexture 'Interface/LoadScreens/LoadScreen-Gradient'
                :FrameStrata('LOW', -1)
        },

        Style'.PlayerFrameHealthBarAnimatedLoss':FrameStrata('LOW', -1),
        
        Style'.manabar'
            -- :SetStatusBarTexture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
            -- :SetStatusBarTexture 'Interface/AddOns/ElvUI/Media/Textures/Melli'
            :Points { TOPLEFT = PlayerFrame:TOPLEFT(0, 0),
                      BOTTOMRIGHT = PlayerFrame:TOPRIGHT(0, -15) }
            :FrameStrata 'LOW'
        {
            Texture'.Bg'
                --Texture = 'Interface/RAIDFRAME/UI-RaidFrame-GroupBg', true, true,
                :Texture 'Interface/LoadScreens/LoadScreen-Gradient'
                -- Texture = { 'Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment-Horizontal-Desaturated', true, true },
                :VertexColor(0.1, 0.1, 0.1)
                :AllPoints(PlayerFrame.manabar)
                :DrawLayer 'BACKGROUND'
                :BlendMode 'DISABLE',
                -- :VertTile(true)
                -- :HorizTile(true) 
        },

    }

    local PlayerInfo = PlayerName:GetParent()
    PlayerInfo:SetFrameStrata('HIGH', 1)

    PlayerPrestigePortrait:Points { RIGHT = PlayerInfo:LEFT() }

    PlayerFrameGroupIndicator:Points {
        BOTTOMLEFT = PlayerFrame:TOPLEFT()
    }
    PlayerFrameRoleIcon:Hide()

    PlayerHitIndicator:Points { CENTER=PlayerFrame.healthbar:CENTER() }
    
    -- PlayerFrame.OverlayArt:SetFrameStrata 'HIGH'

    Style(PlayerStatusGlow)
        :FrameStrata('HIGH', 1)
        :Points { RIGHT = PlayerInfo:TOPLEFT(-17, 7) }

    PlayerRestIcon:Points { CENTER = PlayerStatusGlow:CENTER(0, 2) }

    PlayerLevelText:Hide()
    PlayerName:Hide()

    Style(CastingBarFrame)
        :Points {
            TOPLEFT = PlayerFrame.manabar:TOPLEFT(),
            BOTTOMRIGHT = PlayerFrame.manabar:BOTTOMRIGHT(0, -5)
        }
    {
        Style'.Text':Points { CENTER = CastingBarFrame:CENTER(0, 3) },
        Style'.Border':Hide()
    }

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


addon:RegisterEvent('PLAYER_ENTERING_WORLD')
addon:RegisterEvent('UPDATE_VEHICLE_ACTIONBAR')
addon:RegisterEvent('UNIT_EXITED_VEHICLE')
addon:RegisterEvent('UNIT_DISPLAYPOWER')
-- addon:RegisterEvent('UPDATE_ALL_UI_WIDGETS')

addon:Hook {
    OnEvent = function(e)
        if e == 'UNIT_DISPLAYPOWER' then

            PlayerFrame'.ComboPointPlayerFrame' {
                Points = {{ BOTTOM = PlayerFrame:TOP(0, 5) }},
                FrameStrata = 'BACKGROUND',
                ['.Background'] = {
                    Desaturated = true,
                    TexCoord = { 0, 1, 1, 0 },
                    Points = {{ BOTTOM = ComboPointPlayerFrame:BOTTOM(0, -6) }}
                },
            }

        else

            update()

        end
    end
}

UPDATE_PLAYER_FRAME = update


-- 3x [ADDON_ACTION_BLOCKED] AddOn 'custom-gossip' tried to call the protected function 'PlayerFrame:ClearAllPoints()'.
--     [string "@!BugGrabber\BugGrabber.lua"]:519: in function <!BugGrabber\BugGrabber.lua:519>
--     [string "=[C]"]: in function `ClearAllPoints'
--     [string "@custom-gossip\uiext.lua"]:85: in function `direct'
--     [string "@custom-gossip\lqt_style.lua"]:43: in function `?'
--     [string "@custom-gossip\lqt_style.lua"]:59: in function <custom-gossip\lqt_style.lua:58>
--     [string "@custom-gossip\lqt_style.lua"]:92: in function `Points'
--     [string "@custom-gossip\frames/player.lua"]:43: in function <custom-gossip\frames/player.lua:34>
--     [string "@custom-gossip\frames/player.lua"]:242: in function <custom-gossip\frames/player.lua:227>
--     [string "@custom-gossip\uiext.lua"]:158: in function <custom-gossip\uiext.lua:157>