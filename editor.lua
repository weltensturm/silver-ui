local _, ns = ...

local Style, Frame, Button, Texture, FontString, EditBox, ScrollFrame = LQT.Style, LQT.Frame, LQT.Button, LQT.Texture, LQT.FontString, LQT.EditBox, LQT.ScrollFrame

local PARENT, ApplyFrameProxy, FrameProxyMt = LQT.PARENT, LQT.ApplyFrameProxy, LQT.FrameProxyMt

-- local Q = ns.util.method_chain_wrapper


local editorWindow = nil


local function GetUIParentChildren()
    local found = {}

    local object = EnumerateFrames()
    while object do
        if not object:IsForbidden() and not found[object] and object:GetParent() == UIParent then
            found[object] = true
        end
        object = EnumerateFrames(object)
    end

    return found
end


local function get_name(obj)
    local parent = obj:GetParent()
    if parent then
        for k, v in pairs(parent) do
            if v == obj then
                return '.' .. k
            end
        end
    end
    local name = obj:GetName()
    if name and _G[name] then
        return 'G.' .. name
    end
    return name or obj:GetObjectType()
end


local SortedChildren = nil


local function ToParent(tlx, tly, brx, bry)
    if type(tlx) == 'table' then
        return Style {
            function(self)
                local points = {}
                for point, target in pairs(tlx) do
                    if getmetatable(target) == FrameProxyMt then
                        points[point] = ApplyFrameProxy(self, target)
                    else
                        points[point] = target
                    end
                end
                self:SetPoints(points)
            end
        }
    else
        return Style {
            function(self)
                local parent = self:GetParent()
                self:SetPoints { TOPLEFT = parent:TOPLEFT(tlx, tly), BOTTOMRIGHT = parent:BOTTOMRIGHT(brx, bry) } 
            end
        }
    end
end


local Btn = Button
    :Hooks {
        OnEnter = function(self)
            self.hoverBg:Show()
        end,
        OnLeave = function(self)
            self.hoverBg:Hide()
        end
    }
    .data {
        SetText = function(self, ...)
            self.Text:SetText(...)
        end
    }
{
    FontString'.Text'
        :SetFont('Fonts/FRIZQT__.ttf', 12)
        .. ToParent(),
    Texture'.hoverBg'
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        .. ToParent(),
    Style:SetSize(20, 20)
}

local NOOP = function() end

local gui_types = {
    { 'UIObject', setmetatable({}, { __index = { GetName = NOOP, GetObjectType = NOOP, IsObjectType = NOOP, } }) },
    { 'ParentedObject', setmetatable({}, { __index = { GetDebugName = NOOP, GetParent = NOOP, IsForbidden = NOOP, SetForbidden = NOOP, } }) },
    { 'ScriptObject', setmetatable({}, { __index = { GetScript = NOOP, SetScript = NOOP, HookScript = NOOP, HasScript = NOOP, } }) },
    { 'Region', setmetatable({}, { __index = { GetSourceLocation = NOOP, SetParent = NOOP, IsDragging = NOOP, IsMouseOver = NOOP,
                                               IsObjectLoaded = NOOP, IsProtected = NOOP, CanChangeProtectedState = NOOP, GetPoint = NOOP,
                                               SetPoint = NOOP, SetAllPoints = NOOP, ClearAllPoints = NOOP, GetNumPoints = NOOP,
                                               IsAnchoringRestricted = NOOP, GetPointByName = NOOP, ClearPointByName = NOOP,
                                               AdjustPointsOffset = NOOP, ClearPointsOffset = NOOP, GetLeft = NOOP, GetRight = NOOP,
                                               GetTop = NOOP, GetBottom = NOOP, GetCenter = NOOP, GetRect = NOOP, GetScaledRect = NOOP,
                                               IsRectValid = NOOP, GetWidth = NOOP, SetWidth = NOOP, GetHeight = NOOP, SetHeight = NOOP,
                                               GetSize = NOOP, SetSize = NOOP, GetScale = NOOP, SetScale = NOOP, GetEffectiveScale = NOOP,
                                               SetIgnoreParentScale = NOOP, IsIgnoringParentScale = NOOP, Show = NOOP, Hide = NOOP,
                                               SetShown = NOOP, IsShown = NOOP, IsVisible = NOOP, GetAlpha = NOOP, SetAlpha = NOOP,
                                               SetIgnoreParentAlpha = NOOP, IsIgnoringParentAlpha = NOOP, CreateAnimationGroup = NOOP,
                                               GetAnimationGroups = NOOP, StopAnimating = NOOP, } }) },
    { 'LayeredRegion', setmetatable({}, { __index = { GetDrawLayer = NOOP, SetDrawLayer = NOOP, SetVertexColor = NOOP, } }) },
    { 'FontInstance', setmetatable({}, { __index = { GetFont = NOOP, GetFontObject = NOOP, SetFont = NOOP, SetFontObject = NOOP,
                                                     GetIndentedWordWrap = NOOP, GetJustifyH = NOOP, GetJustifyV = NOOP,
                                                     GetSpacing = NOOP, SetIndentedWordWrap = NOOP, SetJustifyH = NOOP,
                                                     SetJustifyV = NOOP, SetSpacing = NOOP, GetShadowColor = NOOP,
                                                     GetShadowOffset = NOOP, GetTextColor = NOOP, SetShadowColor = NOOP,
                                                     SetShadowOffset = NOOP, SetTextColor = NOOP, } }) },
}


do
    local gui_types_creatable = {
        { 'FontString', UIParent:CreateFontString() },
        { 'Frame', CreateFrame('Frame') },
        { 'ScrollFrame', CreateFrame('ScrollFrame') },
        { 'Button', CreateFrame('Button') },
        { 'Slider', CreateFrame('Slider') },
        { 'CheckButton', CreateFrame('CheckButton') },
        { 'EditBox', CreateFrame('EditBox') }
    }

    for _, v in ipairs(gui_types_creatable) do
        v[2]:Hide()
        table.insert(gui_types, v)
    end

    local uiext_t = {}
    setmetatable(uiext_t, { __index=LQT.FrameExtensions })
    table.insert(gui_types, 1, { 'UIEXT', uiext_t })
end


local function format_float(f)
    if type(f) == 'number' then
        return tostring(math.floor(f * 10000 + 0.5) / 10000)
    else
        return tostring(f)
    end
