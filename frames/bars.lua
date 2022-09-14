local _, ns = ...
local lqt = ns.lqt


local Style, Frame, Texture, MaskTexture, FontString = lqt.Style, lqt.Frame, lqt.Texture, lqt.MaskTexture, lqt.FontString


local BG_TEXTURE = nil
local BG_TEXCOORD = nil

if not MainMenuBar.ArtFrame then
    MainMenuBar.ArtFrame = MainMenuBarArtFrame
    BG_TEXTURE = 'Interface/MAINMENUBAR/MainMenuBar'
    -- BG_TEXTURE = MainMenuBarTexture0:GetTexture()
    BG_TEXCOORD = { 249/1024, (249+504)/1024, 117/256, (117+49)/256 }
    -- BG_TEXCOORD = { 0, 1, 0, 1 }
else
    BG_TEXTURE = MainMenuBar.ArtFrame.Background.BackgroundLarge:GetTexture()
    BG_TEXCOORD = { 0.162, 0.6535, 0.394, 0.587 }
end

MainMenuBar.IsUserPlaced = function() return true end
if MicroButtonAndBagsBar then
    MicroButtonAndBagsBar.IsUserPlaced = function() return true end
    MicroButtonAndBagsBar:Hide()
end
MultiBarBottomLeft.ignoreFramePositionManager = true

if StatusTrackingBarManager then
    StatusTrackingBarManager:UnregisterAllEvents()
    StatusTrackingBarManager:Hide()
end


local MInGlow = {}

local MAnim = 0
local MAnimTarget = 0

local MAnimShowgrid = false
local MAnimShowAlways = false
local MAnimMouse = false

local bars = {}

local MSideAlpha = 0
local MSideAlphaTarget = 0


local function RangeApply(name, start, end_, fn)
    for i = start, end_ do
        local btn = _G[name .. i]
        local prev = _G[name .. i-1]
        fn(i, name .. i, btn, name .. i-1, prev)
    end
end


local function UpdateShow()
    MAnimTarget = (MAnimShowgrid or MAnimMouse or MAnimShowAlways) and 0 or 1
end


local addon = Frame
    :EventHook {
        PLAYER_ENTERING_WORLD = function()
            Style(OrderHallCommandBar)
                :FrameStrata 'LOW'
                :Points {
                    BOTTOM = UIParent:TOP()
                }
            {
                Style'.Background':Texture '',
                Style'.ClassIcon':Texture '',
                Style'.AreaName':Hide(),
                Style'.Currency':Points {
                    TOPLEFT = UIParent:TOPLEFT(150, -5)
                }
            }
            Style(MainMenuBar):FrameStrata 'LOW' {
                Style'.MainMenuExpBar':Points {
                    BOTTOM = UIParent:TOP(0, 5)
                },
                Style'.MainMenuBarMaxLevelBar':Points {
                    BOTTOM = UIParent:TOP(0, 5)
                },
                Style'.ArtFrame' {
                    Style'.CharacterBag#Slot':Hide(),
                    Style'.MainMenuBarBackpackButton':Hide(),
                    Style'.ActionBarDownButton':Hide(),
                    Style'.ActionBarUpButton':Hide(),
                    Style'.PageNumber':Hide(),
                    Style'.Background':Hide(),
                    Style'.RightEndCap':Hide(),
                    Style'.LeftEndCap':Hide(),
                    Style'.FontString':Hide(),
                    Style'.Texture'
                        :Texture ''
                        :Atlas ''
                        :Points { BOTTOM = UIParent:TOP(0, 5) },
                }
            }            
        end,
        ACTIONBAR_SHOWGRID = function()
            MAnimShowgrid = true
            UpdateShow()
        end,
        ACTIONBAR_HIDEGRID = function()
            MAnimShowgrid = false
            UpdateShow()
        end,
        CVAR_UPDATE = function(self, ...)
            MAnimShowAlways = C_CVar.GetCVar("alwaysShowActionBars") == '1'
            UpdateShow()
        end
    }
    :Hooks {
        OnUpdate = function(self, dt)
            if MSideAlpha ~= MSideAlphaTarget then
                local sign = MSideAlpha >= MSideAlphaTarget and -1 or 1
                MSideAlpha = math.min(1, math.max(0, MSideAlpha + sign * dt*5))
                local anim = MSideAlpha^2
                MultiBarRight:SetAlpha(anim)
                MultiBarLeft:SetAlpha(anim)
            end

            if MAnim ~= MAnimTarget then
                local sign = MAnim >= MAnimTarget and -1 or 1
                MAnim = math.min(1, math.max(0, MAnim + sign * dt*5))
            end
        end
    }
    .new()


