---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local query = LQT.query
local Hook = LQT.Hook
local Script = LQT.Script
local Style = LQT.Style
local Frame = LQT.Frame
local Button = LQT.Button
local Texture = LQT.Texture
local FontString = LQT.FontString
local EditBox = LQT.EditBox
local ScrollFrame = LQT.ScrollFrame
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local ApplyFrameProxy = LQT.ApplyFrameProxy
local FrameProxyMt = LQT.FrameProxyMt

local TypeInfo = Addon.TypeInfo
local FillTypeInfo = Addon.FillTypeInfo

local FrameSmoothScroll = Addon.FrameSmoothScroll
local CodeEditor = Addon.CodeEditor
local BoxShadow = Addon.BoxShadow
local ContextMenu = Addon.ContextMenu
local ContextMenuButton = Addon.ContextMenuButton
local FrameTraceWindow = Addon.FrameTraceWindow
local RenameBox = Addon.RenameBox
local FrameInspector = Addon.FrameInspector
local PixelAnchor = Addon.Templates.PixelAnchor
local PixelSizex2 = Addon.Templates.PixelSizex2
local Event = Addon.Event

local TraceReceived = Addon.TraceReceived
local SidebarEnter = Event()
local SidebarLeave = Event()
local SidebarAnim = Event()
local OnPage = Event()


local editorWindow = nil



local CubicInOut = function(x)
    return x < 0.5
        and 4 * x^3
         or 1 - (-2 * x + 2)^3 / 2;
end


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


local Bubble = setmetatable(
    {},
    {
        __index = function(bubble, ev)
            if not rawget(bubble, ev) then

                bubble[ev] = Style {
                    function(widget, parent)
                        if widget:HasScript(ev) then
                            widget:HookScript(ev, function(self, ...)
                                parent:GetScript(ev)(parent, ...)
                            end)
                        elseif widget[ev] then
                            hooksecurefunc(widget[ev], function(self, ...)
                                parent[ev](parent, ...)
                            end)
                        else
                            assert(false, 'Cannot bubble ' .. ev)
                        end
                    end
                }

            end
            return rawget(bubble, ev)
        end
    }
)


local BubbleHover = Style { Bubble.OnEnter, Bubble.OnLeave }


local SortedChildren = nil


local SidebarMouseHooks = Style {
    [Script.OnEnter] = function(self)
        SidebarEnter('mouse')
    end,
    [Script.OnLeave] = function(self)
        SidebarLeave('mouse')
    end,
}


local ExpandDownButton = Button { BubbleHover }
    :RegisterForClicks('LeftButtonUp', 'LeftButtonDown')
    :Height(16)
{
    function(self, parent)
        -- table.insert(parent.buttons, self)
        self.menu = parent
        self.menu:AddButton(self)
    end,
    SetText = function(self, ...)
        self.Text:SetText(...)
    end,
    SetClick = function(self, fn)
        self.Click = fn
    end,

    [Script.OnEnter] = function(self)
        self.hoverBg:Show()
    end,
    [Script.OnLeave] = function(self)
        self.hoverBg:Hide()
    end,

    [Script.OnClick] = function(self, button, down)
        if down then
            self.menu.ClickTracker:SetFocus()
        else
            self.menu:MenuClose()
            if self.Click then
                self.Click(self.menu:GetParent())
            end
        end
    end,

    Text = FontString
        :SetFont('Fonts/ARIALN.ttf', 12)
        .LEFT:LEFT(12, 0)
        :JustifyH 'LEFT',
    hoverBg = Texture
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        :AllPoints(PARENT),
}