end


local function attribute_str_values(obj, k)
    local str = ''
    local result = { pcall(obj[k], obj) }
    for i, v in ipairs(result) do
        if i > 2 then
            str = str .. ', '
        end
        if i > 1 then
            str = str .. format_float(v)
        end
    end
    return str
end


local hoverFrame = nil

local SetFrameStack = nil


local BoxShadow = Frame
    :Points { TOPLEFT = PARENT:TOPLEFT(-8, 8),
              BOTTOMRIGHT = PARENT:BOTTOMRIGHT(8, -8) }
{
    Texture'.TopLeft'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(0, 1/4, 0, 1/4)
        :Points { TOPLEFT = PARENT:TOPLEFT(),
                  BOTTOMRIGHT = PARENT:GetParent():TOPLEFT() },
    Texture'.BottomLeft'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(0, 1/4, 3/4, 1)
        :Points { BOTTOMLEFT = PARENT:BOTTOMLEFT(),
                  TOPRIGHT = PARENT:GetParent():BOTTOMLEFT() },
    Texture'.TopRight'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(3/4, 1, 0, 1/4)
        :Points { TOPRIGHT = PARENT:TOPRIGHT(),
                  BOTTOMLEFT = PARENT:GetParent():TOPRIGHT() },
    Texture'.BottomRight'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(3/4, 1, 3/4, 1)
        :Points { BOTTOMRIGHT = PARENT:BOTTOMRIGHT(),
                  TOPLEFT = PARENT:GetParent():BOTTOMRIGHT() },
    Texture'.Left'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(0, 1/4, 1/4, 3/4)
        :Points { LEFT = PARENT:LEFT(),
                  TOPRIGHT = PARENT:GetParent():TOPLEFT(),
                  BOTTOMRIGHT = PARENT:GetParent():BOTTOMLEFT() },
    Texture'.Right'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(3/4, 1, 1/4, 3/4)
        :Points { RIGHT = PARENT:RIGHT(),
                  TOPLEFT = PARENT:GetParent():TOPRIGHT(),
                  BOTTOMLEFT = PARENT:GetParent():BOTTOMRIGHT() },
    Texture'.Top'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(1/4, 3/4, 0, 1/4)
        :Points { TOP = PARENT:TOP(),
                  BOTTOMLEFT = PARENT:GetParent():TOPLEFT(),
                  BOTTOMRIGHT = PARENT:GetParent():TOPRIGHT() },
    Texture'.Bottom'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(1/4, 3/4, 3/4, 1)
        :Points { BOTTOM = PARENT:BOTTOM(),
                  TOPLEFT = PARENT:GetParent():BOTTOMLEFT(),
                  TOPRIGHT = PARENT:GetParent():BOTTOMRIGHT() },
}


local ButtonContextMenu = Btn
    :Height(16)
    .init {
        function(self, parent)
            table.insert(parent.buttons, self)
        end,
        SetText = function(self, text)
            self.Text:SetText(text)
        end,
        SetClick = function(self, fn)
            self.click = fn
        end
    }
    :Hooks {
        OnClick = function(self)
            self:GetParent():Hide()
            if self.click then
                self.click(self:GetParent():GetParent())
            end
        end
    }
{
    Style'.Text':JustifyH 'LEFT'
}


local FrameContextMenu = Frame
    .init {
        function(self, parent)
            _G.Mixin(self, _G.BackdropTemplateMixin)
            self:HookScript('OnSizeChanged', self.OnBackdropSizeChanged)
            self:SetPoints { TOPLEFT = parent:BOTTOMLEFT() }
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
                    btn:SetPoints { TOPLEFT = previous:BOTTOMLEFT() }
                else
                    btn:SetPoints { TOPLEFT = self:TOPLEFT(12, -6) }
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


local FrameSmoothScroll = ScrollFrame
    .data { scrollSpeed = 0, overShoot = 50 }
    :Scripts {
        OnSizeChanged = function(self)
            self.Content:SetSize(self:GetSize())
        end,
        OnMouseWheel = function(self, delta)
            local current = self:GetVerticalScroll()
            local max = self:GetVerticalScrollRange()
            if current <= 0 and delta > 0 or current >= max-0.01+self.overShoot and delta < 0 then
                self.scrollSpeed = self.scrollSpeed - delta*0.3
            else
                self.scrollSpeed = self.scrollSpeed - delta
            end
        end,
        OnUpdate = function(self, dt)
            if self.scrollSpeed ~= 0 then
                local current = self:GetVerticalScroll()
                local max = self:GetVerticalScrollRange()+self.overShoot
                if current < 0 then
                    current = current + math.min(-current, 2048*dt)
                elseif current > max then
                    current = current - math.min(current - max, 2048*dt)
                end
                self:SetVerticalScroll(current + self.scrollSpeed*dt*512)
                if self.scrollSpeed > 0 then
                    self.scrollSpeed = math.max(0, self.scrollSpeed - (4 + math.abs(self.scrollSpeed*5))*dt)
                else
                    self.scrollSpeed = math.min(0, self.scrollSpeed + (4 + math.abs(self.scrollSpeed*5))*dt)
                end
            end
        end,
        OnVerticalScroll = function(self, offset)
            self.Content:SetHitRectInsets(0, 0, offset, (self.Content:GetHeight() - offset - self:GetHeight()))
        end
    }
{
    Frame'.Content'
        .init(function(self, parent)
            parent:SetScrollChild(self)
            self.children = {}
        end)
        :Height(200)
        :EnableMouse(true)
}


local ButtonAddonScript = Btn
    .init {
        Update = function(self)
            if self.settings.enabled then
                self.ContextMenu.Toggle:SetText('Disable')
                self.Disabled:Hide()
            else
                self.ContextMenu.Toggle:SetText('Enable')
                self.Disabled:Show()
            end
            if self.script.code == self.script.code_original or not self.script.code_original then
                self.Edited:Hide()
                self.ContextMenu.ResetScript:Disable()
                self.ContextMenu.ResetScript.Text:SetTextColor(0.5, 0.5, 0.5)
            else
                self.Edited:Show()
                self.ContextMenu.ResetScript:Enable()
                self.ContextMenu.ResetScript.Text:SetTextColor(1, 1, 1)
            end
        end,
        SetData = function(self, name, script, settings)
            self.Text:SetText(script.name)
            self.name = name
            self.script = script
            self.settings = settings
            self:Update()
        end,
        Copy = function(self)
            local name = SilverUI.CopyScript(self.name, self.script, self.settings)
            local parent = self:GetParent()
            parent:Update()
            for scriptFrame in parent'.Script#' do
                if scriptFrame.script.name == name then
                    scriptFrame:Edit()
                    editorWindow.EditorHead.ScriptName:SetFocus()
                    editorWindow.EditorHead.ScriptName:HighlightText()
                    break
                end
            end
        end,
        Delete = function(self)
            SilverUI.DeleteScript(self.name, self.script)
            self:GetParent():Update()
        end,
        Reset = function(self)
            self.script.code = self.script.code_original
            self:Update()
        end,
        Toggle = function(self)
            self.settings.enabled = not self.settings.enabled
            editorWindow:NotifyReloadRequired()
        end,
        Edit = function(self)
            editorWindow:EditScript(self.name, self.script)
        end,
        ResetScript = function(self)
            SilverUI.ResetScript(self.name, self.script)
            self:Update()
        end
    }
    :RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    :Hooks {
        OnClick = function(self, button)
            if button == 'LeftButton' then
                -- editorWindow.CodeEditor.Content.Editor:SetText(self.script.code)
                -- editorWindow.CodeEditor.Content.Editor:SetCursorPosition(0)
            elseif button == 'RightButton' then
                if self.ContextMenu:IsShown() then
                    self.ContextMenu:Hide()
                else
                    self.ContextMenu:Show()
                end
            end
        end
    }
{
    Style'.Text'
        :JustifyH 'LEFT'
        :Points { TOPLEFT = PARENT:TOPLEFT(10, 0),
                  BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-10, 0) },
    Texture'.Disabled':Points { RIGHT = PARENT:RIGHT(-4, 0) }
        :Texture 'Interface/BUTTONS/UI-GROUPLOOT-PASS-DOWN'
        :Desaturated(true)
        :Size(16, 16),
    Texture'.Edited':Points { RIGHT = PARENT.Disabled:RIGHT(-4, 0) }
        :Texture 'Interface/BUTTONS/UI-GuildButton-OfficerNote-Disabled'
        :Size(16, 16),
    FrameContextMenu'.ContextMenu' {
        ButtonContextMenu'.Edit':Text 'Edit script':Click(function(script) script:Edit() end),
        ButtonContextMenu'.Copy':Text 'Copy':Click(function(script) script:Copy() end),
        ButtonContextMenu'.Toggle':Text 'Disable':Click(function(script) script:Toggle() end),
        ButtonContextMenu'.Reset':Text 'Reset settings':Click(function(script) script:Reset() end),
        ButtonContextMenu'.ResetScript':Text 'Reset script':Click(function(script) script:ResetScript() end),
        ButtonContextMenu'.Delete':Text 'Delete':Click(function(script) script:Delete() end),
        ButtonContextMenu'.Cancel':Text 'Cancel'
    }
}