local StyleRightBar = Style
    :Alpha(0)
    :Hooks {
        OnEnter = function() MSideAlphaTarget = 1 end,
        OnLeave = function() MSideAlphaTarget = 0 end
    }
{
    Style'.CheckButton':Hooks {
        OnEnter = function() MSideAlphaTarget = 1 end,
        OnLeave = function() MSideAlphaTarget = 0 end
    }
}

StyleRightBar(MultiBarRight)
StyleRightBar(MultiBarLeft)



local bar_width = UIParent:GetWidth()/3 -- UIParent:GetWidth()/3/12/3*2


local MouseHooks = {
    OnEnter = function()
        MAnimMouse = true
        UpdateShow()
    end,
    OnLeave = function()
        MAnimMouse = false
        UpdateShow()
    end,
}


local FrameActionBar = Frame
    .init {
        Anim = 1,
        SetButtonPrefix = function(self, prefix)
            self.ButtonPrefix = prefix
        end
    }
    :Size(bar_width, bar_width/12)
    :FrameStrata 'LOW'
    :FrameLevel(2)
    :Hooks(MouseHooks)
    :Hooks {
        OnUpdate = function(self, dt)
            if self.Anim ~= MAnim then
                self.Anim = MAnim
                local anim = MAnim^2
                self.ArtFrame:SetPoints { BOTTOMLEFT = self:BOTTOMLEFT(0, -anim*60),
                                          TOPRIGHT = self:TOPRIGHT(0, -anim*60) }
            end
        end
    }
{
    Frame'.ArtFrame'
        .init(function(self, parent)
            self:SetAllPoints(parent)
        end)
    {
        Texture'.Bg'
            :Texture(BG_TEXTURE)
            :DrawLayer 'BACKGROUND'
            :VertexColor(0.7, 0.7, 0.7)
            :TexCoord(unpack(BG_TEXCOORD))
            .init(function(self, parent)
                self:Points {
                    TOPLEFT = parent:TOPLEFT(0, 6.5),
                    BOTTOMRIGHT = parent:BOTTOMRIGHT(0, -0.5)
                }
            end)
    },

    Frame'.ArtShadow'
        :FrameStrata 'BACKGROUND'
    {
        Texture'.Shadow'
            :Texture 'Interface/Common/ShadowOverlay-Bottom'
            :Height(100)
            .init(function(self, parent)
                self:Points {
                    BOTTOMLEFT = parent:GetParent():BOTTOMLEFT(0, -1),
                    BOTTOMRIGHT = parent:GetParent():BOTTOMRIGHT(0, -1)
                }
            end)
    }
}


local ActionBarMiddle = FrameActionBar
    :ButtonPrefix 'ActionButton'
    :Points { BOTTOM = UIParent:BOTTOM(0, 0.5) }
    .new()

local ActionBarLeft = FrameActionBar
    :ButtonPrefix 'MultiBarBottomLeftButton'
    :Points { TOPRIGHT = ActionBarMiddle:TOPLEFT(),
              BOTTOMRIGHT = ActionBarMiddle:BOTTOMLEFT() }
    .new()

local ActionBarRight = FrameActionBar
    :ButtonPrefix 'MultiBarBottomRightButton'
    :Points { TOPLEFT = ActionBarMiddle:TOPRIGHT(),
              BOTTOMLEFT = ActionBarMiddle:BOTTOMRIGHT() }
    .new()


bars = { Action=ActionBarMiddle,
         MultiBarBottomLeft=ActionBarLeft,
         MultiBarBottomRight=ActionBarRight }


