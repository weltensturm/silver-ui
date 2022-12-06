local ADDON, Addon = ...

local     Style,     Frame,     Button,     Texture,     FontString,     EditBox,     ScrollFrame,
          SELF,     PARENT,     ApplyFrameProxy,     FrameProxyMt
    = LQT.Style, LQT.Frame, LQT.Button, LQT.Texture, LQT.FontString, LQT.EditBox, LQT.ScrollFrame,
      LQT.SELF, LQT.PARENT, LQT.ApplyFrameProxy, LQT.FrameProxyMt

local TypeInfo, FillTypeInfo = Addon.TypeInfo, Addon.FillTypeInfo

local
    FrameSmoothScroll,
    CodeEditor,
    BoxShadow,
    ContextMenu,
    ContextMenuButton,
    FrameTraceWindow,
    FrameInspector
    = Addon.FrameSmoothScroll,
      Addon.CodeEditor,
      Addon.BoxShadow,
      Addon.ContextMenu,
      Addon.ContextMenuButton,
      Addon.FrameTraceWindow,
      Addon.FrameInspector


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
        .TOPLEFT:TOPLEFT(10, 0)
        .BOTTOMRIGHT:BOTTOMRIGHT(-10, 0),
    Texture'.Edited'
        .RIGHT:RIGHT(-4,0)
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
                Style'.Script#':Hide().TOP:TOP()
            }
            local height = 28
            local previous = self.Head
            for i, script in pairs(account.scripts) do
                self {
                    ButtonAddonScript('.Script' .. i)
                        :Height(18)
                        .TOPLEFT:BOTTOMLEFT(previous)
                        .RIGHT:RIGHT()
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
    Btn'.Head'
        .TOPLEFT:TOPLEFT()
        .RIGHT:RIGHT()
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
        Texture'.Disabled'
            .RIGHT:RIGHT(-4, 0)
            :Texture 'Interface/BUTTONS/UI-GROUPLOOT-PASS-DOWN'
            -- :Desaturated(true)
            :BlendMode 'BLEND'
            :Size(16, 16),

        Style'.Text'
            :JustifyH 'LEFT'
            .TOPLEFT:TOPLEFT(10, 0)
            .BOTTOMRIGHT:BOTTOMRIGHT(-10, 0),
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
    FrameSmoothScroll'.Sections'
        .TOPLEFT:TOPLEFT()
        .BOTTOMRIGHT:BOTTOMLEFT(200, 0)
        .init(function(self, parent)
            local previous = nil
            for name, account, character in SilverUI.Addons() do
                self.Content {
                    FrameAddonSection('.' .. name)
                        :Data(name, account, character)
                }
                local content = self.Content[name]
                if previous then
                    content:SetPoint('TOPLEFT', previous, 'BOTTOMLEFT')
                else
                    content:SetPoint('TOPLEFT', self.Content, 'TOPLEFT')
                end
                content:SetPoint('RIGHT', self.Content, 'RIGHT')
                previous = content
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
                self.Settings.Sections.Content'.Frame':Update()
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
                collectgarbage()
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
        .TOPLEFT:TOPLEFT(0, -5)
        .RIGHT:RIGHT(),

    Frame'.TitleMoveHandler'
        :Height(29)
        -- :FrameLevel(5)
        .TOPLEFT:TOPLEFT()
        .TOPRIGHT:TOPRIGHT()
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
        .BOTTOMRIGHT:BOTTOMRIGHT()
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
        .TOPRIGHT:TOPRIGHT(-6, -6),
    
    Btn'.reloadBtn'
        :Size(16, 16)
        :NormalTexture 'Interface/BUTTONS/UI-RefreshButton'
        :FrameLevel(10)
        :Scripts { OnClick = function(self) ReloadUI() end }
        .RIGHT:LEFT(PARENT.closeBtn),
    
    Button'.pickFrameBtn'
        :NormalTexture 'Interface/CURSOR/UnableCrosshairs'
        :HighlightTexture 'Interface/CURSOR/Crosshairs'
        :FrameLevel(10)
        :Size(16, 16)
        .RIGHT:LEFT(PARENT.reloadBtn, -5, 0)
        :Scripts {
            OnClick = function(self, button)
                editorWindow.FrameInspector:PickFrame()
            end
        },

    Btn'.enterPlaygroundBtn'
        :Height(24)
        :Text 'Playground'
        :Width(SELF.Text:GetWidth()+20)
        :FrameLevel(10)
        .TOPLEFT:TOPLEFT(15, -5)
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
        .TOPLEFT:TOPRIGHT(PARENT.enterPlaygroundBtn, 3, 0)
        :Scripts {
            OnClick = function(self) self:GetParent():EnterTrace() end
        }
    {
        Style'.Text':TextColor(0.7, 0.7, 0.7)
    },

    Frame'.TracerHead'
        .TOPLEFT:TOPLEFT(3, -17)
        .TOPRIGHT:TOPRIGHT(3, -17)
        :Height(25)
        :Hide()
    {
        Btn'.BackButton'
            .LEFT:TOPLEFT(5, 0)
            :Text '<'
            :Hooks {
                OnClick = function(self)
                    editorWindow:ShowSettings()
                end
            },
        FontString'.Name'
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            .LEFT:RIGHT(PARENT.BackButton, 10, 0)
            :Text 'Trace',
    },

    Frame'.EditorHead'
        .TOPLEFT:TOPLEFT(3, -17)
        .TOPRIGHT:TOPRIGHT(3, -17)
        :Height(25)
        :Hide()
    {
        Btn'.BackButton'
            .LEFT:TOPLEFT(5, 0)
            :Text '<'
            :Hooks {
                OnClick = function(self)
                    editorWindow:ShowSettings()
                end
            },
        FontString'.AddonName'
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            .LEFT:RIGHT(PARENT.BackButton, 10, 0),
        EditBox'.ScriptName'
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            :Size(200, 16)
            .LEFT:RIGHT(PARENT.AddonName)
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
                .TOPLEFT:BOTTOMLEFT()
                .TOPRIGHT:BOTTOMRIGHT()
                :Height(1)
        }
    },

    CodeEditor'.CodeEditor'
        .TOPLEFT:BOTTOMLEFT(PARENT.TitleBg)
        .BOTTOMRIGHT:BOTTOMRIGHT(-330, 0)
        :Hide()
        .data {
            CtrlEnter = function(self, code)
                local func = assert(loadstring('return function(inspect, trace) ' .. code .. '\n end', "silver editor"))
                local result = { func()(
                    function(frame) editorWindow.FrameInspector:SetFrameStack(frame) end,
                    function(...) editorWindow.Tracer:StartTrace(...) end
                ) }
                if #result > 0 then
                    print(unpack(result))
                end
            end
        },

    FrameSettings'.Settings'
        .TOPLEFT:TOPLEFT(0, -30)
        .BOTTOMRIGHT:BOTTOMRIGHT(-330, 15),

    FrameTraceWindow'.Tracer'
        .TOPLEFT:TOPLEFT(0, -30)
        .BOTTOMRIGHT:BOTTOMRIGHT(-330, 15)
        :Hide(),

    FrameInspector'.FrameInspector'
        .TOPLEFT:TOPRIGHT(PARENT.CodeEditor, 5, 0)
        .BOTTOMRIGHT:BOTTOMRIGHT(-10, 10)
        :ClickFunction(function(self, frame, functionName) self:GetParent().Tracer:StartTrace(frame, functionName) end),

}


local function spawn()

    FillTypeInfo()

    editorWindow = FrameEditor.new('BackdropTemplate')
    SilverUI.Editor = editorWindow

    local lastSelected = nil

    editorWindow:Show()

    editorWindow'.*Corner, .*Edge':SetVertexColor(0.2, 0.2, 0.2, 0.5)
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