local FrameAddonSection = Frame
    :Height(28)
    .init {
        SetData = function(self, name, account, character)
            self.name = name
            self.account = account
            self.settings = character
            self.Head:SetText(name)
            self {
                Style'.Script#':Hide():Points { TOP = self:TOP() }
            }
            local height = 28
            local previous = self.Head
            for i, script in pairs(account.scripts) do
                self {
                    ButtonAddonScript('.Script' .. i)
                        :Height(18)
                        :Points { TOPLEFT = previous:BOTTOMLEFT(), RIGHT = self:RIGHT() }
                        :Data(name, script, character.scripts[script.name])
                        :Show()
                }
                previous = self['Script' .. i]
                height = height + previous:GetHeight()
            end
            if self.settings.enabled then
                self.Head.Disabled:Hide()
                self.Head.ContextMenu.Toggle:SetText('Disable')
            else
                self.Head.Disabled:Show()
                self.Head.ContextMenu.Toggle:SetText('Enable')
            end
            self:SetHeight(height)
        end,
        Update = function(self)
            self:SetData(self.name, self.account, self.settings)
        end,
        NewScript = function(self)
            local script = SilverUI.NewScript(self.name)
            self:Update()
            for scriptFrame in self'.Script#' do
                if scriptFrame.script.name == script then
                    scriptFrame:Edit()
                    editorWindow.EditorHead.ScriptName:SetFocus()
                    editorWindow.EditorHead.ScriptName:HighlightText()
                    break
                end
            end
        end,
        Toggle = function(self)
            self.settings.enabled = not self.settings.enabled
            editorWindow:NotifyReloadRequired()
        end
    }
    :Hooks {
        OnShow = function(self)
            self:Update()
        end
    }
{
    Btn'.Head':Points { TOPLEFT = PARENT:TOPLEFT(), RIGHT = PARENT:RIGHT() }
        :Height(28)
        :RegisterForClicks('LeftButtonUp', 'RightButtonUp')
        :Hooks {
            OnClick = function(self, button)
                if button == 'RightButton' then
                    if self.ContextMenu:IsShown() then
                        self.ContextMenu:Hide()
                    else
                        self.ContextMenu:Show()
                    end
                end
            end
        }
    {
        Texture'.Disabled':Points { RIGHT = PARENT:RIGHT(-4, 0) }
            :Texture 'Interface/BUTTONS/UI-GROUPLOOT-PASS-DOWN'
            -- :Desaturated(true)
            :BlendMode 'BLEND'
            :Size(16, 16),

        Style'.Text'
            :JustifyH 'LEFT'
            :Points { TOPLEFT = PARENT:TOPLEFT(10, 0),
                      BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-10, 0) },
        Texture'.Bg'
            :Texture 'Interface/BUTTONS/GreyscaleRamp64'
            -- :BlendMode 'ADD'
            :VertexColor(1,1,1,0.2)
            .. ToParent(),
            
        FrameContextMenu'.ContextMenu' {
            ButtonContextMenu'.NewScript':Text 'New script':Click(function(head) head:GetParent():NewScript() end),
            ButtonContextMenu'.Toggle':Text 'Disable':Click(function(head) head:GetParent():Toggle() end),
            ButtonContextMenu'.Cancel':Text 'Cancel'
        }
    },
}


