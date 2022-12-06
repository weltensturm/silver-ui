
local Style = LQT.Style

local addon = CreateFrame('Frame')

addon:RegisterEvent'UPDATE_CHAT_WINDOWS'


local alpha = 1
local alphaTarget = 0
local alphaAnim = 1

local function show_all()
    alphaTarget = 1
end

local function hide_all()
    alphaTarget = 0
end


local Hooks = Style:Hooks {
    OnEnter = show_all,
    OnLeave = hide_all
}


local ForceHide


addon:SetEvents {
    UPDATE_CHAT_WINDOWS = function()
        ChatFrame1.timeVisibleSecs = 10
        ChatFrame2.timeVisibleSecs = 10
        ChatFrame3.timeVisibleSecs = 10
        ChatFrame4.timeVisibleSecs = 10
        ChatFrame5.timeVisibleSecs = 10
        ChatFrame6.timeVisibleSecs = 10
        
        -- ChatFrame1:EnableMouse(false)
        -- QuickJoinToastButton:Points {
        --     TOPLEFT = ChatAlertFrame:TOPLEFT(0, -10)
        -- }

        ChatFrameChannelButton:ClearAllPoints()
        ChatFrameChannelButton:SetPoint('BOTTOMLEFT', ChatFrameMenuButton, 'TOPLEFT', 2, 0)

        -- UIParent'GuildMicroButton'
        --     :ClearAllPoints()
        --     :SetTOPLEFT(QuickJoinToastButton:BOTTOMLEFT(1.5, 0))


        -- UIParent'LFDMicroButton'
        --     :ClearAllPoints()
        --     :SetTOPLEFT(GuildMicroButton:BOTTOMLEFT(0, 0))


        -- UIParent'EJMicroButton'
        --     :ClearAllPoints()
        --     :SetTOPLEFT(LFDMicroButton:BOTTOMLEFT())

        for i = 1, 10 do
            Hooks(_G['ChatFrame'..i])
            Hooks(_G['ChatFrame'..i].buttonFrame) {
                Hooks'.Button'
            }
            Hooks(_G['ChatFrame'..i..'Tab'])
        end
    end,
}



local buttons = {
    ChatFrameMenuButton,
    ChatFrameChannelButton,
    -- QuickJoinToastButton,
    -- GuildMicroButton,
    -- LFDMicroButton,
    -- EJMicroButton,
    GeneralDockManager,
    ChatFrame1Tab,
    ChatFrame2Tab,
    ChatFrame3Tab,
    ChatFrame4Tab,
    ChatFrame5Tab,
    ChatFrame6Tab,
    ChatFrame7Tab,
    ChatFrame8Tab,
    ChatFrame9Tab,
    ChatFrame10Tab,
    ChatFrame1.buttonFrame,
    ChatFrame2.buttonFrame,
    ChatFrame3.buttonFrame,
    ChatFrame4.buttonFrame,
    ChatFrame5.buttonFrame,
    ChatFrame6.buttonFrame,
    ChatFrame7.buttonFrame,
    ChatFrame8.buttonFrame,
    ChatFrame9.buttonFrame,
    ChatFrame10.buttonFrame,
}


-- for _, v in pairs(buttons) do
--     v:SetHooks {
--         OnUpdate = function(self)
--             self:SetAlpha(alphaAnim)
--         end
--     }
-- end


addon:SetHooks {
    OnUpdate = function(self, dt)
        if alphaTarget ~= alpha then
            local sign = alpha >= alphaTarget and -1 or 1
            alpha = math.min(1, math.max(0, alpha + sign * dt*5))
            alphaAnim = alpha^3
            
            for _, v in pairs(buttons) do
                v.noMouseAlpha = alpha^2
                v:SetAlpha(alpha^2)
            end
        end
    end
}


hide_all()


for _, v in pairs({
    ChatFrameMenuButton,
    ChatFrameChannelButton,
    -- QuickJoinToastButton,
    -- GuildMicroButton,
    -- LFDMicroButton,
    -- EJMicroButton,
}) do
    Hooks(v)
end