local ExpandDownMenu = ScrollFrame { BubbleHover }
    .TOPLEFT:BOTTOMLEFT()
    .TOPRIGHT:BOTTOMRIGHT()
    :Height(1)
{
    buttons = {},

    function(self, parent)
        self:SetScrollChild(self.Container)
    end,

    AddButton = function(self, button)
        button:SetParent(self.Container)
        table.insert(self.buttons, button)
    end,

    MenuOpen = function(self)
        self.ClickTracker:SetFocus()
        SidebarEnter('dropdown')
        local previous = nil
        local width = 1
        local height = 0
        for _, btn in pairs(self.buttons) do
            btn:SetPoint('RIGHT', self, 'RIGHT')
            if previous then
                btn:SetPoint('TOPLEFT', previous, 'BOTTOMLEFT')
            else
                btn:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, -1)
            end
            height = height + btn:GetHeight()
            previous = btn
        end
        -- self:SetSize(width+24, height+12)
        self.targetHeight = height + 1
        self.animTarget = 1
    end,

    MenuClose = function(self)
        SidebarLeave('dropdown')
        self.animTarget = 0
    end,

    MenuToggle = function(self)
        if self.animTarget == 1 then
            self:MenuClose()
        else
            self:MenuOpen()
        end
    end,

    [Script.OnHide] = function(self)
        self.anim = 0
        self:SetHeight(1)
    end,

    Container = Frame { BubbleHover }
        :AllPoints(PARENT),

    ClickTracker = EditBox
        :AutoFocus(false)
        :Alpha(0)
        .BOTTOM:TOP(UIParent)
        :PropagateKeyboardInput(true)
    {
        [Script.OnEditFocusLost] = function(self)
            self:GetParent():MenuClose()
        end,
        [Script.OnEditFocusGained] = function(self)
            self:GetParent():MenuOpen()
        end
    },

    background = Texture
        .TOPLEFT:TOPLEFT(0, -1)
        .BOTTOMRIGHT:BOTTOMRIGHT()
        :ColorTexture(0, 0, 0, 0.5),

    anim = 0,
    animTarget = 0,
    [Script.OnUpdate] = function(self, dt)
        if self.anim ~= self.animTarget then
            local sign = self.anim >= self.animTarget and -1 or 1
            local new = math.max(sign > 0 and 0 or self.animTarget,
                                 math.min(sign > 0 and self.animTarget or 1,
                                          self.anim + sign * dt*5))
            self.anim = new
            self:SetHeight(1 + self.targetHeight * CubicInOut(self.anim))
        end
    end,

}



local StyledButton = Button {
    Style:SetSize(20, 20),

    [Script.OnEnter] = function(self)
        self.hoverBg:Show()
    end,

    [Script.OnLeave] = function(self)
        self.hoverBg:Hide()
    end,

    SetText = function(self, ...)
        self.Text:SetText(...)
    end,

    SetFont = function(self, font, size, flags)
        self.Text:SetFont(font, size, flags)
        if self.textSized then
            self:ToTextSize()
        end
    end,

    ToTextSize = function(self)
        self.Text:ClearAllPoints()
        self.Text:SetPoint('LEFT', self, 'LEFT')
        self.Text:SetWidth(0)
        self:SetSize(self.Text:GetSize())
        self.textSized = true
    end,

    Text = FontString
        :SetFont('Fonts/FRIZQT__.ttf', 12)
        :AllPoints(PARENT),

    hoverBg = Texture
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.1)
        :Hide()
        :AllPoints(PARENT)
}



