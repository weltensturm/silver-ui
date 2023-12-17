---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local query = LQT.query
local Style = LQT.Style
local Event = LQT.Event
local Frame = LQT.Frame


local center = GameTooltip.NineSlice.Center
local tex = center:GetTexture()
local color = { center:GetVertexColor() }
color[4] = 0.7
for slice in query(GameTooltip, '.NineSlice.Texture') do
    if slice ~= center then
        slice:SetTexture ''
        slice:SetAlpha(0)
        -- slice:SetColorTexture(unpack(color))
        -- slice:SetVertexColor(unpack(color))
        -- slice:SetBlendMode('BLEND')
    end
end


local StyleCenter = Style
    .TOPLEFT:TOPLEFT(GameTooltip, 0, -2)
    .BOTTOMRIGHT:BOTTOMRIGHT(GameTooltip)


Style(GameTooltipStatusBar)
    .TOPLEFT:BOTTOMLEFT(GameTooltip, 6, 6)
    .TOPRIGHT:BOTTOMRIGHT(GameTooltip, -6, 6)
    :Height(1)


Frame {
    [Event.UPDATE_MOUSEOVER_UNIT] = function()
        StyleCenter(center)
    end
}
    .new()