for barname, bar in pairs(bars) do

    local BTN_OUTER = 2.5
    local BTN_INNER = 7
    local BTN_WIDTH = (bar_width - BTN_OUTER*2 - BTN_INNER*11)/12

    RangeApply(barname .. 'Button', 1, 12, function(i, name, btn, prevname, prev)

        Style(btn)
            :Hooks(MouseHooks)
            :Points(prev and { BOTTOMLEFT = bar:BOTTOMLEFT(BTN_OUTER+(i-1)*(BTN_WIDTH+BTN_INNER), BTN_OUTER) }
                          or { BOTTOMLEFT = bar:BOTTOMLEFT(BTN_OUTER, BTN_OUTER) })
            :Size(BTN_WIDTH, BTN_WIDTH)
            -- :FrameStrata('MEDIUM', 1)
        {
            MaskTexture'.Mask'
                :Texture 'Interface/AddOns/silver-ui/art/actionbutton-mask'
                .init(function(self, parent)
                    parent.icon:AddMaskTexture(self)
                    self:SetAllPoints(parent.icon)
                end),

            Style'.NormalTexture':Texture '',

            Style'.icon':TexCoord(0.1, 0.9, 0.1, 0.9):Desaturated(true),

            Style'.HotKey':Font('Fonts/ARIALN.TTF', 14, 'OUTLINE'),

            Style('.*FloatingBG'):Texture '',

            Style'.cooldown'
                :SwipeTexture 'Interface/AddOns/silver-ui/art/actionbutton-mask'
                :SwipeColor(1,1,1,0.5)
                -- :SetSwipeTexture 'Interface/BUTTONS/UI-Quickslot-Depress'               
                -- :SetSwipeColor(0.5,0,0,1)
        }

        bar.ArtFrame {
            Frame('.' .. name .. 'Art')
                :Points { BOTTOMLEFT = btn:BOTTOMLEFT() }
                :Size(btn:GetSize())
                .init {
                    function(self, parent)
                        self.original = btn
                        self.AnchorTo = toFrame == prev and bar.ArtFrame[prevname .. 'Art'] or bar.ArtFrame
                        self.Bar = bar
                        self.BtnFontString = btn.cooldown'.FontString'[1]
                        local from, _, to, x, y = btn:GetPoint()
                        self:SetPoint(from, self.AnchorTo, to, x, y)
                        for a in btn'.*' do
                            for i = 1, a:GetNumPoints() do
                                local from, toFrame, to, x, y = a:GetPoint(i)
                                if toFrame == btn then
                                    a:SetPoint(from, self, to, x, y)
                                end
                            end
                        end
                    end,
                    AnimProgress = 0,
                    AnimTarget = 0,
                    UpdateShow = function(self)
                        local btn = self.original
                        local type, id = GetActionInfo(btn.action)
                        if not id then
                            return
                        end
                        local start, duration, enable, modRate = GetActionCooldown(btn.action)
                        btn.inCooldown =
                            type == 'spell' and enable == 0
                            or duration > 2
                            or btn.chargeCooldown and btn.chargeCooldown:GetCooldownDuration() > 0
            
                        self.AnimTarget = (MInGlow[id] or btn.inCooldown) and 1 or 0
                    end
                }
                :Hooks {
                    OnUpdate = function(self, dt)
                        if self.AnimProgress ~= self.AnimTarget or self.AnimProgress > 0 and MAnim < 1 then
                            local sign = self.AnimProgress >= self.AnimTarget and -1 or 1
                            self.AnimProgress = math.min(1, math.max(0, self.AnimProgress + sign * dt*5))
                            local anim = MAnim^2
                            local anim2 = math.sqrt(self.AnimProgress)                            
                            local from, _, to, x, y = self.original:GetPoint()
                            self:SetPoint(from, self.AnchorTo, to, x, y + math.max(anim2 - 1 + anim, 0)*60)
                        end
                    end
                }
                :Event {
                    SPELL_UPDATE_COOLDOWN = function(self) self:UpdateShow() end,
                    SPELL_UPDATE_USABLE = function(self) self:UpdateShow() end,
                    SPELL_ACTIVATION_OVERLAY_GLOW_SHOW = function(self, id)
                        MInGlow[id] = true
                        self:UpdateShow()
                    end,
                    SPELL_ACTIVATION_OVERLAY_GLOW_HIDE = function(self, id)
                        MInGlow[id] = false
                        self:UpdateShow()
                    end,
                }
        }

        btn:Show()

    end)

end