local ScriptEntry = Frame { SidebarMouseHooks } {
    Update = function(self)
        if self.settings.enabled then
            self.ContextMenu.Toggle:SetText('Disable')
            self.Disabled:Hide()
            self.Enabled:Show()
        else
            self.ContextMenu.Toggle:SetText('Run automatically')
            self.Disabled:Show()
            self.Enabled:Hide()
        end
        if self.script.code == self.script.code_original or not self.script.code_original or not self.script.imported then
            self.ContextMenu.ResetScript:Disable()
            self.ContextMenu.ResetScript.Text:SetTextColor(0.5, 0.5, 0.5)
        else
            self.ContextMenu.ResetScript:Enable()
            self.ContextMenu.ResetScript.Text:SetTextColor(1, 1, 1)
        end
    end,
    SetData = function(self, name, script, settings)
        self.Button:SetText(script.name)
        self.Button.Name:SetText(script.name)
        self.Button.Name:SetCursorPosition(0)
        self.name = name
        self.script = script
        self.settings = settings or { enabled=false }
        self:Update()
    end,
    Reset = function(self)
        self.script.code = self.script.code_original
        self:Update()
    end,
    Edit = function(self)
        editorWindow:EditScript(self.name, self.script)
    end,
    ResetScript = function(self)
        SilverUI.ResetScript(self.name, self.script)
        self:Update()
    end,
    SetName = function(self, name)
        self.script.name = name
    end,
    Rename = function(self)
        self.Button.Name:Edit()
    end,

    [SidebarAnim] = function(self, state)
        self.Button.Name:SetAlpha(state)
        self.ContextMenu:SetAlpha(state)
        self.ActiveBg:SetAlpha(state*0.2)
    end,

    [OnPage] = function(self, page, script)
        local show = page == 'script' and self.script == script
        self.Selected:SetShown(show)
        self.ActiveBg:SetShown(show)
    end,

    Button = StyledButton { BubbleHover }
        :AllPoints()
        :RegisterForClicks('AnyUp')
    {
        ['.Text'] = Style:Alpha(0),

        Name = RenameBox { BubbleHover }
            .TOPLEFT:TOPLEFT(10, 0)
            .BOTTOMRIGHT:BOTTOMRIGHT()
            :EnableMouse(false)
        {
            [SELF.Edit] = function(self)
                SidebarEnter('keyboard')
            end,
            [SELF.Save] = function(self)
                self:GetParent():GetParent():SetName(self:GetText())
                self:GetParent():GetParent():Edit()
                SidebarLeave('keyboard')
            end,
            [SELF.Cancel] = function(self)
                SidebarLeave('keyboard')
            end,
        },

        [Script.OnClick] = function(self, button)
            if button == 'LeftButton' then
                -- editorWindow.CodeEditor.Content.Editor:SetText(self.script.code)
                -- editorWindow.CodeEditor.Content.Editor:SetCursorPosition(0)
                self:GetParent():Edit()
            elseif button == 'RightButton' then
                self:GetParent().ContextMenu:MenuToggle()
            end
        end,
    },

    ActiveBg = Texture
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        :AllPoints(PARENT),

    Enabled = Texture
        .LEFT:LEFT(3.5, 0)
        :Size(14, 14)
        :Texture 'Interface/AddOns/silver-ui/art/icons/dot'
        :VertexColor(1, 1, 1, 0.5)
        :Hide(),

    Disabled = Texture
        .LEFT:LEFT(3.5, 0)
        :Size(14, 14)
        :Texture 'Interface/AddOns/silver-ui/art/icons/dot-split'
        :VertexColor(1, 1, 1, 0.5)
        :Hide(),

    Selected = Texture
        .LEFT:LEFT(3.5, 0)
        :Size(14, 14)
        :Texture 'Interface/AddOns/silver-ui/art/icons/circle'
        :Hide(),

    ContextMenu = ExpandDownMenu {
        Run = ExpandDownButton
            :Text 'Run'
            :Click(function(parent)
                SilverUI.ExecuteScript(parent.name, parent.script.name, parent.script.code)
            end),
        Rename = ExpandDownButton
            :Text 'Rename'
            :Click(function(parent)
                parent.Button.Name:Edit()
            end),
        Copy = ExpandDownButton
            :Text 'Copy'
            :Click(function(parent)
                local name, script = SilverUI.CopyScript(parent.name, parent.script, parent.settings)
                parent:GetParent():Update()
                editorWindow:EditScript(name, script)
            end),
        Toggle = ExpandDownButton
            :Text 'Disable'
            :Click(function(parent)
                parent.settings.enabled = not parent.settings.enabled
                parent:Update()
            end),
        ResetScript = ExpandDownButton:Text 'Reset script':Click(function(script) script:ResetScript() end),
        Delete = ExpandDownButton
            :Text 'Delete'
            :Click(function(parent)
                SilverUI.DeleteScript(parent.name, parent.script)
                parent:GetParent():Update()
            end),
    }
}


local FrameAddonSection = Frame
    :Height(28)
{
    scriptButtons = {},
    SetData = function(self, name, account, character)
        self.name = name
        self.account = account
        self.settings = character
        for _, button in pairs(self.scriptButtons) do
            button:Hide()
            button:SetPoint('TOP', self, 'TOP')
        end
        local height = 28
        local previous
        for i, script in pairs(account.scripts) do
            if not self.scriptButtons[i] then
                self.scriptButtons[i] = ScriptEntry
                    :Height(18)
                    .RIGHT:RIGHT()
                    .new(self)
            end
            local button = self.scriptButtons[i]
            if previous then
                button:SetPoint('TOPLEFT', previous.ContextMenu, 'BOTTOMLEFT', 0, -1)
            else
                button:SetPoint('TOPLEFT', self, 'TOPLEFT')
            end
            button:SetData(name, script, character.scripts[script.name])
            button:Show()
            height = height + button:GetHeight()
            previous = button
        end
        self:SetHeight(height)
    end,
    Update = function(self)
        self:SetData(self.name, self.account, self.settings)
    end,
    NewScript = function(self)
        local script = SilverUI.NewScript(self.name)
        self:Update()
        for _, button in pairs(self.scriptButtons) do
            if button.script.name == script then
                button:Rename()
                break
            end
        end
    end,
    Toggle = function(self)
        self.settings.enabled = not self.settings.enabled
    end,

    [Script.OnShow] = function(self)
        self:Update()
    end,

}


