
local PARENT, Style, Frame, Texture, MaskTexture, FontString = LQT.PARENT, LQT.Style, LQT.Frame, LQT.Texture, LQT.MaskTexture, LQT.FontString


local addon = Frame.new()


-- MoveMicroButtons = function() end
-- UpdateMicroButtonsParent = function() end


local alpha = 0.1
local alphaTarget = 0

local alpha_listeners = {
    OnEnter = function() alphaTarget = 1 end,
    OnLeave = function() alphaTarget = 0 end,
}

local scale = UIParent:GetEffectiveScale()


local TopMenu = Frame
    :Points { TOPLEFT = UIParent:TOPLEFT(),
              TOPRIGHT = UIParent:TOPRIGHT() }
    :Height(24)
    :Hooks(alpha_listeners)
    :FrameStrata 'MEDIUM'
{
    Texture'.Bg'
        :DrawLayer 'ARTWORK'
        :Texture 'Interface/Common/ShadowOverlay-Top'
            .init(function(self, parent)
                Style(self)
                    :Points { TOPLEFT = parent:TOPLEFT(),
                              TOPRIGHT = parent:TOPRIGHT() }
                    :Height(80)
            end),
            
    -- Texture'.Bg2'
    --     :DrawLayer 'BACKGROUND'
    --     :ColorTexture(0.2, 0.2, 0.2)
    --         .init(function(self, parent)
    --             Style(self)
    --                 :Points { TOPLEFT = parent:TOPLEFT(),
    --                           TOPRIGHT = parent:TOPRIGHT() }
    --                 :Height(24)
    --         end)
}
    .new()


