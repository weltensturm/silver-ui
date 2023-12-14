---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local query = LQT.query
local Script = LQT.Script
local Event = LQT.Event
local PARENT = LQT.PARENT
local Style = LQT.Style
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture
local FontString = LQT.FontString


local load

local _, db = SilverUI.Storage {
    name = 'Menu Bar',
    character = {
        enabled = true
    },
    onload = function(account, character)
        if character.enabled then
            load()
        end
    end
}


SilverUI.Settings 'Menu Bar' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Menu Bar',

    Addon.CheckBox
        :Label 'Enable'
        :Get(function(self) return db.enabled end)
        :Set(function(self, value) db.enabled = value end),

}


local alpha = 0.1
local alphaTarget = 0

local AlphaHooks = Style {
    [Script.OnEnter] = function() alphaTarget = 1 end,
    [Script.OnLeave] = function() alphaTarget = 0 end,
}

local scale = UIParent:GetEffectiveScale()


local TopMenu = Frame { AlphaHooks }
    .TOPLEFT:TOPLEFT(UIParent)
    .TOPRIGHT:TOPRIGHT(UIParent)
    :Height(24)
    :FrameStrata 'MEDIUM'
{
    Bg = Texture
        .TOPLEFT:TOPLEFT()
        .TOPRIGHT:TOPRIGHT()
        :DrawLayer 'ARTWORK'
        :Texture 'Interface/Common/ShadowOverlay-Top'
        :Height(80)
}
    .new()


local ICON_SIZE = 32


local MenuButton = Style { AlphaHooks }
    :ClearAllPoints()
    :Size(ICON_SIZE, ICON_SIZE)
    :Parent(TopMenu)
    :HitRectInsets(0, 0, 0, 0)
{
    [Script.OnEnter] = function(self)
        self.Hover.Bg:Show()
    end,
    [Script.OnLeave] = function(self)
        self.Hover.Bg:Hide()
    end,

    ['.Texture'] = Style
        .CENTER:CENTER()
        :Size(ICON_SIZE, ICON_SIZE),
        -- :TexCoord(0.1, 0.9, 0.1, 0.9),

    Hover = Frame {
        function(self) self:SetAllPoints(self:GetParent()) end,
        Bg = Texture
            :ColorTexture(1, 1, 1, 0.1)
            :Hide()
            { function(self) self:SetAllPoints(self:GetParent()) end },
    },

    Mask = MaskTexture
        :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
        :AllPoints(PARENT)
    {
        function(self, parent)
            if parent then
                query(parent, '.Texture'):AddMaskTexture(self)
            end
        end
    },

}


local SEPARATOR = {}

local LAYOUT_LEFT = {
    CharacterMicroButton,
    TalentMicroButton,
    SpellbookMicroButton,
    SEPARATOR,
    AchievementMicroButton,
    CollectionsMicroButton,
    SEPARATOR,
    EJMicroButton,
    LFDMicroButton,
    LFGMicroButton,
    GuildMicroButton,
    QuickJoinToastButton or SocialsMicroButton,
    PVPMicroButton,
}

local LAYOUT_RIGHT = {
    MainMenuMicroButton,
    GameTimeFrame,
    SEPARATOR,
    KeyRingButton,
    MainMenuBarBackpackButton,
    CharacterBag0Slot,
    CharacterBag1Slot,
    CharacterBag2Slot,
    CharacterBag3Slot,
    CharacterReagentBag0Slot
}

local function layout()
    local x = QuestLogMicroButton:GetRight()
    for i=1, #LAYOUT_LEFT do
        if LAYOUT_LEFT[i] == SEPARATOR then
            x = x + 4
        elseif LAYOUT_LEFT[i] then
            local frame = LAYOUT_LEFT[i]
            frame:ClearAllPoints()
            frame:SetPoint('TOPLEFT', TopMenu, 'TOPLEFT', x, -2)
            x = x + frame:GetWidth()
        end
    end

    x = 0
    for i=1, #LAYOUT_RIGHT do
        if LAYOUT_RIGHT[i] == SEPARATOR then
            x = x + 4
        elseif LAYOUT_RIGHT[i] then
            local frame = LAYOUT_RIGHT[i]
            frame:ClearAllPoints()
            frame:SetPoint('TOPRIGHT', TopMenu, 'TOPRIGHT', -x, -2)
            x = x + frame:GetWidth()
        end
    end
end


