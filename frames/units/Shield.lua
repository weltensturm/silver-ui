---@class Addon
local Addon = select(2, ...)

Addon.Units = Addon.Units or {}

local LQT = Addon.LQT
local Hook = LQT.Hook
local Script = LQT.Script
local Event = LQT.Event
local UnitEvent = LQT.UnitEvent
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture

local MASK_WIDTH_RATIO = 4096 / 64

Addon.Units.Shield = Frame {
    [Hook.SetEventUnit] = function(self, unit)
        self.unit = unit
        self:Update()
    end,
    Update = function(self)
        local ratio = 1 - UnitGetTotalAbsorbs(self.unit) / math.max(0.1, UnitHealthMax(self.unit))
        self.MaskLeft:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', self:GetWidth()*ratio/2, 0)
        self.MaskRight:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -self:GetWidth()*ratio/2, 0)
    end,
    [UnitEvent.UNIT_ABSORB_AMOUNT_CHANGED] = SELF.Update,

    -- Mask = MaskTexture
    --     :Texture'Interface/AddOns/silver-ui/art/playerframe-hp-mask'
    --     :AllPoints(PARENT),

    MaskLeft = MaskTexture
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        .BOTTOMLEFT:BOTTOMLEFT(PARENT),

    MaskRight = MaskTexture
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        .BOTTOMRIGHT:BOTTOMRIGHT(PARENT),

    [Script.OnSizeChanged] = function(self, w, h)
        self.MaskLeft:SetSize(h*MASK_WIDTH_RATIO, h)
        self.MaskRight:SetSize(h*MASK_WIDTH_RATIO, h)
    end,

    Bar = Texture
        .TOPLEFT:TOPLEFT()
        .BOTTOMRIGHT:BOTTOMRIGHT()
        -- .TOPLEFT:TOPLEFT()
        -- .BOTTOMLEFT:BOTTOMLEFT()
        -- :ColorTexture(1, 0, 0, 1)
        -- :Texture 'Interface/BUTTONS/GreyscaleRamp64'
        -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar-Glow'
        -- :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar'

        :Texture 'Interface/AddOns/silver-ui/art/bar-absorb'
        :VertexColor(0.5, 0.5, 1, 0.8)
        :BlendMode 'ADD'

        -- :Texture 'Interface/AddOns/silver-ui/art/bar'
        -- :VertexColor(0.3, 0.7, 0.1, 1)

        :AddMaskTexture(PARENT.MaskLeft)
        :AddMaskTexture(PARENT.MaskRight)
}