local SidebarButton = StyledButton { SidebarMouseHooks } {

    Selected = Texture
        .LEFT:LEFT(3.5, 0)
        :Size(14, 14)
        :Texture 'Interface/AddOns/silver-ui/art/icons/circle'
        :Hide(),

    [SidebarAnim] = function(self, state)
        self.Text:SetAlpha(state)
    end,

    ['.Text'] = Style
        :JustifyH 'LEFT'
        :ClearAllPoints()
        :Font('Fonts/ARIALN.TTF', 12, '')
        .TOPLEFT:TOPLEFT(21, 0)
        .BOTTOMLEFT:BOTTOMLEFT(21, 0),
}


local Sidebar = FrameSmoothScroll
    :EnableMouse(true)
{
    anim = 1,
    animTarget = 0,
    entered = {},

    Expand = function(self)
        self.animTarget = 1
    end,

    Contract = function(self)
        self.animTarget = 0
    end,

    [SidebarEnter] = function(self, obj)
        self.entered[obj] = true
        self:Expand()
    end,

    [SidebarLeave] = function(self, obj)
        self.entered[obj] = nil
        if not next(self.entered) then
            self:Contract()
        end
    end,

    [Script.OnUpdate] = function(self, dt)
        if self.anim ~= self.animTarget then
            local sign = self.anim >= self.animTarget and -1 or 1
            local new = math.max(sign > 0 and 0 or self.animTarget,
                                 math.min(sign > 0 and self.animTarget or 1,
                                          self.anim + sign * dt*5))
            self.anim = new
            self:SetWidth(20 + 130 * CubicInOut(self.anim))
            SidebarAnim(self.anim)
        end
    end,

    ['.Content'] = Style { SidebarMouseHooks } {

        EnterTrace = StyledButton { BubbleHover }
            .TOPLEFT:TOPLEFT(0, -6)
            .TOPRIGHT:TOPRIGHT(0, -6)
            :Height(20)
            :Text 'Tracers'
        {
            [Script.OnClick] = function(self)
                editorWindow:EnterTrace()
            end,

            [SidebarAnim] = function(self, state)
                self.Text:SetAlpha(state)
                self.ActiveBg:SetAlpha(state*0.2)
            end,

            [OnPage] = function(self, page)
                self.Selected:SetShown(page == 'tracer')
                self.ActiveBg:SetShown(page == 'tracer')
            end,

            ActiveBg = Texture
                :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
                :BlendMode 'ADD'
                :VertexColor(1,1,1,0.2)
                :Hide()
                :AllPoints(PARENT),

            Crosshair = Texture
                .LEFT:LEFT(3.5, 0)
                :Size(14, 14)
                :Texture 'Interface/AddOns/silver-ui/art/icons/crosshair'
                :Alpha(0.5),

            HitMarker = Texture
                .LEFT:LEFT(3.5, 0)
                :Size(14, 14)
                :Texture 'Interface/AddOns/silver-ui/art/icons/hitmarker'
                :VertexColor(1, 1, 0)
                :Alpha(0)
            {
                [TraceReceived] = function(self)
                    self:SetAlpha(1)
                end
            },
            [Script.OnUpdate] = function(self, dt)
                local current = self.HitMarker:GetAlpha()
                if current > 0 then
                    self.HitMarker:SetAlpha(math.max(current - dt*2, 0))
                end
            end,

            Selected = Texture
                .LEFT:LEFT(3.5, 0)
                :Size(14, 14)
                :Texture 'Interface/AddOns/silver-ui/art/icons/circle'
                :Hide(),

            ['.Text'] = Style
                :JustifyH 'LEFT'
                :ClearAllPoints()
                :Font('Fonts/ARIALN.TTF', 12, '')
                .TOPLEFT:TOPLEFT(21, 0)
                .BOTTOMLEFT:BOTTOMLEFT(21, 0),
        },

        ScriptLabel = FontString
            .TOPLEFT:BOTTOMLEFT(PARENT.EnterTrace, 10, 0)
            -- .RIGHT:RIGHT()
            :Height(25)
            :JustifyH 'LEFT'
            :Font('Fonts/FRIZQT__.ttf', 12)
            :Text 'Scripts'
            :TextColor(0.6, 0.6, 0.6),
        ScriptAdd = Button { SidebarMouseHooks }
            .LEFT:RIGHT(PARENT.ScriptLabel, 2, 0)
            :Size(14, 14)
            :NormalTexture 'Interface/AddOns/silver-ui/art/icons/plus'
        {
            [Script.OnClick] = function(self)
                editorWindow:NewScript()
            end,
        },
        [SidebarAnim] = function(self, state)
            self.ScriptLabel:SetAlpha(state)
            self.ScriptAdd:SetAlpha(state)
        end,

        Scratchpad = SidebarButton
            .TOPLEFT:BOTTOMLEFT(PARENT.ScriptLabel, -10, 0)
            .RIGHT:RIGHT()
            :Text 'Scratchpad'
        {
            Smile = Texture
                .LEFT:LEFT(3.5, 0)
                :Size(14, 14)
                :Texture 'Interface/AddOns/silver-ui/art/icons/smile'
                :VertexColor(1, 1, 1, 0.5),
            ActiveBg = Texture
                :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
                :BlendMode 'ADD'
                :VertexColor(1,1,1,0.2)
                :Hide()
                :AllPoints(PARENT),
            [Script.OnClick] = function(self)
                editorWindow:EditScratchpad()
            end,
            [OnPage] = function(self, page)
                self.Selected:SetShown(page == 'scratchpad')
                self.ActiveBg:SetShown(page == 'scratchpad')
            end,
            [SidebarAnim] = function(self, state)
                self.ActiveBg:SetAlpha(0.2*state)
            end
        },

        Scripts = Frame
            .TOPLEFT:BOTTOMLEFT(PARENT.Scratchpad)
            .RIGHT:RIGHT()
        {
            function(self, parent)
                local previous = nil
                local height = 0
                for name, account, character in SilverUI.Addons() do
                    Style(self){
                        [name] = FrameAddonSection
                            :Data(name, account, character)
                    }
                    local content = self[name]
                    if previous then
                        content:SetPoint('TOPLEFT', previous, 'BOTTOMLEFT')
                    else
                        content:SetPoint('TOPLEFT', self, 'TOPLEFT')
                    end
                    content:SetPoint('RIGHT', self, 'RIGHT')
                    height = height + content:GetHeight()
                    previous = content
                end
                self:SetHeight(height)
            end,

            Update = function(self)
                for script in query(self, '.*') do
                    script:Update()
                end
            end
        },
    },

}


