local _, ns = ...
local lqt = ns.lqt
local Style, Frame, Texture, FontString = lqt.Style, lqt.Frame, lqt.Texture, lqt.FontString

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end


local doUpdate = false


local Hooks = Style:Hooks { OnShow = function() doUpdate = true end }


local StyleWatchFrame = Style .. Hooks
    :Points { TOPLEFT = UIParent:TOPLEFT(30, -30) }
    :Height(500)
{
    Style'.WatchFrameLines' .. Hooks {
        Style'.WatchFrameLine#' .. Hooks {
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
            end
            -- Style'.text':Width(350)
        }
    }
}


Frame
    :Event {
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