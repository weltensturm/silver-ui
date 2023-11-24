---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local query = LQT.query
local Script = LQT.Script
local Event = LQT.Event
local Hook = LQT.Hook
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Style = LQT.Style
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture
local FontString = LQT.FontString
local AnimationGroup = LQT.AnimationGroup
local Animation = LQT.Animation

local IsSpellOverlayed = IsSpellOverlayed or function() end

local load

local _, db = SilverUI.Storage {
    name = 'Action Bars',
    character = {
        enabled = true,
        fadeOffCD = true
    },
    onload = function(_, db)
        if db.enabled then
            load()
        end
    end
}


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


local CheckBox = Addon.SettingsWidgets.CheckBox

SilverUI.Settings 'Action Bars' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Action Bars',

    CheckBox
        :Label 'Enable'
        :Get(function(self) return db.enabled end)
        :Set(function(self, value) db.enabled = value end),

    CheckBox
        :Label 'Fade off cooldown'
        :Get(function(self) return db.fadeOffCD end)
        :Set(function(self, value) db.fadeOffCD = value end),

}


-- values do nothing, this is just for getting a secure event on bar change
local BAR_1_ACTION_PAGE = [[
    [overridebar][possessbar]18;
    [shapeshift]17;
    [vehicleui]16;
    [bar:2]2;
    [bar:3]3;
    [bar:4]4;
    [bar:5]5;
    [bar:6]6;
    [bonusbar:1]7;
    [bonusbar:2]8;
    [bonusbar:3]9;
    [bonusbar:4]10;
    [bonusbar:5]11;
    1;
]]


local ActionBarButtonBase = Style
    .constructor(function(parent, globalName, ...)
        local frame = CreateFrame('Button', globalName, parent, 'SecureActionButtonTemplate, SecureHandlerStateTemplate')
        return frame
    end)
    :RegisterForDrag('LeftButton', 'RightButton')
    :Attribute('type', not IsRetail and 'action')
    :Attribute("typerelease", IsRetail and "action")
	:Attribute("flyoutDirection", 'UP')
{

    function(self)
        if IsRetail then
            self:RegisterForClicks('AnyUp', 'AnyDown')
        else
            self:RegisterForClicks('AnyUp')
        end
        self:SetAttribute(
            '_onstate-bar-action-page',
            [[
                local actionpage = self:GetAttribute('actionpage')

                if actionpage == 1 then
                    local actionpage =
                        HasVehicleActionBar() and GetVehicleBarIndex()
                        or HasOverrideActionBar() and GetOverrideBarIndex()
                        or HasTempShapeshiftActionBar() and GetTempShapeshiftBarIndex()
                        or HasBonusActionBar() and GetActionBarPage() == 1 and GetBonusBarIndex()
                        or GetActionBarPage()

                    local index = self:GetAttribute('index')
                    local num_buttons = self:GetAttribute('NUM_ACTIONBAR_BUTTONS')
                    self:SetAttribute('action', (actionpage-1)*num_buttons+index)
                end
            ]]
        )
        RegisterStateDriver(self, 'bar-action-page', BAR_1_ACTION_PAGE)

        self:WrapScript(
            self,
            'OnDragStart',
            [[
                if not IsModifiedClick("PICKUPACTION") then return end
                return 'action', self:GetAttribute('action')
            ]]
        )

        self:WrapScript(
            self,
            'OnReceiveDrag',
            [[
                if self:GetAttribute('action') then
                    return 'action', self:GetAttribute('action')
                else
                    return 'clear'
                end
            ]]
        )

        if IsRetail then
            hooksecurefunc('TryUseActionButton', function(button, state)
                if self.action == button.action then
                    self:UpdatePushed(state)
                end
            end)
        else
            hooksecurefunc('ActionButtonDown', function(id)
                local button = GetActionButtonForID(id)
                if button.action == self.action then
                    self:UpdatePushed(true)
                end
            end)
            hooksecurefunc('ActionButtonUp', function(id)
                local button = GetActionButtonForID(id)
                if button.action == self.action then
                    self:UpdatePushed(false)
                end
            end)
            hooksecurefunc('MultiActionButtonDown', function(bar, id)
                local button = _G[bar .. 'Button' .. id]
                if button.action == self.action then
                    self:UpdatePushed(true)
                end
            end)
            hooksecurefunc('MultiActionButtonUp', function(bar, id)
                local button = _G[bar .. 'Button' .. id]
                if button.action == self.action then
                    self:UpdatePushed(false)
                end
            end)
        end
    end,

    UpdateFlyout = function(self) end,

    UpdatePushed = function(pushed) end,

    UpdateAction = function() end,

    [Script.OnAttributeChanged] = function(self, name, value)
        if name == 'action' and value ~= self.action then
            self.action = value
            self:UpdateAction()
        end
    end,

    Bind = function(self, actionpage, index)
        self.actionpage = actionpage
        self.index = index
        self.keybindBase = self.actionpage == 1 and 'ACTIONBUTTON'
                        or self.actionpage > 11 and ('MULTIACTIONBAR' .. self.actionpage-8 .. 'BUTTON') -- uhhh
                                                 or ('MULTIACTIONBAR' .. 7-self.actionpage .. 'BUTTON') -- ehhh
        self:SetAttribute('actionpage', self.actionpage)
        self:SetAttribute('index', self.index)
        self:SetAttribute('NUM_ACTIONBAR_BUTTONS', NUM_ACTIONBAR_BUTTONS)
        self:SetAttribute('action', self:ActionPageToAction(self.actionpage, self.index))
    end,

    ActionPageToAction = function(self, actionpage, index)
        if actionpage == 1 then
            actionpage =
                HasVehicleActionBar() and GetVehicleBarIndex()
                or HasOverrideActionBar() and GetOverrideBarIndex()
                or HasTempShapeshiftActionBar() and GetTempShapeshiftBarIndex()
                or HasBonusActionBar() and GetActionBarPage() == 1 and GetBonusBarIndex()
                or GetActionBarPage()
        end
        return (actionpage-1)*NUM_ACTIONBAR_BUTTONS + index
    end,

    [Script.OnEnter] = function(self)
        if GameTooltip:IsForbidden() then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetAction(self.action)
        GameTooltip:Show()
    end,

    [Script.OnLeave] = function(self)
        if GameTooltip:IsForbidden() then return end
        GameTooltip:Hide()
    end,

}