local PageMain = FrameSmoothScroll {

    bg = Texture
        :AllPoints()
        :ColorTexture(0.2, 0.2, 0.2, 0.5),

    shadow = BoxShadow
        :EdgeSize(4)
        :Alpha(0.5),

    ['.Content'] = Style {

        [Script.OnMouseDown] = function(self)
            local editor = self.CodeEditor.Editor
            editor:SetFocus()
            editor:SetCursorPosition(#editor:OrigGetText())
        end,

        EditorHead = Frame
            .TOPLEFT:TOPLEFT()
            .RIGHT:RIGHT()
            :Height(20)
        {
            bg = Texture
                .BOTTOMLEFT:BOTTOMLEFT()
                .BOTTOMRIGHT:BOTTOMRIGHT()
                :Height(2)
                :ColorTexture(0.3, 0.3, 0.3, 0.5),

            label = FontString
                :Font('Fonts/ARIALN.ttf', 12, '')
                :Height(20-2)
                .BOTTOMLEFT:BOTTOMLEFT(25, 0)
                :TextColor(0.7, 0.7, 0.7),

            [OnPage] = function(self, page, script)
                if page == 'script' then
                    self.label:SetText(script.name)
                elseif page == 'scratchpad' then
                    self.label:SetText('Scratchpad')
                elseif page == 'raw' then
                    self.label:SetText(script)
                end
            end,
        },

        CodeEditor = CodeEditor
            .TOPLEFT:BOTTOMLEFT(PARENT.EditorHead)
            .RIGHT:RIGHT()
        {
            [SELF.CtrlEnter] = function(self, code)
                local func = assert(loadstring('return function(inspect, trace, this, Addon) ' .. code .. '\n end', "silver editor"))
                local ok, error = pcall(
                    func(),
                    function(frame) editorWindow.FrameInspector:SetFrameStack(frame) end,
                    function(...) editorWindow.Tracer:StartTrace(...) end,
                    editorWindow.FrameInspector.selected,
                    Addon
                )
                if not ok then
                    self:OnError(error)
                end
            end,

            [SELF.OnError] = function(self, error)
                local e = self:GetParent():GetParent().Error
                if error then
                    e.Text:SetText(error)
                    e.Text:Show()
                    e.Background:Show()
                else
                    e.Text:Hide()
                    e.Background:Hide()
                end
            end,

            ['.Editor'] = Style
                :AutoFocus(false),
            paddingBottom = Frame
                .TOP:BOTTOM(PARENT.Editor)
                :Size(1, 50)
        },

    },

    Error = Frame
        :AllPoints()
    {
        Text = FontString
            :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
            :JustifyH 'LEFT'
            :Hide()
            .BOTTOMLEFT:BOTTOMLEFT(2, 2)
            .BOTTOMRIGHT:BOTTOMRIGHT(-2, 2),

        Background = Texture
            :ColorTexture(0.2, 0.07, 0.07, 0.9)
            .TOPLEFT:TOPLEFT(PARENT.Text, -2, 2)
            .BOTTOMRIGHT:BOTTOMRIGHT(PARENT.Text, 2, -2),
    },

}



local PageSettings = FrameSmoothScroll {

    function(self, parent)
        self.Content.editor = parent
    end,

    ['.Content'] = Style {

        backButton = StyledButton
            .TOPLEFT:TOPLEFT(10, -3)
            :Text '< Back'
            :ToTextSize()
            :Font('Fonts/FRIZQT__.ttf', 12, '')
        {
            [Script.OnClick] = function(self)
                self:GetParent().editor:ShowMain()
            end,
            ['.Text'] = Style
                :TextColor(0.7, 0.7, 0.7)
        },
        label = FontString
            .TOPLEFT:BOTTOMLEFT(PARENT.backButton)
            :Font('Fonts/FRIZQT__.ttf', 16, '')
            :Text 'Settings',

    }

}


local FrameDTT = Frame { PixelAnchor, PixelSizex2 }
    :Width(1000)
    :Height(600)
    .TOPLEFT:TOPLEFT(300, -200)
    :EnableMouse(true)
    :Toplevel(true)
{
    function(self)
        self.editor = self.PageMain.Content.CodeEditor.Editor
        self.scripts = self.SideBar.Content.Scripts
    end,
    buttons = {},
    scriptEditing = nil,
    ShowMain = function(self)
        self:HideAll()
        self.PageMain:Show()
        self.FrameInspector:Show()
    end,
    EditScript = function(self, name, script)
        self:ShowMain()
        self.scriptEditing = script
        -- self.CodeEditor:Show()
        self.editor.Save = function(code)
            if code ~= script.code then
                script.code = code
                self.scripts:Update()
            end
        end
        self.editor:ClearHistory()
        self.editor:SetText(script.code)
        self.editor:SetCursorPosition(0)
        self.editor:SetFocus()
        self.PageMain:SetVerticalScroll(0)
        OnPage('script', script)
    end,
    RenameScript = function(self, name)
    end,
    NewScript = function(self)
        self.scripts['Silver UI']:NewScript()
    end,
    EditScratchpad = function(self)
        self:ShowMain()
        self.scriptEditing = 'scratchpad'
        self.editor.Save = function(code)
            SilverUISavedVariablesCharacter.playground = code
        end
        self.editor:ClearHistory()
        self.editor:SetText(SilverUISavedVariablesCharacter.playground or '\n\n')
        self.editor:SetCursorPosition(0)
        self.editor:SetFocus()
        self.PageMain:SetVerticalScroll(0)
        OnPage('scratchpad')
    end,
    EditRawValue = function(self, value, name)
        self:ShowMain()
        self.scriptEditing = 'raw'
        -- self.CodeEditor:Show()
        self.editor.Save = function(code) end
        self.editor:ClearHistory()
        self.editor:SetText(value)
        self.editor:SetCursorPosition(0)
        self.editor:SetFocus()
        self.PageMain:SetVerticalScroll(0)
        OnPage('raw', name)
    end,
    EnterTrace = function(self)
        self:HideAll()
        self.Tracer:Show()
        OnPage('tracer')
    end,
    HideAll = function(self)
        self.scriptEditing = nil
        self.Tracer:Hide()
        self.PageMain:Hide()
        self.PageSettings:Hide()
    end,
    EnterSettings = function(self)
        self:HideAll()
        self.FrameInspector:Hide()
        self.PageSettings:Show()
    end,
    NextPage = function(self)
        local scriptButtons = self.scripts['Silver UI'].scriptButtons
        if self.Tracer:IsShown() then
            self:EditScratchpad()
        elseif self.scriptEditing == 'scratchpad' then
            if #scriptButtons > 0 then
                self:EditScript('Silver UI', scriptButtons[1].script)
            end
        else
            local nextScript
            for i=1, #scriptButtons do
                local b = scriptButtons[i]
                if b.script == self.scriptEditing then
                    nextScript = i+1
                    break
                end
            end
            if nextScript and nextScript <= #scriptButtons and scriptButtons[nextScript]:IsShown() then
                self:EditScript('', scriptButtons[nextScript].script)
            end
        end
    end,
    PreviousPage = function(self)
        if self.scriptEditing == 'scratchpad' then
            self:EnterTrace()
        elseif not self.Tracer:IsShown() then
            local previousScript
            for i=1, #self.scripts['Silver UI'].scriptButtons do
                local b = self.scripts['Silver UI'].scriptButtons[i]
                if b.script == self.scriptEditing then
                    previousScript = i-1
                    break
                end
            end
            if previousScript then
                if previousScript == 0 then
                    self:EditScratchpad()
                else
                    self:EditScript('', self.scripts['Silver UI'].scriptButtons[previousScript].script)
                end
            end
        end
    end,

    [Script.OnKeyDown] = function(self, key)
        if key == 'ESCAPE' then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        elseif key == 'TAB' then
            if IsControlKeyDown() then
                self:SetPropagateKeyboardInput(false)
                if IsShiftKeyDown() then
                    self:PreviousPage()
                else
                    self:NextPage()
                end
            end
        else
            self:SetPropagateKeyboardInput(true)
        end
    end,

    Shadow = BoxShadow,

    Title = FontString
        .TOPLEFT:TOPLEFT(8, -4)
        :Height(19)
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 14, '')
        :Text 'dtt',

    TitleMoveHandler = Frame
        :Height(25)
        -- :FrameLevel(5)
        .TOPLEFT:TOPLEFT()
        .TOPRIGHT:TOPRIGHT()
    {
        [Script.OnMouseDown] = function(self, button)
            if button == 'LeftButton' then
                local x, y = GetCursorPosition()
                local _, _, _, px, py = self:GetParent():GetPoint()
                local scale = self:GetEffectiveScale()
                self.dragOffset = { x/scale - px, y/scale - py }
                self:SetScript('OnUpdate', self.OnUpdate)
            end
        end,
        [Script.OnMouseUp] = function(self, button)
            if button == 'LeftButton' then
                self:SetScript('OnUpdate', nil)
            end
        end,
        OnUpdate = function(self, dt)
            local x, y = GetCursorPosition()
            local from, frame, to, _, _ = self:GetParent():GetPoint()
            local scale = self:GetEffectiveScale()
            self:GetParent():SetPoint(from, frame, to, x/scale - self.dragOffset[1], y/scale - self.dragOffset[2])
        end
    },

    CornerResizer = Frame
        .BOTTOMRIGHT:BOTTOMRIGHT()
        :Size(16, 16)
        :FrameLevel(20)
    {
        [Script.OnMouseDown] = function(self, button)
            if button == 'LeftButton' then
                local x, y = GetCursorPosition()
                self.mouseStart = { x, y }
                local parent = self:GetParent()
                self.startSize = { parent:GetWidth(), parent:GetHeight() }
                self:SetScript('OnUpdate', self.OnUpdate)
            end
        end,
        [Script.OnMouseUp] = function(self, button)
            if button == 'LeftButton' then
                self:SetScript('OnUpdate', nil)
            end
        end,
        OnUpdate = function(self)
            local x, y = GetCursorPosition()
            local scale = self:GetEffectiveScale()
            self:GetParent():SetSize(
                math.max(self.startSize[1] + (x - self.mouseStart[1])/scale, 510),
                math.max(self.startSize[2] + (self.mouseStart[2] - y)/scale, 210)
            )
            -- PixelUtil.SetSize(
            --     self:GetParent(),
            --     self.startSize[1] + (x - self.mouseStart[1])/scale,
            --     self.startSize[2] + (self.mouseStart[2] - y)/scale
            -- )
        end,
        [Script.OnEnter] = function(self)
            SetCursor('Interface/CURSOR/UI-Cursor-SizeRight')
        end,
        [Script.OnLeave] = function(self)
            SetCursor(nil)
        end,
        Texture = Texture
            :AllPoints(PARENT)
            :Texture 'Interface/AddOns/silver-ui/art/icons/resize'
    },

    Bg = Texture
        :ColorTexture(0.05,0.05,0.05,0.8)
        :AllPoints(PARENT)
        :DrawLayer('BACKGROUND', -7),

    ButtonClose = StyledButton
        :FrameLevel(10)
        .TOPRIGHT:TOPRIGHT(-3, -5)
        :Size(20, 20)
        :Alpha(0.75)
        :NormalTexture 'Interface/AddOns/silver-ui/art/icons/cross'
    {
        [Script.OnClick] = PARENT.Hide
    },

    ButtonReload = StyledButton
        :Size(20, 20)
        :NormalTexture 'Interface/AddOns/silver-ui/art/icons/reload'
        :FrameLevel(10)
        -- .RIGHT:LEFT(PARENT.settingsBtn)
        .RIGHT:LEFT(PARENT.ButtonClose)
    {
        [Script.OnClick] = ReloadUI
    },

    ButtonPickFrame = StyledButton
        :NormalTexture 'Interface/AddOns/silver-ui/art/icons/framepicker'
        :FrameLevel(10)
        :Size(20, 20)
        .RIGHT:LEFT(PARENT.ButtonReload)
    {
        -- [Script.OnClick] = PARENT.FrameInspector.PickFrame -- TODO: fix
        [Script.OnClick] = function(self)
            self:GetParent().FrameInspector:PickFrame()
        end
    },

    SideBar = Sidebar
        .TOPLEFT:TOPLEFT(0, -25)
        .BOTTOMLEFT:BOTTOMLEFT()
        :Width(20),

    PageMain = PageMain
        -- .TOPLEFT:TOPLEFT(0, -25)
        .TOPLEFT:TOPRIGHT(PARENT.SideBar)
        .BOTTOMRIGHT:BOTTOMRIGHT(-330, 0),

    PageSettings = PageSettings
        .TOPLEFT:TOPLEFT(0, -30)
        .BOTTOMRIGHT:BOTTOMRIGHT(-30, 0)
        :Hide(),

    Tracer = FrameTraceWindow
        .TOPLEFT:TOPRIGHT(PARENT.SideBar)
        .BOTTOMRIGHT:BOTTOMRIGHT(-330, 0)
        :Hide(),

    FrameInspector = FrameInspector
        .TOPLEFT:TOPRIGHT(PARENT.PageMain)
        .BOTTOMRIGHT:BOTTOMRIGHT(-10, 0)
    {
        [Hook.ClickEntry] = function(self, table, key)
            if type(table[key]) == 'function' then
                self:GetParent().Tracer:StartTrace(table, key)
            elseif type(table[key]) == 'string' then
                self:GetParent():EditRawValue(table[key], key)
            end
        end,
    }

}


local function spawn()

    FillTypeInfo()

    editorWindow = FrameDTT.new(nil, 'DTT')
    editorWindow:EditScratchpad()
    SilverUI.Editor = editorWindow

    editorWindow:Show()

end




SLASH_DTT1 = '/dtt'

SlashCmdList['DTT'] = function(msg, editbox)

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



