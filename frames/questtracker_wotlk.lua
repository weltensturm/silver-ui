

SilverUI.RegisterScript(
    'Silver UI',
    'Quest Tracker - WotLK',
[[

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

local Style, Frame, Texture, FontString = LQT.Style, LQT.Frame, LQT.Texture, LQT.FontString

local doUpdate = false
local alpha = 1
local alphaTarget = 0

local Hooks = Style:Hooks {
    OnShow = function() doUpdate = true end,
    OnEnter = function() alphaTarget = 1 end,
    OnLeave = function() alphaTarget = 0 end
}

Frame
    :Hooks {
        OnUpdate = function(self, dt)
            if alpha ~= alphaTarget then
                local sign = alpha >= alphaTarget and -1 or 1
                alpha = math.min(1, math.max(0, alpha + sign * dt*5))
                local anim = math.sqrt(alpha)
                WatchFrameHeader:SetAlpha(anim)
                WatchFrameCollapseExpandButton:SetAlpha(anim)
            end
        end
    }
    .new()


local StyleWatchFrame = Style .. Hooks
    :Points { TOPLEFT = UIParent:TOPLEFT(30, -30) }
    :Height(500)
{
    Hooks'.WatchFrameHeader',
    Hooks'.WatchFrameCollapseExpandButton',
    Style'.WatchFrameLines' .. Hooks {
        Style'.WatchFrameLine#' .. Hooks {
            Style'.dash':Text '',
            function(self)
                local from, target, to, x, y = self:GetPoint()
                if target then
                    -- self:ClearAllPoints()
                    -- self:SetPoint(from, target, to, x, y)
                    self:SetWidth(999)
                    self.text:SetWidth(999)
                    self.text:SetWidth(math.min(self.text:GetStringWidth(), 350))
                    self:SetWidth(self.text:GetStringWidth()+10)
                    self:SetHeight(self.text:GetStringHeight()+5)
                end
            end,
            -- Style'.text':Width(350)
        },
        Style'.WatchFrameItem#:Button' ..
            function(self)
                local to = select(2, self:GetPoint())
                self:SetPoints {
                    TOPRIGHT = to:TOPLEFT(0, -2)
                }
            end
    }
}


Frame
    :Events {
        PLAYER_ENTERING_WORLD = function() doUpdate = true end,
        QUEST_LOG_UPDATE = function() doUpdate = true end,
        QUEST_WATCH_LIST_CHANGED = function() doUpdate = true end,
        QUEST_WATCH_UPDATE = function() doUpdate = true end,
    }
    :Hooks {
        OnUpdate = function()
            if doUpdate then
                StyleWatchFrame(WatchFrame)
            end
        end
    }
    .new()


]]
)