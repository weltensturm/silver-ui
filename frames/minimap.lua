
local
    Style,
    Frame,
    Cooldown,
    Texture,
    FontString,
    MaskTexture
    =
    LQT.Style,
    LQT.Frame,
    LQT.Cooldown,
    LQT.Texture,
    LQT.FontString,
    LQT.MaskTexture


local Hide = Style:Hide()


local alpha = 1
local alphaTarget = 0


local alphaHooks = {
    OnEnter = function() alphaTarget = 1 end,
    OnLeave = function() alphaTarget = 0 end
}


local MAP_INSET = 5


local StyleMinimapCluster = Style
    :Size(200, 200)
{
    Hide'.MinimapBorderTop',
    Hide'.MinimapBorder',
    Style'.BorderTop'
        :Points { TOP = MinimapCluster:TOP(0, -17) }
    {
        Hide'.Texture'
    },
    Style'.MinimapZoneTextButton'
        :Points {
            TOP = Minimap:TOP(0, -6-MAP_INSET)
        }
        :Width(100)
        :Hooks(alphaHooks),
    Style'.Tracking'
        :Points {
            CENTER = Minimap:LEFT(5, -5)
        },
    Style'.ZoneTextButton'
        :AllPoints(MinimapCluster.BorderTop)
    {
        Style'.FontString':JustifyH('MIDDLE')
    },
    Style'.TimeManagerClockButton'
        :Points { BOTTOM = Minimap:BOTTOM(0, 0) }
    {
        Hide'.Texture'
    },
    Style'.MiniMapTrackingButtonBorder':Texture '',
    Style'.MiniMapTrackingBackground':Texture '',
        
    Style'.Minimap'
        -- :Size(200, 200)
        -- :Points { TOPRIGHT = MinimapCluster:TOPRIGHT(-10, -20) }
        :Points { CENTER = MinimapCluster:CENTER() }
        :Size(175, 175)
        -- :MaskTexture 'Interface/GUILDFRAME/GuildLogoMask_L'
        -- :MaskTexture 'Interface/Masks/CircleMaskScalable'
        :MaskTexture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
        :Hooks {
            OnMouseWheel = function(self, delta)
                if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
                    self:SetZoom(math.max(self:GetZoom() + delta, 0))
                end
            end
        }
        :Hooks(alphaHooks)
    {
        function(self)
            if self.SetQuestBlobRingScalar then
                self:SetQuestBlobRingScalar(0.8)
            end
            if self.SetTaskBlobRingScalar then
                self:SetTaskBlobRingScalar(0.8)
            end
        end,

        Style'.Button':Hooks(alphaHooks),
        
        Style'.MinimapBackdrop'
            :SetAllPoints(Minimap)
        {
            Hide'.MinimapZoomIn',
            Hide'.MinimapZoomOut',
            Hide'.MinimapNorthTag',
            Hide'.MiniMapWorldMapButton',
            Hide'.MinimapCompassTexture',
            Style'.Button':Hooks(alphaHooks),
            Style'.*.Button':Hooks(alphaHooks),
        },

        Texture'.BgOuter'
            :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
            -- :Texture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
            :Points { TOPLEFT = Minimap:TOPLEFT(-19-MAP_INSET, 19+MAP_INSET),
                    BOTTOMRIGHT = Minimap:BOTTOMRIGHT(19+MAP_INSET, -19-MAP_INSET) }
            :DrawLayer 'BACKGROUND'
            :VertexColor(0, 0, 0, 1),

        Texture'.Bg'
            :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
            -- :Texture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
            :Points { TOPLEFT = Minimap:TOPLEFT(-18-MAP_INSET, 18+MAP_INSET),
                    BOTTOMRIGHT = Minimap:BOTTOMRIGHT(18+MAP_INSET, -18-MAP_INSET) }
            :DrawLayer 'BACKGROUND'
            :VertexColor(0.15, 0.1, 0.1, 0.8),
            
        Frame'.ShadowFrame':FrameStrata 'BACKGROUND' {
            Texture'.Shadow'
                :Points { TOPLEFT = MinimapCluster:TOPLEFT(20+MAP_INSET, -20-MAP_INSET),
                        BOTTOMRIGHT = MinimapCluster:BOTTOMRIGHT(-20-MAP_INSET, 20+MAP_INSET) }
                :Texture('Interface/Masks/CircleMaskScalable')
                :DrawLayer 'BACKGROUND'
                :VertexColor(0,0,0, 0.5)
        },

        Texture'.ZoneBackground'
            :Texture 'Interface/Common/ShadowOverlay-Top'
            :Points { TOPLEFT = Minimap:TOPLEFT(0, -3+MAP_INSET),
                    TOPRIGHT = Minimap:TOPRIGHT(0, -3+MAP_INSET) }
            :Height(30),

        Texture'.ClockBackground'
            :Texture 'Interface/Common/ShadowOverlay-Bottom'
            :Points { BOTTOMLEFT = Minimap:BOTTOMLEFT(0, 3-MAP_INSET),
                    BOTTOMRIGHT = Minimap:BOTTOMRIGHT(0, 3-MAP_INSET) }
            :Height(30),
        
        MaskTexture'.ZoneBackgroundMask'
            .init(function(self)
                Minimap.ZoneBackground:AddMaskTexture(self)
                Minimap.ClockBackground:AddMaskTexture(self)
            end)
            -- :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
            :Texture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
            :Points { TOPLEFT = Minimap:TOPLEFT(4+MAP_INSET, -4-MAP_INSET),
                    BOTTOMRIGHT = Minimap:BOTTOMRIGHT(-4-MAP_INSET, 4+MAP_INSET) },
    
        Cooldown'.XPBG'
            :UseCircularEdge(true)
            :Points { TOPLEFT = Minimap:TOPLEFT(-20.5-MAP_INSET, 20.5+MAP_INSET),
                    BOTTOMRIGHT = Minimap:BOTTOMRIGHT(20.5+MAP_INSET, -20.5-MAP_INSET) }
            :Cooldown(GetTime() - UnitXP('player')/UnitXPMax('player')*0.964, 1)
            :Rotation(math.rad(180*1.035))
            :SwipeTexture 'Interface/GUILDFRAME/GuildLogoMask_L'
            -- :SwipeTexture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
            -- :SwipeColor(0.2, 1, 0.5, 1)
            :SwipeColor(1, 1, 1, 1)
            :DrawEdge(false)
            :FrameStrata('BACKGROUND', 1)
            :HideCountdownNumbers(true)
            :Reverse(true)
            :Pause()
            :Events {
                PLAYER_XP_UPDATE = function(self)
                    self:SetCooldown(GetTime() - UnitXP('player')/UnitXPMax('player')*0.964, 1)
                end
            },

        Cooldown'.XPanim'
            .init { 
                progress = 0,
                target = UnitXP('player')/UnitXPMax('player'),
                start = GetTime()
            }
            :UseCircularEdge(true)
            :Points { TOPLEFT = Minimap:TOPLEFT(-20.5-MAP_INSET, 20.5+MAP_INSET),
                    BOTTOMRIGHT = Minimap:BOTTOMRIGHT(20.5+MAP_INSET, -20.5-MAP_INSET) }
            :Cooldown(GetTime(), 1)
            :Pause()
            :Rotation(math.rad(180*1.035))
            :SwipeTexture 'Interface/GUILDFRAME/GuildLogoMask_L'
            -- :SwipeTexture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
            :SwipeColor(0.3, 0.3, 0.3, 1)
            :DrawEdge(true)
            :FrameStrata('BACKGROUND', 2)
            :HideCountdownNumbers(true)
            :Reverse(true)
            :Events {
                PLAYER_XP_UPDATE = function(self)
                    self.target = UnitXP('player')/math.max(UnitXPMax('player'), 1)
                    print(target)
                    self.start = GetTime()
                    -- self:SetCooldown(GetTime() - UnitXP('player')/UnitXPMax('player')*0.965, 1)
                end,
                PLAYER_ENTERING_WORLD = function(self)
                    self.progress = -0.001
                    self:SetCooldownDuration(1)
                end
            }
            :Hooks {
                OnUpdate = function(self, dt)
                    if self.progress ~= self.target and GetTime() > self.start+3.14 then
                        self.progress = math.min(self.progress + dt/5, self.target)
                        self:SetCooldown(GetTime() - math.min(self.progress, 1)*0.965, 1)
                        self:Pause()
                    end
                end
            },

        Frame'.Level'
            :Points { CENTER = Minimap:BOTTOM(0, 0) }
            :Events {
                PLAYER_LEVEL_CHANGED = function(self, old, new)
                    self.Text:SetText(new)
                end
            }
        {
            FontString'.Text'
                :Font('FONTS/FRIZQT__.ttf', 10, '')
                :Points { CENTER = Minimap:BOTTOM(0, -3-MAP_INSET) }
                :Size(50, 50)
                .init(function(self)
                    self:SetText(UnitLevel('player'))
                end),
            Frame'.BgFrame':FrameStrata 'BACKGROUND' {
                Texture'.Bg'
                    -- :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
                    :Texture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
                    :Size(22, 22)
                    :Points { CENTER = Minimap:BOTTOM(0, 1-MAP_INSET) }
                    :VertexColor(0, 0, 0, 0.5)
            }
        }
    }

}



local libDbIcons = {}
local once = false

Frame
    :Hooks {
        OnUpdate = function(self, dt)
            if alpha ~= alphaTarget then
                
                local sign = alpha >= alphaTarget and -1 or 1
                alpha = math.min(1, math.max(0, alpha + sign * dt*5))

                MinimapBackdrop:SetAlpha(alpha^2)
                for _, v in ipairs(libDbIcons) do
                    v:SetAlpha(alpha^2)
                end
            end
        end
    }
    :EventHooks {
        PLAYER_ENTERING_WORLD = function()
            if once then return end
            once = true

            if LibStub then
                libDbIcons = {}
                for k, v in pairs(LibStub.libs) do
                    if k:find('^LibDBIcon-') then
                        for name, button in pairs(v.objects) do
                            Style(button)
                                :Hooks(alphaHooks)
                            table.insert(libDbIcons, button)
                        end
                    end
                end
            end
        
            Style(UIWidgetTopCenterContainerFrame)
                :Points { TOP = MinimapCluster:BOTTOM(0, -4) }

            if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
                MinimapCluster:SetPoints { TOPRIGHT = UIParent:TOPRIGHT(0, -15) }
            end

            StyleMinimapCluster(MinimapCluster)

        end
    }
    .new()

