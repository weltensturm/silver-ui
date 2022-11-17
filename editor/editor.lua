local ADDON, Addon = ...


local TypeInfo, FillTypeInfo = Addon.TypeInfo, Addon.FillTypeInfo


local     Style,     Frame,     Button,     Texture,     FontString,     EditBox,     ScrollFrame,
          SELF,     PARENT,     ApplyFrameProxy,     FrameProxyMt
    = LQT.Style, LQT.Frame, LQT.Button, LQT.Texture, LQT.FontString, LQT.EditBox, LQT.ScrollFrame,
      LQT.SELF, LQT.PARENT, LQT.ApplyFrameProxy, LQT.FrameProxyMt


local       FrameSmoothScroll,       CodeEditor,       BoxShadow,       ContextMenu,       ContextMenuButton,       FrameTraceWindow
    = Addon.FrameSmoothScroll, Addon.CodeEditor, Addon.BoxShadow, Addon.ContextMenu, Addon.ContextMenuButton, Addon.FrameTraceWindow


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


local function slice(table, start, end_)
    return { unpack(table, start, end_) }
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
        :AllPoints(PARENT),
    Texture'.hoverBg'
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        :AllPoints(PARENT),
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
    return tostring(str):gsub('\r\n', '\\r\\n'):gsub('\n', '\\n')
end


local hoverFrame = nil

local SetFrameStack = nil


local ButtonAddonScript = Btn
    .init {
        Update = function(self)
            if self.settings.enabled then
                self.ContextMenu.Toggle:SetText('Disable')
                self.Text:SetTextColor(1, 1, 1, 1)
            else
                self.ContextMenu.Toggle:SetText('Enable')
                self.Text:SetTextColor(0.5, 0.5, 0.5, 1)
            end
            if self.script.code == self.script.code_original or not self.script.code_original or not self.script.imported then
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
            self:Update()
            editorWindow:NotifyReloadRequired()
        end,
        Edit = function(self)
            editorWindow:EditScript(self.name, self.script)
        end,
        ResetScript = function(self)
            SilverUI.ResetScript(self.name, self.script)
            self:Update()
        end,
        Run = function(self)
            SilverUI.ExecuteScript(self.name, self.script.name, self.script.code)
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
    Texture'.Edited':Points { RIGHT = PARENT:RIGHT(-4,0) }
        :Texture 'Interface/BUTTONS/UI-GuildButton-OfficerNote-Disabled'
        :Size(16, 16),
    ContextMenu'.ContextMenu' {
        ContextMenuButton'.Run':Text 'Run':Click(function(script) script:Run() end),
        ContextMenuButton'.Edit':Text 'Edit script':Click(function(script) script:Edit() end),
        ContextMenuButton'.Copy':Text 'Copy':Click(function(script) script:Copy() end),
        ContextMenuButton'.Toggle':Text 'Disable':Click(function(script) script:Toggle() end),
        ContextMenuButton'.Reset':Text 'Reset settings':Click(function(script) script:Reset() end),
        ContextMenuButton'.ResetScript':Text 'Reset script':Click(function(script) script:ResetScript() end),
        ContextMenuButton'.Delete':Text 'Delete':Click(function(script) script:Delete() end),
        ContextMenuButton'.Cancel':Text 'Cancel'
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
            -- :Texture 'Interface/BUTTONS/GreyscaleRamp64'
            -- :BlendMode 'ADD'
            :ColorTexture(0.3, 0.3, 0.3, 0.5)
            -- :VertexColor(1,1,1,0.2)
            :AllPoints(PARENT),
            
        ContextMenu'.ContextMenu' {
            ContextMenuButton'.NewScript':Text 'New script':Click(function(head) head:GetParent():NewScript() end),
            ContextMenuButton'.Toggle':Text 'Disable':Click(function(head) head:GetParent():Toggle() end),
            ContextMenuButton'.Cancel':Text 'Cancel'
        }
    },
}


local FrameSettings = Frame
{
    Frame'.Sections'
        :Points { TOPLEFT = PARENT:TOPLEFT(),
                  BOTTOMRIGHT = PARENT:BOTTOMLEFT(200, 0) }
    {
        FrameSmoothScroll'.Scroller':AllPoints(PARENT)
    }
        .init(function(self, parent)
                        
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
        end)
}


