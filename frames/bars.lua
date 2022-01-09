local _, ns = ...
local lqt = ns.lqt


local Style, Frame, Texture, MaskTexture, FontString = lqt.Style, lqt.Frame, lqt.Texture, lqt.MaskTexture, lqt.FontString


local addon = CreateFrame('Frame')


addon:EventHook {
    PLAYER_ENTERING_WORLD = function()

        Style(OrderHallCommandBar)
            :FrameStrata 'LOW'
            :ClearAllPoints()
            :BOTTOM(UIParent:TOP())
        {
            Style'.Background':Texture '',
            Style'.ClassIcon':Texture '',
            Style'.AreaName':Hide(),
            Style'.Currency':Points {
                TOPLEFT = UIParent:TOPLEFT(150, -5)
            }
        }
        
    end
}


local function range_apply(name, start, end_, fn)
    for i = start, end_ do
        local btn = _G[name .. i]
        local prev = _G[name .. i-1]
        fn(i, name .. i, btn, name .. i-1, prev)
    end
end


local IN_GLOW = {}


local function style_bars()

    local bar_width = UIParent:GetWidth()/3 -- UIParent:GetWidth()/3/12/3*2

    local ActionBar = Frame
        :Size(bar_width, bar_width/12)
        :FrameStrata 'LOW'
        :Hook {
            OnUpdate = function(self, dt)
                if self.AnimProgress ~= self.AnimTarget then
                    local sign = self.AnimProgress >= self.AnimTarget and -1 or 1
                    self.AnimProgress = math.min(1, math.max(0, self.AnimProgress + sign * dt*5))
                    local anim = self.AnimProgress^2
                    self.ArtFrame:SetPoints { BOTTOMLEFT = self:BOTTOMLEFT(0, -anim*60),
                                              TOPRIGHT = self:TOPRIGHT(0, -anim*60) }
                end
            end
        }
        .data {
            AnimProgress = 0,
            AnimTarget = 1,
            AnimShowgrid = 1,
            AnimMouse = 1,
        }

    ActionBarMiddle = ActionBar
        :BOTTOM(UIParent:BOTTOM(0, 0.5))
        .new()

    ActionBarLeft = ActionBar
        :TOPRIGHT(ActionBarMiddle:TOPLEFT())
        :BOTTOMRIGHT(ActionBarMiddle:BOTTOMLEFT())
        .new()

    ActionBarRight = ActionBar
        :TOPLEFT(ActionBarMiddle:TOPRIGHT())
        :BOTTOMLEFT(ActionBarMiddle:BOTTOMRIGHT())
        .new()

    local bars = { Action=ActionBarMiddle,
                   MultiBarBottomLeft=ActionBarLeft,
                   MultiBarBottomRight=ActionBarRight }

    local hidehooks = {
        OnEnter = function()
            for _, bar in pairs(bars) do
                bar.AnimMouse = 0
                bar.AnimTarget = 0
            end
        end,
        OnLeave = function()
            for _, bar in pairs(bars) do
                bar.AnimMouse = 1
                bar.AnimTarget = bar.AnimShowgrid == 0 and 0 or bar.AnimMouse
            end
        end,
    }

    addon:Hook {
        OnUpdate = function(self, dt)
            for _, bar in pairs(bars) do
                for _, btn in ipairs(bar.ArtFrame.Buttons) do
                    if btn.AnimProgress ~= btn.AnimTarget or btn.AnimProgress > 0 and bar.AnimProgress < 1 then
                        local sign = btn.AnimProgress >= btn.AnimTarget and -1 or 1
                        btn.AnimProgress = math.min(1, math.max(0, btn.AnimProgress + sign * dt*5))
                        local anim = bar.AnimProgress^2
                        local anim2 = math.sqrt(btn.AnimProgress)
                        
                        local from, toG, to, x, y = btn.original:GetPoint()
                        btn:SetPoint(from, toG == prev and bar.ArtFrame[prevname] or bar.ArtFrame, to, x, y + math.max(anim2 - 1 + anim, 0)*60)
                    end
                end

            end
        end
    }

    local function update_buttons()
        for barn, bar in pairs(bars) do
            range_apply(barn .. 'Button', 1, 12, function(i, name, btn, prevname, prev)
                local type, id = GetActionInfo(btn.action)
                if not id then
                    return
                end
                local start, duration, enable, modRate = GetActionCooldown(btn.action)
                local fs = btn.cooldown'.FontString'[1]
                local text = fs:GetText()
                btn.inCooldown =
                    type == 'spell' and enable == 0
                    or duration > 0 and text and fs:IsShown() and #text > 0

                bar.ArtFrame[name].AnimTarget = (IN_GLOW[id] or btn.inCooldown) and 1 or 0
            end)
        end
    end

    addon:EventHook {
        SPELL_ACTIVATION_OVERLAY_GLOW_SHOW = function(self, id)
            IN_GLOW[id] = true
            update_buttons()
        end,
        SPELL_ACTIVATION_OVERLAY_GLOW_HIDE = function(self, id)
            IN_GLOW[id] = false
            update_buttons()
        end,
        ACTIONBAR_SHOWGRID = function()
            for barn, bar in pairs(bars) do
                bar.AnimShowgrid = 0
                bar.AnimTarget = 0
            end
        end,
        ACTIONBAR_HIDEGRID = function()
            for barn, bar in pairs(bars) do
                bar.AnimShowgrid = 1
                bar.AnimTarget = bar.AnimMouse == 0 and 1 or bar.AnimShowgrid
            end
        end,
        SPELL_UPDATE_COOLDOWN = update_buttons,
        SPELL_UPDATE_USABLE = update_buttons
    }

    for barn, bar in pairs(bars) do
        
        bar:Hook(hidehooks)

        bar {
            Frame'.ArtFrame'
                .init { Buttons = {} }
        }

        bar {
            Style'.ArtFrame'
                :AllPoints(bar)
            {
                Texture'.Bg'
                    :Texture(MainMenuBar.ArtFrame.Background.BackgroundLarge:GetTexture())
                    :DrawLayer 'BACKGROUND'
                    :VertexColor(0.7, 0.7, 0.7)
                    :TOPLEFT(bar.ArtFrame:TOPLEFT(0, 6.5))
                    :BOTTOMRIGHT(bar.ArtFrame:BOTTOMRIGHT(0, -0.5))
                    :TexCoord(0.162, 0.6535, 0.394, 0.587)
            },
            
            Frame'.ArtShadow'
                :FrameStrata 'BACKGROUND'
            {
                Texture'.Shadow'
                    :Texture 'Interface/Common/ShadowOverlay-Bottom'
                    :BOTTOMLEFT(bar:BOTTOMLEFT(0, -1))
                    :BOTTOMRIGHT(bar:BOTTOMRIGHT(0, -1))
                    :Height(100)
            }
        }

        local outer = 2.5
        local inner = 7
        local btn_width = (bar_width - outer*2 - inner*11)/12

        range_apply(barn .. 'Button', 1, 12, function(i, name, btn, prevname, prev)
            
            btn:Hook(hidehooks)

            btn {
                Points = {prev and { BOTTOMLEFT = bar:BOTTOMLEFT(outer+(i-1)*(btn_width+inner), outer) }
                                or { BOTTOMLEFT = bar:BOTTOMLEFT(outer, outer) }},
                Size = { btn_width, btn_width },

                MaskTexture'.Mask'
                    :TOPLEFT(btn.icon:TOPLEFT())
                    :BOTTOMRIGHT(btn.icon:BOTTOMRIGHT())
                    :SetTexture('Interface/AddOns/silver-ui/art/actionbutton-mask')
                    .init(function(self)
                        btn.icon:AddMaskTexture(self)
                    end),

                Style'.NormalTexture':Texture '',

                Style'.icon':TexCoord(0.1, 0.9, 0.1, 0.9),

                Style'.HotKey':Font('Fonts/ARIALN.TTF', 14, 'OUTLINE')
            }

            bar.ArtFrame {
                Frame('.' .. name)
                    :BOTTOMLEFT(btn:BOTTOMLEFT())
                    :Size(btn:GetSize())
                    .init(function(self, parent)
                        self.original = btn
                        self.AnimProgress = 0
                        self.AnimTarget = 0
                        table.insert(parent.Buttons, self)
                    end)
            }

            local from, toG, to, x, y = btn:GetPoint()
            bar.ArtFrame[name]:SetPoint(from, toG == prev and bar.ArtFrame[prevname] or bar.ArtFrame, to, x, y)

            for a in btn'.*' do
                for i = 1, a:GetNumPoints() do
                    local from, toG, to, x, y = a:GetPoint(i)
                    if toG == btn then
                        a:SetPoint(from, bar.ArtFrame[name], to, x, y)
                    end
                end
            end

            btn:Show()

        end)

    end

	MainMenuBar.IsUserPlaced = function() return true end
    MicroButtonAndBagsBar.IsUserPlaced = function() return true end
    MultiBarBottomLeft.ignoreFramePositionManager = true

    MainMenuBar {
        Style'.ArtFrame' {
            Style'.ActionBarDownButton':Hide(),
            Style'.ActionBarUpButton':Hide(),
            Style'.PageNumber':Hide(),
            Style'.Background':Hide(),
            Style'.RightEndCap':Hide(),
            Style'.LeftEndCap':Hide(),
        }
    }

    StatusTrackingBarManager:UnregisterAllEvents()
    StatusTrackingBarManager:Hide()

end


style_bars()

-- for _, bar in pairs({ MultiBarBottomLeft, MultiBarBottomRight }) do
--     bar:Hook {
--         OnShow = style_bars,
--         OnHide = style_bars
--     }
-- end