local ActionBarButton = ActionBarButtonBase
    :FlattensRenderLayers(true)
    :IsFrameBuffer(true)
{
    [Event.PLAYER_ENTERING_WORLD] = SELF.UpdateAction,
    [Event.ACTIONBAR_SLOT_CHANGED] = function(self, slot)
        if slot == self.action then
            self:UpdateAction()
        end
    end,

    bg = Texture
        .CENTER:CENTER()
        :DrawLayer 'BACKGROUND'
        :Texture 'Interface/AddOns/silver-ui/art/actionbar-bg',

    icon = Texture
        .CENTER:CENTER()
        :DrawLayer('BACKGROUND', 1)
        :ColorTexture(0, 0, 0, 0.7)
        :TexCoord(0.05, 0.95, 0.05, 0.95)
        :AddMaskTexture(PARENT.iconMask),
    iconMask = MaskTexture
        .CENTER:CENTER()
        :Texture 'Interface/AddOns/silver-ui/art/circle',
    UpdateTexture = function(self)
        local type, id, _ = GetActionInfo(self.action)
        self.icon:SetTexture(GetActionTexture(self.action))
        local known = (type ~= 'spell' or IsSpellKnownOrOverridesKnown(id)) and 1 or 0
        self.icon:SetVertexColor(1, known, known)
    end,
    [Event.SPELL_UPDATE_ICON] = SELF.UpdateTexture,
    [Event.SPELLS_CHANGED] = SELF.UpdateTexture,
    [Hook.UpdateAction] = SELF.UpdateTexture,
    [Script.OnSizeChanged] = function(self, w, h)
        local size = max(w, h)
        self.icon:SetSize(size, size)
        -- self.icon:SetPoint('CENTER', self, 'CENTER', 0, -abs(w - h)/4)
        self.bg:SetSize(size, size)
        self.iconMask:SetSize(size, size)
    end,

    -- border = Texture
    --     :AllPoints(PARENT)
    --     :Texture 'Interface/AddOns/silver-ui/art/actionbutton-shadow',

    rangeTimer = 0,
    hotkey = FontString
        .BOTTOMLEFT:BOTTOMLEFT(1, 1)
        -- :Font('Fonts/FRIZQT__.ttf', 12, '')
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, 'OUTLINE')
        -- :Font('Fonts/ARIALN.TTF', 11, '')
        :Alpha(0.9),
    UpdateBinding = function(self)
        local text = GetBindingKey(self.keybindBase .. self.index)
        if text then
            text = text
                :gsub('SHIFT%-', '|cff999999s-|cffffffff')
                :gsub('CTRL%-', '|cff999999c-|cffffffff')
                :gsub('ALT%-', '|cff999999a-|cffffffff')
                :gsub('NUMPAD', 'NUM')
                :gsub('DIVIDE', '/')
                :gsub('MULTIPLY', '*')
                :gsub('ENTER', '↵')
                :gsub('BACKSPACE', 'BS')
                :gsub('CLEAR', 'CL')
                :gsub('DELETE', '␡')
                :gsub('END', '>>')
                :gsub('HOME', '<<')
                :gsub('INSERT', 'Ins')
                :gsub('MOUSEWHEELDOWN', 'WD')
                :gsub('MOUSEWHEELUP', 'WU')
                :gsub('NUMLOCK', 'NL')
                :gsub('PAGEDOWN', 'PD')
                :gsub('PAGEUP', 'PU')
                :gsub('SCROLLLOCK', 'SL')
                :gsub('SPACE', '␣')
                :gsub('TAB', 'Tab')
        end
        self.hotkey:SetText(text)
    end,
    [Event.UPDATE_BINDINGS] = SELF.UpdateBinding,
    UpdateRange = function(self)
        local inRange = IsActionInRange(self.action)
        if inRange or inRange == nil then
            self.hotkey:SetVertexColor(ACTIONBAR_HOTKEY_FONT_COLOR:GetRGB())
        else
            self.hotkey:SetVertexColor(RED_FONT_COLOR:GetRGB())
        end
    end,
    [Script.OnUpdate] = function(self, dt)
        if self.rangeTimer - dt < 0 then
            self.rangeTimer = self.rangeTimer + 0.2
            self:UpdateRange()
        else
            self.rangeTimer = self.rangeTimer - dt
        end
    end,
    [Hook.UpdateAction] = SELF.UpdateBinding,

    charges = FontString
        .TOPRIGHT:TOPRIGHT(-1, -1)
        -- :Font('Fonts/FRIZQT__.ttf', 12, '')
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, 'OUTLINE')
        -- :Font('Fonts/ARIALN.TTF', 11, '')
        :Alpha(0.9),
    UpdateCharges = function(self)
        if
            IsConsumableAction(self.action)
            or IsStackableAction(self.action)
            or (not IsItemAction(self.action) and GetActionCount(self.action) > 0)
        then
            self.charges:SetText(GetActionCount(self.action))
        else
            local charges, maxCharges = GetActionCharges(self.action)
            if maxCharges > 1 then
                self.charges:SetText(charges)
            else
                self.charges:SetText('')
            end
        end
    end,
    [Event.SPELL_UPDATE_CHARGES] = SELF.UpdateCharges,
    [Hook.UpdateAction] = SELF.UpdateCharges,

    UpdateUsable = function(self)
        local isUsable, notEnoughMana = IsUsableAction(self.action);
        -- self.animTarget = isUsable and 0 or 1
        -- self:SetAlpha(isUsable and 1 or 0.5)
    end,
    [Event.ACTIONBAR_UPDATE_USABLE] = SELF.UpdateUsable,

    pushed = Texture
        :AllPoints(PARENT.icon)
        :Texture 'Interface/AddOns/silver-ui/art/ring'
        :Hide(),
    [Hook.UpdatePushed] = function(self, pushed)
        self.pushed:SetShown(pushed)
    end,
    [Script.OnClick] = function(self, button, down)
        self.pushed:SetShown(down)
    end,
    [Script.OnDragStart] = function(self)
        self.pushed:Hide()
    end,

    active = Texture
        :AllPoints(PARENT)
        :ColorTexture(1, 1, 0, 0.2)
        :DrawLayer 'OVERLAY'
        :Hide(),
    UpdateActive = function(self)
        local active = self.pushed or IsAutoRepeatAction(self.action)
        self.active:SetShown(active)
    end,
    -- [Event.START_AUTOREPEAT_SPELL] = SELF.UpdateActive,
    -- [Event.STOP_AUTOREPEAT_SPELL] = SELF.UpdateActive,

}


