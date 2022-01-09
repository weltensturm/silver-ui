local _, ns = ...
local lqt = ns.lqt

local Cooldown, Texture, MaskTexture = lqt.Cooldown, lqt.Texture, lqt.MaskTexture


local addon = CreateFrame('Frame')


BUFF_WARNING_TIME = 0


addon:Event {

    PLAYER_ENTERING_WORLD = function()
        BuffFrame:ClearAllPoints()
        BuffFrame:SetPoint('BOTTOMRIGHT', PlayerFrame, 'TOPRIGHT', 0, 25)
        for _, button in pairs(BuffFrame.BuffButton or {}) do
            button:SetSize(32, 32)

            if not button.Mask then
                button {
                    MaskTexture'.Mask'
                        :Points { TOPLEFT = button:TOPLEFT(1, -1),
                                BOTTOMRIGHT = button:BOTTOMRIGHT(-1, 1) }
                        :Texture('Interface/Masks/CircleMaskScalable')
                }
                button.Icon:AddMaskTexture(button.Mask)
            end

            button {
                Texture'.Bg'
                    :Texture('Interface/Masks/CircleMaskScalable')
                    :AllPoints(button)
                    :DrawLayer('BACKGROUND')
                    :VertexColor(0,0,0)
            }

            if button.timeLeft then
                if button.savedTime ~= button.expirationTime then
                    button.savedTime = button.expirationTime
                    button {
                        Cooldown'.CooldownBg'
                            :UseCircularEdge(true)
                            :Points {
                                TOPLEFT = button:TOPLEFT(-4, 4),
                                BOTTOMRIGHT = button:BOTTOMRIGHT(4, -4)
                            }
                            :Cooldown(button.expirationTime - button.timeLeft, button.timeLeft)
                            :SwipeTexture('Interface/GUILDFRAME/GuildLogoMask_L')
                            :SwipeColor(0.2, 1, 0.5, 1)
                            :DrawEdge(false)
                            :FrameStrata('BACKGROUND', 1)
                            :Rotation(math.rad(180))
                            :HideCountdownNumbers(true)
                            :Show()
                    }
                end
            else
                if button.CooldownBg then
                    button.CooldownBg:Hide()
                end
            end

        end
        
        local lastBtn = nil
        for _, button in pairs(BuffFrame.DebuffButton or {}) do
            button:SetSize(32, 32)
            -- button.Icon:SetMask('Interface/Masks/CircleMaskScalable')
            if not lastBtn then
                button:ClearAllPoints()
                button:SetPoint('BOTTOMRIGHT', BuffFrame, 'TOPRIGHT', 0, 30)
            end
            button.Border:Hide()
            lastBtn = button
            if not button.Mask then
                button {
                    MaskTexture'.Mask'
                        :Points { TOPLEFT = button:TOPLEFT(1, -1),
                                BOTTOMRIGHT = button:BOTTOMRIGHT(-1, 1) }
                        :Texture('Interface/Masks/CircleMaskScalable')
                        .init(function(self)
                            button.Icon:AddMaskTexture(self)
                        end)
                }
            end
            
            button {
                Texture'.Bg'
                    :Texture('Interface/Masks/CircleMaskScalable')
                    :AllPoints(button)
                    :DrawLayer('BACKGROUND')
                    :VertexColor(1,0,0)
            }
            -- button.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        end
    end,

    UNIT_AURA = function(self, unit)
        if unit == 'player' then
            self.PLAYER_ENTERING_WORLD()
        end
    end

}