local FrameEditor = Frame
    :Width(1000)
    :Height(600)
    :FrameStrata 'HIGH'
    :EnableMouse(true)
    :Point('CENTER', 0, 0)
    -- :ClampedToScreen(true)
    :ResizeBounds(520, 210)
    .init {
        buttons = {},
        scriptEditing = nil,
        scriptEditingAddon = nil,
        ShowSettings = function(self)
            self:HideAll()
            self.Settings:Show()
            self.enterPlaygroundBtn:Show()
            self.enterTraceBtn:Show()
        end,
        EditScript = function(self, addonName, script)
            self:HideAll()
            self.scriptEditing = script
            self.scriptEditingAddon = addonName
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
            self:HideAll()
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
        end,
        EnterTrace = function(self)
            self:HideAll()
            self.Tracer:Show()
            self.TracerHead:Show()
        end,
        HideAll = function(self)
            self.scriptEditing = nil
            self.scriptEditingAddon = nil
            self.EditorHead:Hide()
            self.CodeEditor:Hide()
            self.CodeEditor.Content.Editor:SetText('')
            self.Tracer:Hide()
            self.TracerHead:Hide()
            self.Settings:Hide()
            self.enterPlaygroundBtn:Hide()
            self.enterTraceBtn:Hide()
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
        :Width(SELF.Text:GetWidth()+20)
        :FrameLevel(10)
        :Points { TOPLEFT = PARENT:TOPLEFT(15, -5) }
        :Scripts {
            OnClick = function(self) self:GetParent():EnterPlayground() end
        }
    {
        Style'.Text':TextColor(0.7, 0.7, 0.7)
    },

    Btn'.enterTraceBtn'
        :Height(24)
        :Text 'Trace'
        :Width(SELF.Text:GetWidth()+20)
        :FrameLevel(10)
        :Points { TOPLEFT = PARENT.enterPlaygroundBtn:TOPRIGHT(3, 0) }
        :Scripts {
            OnClick = function(self) self:GetParent():EnterTrace() end
        }
    {
        Style'.Text':TextColor(0.7, 0.7, 0.7)
    },

    Frame'.TracerHead'
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
                    editorWindow:ShowSettings()
                end
            },
        FontString'.Name'
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            :Points { LEFT = PARENT.BackButton:RIGHT(10, 0) }
            :Text 'Trace',
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
                    editorWindow:ShowSettings()
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

    CodeEditor'.CodeEditor'
        :Points { TOPLEFT = PARENT.TitleBg:BOTTOMLEFT(),
                BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-330, 0) }
        :Hide()
        .data {
            CtrlEnter = function(self, code)
                local func = assert(loadstring('return function(inspect, trace) ' .. code .. '\n end', "silver editor"))
                local result = { func()(
                    function(frame) SetFrameStack(_, frame) end,
                    function(...) editorWindow.Tracer:StartTrace(...) end
                ) }
                if #result > 0 then
                    print(unpack(result))
                end
            end
        },

    FrameSettings'.Settings'
        :Points { TOPLEFT = PARENT:TOPLEFT(0, -30),
                  BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-330, 15) },

    FrameTraceWindow'.Tracer'
        :Points { TOPLEFT = PARENT:TOPLEFT(0, -30),
                  BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-330, 15) }
        :Hide(),

    FrameSmoothScroll'.Inspector'
        :Points { TOPLEFT = PARENT.CodeEditor:TOPRIGHT(5, 0),
                  BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-10, 10) },

}


local StyleFrameStackButton = Style
    .data {
        reference = nil,
        parents = nil,
        referenceName = nil,
        is_gui = nil,
        SetReference = function(self, reference, parents, referenceName)
            self.reference = reference
            self.parents = parents
            self.referenceName = referenceName
            self.is_gui =
                type(reference) == 'table'
                and reference.GetObjectType
                and reference:GetObjectType()
                and reference.GetNumPoints
                and reference.GetSize
            if self.is_gui then
                self.Text:SetTextColor(1, 0.666, 1)
            else
                self.Text:SetTextColor(1, 1, 1)
            end
        end
     }
    :Height(17.5)
    :Show()
    :RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp')
    :Hooks {
        OnEnter = function(self)
            if self.is_gui and self.reference ~= hoverFrame and self.reference ~= hoverFrame.tex and self.reference ~= UIParent then
                hoverFrame:SetAllPoints(self.reference)
                hoverFrame:Show()
            end
        end,

        OnLeave = function(self)
            hoverFrame:SetAllPoints(editorWindow)
            hoverFrame:Hide()
        end,

        OnClick = function(self, button)
            if self.is_gui and button == 'RightButton' then
                if self.reference:IsShown() then
                    self.reference:Hide()
                else
                    self.reference:Show()
                end
            elseif button == 'LeftButton' then
                if self.is_gui then
                    SetFrameStack(_, self.reference)
                elseif type(self.reference) == 'table' then
                    local parents = {}
                    for _, v in ipairs(self.parents) do
                        table.insert(parents, v)
                    end
                    table.insert(parents, 1, { self.reference, self.referenceName })
                    SetFrameStack(_, self.reference, parents)
                else
                    if self.referenceName and self.parents[1][1][self.referenceName] then
                        editorWindow.Tracer:StartTrace(self.parents[1][1], self.referenceName)
                    end
                end
            elseif button == 'MiddleButton' then
                editorWindow.Tracer:StartTrace(PlayerCastingBarFrame, 'SetPointBase')
            end
        end,

    }
    :FrameLevel(10)
{
    Style'.Text'
        :Alpha(1)
        :Font('Fonts/ARIALN.TTF', 12, '')
        -- :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11)
}


