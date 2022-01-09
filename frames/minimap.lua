local _, ns = ...

local lqt = ns.lqt

local
    Style,
    Frame,
    Cooldown,
    Texture,
    FontString,
    MaskTexture
    =
    lqt.Style,
    lqt.Frame,
    lqt.Cooldown,
    lqt.Texture,
    lqt.FontString,
    lqt.MaskTexture


-- MultiActionBar_Update = function() end


-- MinimapCluster {
--     Points = {{ BOTTOMLEFT = UIParent:BOTTOMLEFT() }}
-- }





-- local mapid = C_Map.GetBestMapForUnit('player')
-- local layers = C_Map.GetMapArtLayers(mapid)

-- print_table(layers[1])

-- local textures = C_Map.GetMapArtLayerTextures(mapid, 1)

-- print_table(textures)

-- MinimapBorder:SetTexture(textures[3], nil, nil, 'TRILINEAR')

local addon = CreateFrame('Frame')


local Hide = Style:Hide()


addon:Hook {
    OnUpdate = function()
        if MinimapBackdrop.TargetAlpha then
            MinimapBackdrop:SetAlpha(MinimapBackdrop.TargetAlpha)
        end
    end
}


local backdropHooks = {
    OnEnter = function() MinimapBackdrop.TargetAlpha = 1 end,
    OnLeave = function() MinimapBackdrop.TargetAlpha = 0 end
}


addon:Event {
    PLAYER_ENTERING_WORLD = function()

        Style(MinimapCluster)
            :TOPRIGHT(UIParent:TOPRIGHT(-20, 0))
            :Size(200, 200)
        {
            Hide'.MinimapBorderTop'
        }

        MinimapBorder:Hide()
        
        MinimapZoneTextButton:SetPoints {
            TOP = Minimap:TOP(0, -33)
        }
        MinimapZoneTextButton:SetWidth(100)

        TimeManagerClockButton:SetPoints {
            BOTTOM = Minimap:BOTTOM(0, 20)
        }
        TimeManagerClockButton'.Texture':Hide()

        MiniMapTrackingButtonBorder:SetTexture('')
        MiniMapTrackingBackground:SetTexture('')
        
        MinimapCluster:SetSize(250, 250)

        Style(Minimap)
            :Size(250, 250)
            :Points { TOPRIGHT = MinimapCluster:TOPRIGHT(-10, -20) }
            :MaskTexture 'Interface/GUILDFRAME/GuildLogoMask_L'
            :QuestBlobRingScalar(0.8)
            :TaskBlobRingScalar(0.8)
            :Hook {
                OnMouseWheel = function(self, delta)
                    self:SetZoom(math.max(self:GetZoom() + delta, 0))
                end
            }
        {

            Style'.MinimapBackdrop'
                :SetAllPoints(Minimap)
                :Hook(backdropHooks)
            {
                Hide'.MinimapZoomIn',
                Hide'.MinimapZoomOut',
                Hide'.MinimapNorthTag',
                Hide'.MiniMapWorldMapButton',
                Style'.Button':Hook(backdropHooks),
                Style'.*.Button':Hook(backdropHooks),
            },

            Texture'.Bg'
                :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
                :TOPLEFT(Minimap:TOPLEFT(-2, 2))
                :BOTTOMRIGHT(Minimap:BOTTOMRIGHT(2, -2))
                :DrawLayer 'BACKGROUND'
                :VertexColor(0.0, 0.0, 0.0),

            Frame'.ShadowFrame':FrameStrata 'BACKGROUND' {
                Texture'.Shadow'
                    :TOPLEFT(Minimap:TOPLEFT(-2, 2))
                    :BOTTOMRIGHT(Minimap:BOTTOMRIGHT(2, -2))
                    :Texture('Interface/Masks/CircleMaskScalable')
                    :DrawLayer 'BACKGROUND'
                    :VertexColor(0,0,0, 0.5)
            },

            -- MaskTexture'.BackgroundCutout'
            --     .init(function(self)
            --         Minimap.Bg:AddMaskTexture(self)
            --         Minimap.ShadowFrame.Shadow:AddMaskTexture(self)
            --     end)
            --     :Texture 'Interface/Map/MapFogOfWarMaskHardEdge'
            --     :Points { TOPLEFT = Minimap:TOPLEFT(-90, 90),
            --               BOTTOMRIGHT = Minimap:BOTTOMRIGHT(90, -90) },

            Texture'.ZoneBackground'
                :Texture 'Interface/Common/ShadowOverlay-Top'
                :Points { TOPLEFT = Minimap:TOPLEFT(0, -20),
                          TOPRIGHT = Minimap:TOPRIGHT(0, -20) }
                :Height(50),

            Texture'.ClockBackground'
                :Texture 'Interface/Common/ShadowOverlay-Bottom'
                :Points { BOTTOMLEFT = Minimap:BOTTOMLEFT(0, 20),
                          BOTTOMRIGHT = Minimap:BOTTOMRIGHT(0, 20) }
                :Height(50),
            
            MaskTexture'.ZoneBackgroundMask'
                .init(function(self)
                    Minimap.ZoneBackground:AddMaskTexture(self)
                    Minimap.ClockBackground:AddMaskTexture(self)
                end)
                :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
                :Points { TOPLEFT = Minimap:TOPLEFT(-2, 2),
                          BOTTOMRIGHT = Minimap:BOTTOMRIGHT(2, -2) },
        
            Cooldown'.XPBG'
                :UseCircularEdge(true)
                :Points { TOPLEFT = Minimap:TOPLEFT(-4, 4),
                          BOTTOMRIGHT = Minimap:BOTTOMRIGHT(4, -4) }
                :Cooldown(GetTime() - UnitXP('player')*0.965, UnitXPMax('player'))
                :Rotation(math.rad(180*1.035))
                :SwipeTexture 'Interface/GUILDFRAME/GuildLogoMask_L'
                -- :SwipeColor(0.2, 1, 0.5, 1)
                :SwipeColor(0.5, 0.5, 0.5, 1)
                :DrawEdge(false)
                :FrameStrata('BACKGROUND', 1)
                :HideCountdownNumbers(true)
                :Reverse(true)
                :Pause(),

            Frame'.Level'
                :Points { CENTER = Minimap:BOTTOM(0, 0) }
                :Event {
                    PLAYER_LEVEL_CHANGED = function(self, old, new)
                        self.Text:SetText(new)
                    end
                }
            {
                FontString'.Text'
                    :Font('FONTS/FRIZQT__.ttf', 10)
                    :CENTER(Minimap:BOTTOM(0, 20))
                    :Size(50, 50)
                    .init(function(self)
                        self:SetText(UnitLevel('player'))
                    end),
                Frame'.BgFrame':FrameStrata 'BACKGROUND' {
                    Texture'.Bg'
                        :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
                        :Size(30, 30)
                        :Points { CENTER = Minimap:BOTTOM(0, 23) }
                        :VertexColor(0, 0, 0, 0.5)
                }
            }
        }

    end,

	PLAYER_XP_UPDATE = function()
        Minimap.XPBG:SetCooldown(GetTime() - UnitXP('player'), UnitXPMax('player'))
    end
}

