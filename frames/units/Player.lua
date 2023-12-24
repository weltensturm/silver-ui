---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local query = LQT.query
local Override = LQT.Override
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local Script = LQT.Script
local Hook = LQT.Hook
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Style = LQT.Style
local Frame = LQT.Frame
local CheckButton = LQT.CheckButton
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture
local FontString = LQT.FontString
local AnimationGroup = LQT.AnimationGroup
local Animation = LQT.Animation
local Button = LQT.Button


local db
local load


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


Addon:Storage {
    name = 'Player Frame',
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


Addon:Settings 'Player Frame' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Player Frame',

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


local UnitPlayer = Addon.Templates.UnitButton { Addon.Templates.PixelAnchor }
    :Attribute('unit', 'player')
    :Size(300, 300/4)
    :HitRectInsets(20, 20, 25, 25)
{
    Border = Frame
        :AllPoints(PARENT)
        :FrameLevel(5)
    {
        BarOverlay = Texture
            :Texture 'Interface/AddOns/silver-ui/art/playerframe'
            :AllPoints(PARENT)
            :VertexColor(0.1, 0.1, 0.1, 0.7)
    },

    Background = Frame
        :AllPoints(PARENT)
    {
        BarBackground = Texture
            :AllPoints(PARENT)
            :Texture 'Interface/AddOns/silver-ui/art/playerframe-bg'
            :VertexColor(0.1, 0.1, 0.1, 0.9)
    },

    HealthLoss = Addon.Units.HealthLoss
        .TOPLEFT:TOPLEFT(21, -38.5)
        .BOTTOMRIGHT:BOTTOMRIGHT(-21, 21.5)
        :FrameLevel(2)
        :Unit 'player',

    HealthBar = Addon.Units.HealthBar
        .TOPLEFT:TOPLEFT(21, -38.5)
        .BOTTOMRIGHT:BOTTOMRIGHT(-21, 21.5)
        :FrameLevel(3)
        :Unit 'player'
    {
        ['.Bar'] = Style
            :ClearAllPoints()
            .TOPLEFT:TOPLEFT(0, 10)
            .BOTTOMRIGHT:BOTTOMRIGHT()
    },

    Shield = IsRetail and Addon.Units.Shield
        .TOPLEFT:TOPLEFT(21, -38.5)
        .BOTTOMRIGHT:BOTTOMRIGHT(-21, 21.5)
        :FrameLevel(4)
        :EventUnit 'player'
    {
        [Event.PLAYER_ENTERING_WORLD] = SELF.Update,
    },

    PowerBar = Addon.Units.PowerBar
        .CENTER:CENTER(0, 6.5)
        :Size(240, 8)
        -- .TOPLEFT:TOPLEFT(31.5, -26)
        -- .BOTTOMRIGHT:BOTTOMRIGHT(-31.5, 39)
        :Unit 'player'
    {
        ['.Bar'] = Style
            :ClearAllPoints()
            .TOPLEFT:TOPLEFT()
            .BOTTOMRIGHT:BOTTOMRIGHT(0, -10)
    },

    SecondaryPower = Addon.Units.SecondaryPower
        :AllPoints(PARENT)
        :Unit 'player',

    CastBar = Addon.Units.CastBar
        .TOPLEFT:TOPLEFT(30, -40)
        .BOTTOMRIGHT:BOTTOMRIGHT(-30, 40)
        :FrameLevel(6)
        :Unit 'player',

    GCD = Addon.Units.GCD
        .TOPLEFT:TOPLEFT(30, -33)
        .BOTTOMRIGHT:BOTTOMRIGHT(-30, 35)
        :FrameLevel(11),

    VehicleExit = Button
        .TOPRIGHT:TOPRIGHT()
        :Size(32, 32)
        :RegisterForClicks('LeftButtonUp')
        :Hide()
    {
        Bg = Texture
            :AllPoints()
            :ColorTexture(0.7, 0.3, 0.3),
        UpdateShow = function(self)
            self:SetShown(CanExitVehicle())
        end,
        [UnitEvent.UNIT_ENTERED_VEHICLE] = SELF.UpdateShow,
        [UnitEvent.UNIT_EXITED_VEHICLE] = SELF.UpdateShow,
        [Script.OnClick] = function(self)
            if UnitOnTaxi("player") then
                TaxiRequestEarlyLanding();
            else
                VehicleExit();
            end
        end,
    }
        :EventUnit 'player'
}


load = function()

    Frame {
        HideBlizzard = function(self, frame)
            Style(frame):Parent(self):UnregisterAllEvents()
            query(frame, '.CheckButton'):UnregisterAllEvents():Hide()
        end,
    }
    :HideBlizzard(PlayerCastingBarFrame or CastingBarFrame)
    :HideBlizzard(PlayerFrame)
    :Hide()
    .new()

    UnitPlayer
        .BOTTOM:BOTTOM(0, 45)
        :Scale(1.25)
        .new(UIParent, 'SilverUIPlayerFrame')

    if StatusTrackingBarManager then
        -- XP/rep bars
        hooksecurefunc(StatusTrackingBarManager, 'UpdateBarsShown', function()
            StatusTrackingBarManager:Hide()
        end)
    end
end