local Hover = Style {

    hover = Texture
        :AllPoints(PARENT.icon)
        :Texture 'Interface/AddOns/silver-ui/art/ring'
        :SetVertexColor(0.5, 0.5, 0.5, 0.3)
        :Hide(),
    [Script.OnEnter] = function(self)
        self.hover:Show()
    end,
    [Script.OnLeave] = function(self)
        self.hover:Hide()
    end,

}


local Proc = Style {
    proc = false,
    procMask = MaskTexture
        .TOPLEFT:TOPLEFT(-6, 6)
        .BOTTOMRIGHT:BOTTOMRIGHT(6, -6)
        :Texture 'Interface/AddOns/silver-ui/art/proc-1'
    {
        anim = AnimationGroup {
            rotate = Animation.Rotation
                :Duration(360)
                :Radians(-math.pi*60)
        }
    },
    procTexture = Texture
        .TOPLEFT:TOPLEFT(-6, 6)
        .BOTTOMRIGHT:BOTTOMRIGHT(6, -6)
        :Texture 'Interface/AddOns/silver-ui/art/proc-1'
        :AddMaskTexture(PARENT.procMask)
        :VertexColor(1, 1, 1, 1)
        :Hide()
    {
        anim = AnimationGroup {
            rotate = Animation.Rotation
                :Duration(120)
                :Radians(math.pi*60)
        }
    },
    procTexture2 = Texture
        .TOPLEFT:TOPLEFT(-6, 6)
        .BOTTOMRIGHT:BOTTOMRIGHT(6, -6)
        :Texture 'Interface/AddOns/silver-ui/art/proc-2'
        :AddMaskTexture(PARENT.procMask)
        :VertexColor(1, 1, 1, 0.2)
        :BlendMode 'ADD'
        :Hide()
    {
        anim = AnimationGroup {
            rotate = Animation.Rotation
                :Duration(160)
                :Radians(math.pi*60)
        }
    },
    StartProc = function(self)
        self.procTexture.anim:Restart()
        self.procTexture2.anim:Restart()
        self.procMask.anim:Restart()
        self.proc = true
        self.procTexture:Show()
        self.procTexture2:Show()
    end,
    EndProc = function(self)
        self.proc = false
        self.procTexture:Hide()
        self.procTexture2:Hide()
    end,
    [Event.SPELL_ACTIVATION_OVERLAY_GLOW_SHOW] = function(self, spell)
        local _, id, _ = GetActionInfo(self.action)
        if spell == id then
            self:StartProc()
        end
    end,
    [Event.SPELL_ACTIVATION_OVERLAY_GLOW_HIDE] = function(self, spell)
        local _, id, _ = GetActionInfo(self.action)
        if spell == id then
            self:EndProc()
        end
    end,
    [Hook.UpdateAction] = function(self)
        local type, spell, _ = GetActionInfo(self.action)
        if type == 'spell' and spell and IsSpellOverlayed(spell) then
            self:StartProc()
        else
            self:EndProc()
        end
    end,
}


