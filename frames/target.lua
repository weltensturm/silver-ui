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
            Style'.nameBackground':Texture ''
        }
        
        TargetFrame.nameBackground:SetColorTexture(0.2,0.2,0.2,1)
    end
}