local function spawn()

    FillTypeInfo()

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

    SetFrameStack = function(_, selected, parents)

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

        if not parents then
            parents = {}
            local parent = selected
            while parent and parent.GetParent do
                table.insert(parents, { parent, get_name(parent) })
                parent = parent:GetParent()
            end
        end

        local lastBtn = nil
        for i = 1, #parents do
            local reference = parents[i][1]

            local btn = create_btn()
            StyleFrameStackButton(btn)
                :Reference(reference, slice(parents, i+1), parents[i][2])
                :Parent(editorWindow)
                :FrameLevel(10)
                :Text(parents[i][2])
                :Points(
                    lastBtn and { TOPRIGHT = lastBtn:TOPLEFT(10, 0) }
                             or { BOTTOMLEFT = editorWindow.Inspector:TOPLEFT(0, 0) }
                )
            
            btn.Text:SetAlpha(lastBtn and 0.7 or 1)
            btn:SetWidth(btn.Text:GetWidth() + 20)

            table.insert(editorWindow.buttons, btn)

            lastBtn = btn

        end

        lastBtn = nil
        for _, obj in pairs(SortedChildren(selected)) do
            local reference = obj[1]
            local name = obj[2]
            local attrName = obj[3]

            local btn = create_btn()
            StyleFrameStackButton(btn)
                :Reference(reference, parents, attrName)
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
                    elseif reference == selected then
                        self:SetTextColor(1, 1, 0.5)
                    elseif reference.IsShown and not reference:IsShown() then
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

    if obj.GetObjectType and obj.IsShown then
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
    end

    if obj.GetTexture then
        table.insert(result, {
            nil,
            SORT_ATTR ..
            '|cffaaaaabtexture |cffffffff' .. (obj:GetTexture() or 'none')
        })
    end

    if obj.GetNumPoints then
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
    end

    if obj.GetParent then
        local parent = obj:GetParent()
        table.insert(result, {
            parent,
            SORT_ATTR ..
            '|cffaaaaabparent |cffffffff' .. tostring(parent and (parent:GetName() or parent:GetObjectType()))
        })
    end

    local idx = 10000
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
                        , k
                    })
                    idx = idx - 1
                else
                    table.insert(result, { v, SORT_DATA .. '|cffffffff' .. k .. ' = |cffffaaaatable', k })
                end
            elseif type(v) == 'function' then
                table.insert(result, { v, SORT_FN .. '|cffffafaa fn |cffaaaaff' .. k, k })
            else
                table.insert(result, {
                    v,
                    SORT_DATA ..
                    '|cffffffff' .. k .. ' = ' ..
                    '|cffffaaaa' .. type(v) .. '|cffaaaaaa ' .. tostring(v):gsub('\n', '\\n') })
            end
        end
    end

    local hasChildren = false
    local hasChildrenIndex = idx
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
                hasChildren = true
            else
                table.insert(result, { v, SORT_DATA .. '|cffffffff' .. k .. ' = |cffffaaaatable'})
            end
        end
    end

    if hasChildren then
        table.insert(result, {
            v,
            SORT_GUI ..
            '|cff' .. string.format('%06x', 10000 - hasChildrenIndex) ..
            '|cffaaaaaaChildren'
        })
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

            for _, info in pairs(TypeInfo) do
                local matching_fns = {}
                local matching_count = 0
                local fn_count = 0
                for attr, value in pairs(info[2] or {}) do
                    fn_count = fn_count + 1
                    if mt.__index[attr] then
                        matching_fns[attr] = true
                        matching_count = matching_count+1
                    end
                end
                if fn_count > 0 and matching_count == fn_count then
                    for k, v in pairs(matching_fns) do
                        fn_visited[k] = true
                    end
                    table.insert(all_base_classes, { info[1], info[2], matching_fns })
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
                                attribute_str_values(obj, k),
                                'Set'..k:sub(4)
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
                                attribute_str_values(obj, k),
                                'Set'..k:sub(3)
                            })
                        
                        elseif k:find('^Get') or k:find('^Is') then
                            fn_visited[k] = true
                            table.insert(result, { v,
                                SORT_MT ..
                                SORT_TYPE ..
                                SORT_FN ..
                                ' |cffffafaa fn ' ..
                                '|cffaaaaff' .. k ..
                                '|cfaaaaaaa = ' .. attribute_str_values(obj, k),
                                k
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
                                '|cffaaaaff' .. k,
                                k
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