local GlobalFade = 0
local GlobalFadeProgress = 0
local GlobalFadeTarget = 0
local GlobalFadeButton = false
local GlobalFadeGrid = false

local GlobalFadeSystem = Frame {
    [Script.OnUpdate] = function(self, dt)
        if GlobalFadeProgress ~= GlobalFadeTarget then
            local sign = GlobalFadeProgress >= GlobalFadeTarget and -1 or 1
            GlobalFadeProgress = math.min(1, math.max(0, GlobalFadeProgress + sign * dt*5))
            GlobalFade = math.sqrt(GlobalFadeProgress)
        end
    end,
    [Event.ACTIONBAR_SHOWGRID] = function()
        GlobalFadeGrid = true
        GlobalFadeTarget = (GlobalFadeButton or GlobalFadeGrid) and 1 or 0
    end,
    [Event.ACTIONBAR_HIDEGRID] = function()
        GlobalFadeGrid = false
        GlobalFadeTarget = (GlobalFadeButton or GlobalFadeGrid) and 1 or 0
    end,
}


local Fade = Style {
    anim = 0,
    animTarget = 1,
    animProgress = 0,
    animFade = 0,
    animCooldownEnd = 0,
    UpdateFade = function(self)
        if not self.action then return end
        local type, id, _ = GetActionInfo(self.action)
        if not id then
            self.animTarget = db.fadeOffCD and 0 or 1
            return
        end
        local start, duration, enable, _ = GetActionCooldown(self.action)
        self.animCooldownEnd = start + duration
        local currentCharges, maxCharges, cooldownStart, cooldownDuration, _ = GetActionCharges(self.action)
        local inCooldown =
            type == 'spell' and enable == 0
            or duration > 2
            or currentCharges < maxCharges and currentCharges == 0

        local isUsable, notEnoughPower = IsUsableAction(self.action);

        if db.fadeOffCD then
            self.animTarget =
                (self.proc or inCooldown) and 1
                or notEnoughPower and 0.5
                or 0
        else
            self.animTarget = not self.proc and (inCooldown or notEnoughPower) and 0.5 or 1
        end
        self.animFade = duration < 2 and currentCharges < maxCharges and 0.75 or 0
    end,
    [Event.SPELL_UPDATE_COOLDOWN] = SELF.UpdateFade,
    [Event.SPELL_UPDATE_CHARGES] = SELF.UpdateFade,
    [Event.ACTIONBAR_UPDATE_USABLE] = SELF.UpdateFade,
    [Event.ACTIONBAR_SLOT_CHANGED] = function(self, slot)
        if slot == self.action then
            self:UpdateFade()
        end
    end,
    [Script.OnUpdate] = function(self, dt)
        if self.animProgress ~= self.animTarget then
            local sign = self.animProgress >= self.animTarget and -1 or 1
            local new = math.max(sign > 0 and 0 or self.animTarget,
                                 math.min(sign > 0 and self.animTarget or 1,
                                          self.animProgress + sign * dt*5))
            self.animProgress = new
            self.anim = math.sqrt(self.animProgress)
        end
        self:SetAlpha(math.max(self.anim, self.animFade, GlobalFade))
        -- local active = math.max(self.anim, self.animFade, GlobalFade)
        -- self.icon:SetDesaturation(1 - active)
        -- self.icon:SetVertexColor(active*0.5 + 0.5, active*0.5 + 0.5, active*0.5 + 0.5, 1)
        -- self:SetAlpha(0.75 + active*0.25)
        if self.animCooldownEnd <= GetTime() and self.animTarget > 0 then
            self:UpdateFade()
        end
        -- self.icon:SetAlpha(math.max(self.anim, self.animFade, GlobalFade))
    end,
    [Script.OnEnter] = function(self)
        GlobalFadeButton = true
        GlobalFadeTarget = (GlobalFadeButton or GlobalFadeGrid) and 1 or 0
    end,
    [Script.OnLeave] = function(self)
        GlobalFadeButton = false
        GlobalFadeTarget = (GlobalFadeButton or GlobalFadeGrid) and 1 or 0
    end,
    [Hook.UpdateAction] = SELF.UpdateFade,
}



