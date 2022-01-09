local _, ns = ...
local lqt = ns.lqt

local Style, Frame, Texture, MaskTexture, FontString = lqt.Style, lqt.Frame, lqt.Texture, lqt.MaskTexture, lqt.FontString


local addon = Frame.new()


MoveMicroButtons = function() end
UpdateMicroButtonsParent = function() end


MicroButtonAndBagsBar:Hide()


local alpha = 0.1
local alphaTarget = 0

local alpha_listeners = {
    OnEnter = function() alphaTarget = 1 end,
    OnLeave = function() alphaTarget = 0 end,
}



local TopMenu = Frame
    :TOPLEFT(UIParent:TOPLEFT())
    :TOPRIGHT(UIParent:TOPRIGHT())
    :Height(24)
    :Hook(alpha_listeners)
    :FrameStrata 'MEDIUM'
{
    Texture'.Bg'
        :DrawLayer 'ARTWORK'
        :Texture 'Interface/Common/ShadowOverlay-Top'
            .init(function(self, parent)
                Style(self)
                    :TOPLEFT(parent:TOPLEFT())
                    :TOPRIGHT(parent:TOPRIGHT())
                    :Height(80)
            end),
            
    Texture'.Bg2'
        :DrawLayer 'BACKGROUND'
        :ColorTexture(0.2, 0.2, 0.2)
            .init(function(self, parent)
                Style(self)
                    :TOPLEFT(parent:TOPLEFT())
                    :TOPRIGHT(parent:TOPRIGHT())
                    :Height(24)
            end)
}
    .new()


addon:Hook {
    OnUpdate = function(self, dt)
        if alpha ~= alphaTarget then
            local sign = alpha >= alphaTarget and -1 or 1
            alpha = math.min(1, math.max(0, alpha + sign * dt*5))
            local anim = math.sqrt(alpha)
            TopMenu:SetAlpha(anim)
        end
    end
}


Style(QuestLogMicroButton)
    :ClearAllPoints()
    -- :LEFT(TalentMicroButton:RIGHT(10,0))
    :TOPLEFT(TopMenu:TOPLEFT(4, 0))
    :Size(100, 26)
    :NormalTexture 'Interface/QUESTFRAME/AutoQuest'
    :HighlightTexture 'Interface/QUESTFRAME/AutoQuest'
    :PushedTexture 'Interface/QUESTFRAME/AutoQuest'
    :Parent(TopMenu)
    :Hook(alpha_listeners)
{
    Style'.Texture'
        :ClearAllPoints()
        :TOPLEFT(QuestLogMicroButton:TOPLEFT(1, -1))
        :Size(24, 28)
        :SetTexCoord(0.1, 0.5, 0.05, 0.5),
    FontString'.ButtonText'
        :LEFT(QuestLogMicroButton:LEFT(24,0))
        :Font('FONTS/FRIZQT__.ttf', 12)
        .init(function(self, parent)
            self:SetText(parent.tooltipText)
        end)
}



local SPACING = UIParent:GetWidth() / 9


local ICON_SIZE = 24


MenuButton = Style
    :ClearAllPoints()
    :Size(SPACING, ICON_SIZE)
    :Parent(TopMenu)
    :Hook(alpha_listeners)
    :Hook {
        OnEnter = function(self)
            self.Hover.Bg:Show()
        end,
        OnLeave = function(self)
            self.Hover.Bg:Hide()
        end
    }
    .data {
        SetTextures = function(self, path)
            self:SetNormalTexture(path)
            self:SetHighlightTexture(path)
            self:SetPushedTexture(path)
        end
    }
{
    Style'.Texture'
        :ClearAllPoints()
        :Size(ICON_SIZE, ICON_SIZE)
        { function(self) self:SetTOPLEFT(self:GetParent():TOPLEFT(5, 0)) end },
    Style'.Texture'
        :TexCoord(0.05, 0.95, 0.05, 0.95),

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
        .init(function(self, parent)
            Style(self)
                :TOPLEFT(parent:TOPLEFT(5+ICON_SIZE*0.125, -ICON_SIZE*0.125))
                :Size(ICON_SIZE/1.25, ICON_SIZE/1.25)
            parent'.Texture':AddMaskTexture(self)
        end),

    -- Texture'.Border'
    --     -- :Texture 'Interface/COMMON/RingBorder'
    --     :Texture 'Interface/COMMON/BlueMenuRing'
    --     :DrawLayer 'OVERLAY'
    --     :TexCoord(0, 1, 0, 1)
    --     .init(function(self, parent)
    --         Style(self)
    --             :TOPLEFT(parent:TOPLEFT(-ICON_SIZE*0.3125, ICON_SIZE*0.3125))
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
    --             :TOPLEFT(parent:TOPLEFT(0, 3))
    --             :BOTTOMLEFT(parent:BOTTOMLEFT(0, -2))
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
    --             :TOPLEFT(parent:TOPLEFT(10, 3))
    --             :BOTTOMRIGHT(parent:BOTTOMRIGHT(-10, -2))
    --     end
    -- },

    Texture'.BgLeft'
        :ColorTexture(0.2, 0.2, 0.2)
    {
        function(self)
            local parent = self:GetParent()
            Style(self)
                :TOPLEFT(parent:TOPLEFT())
                :BOTTOMLEFT(parent:BOTTOMLEFT())
                :Width(0.5)
        end
    },

    -- Texture'.BgRight'
    --     :ColorTexture(0.2, 0.2, 0.2)
    -- {
    --     function(self)
    --         local parent = self:GetParent()
    --         Style(self)
    --             :TOPRIGHT(parent:TOPRIGHT())
    --             :BOTTOMRIGHT(parent:BOTTOMRIGHT())
    --             :Width(0.5)
    --     end
    -- },

    FontString'.ButtonText'
        :Font('FONTS/FRIZQT__.ttf', 12)
        :JustifyH('LEFT')
        .init(function(self, parent)
            self:SetText(parent.tooltipText)
            self:SetWidth(parent:GetWidth() - 10)
            self:SetLEFT(parent:LEFT(ICON_SIZE + 5, 0))
        end)
}