addon:SetHooks {
    OnUpdate = function(self, dt)
        if alpha ~= alphaTarget then
            local sign = alpha >= alphaTarget and -1 or 1
            alpha = math.min(1, math.max(0, alpha + sign * dt*5))
            local anim = math.sqrt(alpha)
            TopMenu:SetAlpha(anim)
        end
    end
}


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
    .data {
        SetTextures = function(self, path)
            -- self:SetNormalTexture(path)
            -- self:SetHighlightTexture(path)
            -- self:SetPushedTexture(path)
            -- self:GetPushedTexture():SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
    }
{
    Style'.Texture'
        :ClearAllPoints()
        :Size(ICON_SIZE, ICON_SIZE)
        :Points { TOPLEFT = PARENT:TOPLEFT() },
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
        -- :Texture 'Interface/Soulbinds/SoulbindsConduitCollectionsIconMask'
        :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
        -- :Texture 'Interface/COMMON/ShadowOverlay-Left'
        :AllPoints(PARENT)
        .init(function(self, parent)
            parent'.Texture':AddMaskTexture(self)
        end),

    -- Texture'.Border'
    --     -- :Texture 'Interface/COMMON/RingBorder'
    --     :Texture 'Interface/COMMON/BlueMenuRing'
    --     :DrawLayer 'OVERLAY'
    --     :TexCoord(0, 1, 0, 1)
    --     .init(function(self, parent)
    --         Style(self)
    --             :Points { TOPLEFT = parent:TOPLEFT(-ICON_SIZE*0.3125, ICON_SIZE*0.3125) }
    --             :Size(ICON_SIZE*2, ICON_SIZE*2)
    --             -- :BOTTOMRIGHT(parent:BOTTOMRIGHT(22, -22))
    --             -- :Alpha(0.5)
    --     end),
        
    -- Texture'.Bg'
    --     -- :Texture'Interface/BUTTONS/UI-Button-Borders'
    --     :Texture'Interface/Calendar/ButtonFrame'
    --     :TexCoord(0, 0.395, 0.5, 0)
    -- {
    --     function(self) self:SetAllPoints(self:GetParent()) end
    -- },

    -- Texture'.BgLeft'
    --     -- :Texture'Interface/BUTTONS/UI-Button-Borders'
    --     :Texture'Interface/Calendar/ButtonFrame'
    --     :TexCoord(0.39, 0.44, 0.5, 0)
    -- {
    --     function(self)
    --         local parent = self:GetParent()
    --         Style(self)
    --             :Points { TOPLEFT = parent:TOPLEFT(0, 3),
    --                       BOTTOMLEFT = parent:BOTTOMLEFT(0, -2) }
    --             :Width(10)
    --     end
    -- },

    -- Texture'.BgRight'
    --     -- :Texture'Interface/BUTTONS/UI-Button-Borders'
    --     :Texture'Interface/Calendar/ButtonFrame'
    --     :TexCoord(0.73, 0.78, 0.5, 0)
    -- {
    --     function(self)
    --         local parent = self:GetParent()
    --         Style(self)
    --             :TOPRIGHT(parent:TOPRIGHT(0, 3))
    --             :BOTTOMRIGHT(parent:BOTTOMRIGHT(0, -2))
    --             :Width(10)
    --     end
    -- },

    -- Texture'.Bg'
    --     -- :Texture'Interface/BUTTONS/UI-Button-Borders'
    --     :Texture'Interface/Calendar/ButtonFrame'
    --     :TexCoord(0.44, 0.73, 0.5, 0)
    -- {
    --     function(self)
    --         local parent = self:GetParent()
    --         Style(self)
    --             :Points { TOPLEFT = parent:TOPLEFT(10, 3),
    --                       BOTTOMRIGHT = parent:BOTTOMRIGHT(-10, -2) }
    --     end
    -- },

    -- Texture'.BgLeft'
    --     :ColorTexture(0.2, 0.2, 0.2)
    -- {
    --     function(self)
    --         local parent = self:GetParent()
    --         Style(self)
    --             :Points { TOPLEFT = parent:TOPLEFT(),
    --                       BOTTOMLEFT = parent:BOTTOMLEFT() }
    --             :Width(0.75/scale)
    --     end
    -- },

    -- Texture'.BgRight'
    --     :ColorTexture(0.2, 0.2, 0.2)
    -- {
    --     function(self)
    --         local parent = self:GetParent()
    --         Style(self)
    --             :TOPRIGHT(parent:TOPRIGHT())
    --             :BOTTOMRIGHT(parent:BOTTOMRIGHT())
    --             :Width(0.75/scale)
    --     end
    -- },

    -- FontString'.ButtonText'
    --     :Font('FONTS/FRIZQT__.ttf', 12)
    --     :JustifyH('LEFT')
    --     .init(function(self, parent)
    --         self:SetText(parent.tooltipText)
    --         self:SetWidth(parent:GetWidth() - 10)
    --         self:SetPoints { LEFT = parent:LEFT(ICON_SIZE + 5, 0) }
    --     end)
}


local Dropdown = Frame'.Dropdown'
    :Height(40)
    :Hide()
    :Hooks {
        OnShow = function(self)
            local parent = self:GetParent()
            self:SetPoints {
                TOPLEFT = parent:BOTTOMLEFT(),
                TOPRIGHT = parent:BOTTOMRIGHT()
            }
            local prev = nil
            for i, frame in ipairs(self) do
                if prev then
                    frame:Points { TOPLEFT = prev:BOTTOMLEFT(),
                                   TOPRIGHT = prev:BOTTOMRIGHT() }
                else
                    frame:Points { TOPLEFT = self:TOPLEFT(),
                                   TOPRIGHT = self:TOPRIGHT() }
                end
                prev = frame
            end
        end
    }


