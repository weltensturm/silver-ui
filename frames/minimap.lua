---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Event = LQT.Event
local Script = LQT.Script
local PARENT = LQT.PARENT
local Style = LQT.Style
local Frame = LQT.Frame
local Cooldown = LQT.Cooldown
local CheckButton = LQT.CheckButton
local Texture = LQT.Texture
local FontString = LQT.FontString
local MaskTexture = LQT.MaskTexture

local load


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


local _, db = SilverUI.Storage {
    name = 'Minimap',
    character = {
        enabled = true
    },
    onload = function(account, character)
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
    {
        function(self)
            self:SetChecked(db.enabled)
        end,
        [Script.OnClick] = function(self)
            db.enabled = self:GetChecked()
        end,
        Label = FontString
            .LEFT:RIGHT()
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            :Text 'Enable'
    }

}


local Hide = Style:Hide()


local alpha = 1
local alphaTarget = 0


local AlphaHooks = Style {
    [Script.OnEnter] = function() alphaTarget = 1 end,
    [Script.OnLeave] = function() alphaTarget = 0 end
}


local MAP_INSET = 4
local MAP_INSET_MASK = -4.5


local StyleMinimapCluster = Style:Size(200, 200) {
    ['.MinimapBorderTop'] = Hide,
    ['.MinimapBorder'] = Hide,
    ['.BorderTop'] = Style.TOP:TOP(MinimapCluster, 0, -17) {
        ['.Texture'] = Hide
    },
    ['.ZoneTextButton'] = Style .. AlphaHooks
        .TOP:TOP(Minimap, 0, -8-MAP_INSET)
        :FrameStrata('HIGH')
        :Width(150)
    {
        ['.FontString'] = Style
            :JustifyH 'CENTER'
            :AllPoints(PARENT)
    },
    ['.Tracking'] = Style
        .CENTER:LEFT(Minimap, 5, -5)
    {
        ['.Frame, .Button'] =  AlphaHooks
    },
    ['.TimeManagerClockButton'] = Style
        .BOTTOM:BOTTOM(Minimap, 0, MAP_INSET)
    {
        ['.Texture'] = Hide:Texture ''
    },
    ['.MiniMapTrackingButtonBorder'] = Style:Texture '',
    ['.MiniMapTrackingBackground'] = Style:Texture '',

    ['.MinimapContainer'] = Style
        :AllPoints(PARENT),

    ['.MinimapContainer.Minimap, .Minimap'] = Style .. AlphaHooks
        :Size(195, 195)
        :MaskTexture 'Interface/AddOns/silver-ui/art/circle'
    {
        IsRetail and Style.CENTER:CENTER() or Style.TOPRIGHT:TOPRIGHT(-20, -20),

        [Script.OnMouseWheel] = function(self, delta)
            if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
                self:SetZoom(math.max(self:GetZoom() + delta, 0))
            end
        end,

        function(self)
            if self.SetQuestBlobRingScalar then
                self:SetQuestBlobRingScalar(0.98)
            end
            if self.SetTaskBlobRingScalar then
                self:SetTaskBlobRingScalar(0.98)
            end
        end,

        ['.Button'] = AlphaHooks,

        ['.MinimapBackdrop'] = Style:AllPoints(Minimap) {
            ['.MinimapZoomIn'] = Hide,
            ['.MinimapZoomOut'] = Hide,
            ['.MinimapNorthTag'] = Hide,
            ['.MiniMapWorldMapButton'] = Hide,
            ['.MinimapCompassTexture'] = Hide,
            ['.MinimapBorder'] = Hide,
            ['.Button'] = AlphaHooks,
            ['.*.Button'] = AlphaHooks,
        },

        ['.TimeManagerClockButton'] = Style {
            ['.Texture'] = Style:Hide()
        },

        BgOuter = Texture
            .TOPLEFT:TOPLEFT(-1.5, 1.5)
            .BOTTOMRIGHT:BOTTOMRIGHT(1.5, -1.5)
            :Texture 'Interface/AddOns/silver-ui/art/circle'
            :DrawLayer 'BACKGROUND'
            :VertexColor(0, 0, 0, 1),

        Bg = Texture
            .TOPLEFT:TOPLEFT(-1, 1)
            .BOTTOMRIGHT:BOTTOMRIGHT(1, -1)
            :Texture 'Interface/AddOns/silver-ui/art/circle'
            :DrawLayer 'BACKGROUND'
            :VertexColor(0.15, 0.1, 0.1, 0.8),

        ShadowFrame = Frame
            :FrameStrata 'BACKGROUND'
            .TOPLEFT:TOPLEFT(-12, 12)
            .BOTTOMRIGHT:BOTTOMRIGHT(12, -12)
        {
            Shadow30 = Texture
                :AllPoints(PARENT)
                :Texture('Interface/Masks/CircleMaskScalable')
                :DrawLayer 'BACKGROUND'
                :VertexColor(0,0,0, 0.3)
                :Rotation(30),
            Shadow45 = Texture
                :AllPoints(PARENT)
                :Texture('Interface/Masks/CircleMaskScalable')
                :DrawLayer 'BACKGROUND'
                :VertexColor(0,0,0, 0.3)
                :Rotation(45)
        },

        ZoneBackgroundMask = MaskTexture
            :Texture 'Interface/AddOns/silver-ui/art/circle'
            .TOPLEFT:TOPLEFT(4+MAP_INSET_MASK, -4-MAP_INSET_MASK)
            .BOTTOMRIGHT:BOTTOMRIGHT(-4-MAP_INSET_MASK, 4+MAP_INSET_MASK),

        ZoneBackground = Texture
            .TOPLEFT:TOPLEFT(0, -3+MAP_INSET)
            .TOPRIGHT:TOPRIGHT(0, -3+MAP_INSET)
            :Height(30)
            :Texture 'Interface/Common/ShadowOverlay-Top'
            :AddMaskTexture(PARENT.ZoneBackgroundMask),

        ClockBackground = Texture
            .BOTTOMLEFT:BOTTOMLEFT(0, 3-MAP_INSET)
            .BOTTOMRIGHT:BOTTOMRIGHT(0, 3-MAP_INSET)
            :Height(30)
            :Texture 'Interface/Common/ShadowOverlay-Bottom'
            :AddMaskTexture(PARENT.ZoneBackgroundMask),

        XPBG = Cooldown
            :DrawEdge(false)
            .TOPLEFT:TOPLEFT(-3.5, 3.5)
            .BOTTOMRIGHT:BOTTOMRIGHT(3.5, -3.5)
            :Reverse(true)
            :CooldownDuration(1)
            :Rotation(math.rad(180*1.035))
            :SwipeTexture 'Interface/AddOns/silver-ui/art/circle'
            -- :SwipeColor(0.2, 1, 0.5, 1)
            :SwipeColor(1, 1, 1, 1)
            :FrameStrata('BACKGROUND', 1)
            :HideCountdownNumbers(true)
            :Pause()
        {
            [Event.PLAYER_XP_UPDATE] = function(self)
                self:SetCooldown(GetTime() - UnitXP('player')/UnitXPMax('player')*0.964, 1)
            end,
            [Event.PLAYER_ENTERING_WORLD] = function(self)
                self:SetCooldown(GetTime() - UnitXP('player')/UnitXPMax('player')*0.964, 1)
            end
        },

        XPanim = Cooldown
            :DrawEdge(false)
            .TOPLEFT:TOPLEFT(-3.5, 3.5)
            .BOTTOMRIGHT:BOTTOMRIGHT(3.5, -3.5)
            :Rotation(math.rad(180*1.035))
            :SwipeTexture 'Interface/AddOns/silver-ui/art/circle'
            :SwipeColor(0.3, 0.3, 0.3, 1)
            :FrameStrata('BACKGROUND', 2)
            :HideCountdownNumbers(true)
            :Reverse(true)
            :CooldownDuration(1)
            :Pause()
        {
            progress = 0,
            target = 0,
            start = GetTime(),
            [Event.PLAYER_XP_UPDATE] = function(self)
                self.target = UnitXP('player')/math.max(UnitXPMax('player'), 1)
                self.start = GetTime()
            end,
            [Event.PLAYER_ENTERING_WORLD] = function(self)
                self.progress = 0
                self.target = UnitXP('player')/math.max(UnitXPMax('player'), 1)
                self.start = GetTime() - 2.14
            end,
            [Script.OnUpdate] = function(self, dt)
                if self.progress ~= self.target and GetTime() > self.start+3.14*2 then
                    self.progress = math.min(self.progress + dt/5, self.target)
                    self:SetCooldown(GetTime() - math.min(self.progress, 1)*0.965, 1)
                    self:Pause()
                end
            end
        },

        Level = Frame.CENTER:BOTTOM(0, MAP_INSET) {
            [Event.PLAYER_LEVEL_CHANGED] = function(self, old, new)
                self.Text:SetText(new)
            end,
            Text = FontString
                :Font('FONTS/FRIZQT__.ttf', 10, '')
                .CENTER:BOTTOM(Minimap, 0, -MAP_INSET)
                :Size(50, 50)
            {
                function(self)
                    self:SetText(UnitLevel('player'))
                end
            },
            BgFrame = Frame:FrameStrata 'BACKGROUND' {
                Bg = Texture
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
    Frame {
        [Script.OnUpdate] = function(self, dt)
            if alpha ~= alphaTarget then

                local sign = alpha >= alphaTarget and -1 or 1
                alpha = math.min(1, math.max(0, alpha + sign * dt*5))

                MinimapBackdrop:SetAlpha(alpha^2)

                if MinimapCluster.Tracking then
                    MinimapCluster.Tracking:SetAlpha(alpha^2)
                end

                if AddonCompartmentFrame then
                    AddonCompartmentFrame:SetAlpha(alpha^2)
                end

                for _, v in ipairs(libDbIcons) do
                    v:SetAlpha(alpha^2)
                end
            end
        end,

        [Event.PLAYER_ENTERING_WORLD] = function()
            if once then return end
            once = true

            if LibStub then
                libDbIcons = {}
                for k, v in pairs(LibStub.libs) do
                    if k:find('^LibDBIcon-') then
                        for name, button in pairs(v.objects) do
                            AlphaHooks(button)
                            table.insert(libDbIcons, button)
                        end
                    end
                end
            end

            Style(UIWidgetTopCenterContainerFrame)
                .TOP:BOTTOM(Minimap, 0, -12)
                :Scale(0.75)

            if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
                MinimapCluster:ClearAllPoints()
                MinimapCluster:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', 0, -15)
            end

            StyleMinimapCluster(MinimapCluster)

        end
    }
    .new()
end
