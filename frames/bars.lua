
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local Style, Frame, Texture, MaskTexture, FontString = LQT.Style, LQT.Frame, LQT.Texture, LQT.MaskTexture, LQT.FontString


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
    :EventHooks {
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
            Style(MainMenuBar)
                :FrameStrata 'LOW'
                -- :Points { BOTTOM = UIParent:TOP() }
            {
                -- Style'.MainMenuExpBar':Points {
                --     BOTTOM = UIParent:TOP(0, 5)
                -- },
                Style'.MainMenuExpBar':Strip():EnableMouse(false),
                Style'.MainMenuExpBar.Button':Strip(),
                Style'.MainMenuBarMaxLevelBar.Texture':Texture '':Alpha(0),
                -- Style'.MainMenuBarMaxLevelBar':Points {
                --     BOTTOM = UIParent:TOP(0, 5)
                -- },
                -- Style'.ReputationWatchBar':Points {
                --     BOTTOM = UIParent:TOP(0, 5)
                -- },
                Style'.ArtFrame' {
                    -- Style'.CharacterBag#Slot':Hide(),
                    -- Style'.MainMenuBarBackpackButton':Hide(),
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
    Style'.CheckButton'
        :Hooks {
            OnEnter = function() MSideAlphaTarget = 1 end,
            OnLeave = function() MSideAlphaTarget = 0 end
        }
    {
        Style'.cooldown'
            :DrawBling(false)
    }
}

StyleRightBar(MultiBarRight)
StyleRightBar(MultiBarLeft)


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


local bars = { Action='',
               MultiBarBottomLeft='',
               MultiBarBottomRight='' }


hooksecurefunc('ActionButton_UpdateCooldown', function(button)
    button.cooldown:SetSwipeColor(1,1,1,0.5)
end)


for barname, bar in pairs(bars) do

    RangeApply(barname .. 'Button', 1, 12, function(i, name, btn, prevname, prev)

        Style(btn)
            :Hooks(MouseHooks)
            .data {
                AnimProgress = 1,
                AnimTarget = 0,
                UpdateShow = function(self)
                    local type, id = GetActionInfo(self.action)
                    if not id then
                        return
                    end
                    local start, duration, enable, modRate = GetActionCooldown(self.action)
                    self.inCooldown =
                        type == 'spell' and enable == 0
                        or duration > 2
                        or self.chargeCooldown and self.chargeCooldown:GetCooldownDuration() > 0
        
                    self.AnimTarget = (MInGlow[id] or self.inCooldown) and 1 or 0
                end
            }
            :Hooks {
                OnUpdate = function(self, dt)
                    if self.AnimProgress ~= self.AnimTarget or self.AnimProgress > 0 or MAnim > 0 then
                        local sign = self.AnimProgress >= self.AnimTarget and -1 or 1
                        self.AnimProgress = math.min(1, math.max(0, self.AnimProgress + sign * dt*5))
                        local anim = MAnim^2
                        local anim2 = math.sqrt(self.AnimProgress)
                        self:SetAlpha(math.max(anim2, 1-anim))
                    end
                end
            }
            :EventHooks {
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
        {
            Style'.cooldown'
                :SwipeTexture 'Interface/ContainerFrame/BagSlot2x'
                :BlingTexture ''
                :DrawBling(false),
            Style'.NormalTexture'
                :VertexColor(0.3, 0.3, 0.3, 1)
        }

    end)

end
