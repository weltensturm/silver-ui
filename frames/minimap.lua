
local
    Style,
    Frame,
    Cooldown,
    CheckButton,
    Texture,
    FontString,
    MaskTexture
    =
    LQT.Style,
    LQT.Frame,
    LQT.Cooldown,
    LQT.CheckButton,
    LQT.Texture,
    LQT.FontString,
    LQT.MaskTexture


local db
local load


SilverUI.Storage {
    name = 'Minimap',
    character = {
        enabled = true
    },
    onload = function(account, character)
        db = character
        if character.enabled then
            load()
        end
    end
}


SilverUI.Settings 'Minimap' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Minimap',

    CheckButton
        :Size(24, 24)
        :NormalTexture 'Interface/Buttons/UI-CheckBox-Up'
        :PushedTexture 'Interface/Buttons/UI-CheckBox-Down'
	 	:HighlightTexture 'Interface/Buttons/UI-CheckBox-Highlight'
        :CheckedTexture 'Interface/Buttons/UI-CheckBox-Check'
        :DisabledCheckedTexture 'Interface/Buttons/UI-CheckBox-Check-Disabled'
        :HitRectInsets(-4, -100, -4, -4)
        :Hooks {
            OnClick = function(self)
                db.enabled = self:GetChecked()
            end
        }
    {
        function(self)
            self:SetChecked(db.enabled)
        end,
        FontString'.Label'
            .LEFT:RIGHT()
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            :Text 'Enable'
    }

}


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
        .TOP:TOP(MinimapCluster, 0, -17)
    {
        Hide'.Texture'
    },
    Style'.MinimapZoneTextButton'
        .TOP:TOP(Minimap, 0, -6-MAP_INSET)
        :Width(100)
        :Hooks(alphaHooks),
    Style'.Tracking'
        .CENTER:LEFT(Minimap, 5, -5),
    Style'.ZoneTextButton'
        :AllPoints(MinimapCluster.BorderTop)
    {
        Style'.FontString'
            :JustifyH 'CENTER'
            :AllPoints(PARENT)
    },
    Style'.TimeManagerClockButton'
        .BOTTOM:BOTTOM(Minimap, 0, MAP_INSET)
    {
        Hide'.Texture'
    },
    Style'.MiniMapTrackingButtonBorder':Texture '',
    Style'.MiniMapTrackingBackground':Texture '',

    Style'.Minimap'
        .CENTER:CENTER()
        :Size(195, 195)
        :MaskTexture 'Interface/AddOns/silver-ui/art/circle'
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
                self:SetQuestBlobRingScalar(0.98)
            end
            if self.SetTaskBlobRingScalar then
                self:SetTaskBlobRingScalar(0.98)
            end
        end,

        Style'.Button':Hooks(alphaHooks),
        
        Style'.MinimapBackdrop'
            :AllPoints(Minimap)
        {
            Hide'.MinimapZoomIn',
            Hide'.MinimapZoomOut',
            Hide'.MinimapNorthTag',
            Hide'.MiniMapWorldMapButton',
            Hide'.MinimapCompassTexture',
            Hide'.MinimapBorder',
            Style'.Button':Hooks(alphaHooks),
            Style'.*.Button':Hooks(alphaHooks),
        },

        Texture'.BgOuter'
            .TOPLEFT:TOPLEFT(-1.5, 1.5)
            .BOTTOMRIGHT:BOTTOMRIGHT(1.5, -1.5)
            :Texture 'Interface/AddOns/silver-ui/art/circle'
            :DrawLayer 'BACKGROUND'
            :VertexColor(0, 0, 0, 1),

        Texture'.Bg'
            .TOPLEFT:TOPLEFT(-1, 1)
            .BOTTOMRIGHT:BOTTOMRIGHT(1, -1)
            :Texture 'Interface/AddOns/silver-ui/art/circle'
            :DrawLayer 'BACKGROUND'
            :VertexColor(0.15, 0.1, 0.1, 0.8),
            
        Frame'.ShadowFrame'
            :FrameStrata 'BACKGROUND'
            .TOPLEFT:TOPLEFT(-12, 12)
            .BOTTOMRIGHT:BOTTOMRIGHT(12, -12)
        {
            Texture'.Shadow30'
                :AllPoints(PARENT)
                :Texture('Interface/Masks/CircleMaskScalable')
                :DrawLayer 'BACKGROUND'
                :VertexColor(0,0,0, 0.3)
                :Rotation(30),
            Texture'.Shadow45'
                :AllPoints(PARENT)
                :Texture('Interface/Masks/CircleMaskScalable')
                :DrawLayer 'BACKGROUND'
                :VertexColor(0,0,0, 0.3)
                :Rotation(45)
        },

        Style'.TimeManagerClockButton' {
            Style'.Texture':Hide()
        },

        Texture'.ZoneBackground'
            .TOPLEFT:TOPLEFT(0, -3+MAP_INSET)
            .TOPRIGHT:TOPRIGHT(0, -3+MAP_INSET)
            :Texture 'Interface/Common/ShadowOverlay-Top'
            :Height(30),

        Texture'.ClockBackground'
            .BOTTOMLEFT:BOTTOMLEFT(0, 3-MAP_INSET)
            .BOTTOMRIGHT:BOTTOMRIGHT(0, 3-MAP_INSET)
            :Texture 'Interface/Common/ShadowOverlay-Bottom'
            :Height(30),
        
        MaskTexture'.ZoneBackgroundMask'
            .init(function(self)
                Minimap.ZoneBackground:AddMaskTexture(self)
                Minimap.ClockBackground:AddMaskTexture(self)
            end)
            :Texture 'Interface/AddOns/silver-ui/art/circle'
            .TOPLEFT:TOPLEFT(4+MAP_INSET, -4-MAP_INSET)
            .BOTTOMRIGHT:BOTTOMRIGHT(-4-MAP_INSET, 4+MAP_INSET),
    
        Cooldown'.XPBG'
            :DrawEdge(false)
            .TOPLEFT:TOPLEFT(-3.5, 3.5)
            .BOTTOMRIGHT:BOTTOMRIGHT(3.5, -3.5)
            :Cooldown(GetTime(), 1)
            :Rotation(math.rad(180*1.035))
            :SwipeTexture 'Interface/AddOns/silver-ui/art/circle'
            -- :SwipeColor(0.2, 1, 0.5, 1)
            :SwipeColor(1, 1, 1, 1)
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
            :DrawEdge(false)
            .TOPLEFT:TOPLEFT(-3.5, 3.5)
            .BOTTOMRIGHT:BOTTOMRIGHT(3.5, -3.5)
            :Cooldown(GetTime(), 1)
            :Pause()
            :Rotation(math.rad(180*1.035))
            :SwipeTexture 'Interface/AddOns/silver-ui/art/circle'
            :SwipeColor(0.3, 0.3, 0.3, 1)
            :FrameStrata('BACKGROUND', 2)
            :HideCountdownNumbers(true)
            :Reverse(true)
            :Events {
                PLAYER_XP_UPDATE = function(self)
                    self.target = UnitXP('player')/math.max(UnitXPMax('player'), 1)
                    self.start = GetTime()
                    -- self:SetCooldown(GetTime() - UnitXP('player')/UnitXPMax('player')*0.965, 1)
                end,
                PLAYER_ENTERING_WORLD = function(self)
                    self.progress = 0.001
                    self:SetCooldownDuration(1)
                    self:SetCooldown(GetTime(), 1)
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
            .CENTER:BOTTOM(0, MAP_INSET)
            :Events {
                PLAYER_LEVEL_CHANGED = function(self, old, new)
                    self.Text:SetText(new)
                end
            }
        {
            FontString'.Text'
                :Font('FONTS/FRIZQT__.ttf', 10, '')
                .CENTER:BOTTOM(Minimap, 0, -MAP_INSET)
                :Size(50, 50)
                .init(function(self)
                    self:SetText(UnitLevel('player'))
                end),
            Frame'.BgFrame':FrameStrata 'BACKGROUND' {
                Texture'.Bg'
                    :Texture 'Interface/AddOns/silver-ui/art/circle'
                    :Size(22, 22)
                    .CENTER:BOTTOM(Minimap, 0, 3-MAP_INSET)
                    :VertexColor(0, 0, 0, 0.5)
            }
        }
    }

}



local libDbIcons = {}
local once = false


load = function()
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
                    .TOP:BOTTOM(MinimapCluster, 0, -4)

                if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
                    MinimapCluster:ClearAllPoints()
                    MinimapCluster:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', 0, -15)
                end

                StyleMinimapCluster(MinimapCluster)

            end
        }
        .new()
end
