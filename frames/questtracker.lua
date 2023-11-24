---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local query = LQT.query
local Event = LQT.Event
local Script = LQT.Script
local Style = LQT.Style
local Frame = LQT.Frame
local Texture = LQT.Texture
local FontString = LQT.FontString
local CheckButton = LQT.CheckButton


if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end


local db
local load


SilverUI.Storage {
    name = 'Quest Tracker',
    character = {
        enabled = true
    },
    onload = function(account, character)
        db = character
        if character.enabled then
            load()
        end
    end
}


SilverUI.Settings 'Quest Tracker' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Quest Tracker',

    Addon.CheckBox
        :Label 'Enable'
        :Get(function(self) return db.enabled end)
        :Set(function(self, value) db.enabled = value end),

}


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


local TextStyle = Style {
    function(self)
        self:SetWidth(440)
        if self.GetStringWidth then
            -- self:SetWidth(self:GetStringWidth())
        else
            -- self:SetWidth(self:GetTextWidth())
        end
    end
}


local SectionStyle = Style {
    -- function(self)
    --     if self.module then
    --         self.module.fromHeaderOffsetY = 0
    --         self.module.fromModuleOffsetY = 0
    --     end
    -- end,
    ['.rightButton'] = Style
        .TOPLEFT:TOPRIGHT()
        :Hooks(hooks),
    ['.HeaderText'] = TextStyle,
    ['.HeaderButton'] = TextStyle:FrameLevel(3):Hooks(hooks),
    ['.Text'] = TextStyle,
    ['.Frame'] = Style {
        ['.Text'] = TextStyle,
        ['.Dash'] = Style:Text '',
        ['.Check'] = Style:Hide(),

        ['.Bar'] = Style.LEFT:LEFT() {
            ['.Label'] = Style.TOPLEFT:TOPLEFT(),
            ['.Texture'] = Style:Texture ''
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



local StyleObjectiveTrackerFrame = Style {
    HoverBg = Frame
        :AllPoints(ObjectiveTrackerFrame)
        :Hooks(hooks),

    ['.BlocksFrame'] = Style {
        ['.Button'] = Style:Hooks(hooks):Alpha(0),
        ['.ScrollFrame'] = Style {
            ['.ScrollContents'] = SectionStyle {
                ['.Frame'] = Style {
                    ['.Icon'] = Style:Hide(),
                    ['.Bar'] = Style {
                        ['.Label'] = Style
                            .LEFT:LEFT(20, 5)
                    }
                }
            }
        },
        ['.Frame'] = Style {
            SectionStyle,
            -- Style:FitToChildren(),
        },
        -- Style:FitToChildren()
    }
}


local function update_size(e)
    frames_hide = query(ObjectiveTrackerFrame.BlocksFrame, '.Frame')
    buttons_hide = query(ObjectiveTrackerFrame.BlocksFrame, '.Button')
    StyleObjectiveTrackerFrame(ObjectiveTrackerFrame)
end


load = function()
    Frame {
        [Script.OnUpdate] = function(self, dt)
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
        end,

        [Event.PLAYER_ENTERING_WORLD] = update_size,
        -- [Event.QUEST_WATCH_LIST_CHANGED] = update_size, -- called way too often, bad performance
        [Event.QUEST_WATCH_UPDATE] = update_size,
        [Event.QUEST_LOG_UPDATE] = update_size,
        [Event.SUPER_TRACKING_CHANGED] = update_size
    }
        .new()


    Style(ObjectiveTrackerFrame) {
        ['.HeaderMenu'] = Style {
            ['.Button'] = Style:Hooks(hooks),
            HoverFrame = Frame
                :FrameStrata('BACKGROUND', -1)
                .TOPLEFT:TOPLEFT(ObjectiveTrackerFrame)
                .TOPRIGHT:TOPRIGHT(ObjectiveTrackerFrame)
                :Hooks(hooks)
                :Hooks {
                    OnMouseDown = function(self)
                        self:GetParent().MinimizeButton:Click()
                    end
                }
        },

        ['.BlocksFrame'] = Style {
            ['.Frame'] = Style
                .filter(function(self) return self.MinimizeButton and self.Background end)
            {
                ['.MinimizeButton'] = Style
                    :Hooks(hooks)
                    :Hooks {
                        OnClick = update_size
                    },
                ['.Background'] = Style:Hide(),
                TitleClickBackground = Frame
                    -- :FrameStrata 'BACKGROUND'
                    :AllPoints()
                    :Hooks(hooks)
                    :Hooks {
                        OnMouseDown = function(self)
                            self:GetParent().MinimizeButton:Click()
                        end
                    }
            }
        }

    }

end
