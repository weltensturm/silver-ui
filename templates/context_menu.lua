local ADDON, Addon = ...


local PARENT, Frame, Texture, Button, FontString = LQT.PARENT, LQT.Frame, LQT.Texture, LQT.Button, LQT.FontString


Addon.ContextMenuButton = Button
    :Height(16)
    .init {
        function(self, parent)
            table.insert(parent.buttons, self)
        end,
        SetText = function(self, ...)
            self.Text:SetText(...)
        end,
        SetClick = function(self, fn)
            self.Click = fn
        end,
    }
    :Hooks {
        OnEnter = function(self)
            self.hoverBg:Show()
        end,
        OnLeave = function(self)
            self.hoverBg:Hide()
        end,
        OnClick = function(self)
            self:GetParent():Hide()
            if self.Click then
                self.Click(self:GetParent():GetParent())
            end
        end
    }
{
    FontString'.Text'
        :SetFont('Fonts/FRIZQT__.ttf', 12)
        :AllPoints(PARENT)
        :JustifyH 'LEFT',
    Texture'.hoverBg'
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        :AllPoints(PARENT),
}


Addon.ContextMenu = Frame
    .TOPLEFT:BOTTOMLEFT()
    .init {
        function(self, parent)
            _G.Mixin(self, _G.BackdropTemplateMixin)
            self:HookScript('OnSizeChanged', self.OnBackdropSizeChanged)
            self.buttons = {}
        end
    }
    :SetBackdrop {
        -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment",
        bgFile = 'Interface/HELPFRAME/DarkSandstone-Tile',
        edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
        edgeSize = 12,
        tile = true,
        tileSize = 300,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
    :Hide()
    :FrameStrata 'FULLSCREEN_DIALOG'
    :FrameLevel(5)
    :Hooks {
        OnShow = function(self)
            local previous = nil
            local width = 1
            local height = 0
            for _, btn in pairs(self.buttons) do
                if previous then
                    btn:SetPoint('TOPLEFT', previous, 'BOTTOMLEFT')
                else
                    btn:SetPoint('TOPLEFT', self, 'TOPLEFT', 12, -6)
                end
                btn:SetWidth(9999)
                width = math.max(width, btn.Text:GetStringWidth())
                height = height + btn:GetHeight()
                previous = btn
            end
            for _, btn in pairs(self.buttons) do
                btn:SetWidth(width)
            end
            self:SetSize(width+24, height+12)
            self.ClickBlocker:Show()
        end,
        OnHide = function(self)
            self.ClickBlocker:Hide()
        end
    }
{
    Frame'.ClickBlocker'
        .init(function(self, parent) self.menu = parent end)
        -- :Parent(UIParent)
        :AllPoints(UIParent)
        :FrameStrata 'FULLSCREEN_DIALOG'
        :FrameLevel(4)
        :Hooks {
            OnMouseDown = function(self)
                self.menu:Hide()
            end
        }
        :Hide()
}