local DropdownBtn = Frame
    :Height(ICON_SIZE)
    :Hooks {
        OnEnter = function(self)
            self:GetParent():Show()
            self.Hover:Show()
            alphaTarget = 1
        end,
        OnLeave = function(self)
            self:GetParent():Hide()
            self.Hover:Hide()
            alphaTarget = 0
        end,
    }
    :FrameStrata('MEDIUM', -1)
    .data {
        SetText = function(self, text)
            self.DisplayText:SetText(text)
        end,
        SetOnClick = function(self, click)
            self:Hooks { OnMouseUp = click }
        end
    }
{
    Texture'.Hover'
        :ColorTexture(1, 1, 1, 0.1)
        :Hide()
        { function(self) self:SetAllPoints(self:GetParent()) end },
    Texture'.Bg'
        :ColorTexture(0.15, 0.15, 0.15)
        :DrawLayer('BACKGROUND', -1)
        .init(function(self, parent) self:SetAllPoints(parent) end),
    FontString'.DisplayText'
        :Font('FONTS/FRIZQT__.ttf', 12)
        :JustifyH 'LEFT'
        .init(function(self, parent)
            self:SetPoints {
                TOPLEFT = parent:TOPLEFT(30, 0),
                BOTTOMRIGHT = parent:BOTTOMRIGHT()
            }
        end)
}


local DropdownSeparator = Frame
    :Height(3)
    :Hooks {
        OnEnter = function(self)
            self:GetParent():Show()
            alphaTarget = 1
        end,
        OnLeave = function(self)
            self:GetParent():Hide()
            alphaTarget = 0
        end,
    }
{
    Texture'.Bg'
        :ColorTexture(0.2, 0.2, 0.2)
        :DrawLayer 'BACKGROUND'
        .init(function(self, parent) self:SetAllPoints(parent) end),
    Texture'.Line'
        :ColorTexture(1,1,1,0.5)
        .init(function(self, parent)
            self:SetPoints {
                TOPLEFT = parent:TOPLEFT(5, -1.1),
                BOTTOMRIGHT = parent:BOTTOMRIGHT(-5, 1.1)
            }
        end)
}


addon:SetEventHooks {
    PLAYER_ENTERING_WORLD = function()

        if KeyRingButton then
            KeyRingButton:SetPoints { TOPRIGHT = UIParent:TOPRIGHT() }
        end

        MenuButton(MainMenuBarBackpackButton)
            :Points { TOPRIGHT = (KeyRingButton or GameTimeFrame):TOPLEFT() }
            :Parent(TopMenu)
        {
            Style'.*NormalTexture':Texture ''
        }
        -- Style'.CharacterBag#Slot':Hide(),
        -- Style'.MainMenuBarBackpackButton':Hide(),
        
        Style(MainMenuBarArtFrame or MicroButtonAndBagsBar) {
            MenuButton'.CharacterBag#Slot'
                :Parent(TopMenu)
            {
                Style'.*NormalTexture':Texture ''
            },
            Style'.BagBarExpandToggle':Hide()
        }
        local previous = MainMenuBarBackpackButton
        for i=0, 3 do
            _G['CharacterBag' .. i .. 'Slot']:SetPoints { TOPRIGHT = previous:TOPLEFT() }
            previous = _G['CharacterBag' .. i .. 'Slot']
        end
    end
}


