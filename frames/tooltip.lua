
local addon = CreateFrame('Frame')

local center = GameTooltip.NineSlice.Center
local tex = center:GetTexture()
local color = { center:GetVertexColor() }
color[4] = 0.7
for slice in GameTooltip'.NineSlice.Texture' do
    if slice ~= center then
        slice:SetTexture ''
        slice:SetAlpha(0)
        -- slice:SetColorTexture(unpack(color))
        -- slice:SetVertexColor(unpack(color))
        -- slice:SetBlendMode('BLEND')
    end
end

center:Points {
    TOPLEFT = GameTooltip:TOPLEFT(0, -2),
    BOTTOMRIGHT = GameTooltip:BOTTOMRIGHT()
}

GameTooltip:Hook {
    OnShow = function()

    end
}

GameTooltipStatusBar:SetPoints({
    TOPLEFT = GameTooltip:BOTTOMLEFT(6, 6),
    TOPRIGHT = GameTooltip:BOTTOMRIGHT(-6, 6)
})
GameTooltipStatusBar:SetHeight(1)


addon:Event {
    UPDATE_MOUSEOVER_UNIT = function()
        
        center:Points {
            TOPLEFT = GameTooltip:TOPLEFT(0, -2),
            BOTTOMRIGHT = GameTooltip:BOTTOMRIGHT()
        }

    end
}

