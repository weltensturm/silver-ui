
local PARENT, Style, Frame, Texture, MaskTexture, FontString = LQT.PARENT, LQT.Style, LQT.Frame, LQT.Texture, LQT.MaskTexture, LQT.FontString


local addon = Frame.new()


local alpha = 0.1
local alphaTarget = 0

local alpha_listeners = {
    OnEnter = function() alphaTarget = 1 end,
    OnLeave = function() alphaTarget = 0 end,
}

local scale = UIParent:GetEffectiveScale()


local TopMenu = Frame
    .TOPLEFT:TOPLEFT(UIParent)
    .TOPRIGHT:TOPRIGHT(UIParent)
    :Height(24)
    :Hooks(alpha_listeners)
    :FrameStrata 'MEDIUM'
{
    Texture'.Bg'
        .TOPLEFT:TOPLEFT()
        .TOPRIGHT:TOPRIGHT()
        :DrawLayer 'ARTWORK'
        :Texture 'Interface/Common/ShadowOverlay-Top'
        :Height(80)
}
    .new()


local SPACING = UIParent:GetWidth() / 9


local ICON_SIZE = 32


local MenuButton = Style
    :ClearAllPoints()
    :Size(ICON_SIZE, ICON_SIZE)
    :Parent(TopMenu)
    :HitRectInsets(0, 0, 0, 0)
    :Hooks(alpha_listeners)
    :Hooks {
        OnEnter = function(self)
            self.Hover.Bg:Show()
        end,
        OnLeave = function(self)
            self.Hover.Bg:Hide()
        end
    }
{
    Style'.Texture'
        .CENTER:CENTER()
        :Size(ICON_SIZE, ICON_SIZE),
    Style'.Texture'
        -- :TexCoord(0.1, 0.9, 0.1, 0.9),
,
    Frame'.Hover' {
        function(self) self:SetAllPoints(self:GetParent()) end,
        Texture'.Bg'
            :ColorTexture(1, 1, 1, 0.1)
            :Hide()
            { function(self) self:SetAllPoints(self:GetParent()) end },
    },

    MaskTexture'.Mask'
        :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
        :AllPoints(PARENT)
        .init(function(self, parent)
            Style(parent) {
                Style'.Texture':AddMaskTexture(self)
            }
        end),

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
        Style'.MicroButtonAndBagsBar':Hide()
    }

    Style(QuestLogMicroButton)
        .TOPLEFT:TOPLEFT(TopMenu, 4, -2)
        :Height(26)
        -- :Width(QuestLogMicroButton.ButtonText:GetWidth() + ICON_SIZE)
        :HitRectInsets(0, 0, 0, 0)
        :NormalTexture 'Interface/QUESTFRAME/AutoQuest'
        :HighlightTexture 'Interface/QUESTFRAME/AutoQuest'
        :PushedTexture 'Interface/QUESTFRAME/AutoQuest'
        :Parent(TopMenu)
        :Hooks(alpha_listeners)
        {
            Style'.Texture'
                .TOPLEFT:TOPLEFT(1, -1)
                :Size(24, 28)
                :SetTexCoord(0.1, 0.5, 0.05, 0.5),
            FontString'.ButtonText'
                .LEFT:LEFT(24, 0)
                :Font('FONTS/FRIZQT__.ttf', 12)
                .init(function(self, parent)
                    self:SetText(parent.tooltipText)
                end),
            function(self)
                self:SetWidth(self.ButtonText:GetRight() - self:GetLeft() + 10)
            end
        }

    MenuButton(CharacterMicroButton) {        
        Texture'.BgLeft'
            :ColorTexture(0.2, 0.2, 0.2)
            .TOPLEFT:TOPLEFT(-5, 0)
            .BOTTOMLEFT:BOTTOMLEFT(-5, 0)
            :Width(0.75/scale),
    }

    MenuButton(TalentMicroButton) {
        Style'.Texture':SetTexCoord(0.1, 0.9, 0.4, 1)
    }

    MenuButton(SpellbookMicroButton)

    MenuButton(AchievementMicroButton) {  
        Texture'.BgLeft'
            :ColorTexture(0.2, 0.2, 0.2)
            .TOPLEFT:TOPLEFT(-5, 0)
            .BOTTOMLEFT:BOTTOMLEFT(-5, 0)
            :Width(0.75/scale),
    }

    MenuButton(CollectionsMicroButton)

    MenuButton(EJMicroButton) {
        Style'.Texture':TexCoord(0.1, 0.9, 0.2, 0.8)
    }

    MenuButton(LFDMicroButton) {
        Style'.Texture':TexCoord(0.1, 0.9, 0.2, 0.8)
    }

    MenuButton(LFGMicroButton) {
        Style'.Texture':SetTexCoord(0.1, 0.9, 0.45, 0.9)
    }

    MenuButton(GuildMicroButton) {
        Style'.Texture':TexCoord(0.1, 0.9, 0.2, 0.8)
    }

    MenuButton(QuickJoinToastButton or SocialsMicroButton) {
        Style'.Texture':TexCoord(0.1, 0.9, 0.1, 0.9):Texture(FriendsFrameIcon:GetTexture())
    }

    MenuButton(PVPMicroButton) {
        Style'.texture':TexCoord(0.03,0.64,0,0.6)
    }

    MenuButton(MainMenuMicroButton)

    MenuButton(GameTimeFrame)

    MenuButton(KeyRingButton)

    Style(StoreMicroButton)
        .BOTTOMLEFT:TOPLEFT(UIParent)

    layout()

end


local doUpdate = false


hooksecurefunc('MoveMicroButtons', function() doUpdate = true end)

Frame
    :Events {
        PLAYER_ENTERING_WORLD = function()    
            MenuButton(MainMenuBarBackpackButton) {
                Style'.*NormalTexture':Texture ''
            }
            
            Style(MainMenuBarArtFrame or MicroButtonAndBagsBar) {
                MenuButton'.CharacterBag#Slot, .CharacterReagentBag0Slot' {
                    Style'.*NormalTexture':Texture ''
                },
                Style'.BagBarExpandToggle':Hide()
            }

            doUpdate = true
        end
    }
    :Hooks {
        OnUpdate = function(self, dt)
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