local GreyoutNoPower = Style {
    UpdateGreyout = function(self)
        local isUsable, notEnoughPower = IsUsableAction(self.action);
        self.icon:SetDesaturated(notEnoughPower)
    end,
    [Event.ACTIONBAR_UPDATE_USABLE] = SELF.UpdateGreyout,
    [Event.PLAYER_ENTERING_WORLD] = SELF.UpdateGreyout,
    [Hook.UpdateAction] = SELF.UpdateGreyout
}



local ClockHand = Texture
    :SnapToPixelGrid(false)
    :TexelSnappingBias(0)
    :Texture 'Interface/AddOns/silver-ui/art/edge-light'
    :DrawLayer 'OVERLAY'
    :Scale(10)
    :Hide()
{
    SetClock = function(self, remaining, scale)
        self.Animation.Rotation:SetRadians(math.pi*2 * remaining/scale)
        self.Animation.Rotation:SetDuration(remaining)
        self.Animation:Restart(true)
        self:Show()
    end,
    Animation = AnimationGroup {
        Rotation = Animation.Rotation
    },
}


local ClockCooldown = Style {
    clockCooldownEnd = 0,
    UpdateCooldown = function(self)
        local start, duration, enable, _ = GetActionCooldown(self.action)
        self.clockCooldownEnd = start + duration
        if duration > 2 then
            local remaining = start - GetTime() + duration
            self.CooldownSeconds:SetClock(remaining, 60)
            if remaining > 60 then
                self.CooldownMinutes:SetClock(remaining, 60*60)
            else
                self.CooldownMinutes:Hide()
            end
        else
            self.CooldownSeconds:Hide()
        end
        for _, v in pairs(self.CooldownCharges) do
            v:Hide()
        end

        local currentCharges, maxCharges, cooldownStart, cooldownDuration, _ = GetActionCharges(self.action)
        local count = maxCharges-currentCharges
        for i=1, count do
            if currentCharges == 0 then i = i + 1 end
            if i > maxCharges then break end
            local remaining = cooldownStart - GetTime() + cooldownDuration*i
            if not self.CooldownCharges[i] then
                self.CooldownCharges[i] = ClockHand
                    .TOPLEFT:TOPLEFT(-1.2, 1.2)
                    .BOTTOMRIGHT:BOTTOMRIGHT(1.2, -1.2)
                    .new(self)
            end
            self.CooldownCharges[i]:SetClock(remaining, 60)
        end
    end,
    [Event.ACTIONBAR_UPDATE_COOLDOWN] = SELF.UpdateCooldown,
    [Script.OnUpdate] = function(self)
        if self.clockCooldownEnd <= GetTime() and self.CooldownSeconds:IsShown() then
            self:UpdateCooldown()
        end
    end,

    CooldownSeconds = ClockHand
        :Texture 'Interface/AddOns/silver-ui/art/edge'
        .TOPLEFT:TOPLEFT(-1.2, 1.2)
        .BOTTOMRIGHT:BOTTOMRIGHT(1.2, -1.2),

    CooldownMinutes = ClockHand
        :Texture 'Interface/AddOns/silver-ui/art/edge-minute'
        .TOPLEFT:TOPLEFT(-1.2, 1.2)
        .BOTTOMRIGHT:BOTTOMRIGHT(1.2, -1.2),

    CooldownCharges = {},

}


