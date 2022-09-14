local _, ns = ...

local addon = CreateFrame('Frame')

addon:RegisterEvent'UPDATE_CHAT_WINDOWS'


local alpha = 0.1
local alphaTarget = 0

local function show_all()
    alphaTarget = 1
end

local function hide_all()
    alphaTarget = 0
end



addon:Event {
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

        ChatFrameChannelButton:Points {
            BOTTOMLEFT = ChatFrameMenuButton:TOPLEFT(2, 0)
        }

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
            _G['ChatFrame'..i]:Hooks {
                OnEnter = show_all,
                OnLeave = hide_all
            }
            _G['ChatFrame'..i].buttonFrame:Hooks {
                OnEnter = show_all,
                OnLeave = hide_all
            }
            _G['ChatFrame'..i..'Tab']:Hooks {
                OnEnter = show_all,
                OnLeave = hide_all
            }
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
    ChatFrame10Tab
}


addon:Hooks {
    OnUpdate = function(self, dt)
        if alphaTarget ~= alpha then
            local sign = alpha >= alphaTarget and -1 or 1
            alpha = math.min(1, math.max(0, alpha + sign * dt*5))
            
            for _, v in pairs(buttons) do
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
    v:Hooks {
        OnEnter = show_all,
        OnLeave = hide_all
    }
end
