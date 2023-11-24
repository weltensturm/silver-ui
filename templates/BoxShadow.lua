---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Script = LQT.Script
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture


local ShadowTexture = Texture
    :Texture 'Interface/AddOns/silver-ui/art/shadow'
    -- :SnapToPixelGrid(false)
    :TexelSnappingBias(0)


Addon.BoxShadow = Frame
    :IgnoreParentScale(true)
{
    function(self)
        self:SetEdgeSize(6)
    end,
    SetEdgeSize = function(self, size)
        self.edgeSize = size
        self.scale = self:GetEffectiveScale()
        local s = PixelUtil.GetNearestPixelSize(size, self.scale)
        self:SetPoint('TOPLEFT', self:GetParent(), 'TOPLEFT', -s, s)
        self:SetPoint('BOTTOMRIGHT', self:GetParent(), 'BOTTOMRIGHT', s, -s)
        for _, edge in pairs { self.TopLeft, self.BottomLeft, self.TopRight, self.BottomRight } do
            edge:SetSize(s*2, s*2)
        end
    end,

    [Script.OnSizeChanged] = function(self)
        if self.scale ~= self:GetEffectiveScale() then
            self:SetEdgeSize(self.edgeSize)
        end
    end,

    TopLeft = ShadowTexture
        :TexCoord(0, 1/2, 0, 1/2)
        .TOPLEFT:TOPLEFT(),
    BottomLeft = ShadowTexture
        :TexCoord(0, 1/2, 1/2, 1)
        .BOTTOMLEFT:BOTTOMLEFT(),
    TopRight = ShadowTexture
        :TexCoord(1/2, 1, 0, 1/2)
        .TOPRIGHT:TOPRIGHT(),
    BottomRight = ShadowTexture
        :TexCoord(1/2, 1, 1/2, 1)
        .BOTTOMRIGHT:BOTTOMRIGHT(),

    Left = ShadowTexture
        :TexCoord(0, 1/2, 1/3, 2/3)
        .TOPLEFT:BOTTOMLEFT(PARENT.TopLeft)
        .BOTTOMRIGHT:TOPRIGHT(PARENT.BottomLeft),
    Right = ShadowTexture
        :TexCoord(1/2, 1, 1/3, 2/3)
        .TOPLEFT:BOTTOMLEFT(PARENT.TopRight)
        .BOTTOMRIGHT:TOPRIGHT(PARENT.BottomRight),
    Top = ShadowTexture
        :TexCoord(1/3, 2/3, 0, 1/2)
        .TOPLEFT:TOPRIGHT(PARENT.TopLeft)
        .BOTTOMRIGHT:BOTTOMLEFT(PARENT.TopRight),
    Bottom = ShadowTexture
        :TexCoord(1/3, 2/3, 1/2, 1)
        .TOPLEFT:TOPRIGHT(PARENT.BottomLeft)
        .BOTTOMRIGHT:BOTTOMLEFT(PARENT.BottomRight),

}