local style = function()

    Style(MainMenuBar) {
        ['.MicroButtonAndBagsBar'] = Style:Hide()
    }

    AlphaHooks(QuestLogMicroButton)
        .TOPLEFT:TOPLEFT(TopMenu, 4, -2)
        :Height(26)
        -- :Width(QuestLogMicroButton.ButtonText:GetWidth() + ICON_SIZE)
        :HitRectInsets(0, 0, 0, 0)
        :NormalTexture 'Interface/QUESTFRAME/AutoQuest'
        :HighlightTexture 'Interface/QUESTFRAME/AutoQuest'
        :PushedTexture 'Interface/QUESTFRAME/AutoQuest'
        :Parent(TopMenu)
        {
            ['.Texture'] = Style
                .TOPLEFT:TOPLEFT(1, -1)
                :Size(24, 28)
                :SetTexCoord(0.1, 0.5, 0.05, 0.5),
            ButtonText = FontString
                .LEFT:LEFT(24, 0)
                :Font('FONTS/FRIZQT__.ttf', 12)
                :Text(PARENT.tooltipText),
            function(self)
                self:SetWidth(self.ButtonText:GetRight() - self:GetLeft() + 10)
            end
        }

    MenuButton(CharacterMicroButton) {
        BgLeft = Texture
            :ColorTexture(0.2, 0.2, 0.2)
            .TOPLEFT:TOPLEFT(-5, 0)
            .BOTTOMLEFT:BOTTOMLEFT(-5, 0)
            :Width(0.75/scale),
    }

    MenuButton(TalentMicroButton) {
        ['.Texture'] = Style:SetTexCoord(0.1, 0.9, 0.4, 1)
    }

    MenuButton(SpellbookMicroButton)

    if AchievementMicroButton then
        MenuButton(AchievementMicroButton) {
            ['.BgLeft'] = Texture
                :ColorTexture(0.2, 0.2, 0.2)
                .TOPLEFT:TOPLEFT(-5, 0)
                .BOTTOMLEFT:BOTTOMLEFT(-5, 0)
                :Width(0.75/scale),
        }
    end

    if CollectionsMicroButton then
        MenuButton(CollectionsMicroButton)
    end

    if EJMicroButton then
        MenuButton(EJMicroButton) {
            ['.Texture'] = Style:TexCoord(0.1, 0.9, 0.2, 0.8)
        }
    end

    if LFDMicroButton then
        MenuButton(LFDMicroButton) {
            ['.Texture'] = Style:TexCoord(0.1, 0.9, 0.2, 0.8)
        }
    end

    if LFGMicroButton then
        MenuButton(LFGMicroButton) {
            ['.Texture'] = Style:SetTexCoord(0.1, 0.9, 0.45, 0.9)
        }
    end

    if GuildMicroButton then
        MenuButton(GuildMicroButton) {
            ['.Texture'] = Style:TexCoord(0.1, 0.9, 0.2, 0.8)
        }
    end

    MenuButton(QuickJoinToastButton or SocialsMicroButton) {
        ['.Texture'] = Style:TexCoord(0.1, 0.9, 0.1, 0.9):Texture(FriendsFrameIcon:GetTexture())
    }

    if PVPMicroButton then
        MenuButton(PVPMicroButton) {
            ['.texture'] = Style:TexCoord(0.03,0.64,0,0.6)
        }
    end

    MenuButton(MainMenuMicroButton)

    MenuButton(GameTimeFrame)

    if KeyRingButton then
        MenuButton(KeyRingButton)
    end

    if StoreMicroButton then
        Style(StoreMicroButton)
            .BOTTOMLEFT:TOPLEFT(UIParent)
    end

    MenuButton(MainMenuBarBackpackButton) {
        ['.*NormalTexture'] = Style:Texture ''
    }

    Style(MainMenuBarArtFrame or BagsBar) {
        ['.CharacterBag#Slot, .CharacterReagentBag0Slot'] = MenuButton {
            ['.NormalTexture, .*NormalTexture'] = Style
                :Texture ''
                :Hide()
                :Alpha(0),
        },
        ['.BagBarExpandToggle'] = Style:Hide()
    }

    layout()

end


load = function()
    local doUpdate = false


    if BagsBar then
        hooksecurefunc(BagsBar, 'Layout', function() doUpdate = true end)
    end

    Frame {
        [Event.PLAYER_ENTERING_WORLD] = function()
            doUpdate = true
        end,
        [Script.OnUpdate] = function(self, dt)
            if doUpdate then
                doUpdate = false
                style()
            end

            if alpha ~= alphaTarget then
                local sign = alpha >= alphaTarget and -1 or 1
                alpha = math.min(1, math.max(0, alpha + sign * dt*5))
                local anim = math.sqrt(alpha)
                TopMenu:SetAlpha(anim)
            end
        end
    }
        .new()
end