local ActionBarFrame = Frame {

    padding = 0,

    SetButtonTemplate = function(self, template)
        self.ButtonTemplate = template
    end,
    SetPadding = function(self, padding)
        self.padding = padding
    end,
    SetBar = function(self, bar)
        assert(not self.bar)
        self.bar = bar
        for i=1, 12 do
            self['Button'.. i] =
                self.ButtonTemplate
                    :Bind(bar, i)
                    :Point('BOTTOMLEFT',
                           i > 1 and self['Button'..(i-1)] or self,
                           i > 1 and 'BOTTOMRIGHT' or 'BOTTOMLEFT',
                           self.padding*(i > 1 and 1 or 0), 0)
                    .new(self)
            self['Button' .. i].bar = self
        end
    end,
    UpdateSpellFlyoutDirection = ActionBarMixin.UpdateSpellFlyoutDirection,
    GetSpellFlyoutDirection = ActionBarMixin.GetSpellFlyoutDirection,
    actionButtons = {},

    [Script.OnSizeChanged] = function(self, width, height)
        query(self, '.Button*'):SetSize(width/12 - self.padding/12*11, height)
    end,

    [Script.OnEnter] = function(self)
        GlobalFadeButton = true
        GlobalFadeTarget = (GlobalFadeButton or GlobalFadeGrid) and 1 or 0
    end,
    [Script.OnLeave] = function(self)
        GlobalFadeButton = false
        GlobalFadeTarget = (GlobalFadeButton or GlobalFadeGrid) and 1 or 0
    end,

    -- bg = Texture
    --     :AllPoints(PARENT)
    --     :ColorTexture(0, 0, 0, 0.65),
    -- Shadow = Addon.BoxShadow

}


local StyledActionBarButton = ActionBarButton .. Proc .. ClockCooldown .. Hover .. Fade .. GreyoutNoPower


local TopSmallButton = StyledActionBarButton {
    ['.bg'] = Style:Texture 'Interface/AddOns/silver-ui/art/actionbar-bg-top',
    ['.iconMask'] = Style
        :Texture('Interface/AddOns/silver-ui/art/actionbar-top', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),
    ['.hover'] = Style:Texture 'Interface/AddOns/silver-ui/art/actionbar-top-hover',
    ['.pushed'] = Style:Texture 'Interface/AddOns/silver-ui/art/actionbar-top-hover',
    ['.hotkey'] = Style:ClearAllPoints().BOTTOMLEFT:BOTTOMLEFT(1, -1),
}