local FrameSettings = Frame
{
    Frame'.Sections'
    {
        -- Texture'.Bg':ColorTexture(1, 1, 1, 0.5) .. ToParent,
        FrameSmoothScroll'.Scroller' .. ToParent()
    }
        .init(function(self, parent)
            self:SetPoints { TOPLEFT = parent:TOPLEFT(),
                          BOTTOMRIGHT = parent:BOTTOMLEFT(200, 0) }
                        
            local previous = nil
            for name, account, character in SilverUI.Addons() do
                local content = self.Scroller.Content
                content {
                    FrameAddonSection('.' .. name)
                }
                if previous then
                    content[name]:SetPoints { TOPLEFT = previous:BOTTOMLEFT(), RIGHT = content:RIGHT() }
                else
                    content[name]:SetPoints { TOPLEFT = content:TOPLEFT(), RIGHT = content:RIGHT() }
                end
                content[name]:SetData(name, account, character)
                previous = content[name]
            end
        end),
    -- Frame'.Options'
    --     .init(function(self, parent)
    --         self:SetPoints { TOPLEFT = parent.Sections:TOPRIGHT(),
    --                       BOTTOMRIGHT = parent:BOTTOMRIGHT() }
    --     end)
    -- {
    --     FrameSmoothScroll'.Scroller' .. ToParent()
    -- },
}


