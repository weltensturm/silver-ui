
local Style, Frame, Texture, FontString = LQT.Style, LQT.Frame, LQT.Texture, LQT.FontString


if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end


-- ObjectiveTrackerFrame.IsUserPlaced = function() return true end

-- OBJECTIVE_TRACKER_TEXT_WIDTH = 350
-- OBJECTIVE_TRACKER_LINE_WIDTH = 380


local trackerHeaderAlpha = 0.1
local trackerHeaderAlphaTarget = 0

local hooks = {
    OnEnter = function()
        trackerHeaderAlphaTarget = 1
    end,
    OnLeave = function()
        trackerHeaderAlphaTarget = 0
    end
}

local frames_hide = {}
local buttons_hide = {}

local SectionStyle = nil


local function update_size(e)

    frames_hide = ObjectiveTrackerFrame.BlocksFrame'.Frame'
    buttons_hide = ObjectiveTrackerFrame.BlocksFrame'.Button'
    
    Style(ObjectiveTrackerFrame) {
        Frame'.HoverBg'
            :AllPoints(ObjectiveTrackerFrame)
            :Hooks(hooks),
            
        Style'.BlocksFrame' {
            Style'.Button':Hooks(hooks):Alpha(0),
            Style'.ScrollFrame' {
                SectionStyle'.ScrollContents',
                Style'.ScrollContents' {
                    Style'.Frame' {
                        Style'.Icon':Hide(),
                        Style'.Bar' {
                            Style'.Label' {
                                function(self)
                                    self:SetPoints { LEFT = self:GetParent():LEFT(20, 5) }
                                end
                            }
                        }
                    }
                }
            },
            Style'.Frame' {
                SectionStyle,
                -- Style:FitToChildren(),
            },
            -- Style:FitToChildren()
        }
    }
end

local addon = Frame
    :Hooks {
        OnUpdate = function(self, dt)
            if trackerHeaderAlphaTarget ~= trackerHeaderAlpha then
                local sign = trackerHeaderAlpha >= trackerHeaderAlphaTarget and -1 or 1
                trackerHeaderAlpha = math.min(1, math.max(0, trackerHeaderAlpha + sign * dt*5))
                local anim = math.sqrt(trackerHeaderAlpha)

                
                ObjectiveTrackerFrame:SetAlpha(0.5 + trackerHeaderAlpha/2)
                -- ObjectiveTrackerFrame.Bg:SetAlpha(anim)
                ObjectiveTrackerFrame.HeaderMenu:SetAlpha(anim)
                for frame in frames_hide do
                    if frame.MinimizeButton and frame.Background then
                        frame:SetAlpha(anim)
                        frame.MinimizeButton:SetAlpha(anim)
                    end
                end
                for btn in buttons_hide do
                    btn:SetAlpha(anim)
                end
            end
        end
    }
    
    :EventHooks {
        PLAYER_ENTERING_WORLD = update_size,
        -- QUEST_WATCH_LIST_CHANGED = update_size, -- called way too often, bad performance
        QUEST_WATCH_UPDATE = update_size,
        QUEST_LOG_UPDATE = update_size,
        SUPER_TRACKING_CHANGED = update_size
    }

    .new()


local TextStyle = Style {
    function(self)
        -- self:SetWidth(440)
        if self.GetStringWidth then
            self:SetWidth(self:GetStringWidth())
        else
            self:SetWidth(self:GetTextWidth())
        end
    end
}


SectionStyle = Style {
    -- function(self)
    --     if self.module then
    --         self.module.fromHeaderOffsetY = 0
    --         self.module.fromModuleOffsetY = 0
    --     end
    -- end,
    Style'.rightButton'
        :Hooks(hooks)
        { function(self) self:Points { TOPLEFT = self:GetParent():TOPRIGHT() } end },
    TextStyle'.HeaderText',
    TextStyle'.HeaderButton':FrameLevel(3):Hooks(hooks),
    TextStyle'.Text',
    Style'.Frame' {
        TextStyle'.Text',
        Style'.Dash':Text '',
        Style'.Check':Hide(),
        
        Style'.Bar' {
            function(self)
                self:SetPoints { LEFT = self:GetParent():LEFT() }
            end,
            Style'.Label' {
                function(self)
                    self:SetPoints { TOPLEFT = self:GetParent():TOPLEFT() }
                end
            },
            Style'.Texture':Texture ''
        }

        -- Style'.Bar' {
        --     function(self)
        --         self:Points { LEFT = self:GetParent():LEFT(5, 0) }
        --     end
        -- }
        -- Style'.Bar'
        --     :Height(4)
        -- {
        --     Style'.BorderMid':Height(6),
        --     Style'.BorderRight':Size(6, 6),
        --     Style'.BorderLeft':Size(6, 6),
        --     function(self)
        --         self:Points { LEFT = self:GetParent():LEFT() }
        --     end
        -- }
    }
}


Style(ObjectiveTrackerFrame) {
    Style'.HeaderMenu' {
        Style'.Button':Hooks(hooks),
        Frame'.HoverFrame'
            :FrameStrata('BACKGROUND', -1)
            :Points {
                TOPLEFT = ObjectiveTrackerFrame:TOPLEFT(),
                TOPRIGHT = ObjectiveTrackerFrame:TOPRIGHT()
            }
            :Hooks(hooks)
            :Hooks {
                OnMouseDown = function(self)
                    self:GetParent().MinimizeButton:Click()
                end
            }
    },
    
    Style'.BlocksFrame' {
        Style'.Frame'
            .filter(function(self) return self.MinimizeButton and self.Background end)
        {
            Style'.MinimizeButton'
                :Hooks(hooks)
                :Hooks {
                    OnClick = update_size
                },
            Style'.Background':Hide(),
            Frame'.TitleClickBackground'
                -- :FrameStrata 'BACKGROUND'
                :Hooks(hooks)
                :Hooks {
                    OnMouseDown = function(self)
                        self:GetParent().MinimizeButton:Click()
                    end
                }
                .init(function(self, parent) self:SetAllPoints(parent) end)
        }
    }

}
