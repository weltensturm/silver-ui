---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Script = LQT.Script
local PARENT, Frame, Texture, MaskTexture = LQT.PARENT, LQT.Frame, LQT.Texture, LQT.MaskTexture


local ShadowTexture = Texture
    :Texture 'Interface/AddOns/silver-ui/art/shadow'
    -- :SnapToPixelGrid(false)
    :TexelSnappingBias(0)

local F = 0.65
local O = 1/4*F

local S = PixelUtil.GetNearestPixelSize(6, UIParent:GetEffectiveScale())
local SSF = PixelUtil.GetNearestPixelSize(6+6*F, UIParent:GetEffectiveScale())

local function Pixel2Align(widget, size)
    local pixelFactor = PixelUtil.GetPixelToUIUnitFactor()
    local pixels = math.floor(size * widget:GetEffectiveScale() / pixelFactor)
    if pixels % 2 ~= 0 then
        pixels = pixels + 1
    end
    return pixels / widget:GetEffectiveScale() * pixelFactor
end


-- local S = Pixel2Align(UIParent, 6)
-- local SSF = Pixel2Align(UIParent, 6+6*F)


Addon.BoxShadow = Frame {
    function(self)
        self:SetEdgeSize(6)
    end,
    SetEdgeSize = function(self, size)
        self.edgeSize = size
        self.scale = self:GetEffectiveScale()
        local s = PixelUtil.GetNearestPixelSize(size, self.scale)
        self:SetPoint('TOPLEFT', self:GetParent(), 'TOPLEFT', -s, s)
        self:SetPoint('BOTTOMRIGHT', self:GetParent(), 'BOTTOMRIGHT', s, -s)
        self.Texture:SetTextureSliceMargins(64, 64, 64, 64)
    end,

    [Script.OnSizeChanged] = function(self)
        if self.scale ~= self:GetEffectiveScale() then
            self:SetEdgeSize(self.edgeSize)
        end
    end,

    Texture = Texture
        :AllPoints()
        :SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
        :Texture 'Interface/AddOns/silver-ui/art/shadow',

}
