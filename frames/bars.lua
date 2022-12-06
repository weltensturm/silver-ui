
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

local SELF, PARENT, Style, Frame, Cooldown, Texture, MaskTexture, FontString = LQT.SELF, LQT.PARENT, LQT.Style, LQT.Frame, LQT.Cooldown,
      LQT.Texture, LQT.MaskTexture, LQT.FontString


local MInGlow = {}

local MAnim = 0
local MAnimTarget = 0

local MAnimShowgrid = false
local MAnimShowAlways = false
local MAnimMouse = false

local bars = {}

local MSideAlpha = 0
local MSideAlphaTarget = 0


local function UpdateShow()
    MAnimTarget = (MAnimShowgrid or MAnimMouse or MAnimShowAlways) and 0 or 1
end


local addon = Frame
    :EventHooks {
        PLAYER_ENTERING_WORLD = function()
            Style(OrderHallCommandBar)
                :FrameStrata 'LOW'
                .BOTTOM:TOP(UIParent)
            {
                Style'.Background':Texture '',
                Style'.ClassIcon':Texture '',
                Style'.AreaName':Hide(),
                Style'.Currency'.TOPLEFT:TOPLEFT(UIParent, 150, -5)
            }
            Style(MainMenuBar)
                :FrameStrata 'LOW'
                -- .BOTTOM:TOP(UIParent)
            {
                -- Style'.MainMenuExpBar'.BOTTOM:TOP(UIParent, 0, 5),
                Style'.MainMenuExpBar':Strip():EnableMouse(false),
                Style'.MainMenuExpBar.Button':Strip(),
                Style'.MainMenuBarMaxLevelBar.Texture':Texture '':Alpha(0),
                -- Style'.MainMenuBarMaxLevelBar'.BOTTOM:TOP(UIParent, 0, 5),
                -- Style'.ReputationWatchBar'.BOTTOM:TOP(UIParent, 0, 5),
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
                        .BOTTOM:TOP(UIParent, 0, 5),
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


local Cooldown60Charge = Cooldown
    :DrawSwipe(false)
    :DrawBling(false)
    :DrawEdge(true)
    :UseCircularEdge(true)
    :EdgeScale(1.4)
    :EdgeTexture 'Interface/AddOns/silver-ui/art/edge-light'


local StyleActionButton = Style
    :Hooks(MouseHooks)
    .data {
        AnimProgress = 1,
        AnimTarget = 0,
        CooldownCharges = {},
        UpdateShow = function(self)
            local type, id = GetActionInfo(self.action)
            if not id then
                self.AnimTarget = 0
                return
            end
            local start, duration, enable, _ = GetActionCooldown(self.action)
            local inCooldown =
                type == 'spell' and enable == 0
                or duration > 2
                or self.chargeCooldown and self.chargeCooldown:GetCooldownDuration() > 0

            self.AnimTarget = (MInGlow[id] or inCooldown) and 1 or 0
            self:UpdateMinuteSeconds()
        end,
        UpdateMinuteSeconds = function(self)
            local start, duration, enable, _ = GetActionCooldown(self.action)
            if duration > 2 then
                local start60 = start + duration - 60
                local minutes = 0
                while start60 > GetTime() do
                    start60 = start60 - 60
                    minutes = minutes + 1
                end
                self.Cooldown60:Show()
                self.Cooldown60:SetCooldown(start60, 60)
                local fade = minutes > 0 and 0.5 or 1
                if minutes > 0 then
                    self.CooldownMinutes:Show()
                    self.CooldownMinutes:SetCooldown(start + duration - 60*60, 60*60)
                    -- self.CooldownMinutesContainer.CooldownMinutes:Show()
                    -- self.CooldownMinutesContainer.CooldownMinutes:SetText('' .. minutes)
                else
                    self.CooldownMinutes:Hide()
                    -- self.CooldownMinutesContainer.CooldownMinutes:Hide()
                end
            else
                self.Cooldown60:Hide()
                self.CooldownMinutesContainer.CooldownMinutes:Hide()
            end
            for _, v in pairs(self.CooldownCharges) do
                v:Hide()
            end

            local currentCharges, maxCharges, cooldownStart, cooldownDuration, _ = GetActionCharges(self.action)
            local count = maxCharges-currentCharges
            for i=1, count do
                if currentCharges == 0 then i = i + 1 end
                if i > maxCharges then break end
                local start60 = cooldownStart + cooldownDuration*i - 60
                local minutes = 0
                while start60 > GetTime() do
                    start60 = start60 - 60
                    minutes = minutes + 1
                end
                if not self.CooldownCharges[i] then
                    self.CooldownCharges[i] = Cooldown60Charge
                        :Parent(self)
                        .TOPLEFT:TOPLEFT(-1.2, 1.2)
                        .BOTTOMRIGHT:BOTTOMRIGHT(1.2, -1.2)
                        .new()
                end
                self.CooldownCharges[i]:SetCooldown(start60, 60)
            end
        end,
    }
    :Hooks {
        OnUpdate = function(self, dt)
            if self.AnimProgress ~= self.AnimTarget then
                local sign = self.AnimProgress >= self.AnimTarget and -1 or 1
                self.AnimProgress = math.min(1, math.max(0, self.AnimProgress + sign * dt*5))
                self.Anim = math.sqrt(self.AnimProgress)
            end
            self:SetAlpha(math.max(1-MAnim^2, self.Anim))
        end
    }
    :EventHooks {
        ACTIONBAR_UPDATE_COOLDOWN = SELF.UpdateShow,
        ACTIONBAR_UPDATE_USABLE = SELF.UpdateShow,
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
        -- :SwipeTexture 'Interface/ContainerFrame/BagSlot2x'
        -- :SwipeTexture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
        :SwipeTexture 'Interface/GUILDFRAME/GuildLogoMask_L'
        :SwipeColor(0,0,0,0.5)
        :UseCircularEdge(true)
        :BlingTexture ''
        :DrawBling(false)
        -- :AllPoints(PARENT)
        .TOPLEFT:TOPLEFT(-1.2, 1.2)
        .BOTTOMRIGHT:BOTTOMRIGHT(1.2, -1.2)
        :Hooks {
            OnCooldownDone = function(self)
                self:GetParent():UpdateShow()
            end
        },
    Style'.NormalTexture'
        :VertexColor(0.3, 0.3, 0.3, 0),
    Style'.icon',

    MaskTexture'.IconMask'
        .init(function(self, parent)
            parent.icon:AddMaskTexture(self)
        end)
        :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
        .TOPLEFT:TOPLEFT(-1.2, 1.2)
        .BOTTOMRIGHT:BOTTOMRIGHT(1.2, -1.2),

    Style'.SlotBackground'
        :Texture '',

    Style'.HighlightTexture'
        :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
        :DrawLayer('BACKGROUND', 0)
        :VertexColor(0, 0, 0, 0.3)
        .TOPLEFT:TOPLEFT(-3.5, 3.5)
        .BOTTOMRIGHT:BOTTOMRIGHT(3.5, -3.5),

    Style'.CheckedTexture'
        :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
        :DrawLayer('BACKGROUND', 0)
        :VertexColor(1, 1, 0, 0.5)
        .TOPLEFT:TOPLEFT(-3.5, 3.5)
        .BOTTOMRIGHT:BOTTOMRIGHT(3.5, -3.5),

    Style'.PushedTexture'
        -- :Texture 'Interface/CHARACTERFRAME/TempPortraitAlphaMask'
        :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
        :DrawLayer('BACKGROUND', 1)
        :Hooks {
            OnShow = function(self)
                self:SetTexture 'Interface/GUILDFRAME/GuildLogoMask_L'
                self:SetDrawLayer 'BACKGROUND'
            end
        }
        :VertexColor(1, 1, 0, 0.7)
        .TOPLEFT:TOPLEFT(-3.5, 3.5)
        .BOTTOMRIGHT:BOTTOMRIGHT(3.5, -3.5),
    
    Cooldown'.Cooldown60'
        .TOPLEFT:TOPLEFT(-1.2, 1.2)
        .BOTTOMRIGHT:BOTTOMRIGHT(1.2, -1.2)
        :DrawSwipe(false)
        :DrawBling(false)
        :DrawEdge(true)
        :UseCircularEdge(true)
        :EdgeTexture('Interface/AddOns/silver-ui/art/edge')
        :EdgeScale(1.4)
        :Hooks {
            OnCooldownDone = function(self)
                local parent = self:GetParent()
                local start, duration = GetActionCooldown(parent.action)
                if duration > 2 then
                    parent:UpdateMinuteSeconds()
                end
            end
        },
    
    Cooldown'.CooldownMinutes'
        .TOPLEFT:TOPLEFT(-1.2, 1.2)
        .BOTTOMRIGHT:BOTTOMRIGHT(1.2, -1.2)
        :DrawSwipe(false)
        :DrawBling(false)
        :DrawEdge(true)
        :UseCircularEdge(true)
        :EdgeTexture('Interface/AddOns/silver-ui/art/edge-minute')
        :EdgeScale(1.4),

    Frame'.CooldownMinutesContainer'
        :AllPoints(PARENT)
        :FrameLevel(5)
    {
        FontString'.CooldownMinutes'
            .CENTER:CENTER()
            :Font('Fonts/ARIALN.ttf', 16, 'OUTLINE')
            :JustifyH 'CENTER'
            :Hide()
    }

}



local bars = {
    MainMenuBar,
    MultiBarBottomLeft,
    MultiBarBottomRight,
    MultiBarLeft,
    MultiBarRight,
    MultiBar5,
    MultiBar6,
    MultiBar7,
}


hooksecurefunc('ActionButton_UpdateCooldown', function(button)
    button.cooldown:SetSwipeColor(0,0,0,0)
    -- button.cooldown:SetEdgeTexture('Interface/AddOns/silver-ui/art/edge')
    -- button.cooldown:SetDrawEdge(true)
    -- button.cooldown:SetEdgeScale(1.4)
    if button.UpdateMinuteSeconds then
        button:UpdateMinuteSeconds()
    end
    if button.chargeCooldown then
        button.chargeCooldown:SetDrawEdge(false) -- SetEdgeTexture('Interface/AddOns/silver-ui/art/edge-light')
    end
end)

hooksecurefunc('ActionButtonCooldown_OnCooldownDone', function(button)
    if button.UpdateShow then
        button:UpdateShow()
    end
end)

for _, bar in pairs(bars) do
    bar {
        StyleActionButton'.CheckButton'
    }
end