local FrameEditor = Frame
    :Width(1000)
    :Height(600)
    :EnableMouse(true)
    :Point('CENTER', 0, 0)
    -- :ClampedToScreen(true)
    .init {
        buttons = {},
        scriptEditing = nil,
        scriptEditingAddon = nil,
        EditScript = function(self, addonName, script)
            self.scriptEditing = script
            self.scriptEditingAddon = addonName
            self.enterPlaygroundBtn:Hide()
            self.Settings:Hide()
            self.EditorHead.AddonName:SetText(addonName .. '/')
            self.EditorHead.ScriptName:SetText(script.name)
            self.EditorHead.ScriptName:Show()
            self.EditorHead:Show()
            self.CodeEditor:Show()
            self.CodeEditor.Content.Editor.Save = function(code)
                script.code = code
                self.Settings.Sections.Scroller.Content'.Frame':Update()
            end
            self.CodeEditor.Content.Editor:SetText(script.code)
            self.CodeEditor.Content.Editor:SetCursorPosition(0)
            self.CodeEditor.Content.Editor:SetFocus()
            self.CodeEditor:SetVerticalScroll(0)
        end,
        StopEditing = function(self)
            self.scriptEditing = nil
            self.scriptEditingAddon = nil
            self.EditorHead:Hide()
            self.CodeEditor:Hide()
            self.CodeEditor.Content.Editor:SetText('')
            self.Settings:Show()
            self.enterPlaygroundBtn:Show()
        end,
        RenameScript = function(self, name)
            if not self.scriptEditing then return end
            local oldName = self.scriptEditing.name
            if oldName ~= name then
                local addonName = self.scriptEditingAddon
                if SilverUI.HasScript(addonName, name) then
                    self.EditorHead.ScriptName:SetTextColor(1, 0.2, 0.2)
                else
                    self.EditorHead.ScriptName:SetTextColor(1, 1, 1)
                    local settings = SilverUISavedVariablesCharacter.addons[addonName]
                    settings.scripts[name] = settings.scripts[oldName]
                    settings.scripts[oldName] = nil
                    self.scriptEditing.name = name
                end
            end
        end,
        NotifyReloadRequired = function(self)

        end,
        EnterPlayground = function(self)
            self.enterPlaygroundBtn:Hide()
            self.Settings:Hide()
            self.EditorHead.AddonName:SetText('Playground')
            self.EditorHead.ScriptName:Hide()
            self.EditorHead:Show()
            self.CodeEditor:Show()
            self.CodeEditor.Content.Editor.Save = function(code)
                SilverUISavedVariablesCharacter.playground = code
            end
            self.CodeEditor.Content.Editor:SetText(SilverUISavedVariablesCharacter.playground or '\n\n')
            self.CodeEditor.Content.Editor:SetCursorPosition(0)
            self.CodeEditor.Content.Editor:SetFocus()
            self.CodeEditor:SetVerticalScroll(0)
        end
    }
    :Scripts {
        OnKeyDown = function(self, key)
            if key == 'ESCAPE' then
                self:SetPropagateKeyboardInput(false)
                self:Hide()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end
    }
{
    BoxShadow'.Shadow':Alpha(0.5),
    Texture'.TitleBg'
        :Height(24)
        :ColorTexture(0.2, 0.2, 0.2, 0.7)
        :DrawLayer('BACKGROUND', -6)
        :Points { TOPLEFT = PARENT:TOPLEFT(0, -5),
                  RIGHT = PARENT:RIGHT() },

    Frame'.TitleMoveHandler'
        :Height(29)
        -- :FrameLevel(5)
        :Points { TOPLEFT = PARENT:TOPLEFT(),
                  TOPRIGHT = PARENT:TOPRIGHT() }
        :Scripts {
            OnMouseDown = function(self, button)
                if button == 'LeftButton' then
                    self.dragging = true
                    local x, y = GetCursorPosition()
                    local _, _, _, px, py = self:GetParent():GetPoint()
                    local scale = self:GetEffectiveScale()
                    self.dragOffset = { x/scale - px, y/scale - py }
                end
            end,
            OnMouseUp = function(self, button)
                if button == 'LeftButton' then
                    self.dragging = false
                end
            end,
            OnUpdate = function(self, dt)
                if self.dragging then
                    local x, y = GetCursorPosition()
                    local from, frame, to, _, _ = self:GetParent():GetPoint()
                    local scale = self:GetEffectiveScale()
                    self:GetParent():SetPoint(from, frame, to, x/scale - self.dragOffset[1], y/scale - self.dragOffset[2])
                end
            end
        },

    Frame'.Resizer'
        :Size(16, 16)
        :Points { BOTTOMRIGHT = PARENT:BOTTOMRIGHT() }
        :Scripts {
            OnMouseDown = function(self, button)
                self:GetParent():StartSizing('bottomright')
            end,
            OnMouseUp = function(self, button)
                self:GetParent():StopMovingOrSizing()
            end
        }
    {
        Texture'.Texture'
            :AllPoints(PARENT)
            :ColorTexture(1,1,1)
    },

    Texture'.Bg'
        :ColorTexture(0.05,0.05,0.05,0.8)
        :AllPoints(PARENT)
        :DrawLayer('BACKGROUND', -7),

    Btn'.closeBtn'
        :SetText('X')
        :FrameLevel(10)
        :Scripts { OnClick = function(self) self:GetParent():Hide() end }
        :Points { TOPRIGHT = PARENT:TOPRIGHT(-6, -6) },
    
    Btn'.reloadBtn'
        :Size(16, 16)
        :NormalTexture 'Interface/BUTTONS/UI-RefreshButton'
        :FrameLevel(10)
        :Scripts { OnClick = function(self) ReloadUI() end }
        :Points { RIGHT = PARENT.closeBtn:LEFT() },
    
    Button'.pickFrameBtn'
        :NormalTexture 'Interface/CURSOR/UnableCrosshairs'
        :HighlightTexture 'Interface/CURSOR/Crosshairs'
        :FrameLevel(10)
        :Size(16, 16)
        :Points { RIGHT = PARENT.reloadBtn:LEFT(-5, 0) }
        :Scripts {
            OnClick = function(self, button)
                hoverFrame:start()
            end
        },

    Btn'.enterPlaygroundBtn'
        :Height(24)
        :Text 'Playground'
        :Width(100)
        :FrameLevel(10)
        :Points { TOPLEFT = PARENT:TOPLEFT(15, -5) }
        :Scripts {
            OnClick = function(self) self:GetParent():EnterPlayground() end
        }
    {
        Style'.Text'
            :JustifyH 'LEFT'
            :TextColor(0.7, 0.7, 0.7)
    },

    Frame'.EditorHead'
        :Points { TOPLEFT = PARENT:TOPLEFT(3, -17),
                  TOPRIGHT = PARENT:TOPRIGHT(3, -17) }
        :Height(25)
        :Hide()
    {
        Btn'.BackButton'
            :Points { LEFT = PARENT:TOPLEFT(5, 0) }
            :Text '<'
            :Hooks {
                OnClick = function(self)
                    editorWindow:StopEditing()
                end
            },
        FontString'.AddonName'
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            :Points { LEFT = PARENT.BackButton:RIGHT(10, 0) },
        EditBox'.ScriptName'
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            :Size(200, 16)
            :Points { LEFT = PARENT.AddonName:RIGHT() }
            :Hooks {
                OnTextChanged = function(self, text)
                    editorWindow:RenameScript(self:GetText())
                end,
                OnEnterPressed = function(self)
                    editorWindow.CodeEditor.Content.Editor:SetFocus()
                end
            }
        {
            Texture'.ScriptNameBorder'
                :ColorTexture(0.5, 0.5, 0.5, 0.7)
                :Points { TOPLEFT = PARENT:BOTTOMLEFT(),
                        TOPRIGHT = PARENT:BOTTOMRIGHT() }
                :Height(1)
        }
    },

    FrameSmoothScroll'.CodeEditor'
        :Points { TOPLEFT = PARENT.TitleBg:BOTTOMLEFT(),
                  BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-330, 0) }
        :Hide()
    {
        Style'.Content' {

            -- EditBox'.Shadow'
            --     :Points { TOPLEFT = PARENT:TOPLEFT(30,0), TOPRIGHT = PARENT:TOPRIGHT() }
            --     :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
            --     :JustifyH("LEFT")
            --     :JustifyV("TOP")
            --     :MultiLine(true)
            --     :TextColor(0.7, 0.7, 0.7)
            --     :EnableMouse(false),

            Frame'.ClickBackground'
                :AllPoints(PARENT)
                :EnableMouse(true)
                :Scripts {
                    OnMouseDown = function(self)
                        local editor = self:GetParent().Editor
                        editor:SetFocus()
                        editor:SetCursorPosition(#editor:OrigGetText())
                    end
                },

            FontString'.Shadow'
                :Points { TOPLEFT = PARENT:TOPLEFT(40,-3), TOPRIGHT = PARENT:TOPRIGHT() }
                :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
                :JustifyH("LEFT")
                :JustifyV("TOP")
                :TextColor(0.7, 0.7, 0.7),

            EditBox'.Editor'
                .init { function(self, parent) self.parent = parent end }
                .init { Save = function() end }
                :Points { TOPLEFT = PARENT:TOPLEFT(40,-3), TOPRIGHT = PARENT:TOPRIGHT() }
                :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
                :FrameLevel(5)
                :Scripts {
                    OnShow = function(self)
                        self:SetFocus()
                    end,
                    OnEnterPressed = function(self)
                        if not self.CTRL then
                            self:Insert('\n')
                        else
                            local func = assert(loadstring('return function(inspect) ' .. self:GetText() .. '\n end', "silver editor"))
                            local result = { func()(function(frame) SetFrameStack(_, frame) end) }
                            if #result > 0 then
                                print(unpack(result))
                            end
                        end
                    end,
                    OnTabPressed = function(self)
                        if self.SHIFT then
                            local pos = self:GetCursorPosition()
                            local text = self:GetText()
                            local line_start = pos
                            local char = text:sub(pos, pos)

                            while char ~= '\n' and line_start > 1 do
                                line_start = line_start - 1
                                char = text:sub(line_start, line_start)
                            end

                            local delete_end = line_start+1
                            for i = 0, 3 do
                                char = text:sub(delete_end, delete_end)
                                if char ~= ' ' then
                                    break
                                else
                                    delete_end = delete_end + 1
                                end
                            end
                            self:SetText(text:sub(1, line_start) .. text:sub(delete_end))
                        else
                            self:Insert('    ')
                        end
                    end,
                    OnKeyDown = function(self, key)
                        if key == 'LCTRL' or key == 'RCTRL' then
                            self.CTRL = true
                        elseif key == 'LSHIFT' or key == 'RSHIFT' then
                            self.SHIFT = true
                        elseif key == 'LMETA' or key == 'RMETA' then
                            self.CTRL = false
                        elseif key == 'R' and self.CTRL then
                            self.CTRL = false
                            ReloadUI()
                        elseif key == 'F' and self.CTRL then
                            hoverFrame:start()
                        end
                    end,
                    OnKeyUp = function(self, key)
                        if key == 'LCTRL' or key == 'RCTRL' then
                            self.CTRL = false
                        elseif key == 'LSHIFT' or key == 'RSHIFT' then
                            self.SHIFT = false
                        elseif key == 'LMETA' or key == 'RMETA' then
                            self.CTRL = false
                        elseif key == 'ESCAPE' then
                            self.CTRL = false
                            editorWindow:Hide()
                        end
                    end,
                    OnTextChanged = function(self, text)
                        self.parent.Shadow:SetText(self:OrigGetText())
                        self.parent.Shadow:Show()
                        local n = self.parent.Shadow:GetNumLines()
                        local lines = ''
                        for i = 1, n do
                            lines = lines .. string.rep(' ', 4 - string.len('' .. i)) .. i .. '\n'
                        end
                        self.parent.LineNumbers:SetText(lines)
                        local fn, error = loadstring('return function(inspect) ' .. self:GetText() .. '\n end', "silver editor")
                        if fn then
                            self.parent.Error:Hide()
                            self.parent.Red:Hide()
                            self.Save(self:GetText())
                        else
                            self.parent.Error:SetText(error)
                            self.parent.Red:Show()
                            self.parent.Error:Show()
                        end
                    end,
                    OnEditFocusLost = function(self)
                        self.CTRL = false
                    end
                }
                :JustifyH("LEFT")
                :JustifyV("TOP")
                :MultiLine(true)
                .init {
                    function(self)
                        self.OrigGetText = self.GetText
                        self.parent.Shadow.OrigSetText = self.parent.Shadow.SetText
                        LqtIndentationLib.enable(self, nil, 4)
                        -- LqtIndentationLib.enable(self.parent.Shadow, nil, 4)
                    end
                },
        
            FontString'.LineNumbers'
                :Points { TOPRIGHT = PARENT.Editor:TOPLEFT(-4, 0) }
                :JustifyH('LEFT')
                :TextColor(0.7, 0.7, 0.7)
                :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, ''),

            FontString'.Error'
                :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
                :JustifyH 'LEFT'
                :Hide()
                :Points {
                    BOTTOMLEFT = PARENT:GetParent():GetParent():BOTTOMLEFT(2, 2),
                    BOTTOMRIGHT = PARENT:GetParent():GetParent():BOTTOMRIGHT(-2, 2),
                },

            Texture'.Red'
                :ColorTexture(0.3, 0, 0, 0.9)
                :Points { TOPLEFT = PARENT.Error:TOPLEFT(-2, 2),
                          BOTTOMRIGHT = PARENT.Error:BOTTOMRIGHT(2, -2) },

        }
    },

    
    FrameSettings'.Settings'
        :Points { TOPLEFT = PARENT:TOPLEFT(10, -31),
                  BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-330, 15) },

    FrameSmoothScroll'.Inspector'
        :Points { TOPLEFT = PARENT.CodeEditor:TOPRIGHT(5, 0),
                  BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-10, 10) },

}


