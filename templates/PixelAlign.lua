---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Script, PARENT, Style, Frame, Texture, Button, FontString
    = LQT.Script, LQT.PARENT, LQT.Style, LQT.Frame, LQT.Texture, LQT.Button, LQT.FontString


--- TODO: unfinished and broken. resizable frames get broken really hard


Addon.PixelAlign = Style {

    PixelAlignFrame = Frame
        .TOPLEFT:TOPLEFT(UIParent)
        .BOTTOMRIGHT:TOPLEFT()
    {
        [Script.OnSizeChanged] = function(self, x, y)
            local align = self:GetParent().PixelAlign
            local scale = self:GetEffectiveScale()
            local pixelFactor = PixelUtil.GetPixelToUIUnitFactor()
            local xscaled = x * scale / pixelFactor
            local xoffset = (xscaled - Round(xscaled)) / scale * pixelFactor
            local yscaled = y * scale / pixelFactor
            local yoffset = (yscaled - Round(yscaled)) / scale * pixelFactor

            align.Translate:SetOffset(xoffset, yoffset)
            align:Play(true)
            align:Pause()
        end
    },

    PixelAlign = LQT.AnimationGroup {
        Translate = LQT.Animation.Translation
            :Duration(99999)
            :Offset(0.01, 0.01)
    }
}
