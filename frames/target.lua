local _, ns = ...
local lqt = ns.lqt

local Frame, Style, Texture = lqt.Frame, lqt.Style, lqt.Texture


local addon = Frame.new()


addon:Event {
    PLAYER_ENTERING_WORLD = function()

        Style(TargetFrame) {
            Style'.textureFrame' {
                Style'.texture':Texture 'Interface/TARGETINGFRAME/UI-TARGETINGFRAME-MINUS',
            },
            Style'.nameBackground':Texture '',
            Style'.Background':Texture ''
        }
        
        -- TargetFrame.nameBackground:SetColorTexture(0.2,0.2,0.2,1)
    end,

    PLAYER_TARGET_CHANGED = function()
        -- TargetFrame.textureFrame.texture:SetTexture('Interface/TARGETINGFRAME/UI-TARGETINGFRAME-MINUS')
        -- TargetFrame.textureFrame.texture:SetTexture('Interface/TARGETINGFRAME/PlayerFrame')

        TargetFrame.textureFrame.texture:Hide()
        TargetFrame.textureFrame.texture:SetTexture('Interface/TARGETINGFRAME/PlayerFrame')
        TargetFrame.textureFrame.texture:Points {
            TOPLEFT = TargetFrame.portrait:TOPLEFT(-5, 5),
            BOTTOMRIGHT = TargetFrame.portrait:BOTTOMRIGHT(5, -5)
        }
        TargetFrame.textureFrame.texture:SetTexCoord(0.01,0.73,0.02,0.75)

        TargetFrame.healthbar:SetHeight(4)
        TargetFrame.healthbar:SetReverseFill(true)
        TargetFrame.manabar:SetHeight(4)
        TargetFrame.manabar:Points { TOPLEFT = TargetFrame.healthbar:BOTTOMLEFT() }
        TargetFrame.manabar:SetReverseFill(true)

    end
}