local StyleBtn = Style
    .data {
        frame = nil,
        is_gui = nil,
        SetFrame = function(self, frame)
            self.frame = frame
            self.is_gui = type(frame) == 'table' and frame.GetObjectType and frame:GetObjectType() and frame.GetNumPoints and frame.GetSize
        end
     }
    :Height(17.5)
    :Show()
    :RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    :Hooks {
        OnEnter = function(self)
            if self.is_gui and self.frame ~= hoverFrame and self.frame ~= hoverFrame.tex and self.frame ~= UIParent then
                hoverFrame:SetAllPoints(self.frame)
                hoverFrame:Show()
            end
        end,

        OnLeave = function(self)
            hoverFrame:SetAllPoints(editorWindow)
            hoverFrame:Hide()
        end,

        OnClick = function(self, button)
            if self.is_gui and button == 'RightButton' then
                if self.frame:IsShown() then
                    self.frame:Hide()
                else
                    self.frame:Show()
                end
            elseif self.is_gui and button == 'LeftButton' then
                SetFrameStack(_, self.frame)
            elseif type(self.frame) == 'table' and button == 'LeftButton' then
                print_table(self.frame)
            end
        end,

    }
    :FrameLevel(10)
{
    Style'.Text'
        :Font('Fonts/ARIALN.TTF', 12, '')
        -- :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11)
}