local style = function()

    Style(MainMenuBar) {
        Style'.MicroButtonAndBagsBar':Hide()
    }

    Style(QuestLogMicroButton)
        :Points { TOPLEFT = TopMenu:TOPLEFT(4, -2) }
        :Height(26)
        :Width(100)
        -- :Width(QuestLogMicroButton.ButtonText:GetWidth() + ICON_SIZE)
        :HitRectInsets(0, 0, 0, 0)
        :NormalTexture 'Interface/QUESTFRAME/AutoQuest'
        :HighlightTexture 'Interface/QUESTFRAME/AutoQuest'
        :PushedTexture 'Interface/QUESTFRAME/AutoQuest'
        :Parent(TopMenu)
        :Hooks(alpha_listeners)
        {
        Style'.Texture'
            :Points { TOPLEFT = QuestLogMicroButton:TOPLEFT(1, -1) }
            :Size(24, 28)
            :SetTexCoord(0.1, 0.5, 0.05, 0.5),
        FontString'.ButtonText'
            :Points { LEFT = QuestLogMicroButton:LEFT(24,0) }
            :Font('FONTS/FRIZQT__.ttf', 12)
            .init(function(self, parent)
                self:SetText(parent.tooltipText)
            end)
        }

    MenuButton(CharacterMicroButton)
        :Textures ''
        :Points {
            TOPLEFT = QuestLogMicroButton:TOPRIGHT(10, 2)
        }
        -- :Hooks {
        --     OnEnter = function(self)
        --         self.Dropdown:Show()
        --     end,
        --     OnLeave = function(self)
        --         self.Dropdown:Hide()
        --     end
        -- }
    {
        
        Texture'.BgLeft'
            :ColorTexture(0.2, 0.2, 0.2)
        {
            function(self)
                local parent = self:GetParent()
                Style(self)
                    :Points { TOPLEFT = parent:TOPLEFT(-5, 0),
                              BOTTOMLEFT = parent:BOTTOMLEFT(-5, 0) }
                    :Width(0.75/scale)
            end
        }

        -- Dropdown {
        --     DropdownBtn'.1':Text(CharacterFrameTab2Text:GetText()):OnClick(function() CharacterMicroButton:Click() CharacterFrameTab2:Click() end),
        --     DropdownBtn'.2':Text(CharacterFrameTab3Text:GetText()):OnClick(function() CharacterMicroButton:Click() CharacterFrameTab3:Click() end),
        --     DropdownSeparator'.3',
        --     DropdownBtn'.4':OnClick(function() TalentMicroButton:Click() PlayerTalentFrameTab1:Click() end),
        --     DropdownBtn'.5':OnClick(function() TalentMicroButton:Click() PlayerTalentFrameTab2:Click() end),
        --     DropdownSeparator'.6',
        --     DropdownBtn'.7':OnClick(function() SpellbookMicroButton:Click() SpellBookFrameTabButton1:Click() end),
        --     DropdownBtn'.8':OnClick(function() SpellbookMicroButton:Click() SpellBookFrameTabButton2:Click() end),
        --     Style:Event {
        --         PLAYER_ENTERING_WORLD = function(self)
        --             TalentMicroButton:Click()
        --             self[4]:SetText(PlayerTalentFrameTab1Text:GetText())
        --             self[5]:SetText(PlayerTalentFrameTab2Text:GetText())
        --             TalentMicroButton:Click()
        --             SpellbookMicroButton:Click()
        --             self[7]:SetText(SpellBookFrameTabButton1Text:GetText())
        --             self[8]:SetText(SpellBookFrameTabButton2Text:GetText())
        --             SpellbookMicroButton:Click()
        --         end,
        --     }
        -- }
    }


    if GetNumSpecializationsForClassID then
        local function update_spec()
            local _, className, classID = UnitClass("player");
            local numSpecs = GetNumSpecializationsForClassID(classID);
            local spec = GetSpecialization();
            local icon = nil
            local texCoords = { 0.05, 0.95, 0.05, 0.95 }
        
            if spec and spec <= numSpecs then
                icon = select(4, GetSpecializationInfo(spec));
            end
            
            if not icon then
                icon = 'Interface/TargetingFrame/UI-Classes-Circles'
                texCoords = CLASS_ICON_TCOORDS[strupper(className)]
            end
        
            MenuButton(TalentMicroButton)
                :Points { LEFT = CharacterMicroButton:RIGHT(0,0) }
                :Textures(icon)
        end

        update_spec()

        addon:SetEventHooks {
            PLAYER_ENTERING_WORLD = update_spec,
            PLAYER_SPECIALIZATION_CHANGED = update_spec,
        }
    else
        
        MenuButton(TalentMicroButton)
            :Points { LEFT = CharacterMicroButton:RIGHT(0,0) }
        {
            Style'.Texture':SetTexCoord(0.1, 0.9, 0.4, 1)
        }
    end

    MenuButton(SpellbookMicroButton)
        :Points { LEFT = TalentMicroButton:RIGHT(0, 0) }
        :Textures 'Interface/ICONS/INV_Misc_Book_09'

    MenuButton(AchievementMicroButton)
        :Points { TOPLEFT = SpellbookMicroButton:TOPRIGHT(10,0) }
        -- :NormalTexture 'Interface/ICONS/Achievement_Dungeon_ClassicDungeonMaster'
        :Textures 'Interface/ICONS/Achievement_Quests_Completed_06'
    {  
        Texture'.BgLeft'
            :ColorTexture(0.2, 0.2, 0.2)
        {
            function(self)
                local parent = self:GetParent()
                Style(self)
                    :Points { TOPLEFT = parent:TOPLEFT(-5, 0),
                              BOTTOMLEFT = parent:BOTTOMLEFT(-5, 0) }
                    :Width(0.75/scale)
            end
        },
    }

    if CollectionsMicroButton then
        MenuButton(CollectionsMicroButton)
            :Points { LEFT = AchievementMicroButton:RIGHT(0,0) }
            :Textures 'Interface/ICONS/Achievement_Boss_spoils_of_pandaria'
    end

    if EJMicroButton then
        MenuButton(EJMicroButton)
            :Points { TOPLEFT = CollectionsMicroButton:TOPRIGHT(10, 0) }
        {
            Style'.Texture':TexCoord(0.1, 0.9, 0.2, 0.8)
        }
    end

    MenuButton(LFDMicroButton)
        :Points { TOPLEFT = EJMicroButton and EJMicroButton:TOPRIGHT() or AchievementMicroButton:TOPRIGHT() }
    {
        Style'.Texture':TexCoord(0.1, 0.9, 0.2, 0.8)
    }

    MenuButton(LFGMicroButton)
        :Points { TOPLEFT = EJMicroButton and EJMicroButton:TOPRIGHT() or AchievementMicroButton:TOPRIGHT() }
    {
        Style'.Texture':SetTexCoord(0.1, 0.9, 0.45, 0.9)
    }


    if GuildMicroButton then
        MenuButton(GuildMicroButton)
            :Points { TOPLEFT = (LFDMicroButton or LFGMicroButton):TOPRIGHT() }
        {
            Style'.Texture':TexCoord(0.1, 0.9, 0.2, 0.8)
        }
    end

    MenuButton(QuickJoinToastButton or SocialsMicroButton)
        :Points { TOPLEFT = (GuildMicroButton or LFGMicroButton):TOPRIGHT() }
    {
        Style'.Texture':TexCoord(0.1, 0.9, 0.1, 0.9):Texture(FriendsFrameIcon:GetTexture())
    }

    -- if QuickJoinToastButton then
    --     QuickJoinToastButton.SetPointOrig = QuickJoinToastButton.SetPoint
    --     QuickJoinToastButton.SetPoint = function() end

    --     QuickJoinToastButton.ModifyToastDirection = function() end
    -- end


    if PVPMicroButton then
        MenuButton(PVPMicroButton)
            :Points { TOPLEFT = SocialsMicroButton:TOPRIGHT() }
        {
            Style'.texture':TexCoord(0.03,0.64,0,0.6)
        }
    end


    MenuButton(MainMenuMicroButton)
        :Points { TOPRIGHT = TopMenu:TOPRIGHT() }

    MenuButton(GameTimeFrame)
        :Points { TOPRIGHT = MainMenuMicroButton:TOPLEFT() }

    -- MenuButton(MiniMapMailFrame)
    --     :TOPRIGHT(GameTimeFrame:TOPLEFT())
    --     :Parent(UIParent)
    --     :FrameStrata('HIGH')
    -- {
    --     Style'.MiniMapMailBorder':Hide()
    -- }

    if KeyRingButton then
        MenuButton(KeyRingButton)
            :Points { TOPRIGHT = GameTimeFrame:TOPLEFT() }
    end


    Style(StoreMicroButton)
        :Points { BOTTOMLEFT = UIParent:TOPLEFT() }

end


local doUpdate = false


hooksecurefunc('UIParent_ManageFramePositions', function() doUpdate = true end)

Frame
    :Events {
        PLAYER_ENTERING_WORLD = function() doUpdate = true end
    }
    :Hooks {
        OnUpdate = function()
            if doUpdate then
                doUpdate = false
                style()
            end
        end
    }
    .new()
-- style()