local CharacterButton = Style
    .constructor(function(parent, globalName, ...)
        return CreateFrame('Button', globalName, parent, 'SecureActionButtonTemplate')
    end)
    :Attribute('type', 'macro')
    :Attribute('macrotext', '/click CharacterMicroButton')
    :RegisterForClicks('AnyDown')
    :FlattensRenderLayers(true)
    :IsFrameBuffer(true)
{
    fade = 0.001,
    bg = Texture
        :AllPoints()
        :DrawLayer 'BACKGROUND'
        :Texture 'Interface/AddOns/silver-ui/art/actionbar-bg',
    iconMask = MaskTexture
        :Texture 'Interface/AddOns/silver-ui/art/circle'
        .TOPLEFT:TOPLEFT(2, -2)
        .BOTTOMRIGHT:BOTTOMRIGHT(-2, 2),
    icon = Texture
        :AllPoints()
        :ColorTexture(0, 0, 0, 0.7)
        :TexCoord(0.05, 0.95, 0.05, 0.95)
        :AddMaskTexture(PARENT.iconMask),

    UpdatePortrait = function(self)
        SetPortraitTexture(self.icon, 'player')
    end,
    [Event.UNIT_PORTRAIT_UPDATE] = SELF.UpdatePortrait,
    [Event.PORTRAITS_UPDATED] = SELF.UpdatePortrait,
    [Event.PLAYER_ENTERING_WORLD] = SELF.UpdatePortrait,
    [Script.OnUpdate] = function(self, dt)
        if self.fade ~= GlobalFade then
            self.fade = GlobalFade
            self:SetAlpha(GlobalFade)
        end
    end,
    [Script.OnEnter] = function(self)
        GlobalFadeButton = true
        GlobalFadeTarget = (GlobalFadeButton or GlobalFadeGrid) and 1 or 0
    end,
    [Script.OnLeave] = function(self)
        GlobalFadeButton = false
        GlobalFadeTarget = (GlobalFadeButton or GlobalFadeGrid) and 1 or 0
    end,
}
    .. Hover


load = function()

    Frame {
        HideBlizzard = function(self, frame)
            if frame then
                Style(frame):Parent(self)
                --:UnregisterAllEvents()
                if frame.actionButtons then
                    for _, button in pairs(frame.actionButtons) do
                        button:UnregisterAllEvents()
                        button:Hide()
                    end
                end
            end
        end,
    }
        :HideBlizzard(MainMenuBar)
        :HideBlizzard(MultiBarBottomRight)
        :HideBlizzard(MultiBarBottomLeft)
        :HideBlizzard(MultiBar5)
        :Hide()
        .new()

    GlobalFadeSystem.new()

    local size = UIParent:GetWidth()/3

    local ActionBar1 = ActionBarFrame
        :ButtonTemplate(StyledActionBarButton)
        :Bar(1) -- MainMenuBar
        .new()
    PixelUtil.SetPoint(ActionBar1, 'BOTTOMLEFT', UIParent, 'BOTTOM', size/12/2, size/12/2*1/2)
    PixelUtil.SetSize(ActionBar1, size, size/12)

    local ActionBar2 = ActionBarFrame
        :ButtonTemplate(StyledActionBarButton)
        :Bar(6) -- MultiBarBottomLeft
        .RIGHT:LEFT(ActionBar1)
        .new()
    PixelUtil.SetSize(ActionBar2, size, size/12)


    local ActionBar3 = ActionBarFrame
        :ButtonTemplate(TopSmallButton)
        :Bar(5) -- MultiBarBottomRight
        .TOPLEFT:BOTTOMLEFT(ActionBar1, -size/12/2, size/12/2/2)
        :FrameLevel(0)
        .new()
    PixelUtil.SetSize(ActionBar3, size, size/12/2)

    local ActionBar6 = ActionBarFrame
        :ButtonTemplate(TopSmallButton)
        :Bar(13) -- MultiBar5 / Action Bar 6 ?????
        .TOPRIGHT:BOTTOMRIGHT(ActionBar2, -size/12/2, size/12/2/2)
        :FrameLevel(0)
        .new()
    PixelUtil.SetSize(ActionBar6, size, size/12/2)


    local CharacterButton = CharacterButton
        .RIGHT:LEFT(ActionBar2)
        :FrameStrata(ActionBar1:GetFrameStrata())
        :FrameLevel(ActionBar1:GetFrameLevel())
        .new()
    PixelUtil.SetSize(CharacterButton, size/12, size/12)

    Frame
        :AllPoints()
        :FrameStrata 'BACKGROUND'
    {
        Shadow = Texture
            :Texture 'Interface/Common/ShadowOverlay-Bottom'
            :Height(100)
            .BOTTOMLEFT:BOTTOMLEFT(0, -1)
            .BOTTOMRIGHT:BOTTOMRIGHT(0, -1)
    }
        .new()
end