local function spawn()

    local btnPool = {}

    local create_btn = function()
        local btn = nil
        if #btnPool > 0 then
            btn = btnPool[#btnPool]
            table.remove(btnPool, #btnPool)
            btn:UnhookAll()
            Btn(btn)
        else
            btn = Btn.new()
        end
        btn.Text:SetTextColor(1, 1, 1)
        btn.Text:SetFont('Fonts/FRIZQT__.ttf', 12)
        btn.Text:ClearAllPoints()
        btn.Text:SetPoint('LEFT', btn, 'LEFT', 10, 0)
        return btn
    end

    editorWindow = FrameEditor.new('BackdropTemplate')
    SilverUI.Editor = editorWindow

    hoverFrame = Frame
        :SetFrameStrata('TOOLTIP')
        .data {
            start = function(self)
                self.pick = true
                self:SetAllPoints(UIPanel)
                self:EnableMouse(true)
                self:Show()
                editorWindow:Hide()
            end,
            stop = function(self, stack, smallest)
                self.pick = false
                self.tex:SetAllPoints(self)
                self:EnableMouse(false)
                self:Hide()
                editorWindow:Show()
                SetFrameStack(stack, smallest)
            end
        }
        :Scripts {
            OnMouseDown = function(self, button)
                if button == 'LeftButton' then
                    self:stop(self.lastStack, self.smallest)
                end
            end,
            OnUpdate = function(self, time)
                if self.pick then
                    local stack = C_System.GetFrameStack()
                    if stack ~= self.lastStack then
                        self.lastStack = stack
                        local smallest = UIParent
                        for k, v in pairs(stack) do
                            if v ~= self.tex then
                                local w, h = v:GetSize()
                                local w_c, h_c = smallest:GetSize()
                                if w*h < w_c*h_c then
                                    smallest = v
                                end
                            end
                        end
                        self.smallest = smallest
                        self.tex:SetAllPoints(smallest)
                    end
                end
            end
        }
    {
        Texture'.tex'
            :DrawLayer 'OVERLAY'
            :ColorTexture(0, 1, 0, 0.4)
            .init(function(self, parent) self:SetAllPoints(parent) end)
    }
        .new()

    local lastSelected = nil

    SetFrameStack = function(_, selected)

        if selected ~= lastSelected then
            editorWindow.Inspector:SetVerticalScroll(0)
        end
        lastSelected = selected

        for i = #editorWindow.Inspector.Content.children, 1, -1 do
            editorWindow.Inspector.Content.children[i]:Hide()
            editorWindow.Inspector.Content.children[i]:ClearAllPoints()
            editorWindow.Inspector.Content.children[i]:SetParent(nil)
            table.insert(btnPool, editorWindow.Inspector.Content.children[i])
            table.remove(editorWindow.Inspector.Content.children, i)
        end

        for i = #editorWindow.buttons, 1, -1 do
            editorWindow.buttons[i]:Hide()
            editorWindow.buttons[i]:ClearAllPoints()
            editorWindow.buttons[i]:SetParent(UIParent)
            table.insert(btnPool, editorWindow.buttons[i])
            table.remove(editorWindow.buttons, i)
        end

        assert(#editorWindow.Inspector.Content.children == 0)

        local lastBtn = nil

        local parents = {}
        local parent = selected
        while parent do
            table.insert(parents, { parent, get_name(parent) })
            parent = parent:GetParent()
        end

        local lastBtn = nil
        for i = 1, #parents do
            local c = parents[i][1]

            local btn = create_btn()
            StyleBtn(btn)
                :Frame(c)
                :Parent(editorWindow)
                :FrameLevel(10)
                :Text(parents[i][2])
                :Points(
                    lastBtn and { TOPRIGHT = lastBtn:TOPLEFT(10, 0) }
                             or { BOTTOMLEFT = editorWindow.Inspector:TOPLEFT(0, 5) }
                )
            
            if lastBtn then
                btn.Text:SetTextColor(0.7, 0.7, 0.7)
            end
            btn:SetWidth(btn.Text:GetWidth() + 20)

            table.insert(editorWindow.buttons, btn)

            lastBtn = btn

        end

        lastBtn = nil
        for _, obj in pairs(SortedChildren(selected)) do
            local name = obj[2]
            local c = obj[1]

            local btn = create_btn()
            StyleBtn(btn)
                :Frame(c)
                :Parent(editorWindow.Inspector.Content)
                :Text(name)
                -- :Height(20)
                :Width(editorWindow.Inspector:GetWidth() - 8)
            {
                Style'.Text'
                    :Points { LEFT = btn:LEFT() }
                .. function(self)
                    if not self.is_gui then
                        self:SetTextColor(0.5, 0.5, 0.5)
                    elseif c == selected then
                        self:SetTextColor(1, 1, 0.5)
                    elseif c.IsShown and not c:IsShown() then
                        self:SetTextColor(0.7, 0.7, 0.7)
                    else
                        self:SetTextColor(1, 1, 1)
                    end
                end
            }

            if lastBtn then
                btn:SetPoint('TOPLEFT', lastBtn, 'BOTTOMLEFT', 0, -0)
            else
                btn:SetPoint('TOPLEFT', editorWindow.Inspector.Content, 'TOPLEFT', 10, -0)
            end
            lastBtn = btn

            table.insert(editorWindow.Inspector.Content.children, btn)
        end
    end

    -- SetFrameStack(nil, UIParent)

    -- editorWindow:SetBackdrop({
    --     -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment",
    --     -- bgFile = 'Interface/HELPFRAME/DarkSandstone-Tile',
    --     edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
    --     edgeSize = 10,
    --     tile = true,
    --     tileSize = 300,
    --     insets = { left = 1, right = 1, top = 1, bottom = 1 }
    -- })
    editorWindow:Show()

    editorWindow'.*Corner, .*Edge':SetVertexColor(0.2, 0.2, 0.2, 0.5)
end



SortedChildren = function(obj)

    local result = {}

    local SORT_ATTR = '|c00000000'
    local SORT_DATA = '|c00000001'
    local SORT_GUI = '|c00000002'
    local SORT_FN = '|c00000003'
    local SORT_MT = '|c00000004'

    table.insert(result, {
        nil,
        SORT_ATTR ..
        '|cffaaaaaatype |cffffffff' .. obj:GetObjectType() .. (obj:IsShown() and '' or '|cffaaaaaa H')
    })

    if obj:GetName() then
        table.insert(result, {
            nil,
            SORT_ATTR ..
            '|cffaaaaabname |cffffffff' .. obj:GetName()
        })
    end

    if obj.GetTexture then
        table.insert(result, {
            nil,
            SORT_ATTR ..
            '|cffaaaaabtexture |cffffffff' .. (obj:GetTexture() or 'none')
        })
    end

    local point_names = {
        TOPLEFT = 'TL',
        TOP = 'T',
        TOPRIGHT = 'TR',
        LEFT = 'L',
        CENTER = 'C',
        RIGHT = 'R',
        BOTTOMLEFT = 'BL',
        BOTTOM = 'B',
        BOTTOMRIGHT = 'BR'
    }

    for i = 1, obj:GetNumPoints() do
        pcall(function()
            local point, relativeTo, relativePoint, x, y = obj:GetPoint(i)
            table.insert(result, {
                relativeTo,
                SORT_ATTR ..
                '|cffaaaaac' .. point_names[point] ..
                ' |cffffffff' .. (relativeTo and relativeTo:GetObjectType() or '') .. ' ' ..
                (relativeTo and relativeTo:GetName() or '') .. '.' ..
                point_names[relativePoint] .. '(' .. format_float(x) .. ', ' .. format_float(y) .. ')'
            })
        end)
    end

    local parent = obj:GetParent()
    table.insert(result, {
        parent,
        SORT_ATTR ..
        '|cffaaaaabparent |cffffffff' .. tostring(parent and (parent:GetName() or parent:GetObjectType()))
    })

    local idx = 1
    local visited = {}
    for k, v in pairs(obj) do
        if type(v) ~= 'table' or not v.GetParent or v:GetParent() ~= obj then
            visited[v] = true
            if type(v) == 'table' then
                if v.GetObjectType and v.GetTop and v.GetLeft then
                    table.insert(result, {
                        v,
                        SORT_GUI ..
                        '|cff' .. string.format('%06x', 10000 - idx) ..
                        '|cffffaaff' .. v:GetObjectType() .. ' ' .. (v:IsShown() and '' or '|cffaaaaaaH ') ..
                        '|cffffffff' .. k .. ' ' ..
                        '|cffaaaaaa' .. (v.GetName and (v:GetName() or '') .. ' ' or '') ..
                        '|c00000000' -- ..
                        -- tostring(-(v:GetTop() or 999999)) .. ' ' ..
                        -- tostring(-(v:GetLeft() or 999999))
                    })
                    idx = idx - 1
                else
                    table.insert(result, { v, SORT_DATA .. '|cffffffff' .. k .. ' = |cffffaaaatable'})
                end
            elseif type(v) == 'function' then
                table.insert(result, { v, SORT_FN .. '|cffffafaa fn |cffaaaaff' .. k })
            else
                table.insert(result, {
                    v,
                    SORT_DATA ..
                    '|cffffffff' .. k .. ' = ' ..
                    '|cffffaaaa' .. type(v) .. '|cffaaaaaa ' .. tostring(v) })
            end
        end
    end

    table.insert(result, {
        v,
        SORT_GUI ..
        '|cff' .. string.format('%06x', 10000 - idx) ..
        '|cffaaaaaaChildren'
    })
    idx = idx - 1

    for k, v in pairs(obj) do
        if type(v) == 'table' and v.GetParent and v:GetParent() == obj then
            visited[v] = true
            if v.GetObjectType and v.GetTop and v.GetLeft then
                table.insert(result, {
                    v,
                    SORT_GUI ..
                    '|cff' .. string.format('%06x', 10000 - idx) ..
                    '|cffffaaff' .. v:GetObjectType() .. ' ' .. (v:IsShown() and '' or '|cffaaaaaaH ') ..
                    '|cffffffff' .. k .. ' ' ..
                    '|cffaaaaaa' .. (v.GetName and (v:GetName() or '') .. ' ' or '') ..
                    '|c00000000' -- ..
                    -- tostring(-(v:GetTop() or 999999)) .. ' ' ..
                    -- tostring(-(v:GetLeft() or 999999))
                })
                idx = idx - 1
            else
                table.insert(result, { v, SORT_DATA .. '|cffffffff' .. k .. ' = |cffffaaaatable'})
            end
        end
    end

    if obj.has_lqt then
        for c in LQT.query(obj, '.*') do
            if not visited[c] then
                table.insert(result, {
                    c,
                    SORT_GUI ..
                    '|cff' .. string.format('%06x', 10000 - idx) ..
                    '|cffffaaff' .. c:GetObjectType() .. ' ' .. (c:IsShown() and '' or '|cffaaaaaaH ') ..
                    '|cffffffff ' ..
                    '|cffaaaaaa' .. (c.GetName and (c:GetName() or '') .. ' ' or '') ..
                    '|c00000000' -- ..
                    -- tostring(-(c:GetTop() or 999999)) .. ' ' ..
                    -- tostring(-(c:GetLeft() or 999999))
                })
                idx = idx - 1
            end
        end
    end

    if type(obj) == 'table' then
        local mt = getmetatable(obj)
        if mt and mt.__index then
            
            local all_base_classes = {}

            local fn_visited = {}

            for _, info in pairs(gui_types) do
                local gui_mt = getmetatable(info[2])
                local matching_fns = {}
                local matching_count = 0
                local fn_count = 0
                for attr, value in pairs(gui_mt and gui_mt.__index or {}) do
                    if type(value) == 'function' then
                        fn_count = fn_count + 1
                        if mt.__index[attr] then
                            matching_fns[attr] = true
                            matching_count = matching_count+1
                        end
                    end
                end
                if matching_count == fn_count then
                    for k, v in pairs(matching_fns) do
                        fn_visited[k] = true
                    end
                    table.insert(all_base_classes, { info[1], gui_mt.__index, matching_fns })
                end
            end
            local remaining_fns = {}
            local remaining_count = 0
            for k, v in pairs(mt.__index) do
                if type(v) == 'function' and not fn_visited[k] then
                    remaining_fns[k] = true
                    remaining_count = remaining_count+1
                end
            end
            if remaining_count > 0 then
                table.insert(all_base_classes, { obj:GetObjectType(), mt.__index, remaining_fns })
            end
            
            fn_visited = {}
            for i, info in pairs(all_base_classes) do

                local SORT_TYPE = '|cff' .. string.format('%06x', 9999 - i)

                table.insert(result, { nil,
                    SORT_MT ..
                    SORT_TYPE ..
                    '|c00000000' ..
                    '|cffaaaaaa' .. info[1]
                })
                for k, v in pairs(info[3]) do
                    if not fn_visited[k] then
                        if k:find('^Get') and info[3]['Set'..k:sub(4)] then
                            fn_visited[k] = true
                            fn_visited['Set'..k:sub(4)] = true
                            table.insert(result, { v,
                                SORT_MT ..
                                SORT_TYPE ..
                                SORT_FN ..
                                ' |cfaaaaaaa Get' ..
                                '|cffaafaff' .. k:sub(4) ..
                                '|cffaaaaaa = ' ..
                                attribute_str_values(obj, k)
                            })
                        elseif k:find('^Is') and info[3]['Set'..k:sub(3)] then
                            fn_visited[k] = true
                            fn_visited['Set'..k:sub(3)] = true
                            table.insert(result, { v,
                                SORT_MT ..
                                SORT_TYPE ..
                                SORT_FN ..
                                ' |cfaaaaaaa Is' ..
                                '|cffaafaff' .. k:sub(3) ..
                                '|cffaaaaaa = ' ..
                                attribute_str_values(obj, k)
                            })
                        elseif k:find('^Set') and (info[3]['Get'..k:sub(4)] or info[3]['Is'..k:sub(4)]) then
                            -- let Get and Is handle it
                        else
                            fn_visited[k] = true
                            table.insert(result, { v,
                                SORT_MT ..
                                SORT_TYPE ..
                                SORT_FN ..
                                ' |cffffafaa fn ' ..
                                '|cffaaaaff' .. k
                            })
                        end
                    end
                end
            end

        end
    end

    table.sort(result, function(a, b) return a[2] < b[2] end)

    return result
end


SLASH_GUITREE1 = '/guitree'
SLASH_GUITREE2 = '/gt'

SlashCmdList['GUITREE'] = function(msg, editbox)
    
    if editorWindow then
        if editorWindow:IsShown() then
            editorWindow:Hide()
        else
            editorWindow:Show()
        end
    else
        spawn()
    end

end