local Dropdown = Frame'.Dropdown'
    :Height(40)
    :Hide()
    :Hook {
        OnShow = function(self)
            local parent = self:GetParent()
            self:Points {
                TOPLEFT = parent:BOTTOMLEFT(),
                TOPRIGHT = parent:BOTTOMRIGHT()
            }
            local prev = nil
            for i, frame in ipairs(self) do
                if prev then
                    frame:SetTOPLEFT(prev:BOTTOMLEFT())
                    frame:SetTOPRIGHT(prev:BOTTOMRIGHT())
                else
                    frame:SetTOPLEFT(self:TOPLEFT())
                    frame:SetTOPRIGHT(self:TOPRIGHT())
                end
                prev = frame
            end
        end
    }


local DropdownBtn = Frame
    :Height(ICON_SIZE)
    :Hook {
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
            self:Hook { OnMouseUp = click }
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
            self:Points {
                TOPLEFT = parent:TOPLEFT(30, 0),
                BOTTOMRIGHT = parent:BOTTOMRIGHT()
            }
        end)
}


local DropdownSeparator = Frame
    :Height(3)
    :Hook {
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
            self:Points {
                TOPLEFT = parent:TOPLEFT(5, -1.1),
                BOTTOMRIGHT = parent:BOTTOMRIGHT(-5, 1.1)
            }
        end)
}


addon:EventHook {
    PLAYER_ENTERING_WORLD = function()
        TalentMicroButton:Click()
        TalentMicroButton:Click()
        SpellbookMicroButton:Click()
        SpellbookMicroButton:Click()
    end
}


MenuButton(CharacterMicroButton)
    :Textures ''
    :Points {
        TOPLEFT = QuestLogMicroButton:TOPRIGHT(10, 0)
    }
    :Hook {
        OnEnter = function(self)
            self.Dropdown:Show()
        end,
        OnLeave = function(self)
            self.Dropdown:Hide()
        end
    }
{
    Dropdown {
        DropdownBtn'.1':Text(CharacterFrameTab2Text:GetText()):OnClick(function() CharacterMicroButton:Click() CharacterFrameTab2:Click() end),
        DropdownBtn'.2':Text(CharacterFrameTab3Text:GetText()):OnClick(function() CharacterMicroButton:Click() CharacterFrameTab3:Click() end),
        DropdownSeparator'.3',
        DropdownBtn'.4':OnClick(function() TalentMicroButton:Click() PlayerTalentFrameTab1:Click() end),
        DropdownBtn'.5':OnClick(function() TalentMicroButton:Click() PlayerTalentFrameTab2:Click() end),
        DropdownSeparator'.6',
        DropdownBtn'.7':OnClick(function() SpellbookMicroButton:Click() SpellBookFrameTabButton1:Click() end),
        DropdownBtn'.8':OnClick(function() SpellbookMicroButton:Click() SpellBookFrameTabButton2:Click() end),
        Style:Event {
            PLAYER_ENTERING_WORLD = function(self)
                TalentMicroButton:Click()
                self[4]:SetText(PlayerTalentFrameTab1Text:GetText())
                self[5]:SetText(PlayerTalentFrameTab2Text:GetText())
                TalentMicroButton:Click()
                SpellbookMicroButton:Click()
                self[7]:SetText(SpellBookFrameTabButton1Text:GetText())
                self[8]:SetText(SpellBookFrameTabButton2Text:GetText())
                SpellbookMicroButton:Click()
            end,
        }
    }
}


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
        :LEFT(CharacterMicroButton:RIGHT(0,0))
        :Textures(icon)
end
update_spec()

addon:EventHook {
    PLAYER_ENTERING_WORLD = update_spec,
    PLAYER_SPECIALIZATION_CHANGED = update_spec,
}

MenuButton(SpellbookMicroButton)
    :LEFT(TalentMicroButton:RIGHT(0, 0))
    :Textures 'Interface/ICONS/INV_Misc_Book_09'

MenuButton(AchievementMicroButton)
    :TOPLEFT(SpellbookMicroButton:TOPRIGHT(0,0))
    -- :NormalTexture 'Interface/ICONS/Achievement_Dungeon_ClassicDungeonMaster'
    :Textures 'Interface/ICONS/Achievement_Quests_Completed_06'


MenuButton(CollectionsMicroButton)
    :LEFT(AchievementMicroButton:RIGHT(0,0))
    :Textures 'Interface/ICONS/Achievement_Boss_spoils_of_pandaria'

    
MenuButton(MainMenuMicroButton)
    :TOPRIGHT(TopMenu:TOPRIGHT())

Style(StoreMicroButton)
    :BOTTOMLEFT(UIParent:TOPLEFT())
