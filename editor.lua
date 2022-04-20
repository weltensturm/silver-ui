local _, ns = ...
local lqt = ns.lqt
local Style, Frame, Button, Texture, FontString = lqt.Style, lqt.Frame, lqt.Button, lqt.Texture, lqt.FontString

local Q = ns.util.method_chain_wrapper


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


local sorted_children = nil


local function ToParent(self)
    self:SetAllPoints(self:GetParent())
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
        { ToParent },
    Texture'.hoverBg'
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        { ToParent },
    Style:SetSize(20, 20)
}


local gui_types = {
    { 'Frame', CreateFrame('Frame') },
    { 'ScrollFrame', CreateFrame('ScrollFrame') },
    { 'Button', CreateFrame('Button') },
    { 'Slider', CreateFrame('Slider') },
    { 'CheckButton', CreateFrame('CheckButton') },
    { 'EditBox', CreateFrame('EditBox') }
}

for _, v in pairs(gui_types) do
    v[2]:Hide()
end


do
    local uiext_t = {}
    setmetatable(uiext_t, { __index=ns.uiext })
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
            btn = Btn.new() -- CreateFrame('Button', nil, UIParent, "UIPanelButtonTemplate")
        end
        btn.Text:SetTextColor(1, 1, 1)
        btn.Text:SetFont('Fonts/FRIZQT__.ttf', 12)
        btn.Text:ClearAllPoints()
        btn.Text:SetPoint('LEFT', btn, 'LEFT', 10, 0)
        return Q(btn)
    end

    local hoverFrame = nil

    editorWindow = Frame
        :SetWidth(1000)
        :SetHeight(600)
        :EnableMouse(true)
        :Point('CENTER', 0, 0)    
    {
        Texture'.TitleBg'
            :Height(25)
            :ColorTexture(0.1, 0.1, 0.1)
            :DrawLayer('BACKGROUND', -6)
        {
            function(self)
                self:SetTOPLEFT(self:GetParent():TOPLEFT(3, -3))
                self:SetRIGHT(self:GetParent():RIGHT(-3, 0))
            end
        },
        Btn'.closeBtn'
            :SetText('X')
            :Scripts { OnClick = function(self) editorWindow:Hide() end }
            { function(self) self:SetPoint('TOPRIGHT', self:GetParent(), 'TOPRIGHT', -6, -6) end },
            
        Btn'.pickFrameBtn'
            :Text('>')
            :Width(30)
            :Scripts {
                OnClick = function(self, button)
                    if button == 'LeftButton' then
                        hoverFrame:start()
                    end
                end
            }
            .init(function(self)
                self:Points { TOPLEFT=self:GetParent():TOPLEFT(3.9, -5) }
            end)
    }
        .new('BackdropTemplate')

    local set_frame_stack = nil

    hoverFrame = Frame
        :SetFrameStrata('TOOLTIP')
        .data {
            start = function(self)
                self.pick = true
                self:SetAllPoints(UIPanel)
                self:EnableMouse(true)
                self:Show()
                editorWindow:Hide()
                self:Scripts {
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
            end,
            stop = function(self, stack, smallest)
                self:Scripts {
                    OnMouseDown = nil,
                    OnUpdate = nil
                }
                self.pick = false
                self.tex:SetAllPoints(self)
                self:EnableMouse(false)
                self:Hide()
                editorWindow:Show()
                set_frame_stack(stack, smallest)
            end
        }
    {
        Texture'.tex'
            :DrawLayer 'OVERLAY'
            :ColorTexture(0, 1, 0, 0.4)
            .init(function(self, parent) self:SetAllPoints(parent) end)
    }
        .new()

    local editorShadow = nil

    local editor = Q(CreateFrame('EditBox', nil, editorWindow))
        :SetPoint('TOPLEFT', editorWindow, 'TOPLEFT', 10, -31)
        :SetPoint('BOTTOMRIGHT', editorWindow, 'BOTTOMRIGHT', -330, 15)
        :SetFont('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11)
        -- :SetShadowOffset(0.01, 0.01)
        -- :SetShadowColor(0.9,0.9,0.9)
        :Scripts {
            OnEnterPressed = function(self)
                if not self.CTRL then
                    self:Insert('\n')
                else
                    local func = assert(loadstring(self:GetText()))
                    local result = { func() }
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
                editorShadow:SetText(self:GetText())
            end,
            OnEditFocusLost = function(self)
                self.CTRL = false
            end
        }
        :SetJustifyH("LEFT")
        :SetJustifyV("TOP")
        :SetMultiLine(true)
        [1]
    
    editorShadow = Q(CreateFrame('EditBox', nil, editorWindow))
        :SetAllPoints(editor)
        :SetFont('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11)
        :SetJustifyH("LEFT")
        :SetJustifyV("TOP")
        :SetMultiLine(true)
        :SetTextColor(0.7, 0.7, 0.7)
        :Disable()

    local scrollSpeed = 0
    local sf = CreateFrame("ScrollFrame", nil, editorWindow)
    sf:SetPoint('TOPLEFT', editor, 'TOPRIGHT', 5, 0)
    sf:SetPoint('BOTTOMRIGHT', editorWindow, 'BOTTOMRIGHT', -10, 10)

    local scroll = CreateFrame('Frame', nil, editorWindow)
    
	sf:Scripts {
        OnSizeChanged = function(self)
            scroll:SetWidth(self:GetWidth())
            scroll:SetHeight(self:GetHeight())
	    end,
        OnMouseWheel = function(self, delta)
            scrollSpeed = scrollSpeed - delta
        end
    }
    sf:Scripts {
        OnUpdate = function(self, time)
            if scrollSpeed ~= 0 then
                local current = self:GetVerticalScroll()
                local max = self:GetVerticalScrollRange()
                if current < 0 then
                    current = current + math.min(-current, 2048*time)
                elseif current > max then
                    current = current - math.min(current - max, 2048*time)
                end
                self:SetVerticalScroll(current + scrollSpeed*time*512)
                if scrollSpeed > 0 then
                    scrollSpeed = math.max(0, scrollSpeed - (4 + math.abs(scrollSpeed*5))*time)
                else
                    scrollSpeed = math.min(0, scrollSpeed + (4 + math.abs(scrollSpeed*5))*time)
                end
            end
        end,
	    OnVerticalScroll = function(parent, offset)
		    scroll:SetHitRectInsets(0, 0, offset, (scroll:GetHeight() - offset - parent:GetHeight()))
	    end
    }
    scroll:SetWidth(sf:GetWidth())
    scroll:SetHeight(200)
    scroll:EnableMouse(true)

    sf:SetScrollChild(scroll)
    
    scroll.children = {}

    editorWindow.buttons = {}

    set_frame_stack = function(_, smallest)

        sf:SetVerticalScroll(0)

        for i = #scroll.children, 1, -1 do
            scroll.children[i]:Hide()
            scroll.children[i]:ClearAllPoints()
            scroll.children[i]:SetParent(nil)
            table.insert(btnPool, scroll.children[i])
            table.remove(scroll.children, i)
        end

        for i = #editorWindow.buttons, 1, -1 do
            editorWindow.buttons[i]:Hide()
            editorWindow.buttons[i]:ClearAllPoints()
            editorWindow.buttons[i]:SetParent(UIParent)
            table.insert(btnPool, editorWindow.buttons[i])
            table.remove(editorWindow.buttons, i)
        end

        assert(#scroll.children == 0)

        local lastText = nil

        local parents = {}
        local parent = smallest
        while parent do
            table.insert(parents, { parent, get_name(parent) })
            parent = parent:GetParent()
        end

        local lastBtn = nil
        for i = 1, #parents do
            local c = parents[i][1]

            local btn = create_btn()
                :SetParent(editorWindow)
                :SetHeight(15)
                :SetText(parents[i][2])
                :Show()
                :Hooks {
                    OnEnter = function(self)
                        if c:GetTop() and c ~= hoverFrame and c ~= hoverFrame.tex and c ~= UIParent then
                            hoverFrame:SetAllPoints(c)
                            hoverFrame:Show()
                        end
                    end,

                    OnLeave = function(self)
                        hoverFrame:SetAllPoints(editorWindow)
                        hoverFrame:Hide()
                    end,

                    OnMouseDown = function(self, button)
                        if button == 'RightButton' then
                            if c:IsShown() then
                                c:Hide()
                            else
                                c:Show()
                            end
                        elseif button == 'LeftButton' then
                            set_frame_stack(_, c)
                        end
                    end,

                    -- OnMouseUp = function() end
                }
                :SetPoint(unpack(
                    lastBtn and {'TOPRIGHT', lastBtn, 'TOPLEFT', 10, 0}
                             or {'BOTTOMLEFT', sf, 'TOPLEFT', 0, 7}
                ))
            
            local text = btn[1].Text
            text:SetFont('Fonts/ARIALN.TTF', 12)
            if lastBtn then
                text:SetTextColor(0.7, 0.7, 0.7)
            end
            btn:SetWidth(text:GetWidth() + 20)

            table.insert(editorWindow.buttons, btn[1])

            lastBtn = btn[1]

        end

        for _, obj in pairs(sorted_children(smallest)) do
            local name = obj[2]
            local c = obj[1]
            local is_gui = type(c) == 'table' and c.GetObjectType and c:GetObjectType()

            local btn = create_btn()
                :SetParent(scroll)
                :SetText(name)
                :SetHeight(20)
                :SetWidth(sf:GetWidth() - 8)
                :Show()
                :Hooks {
                    OnEnter = function(self)
                        pcall(function()
                            if is_gui and c.GetTop and c:GetTop() and c ~= hoverFrame and c ~= hoverFrame.tex then
                                hoverFrame:SetAllPoints(c)
                                hoverFrame:Show()
                            end
                        end)
                    end,

                    OnLeave = function(self)
                        hoverFrame:SetAllPoints(editorWindow)
                        hoverFrame:Hide()
                    end,

                    OnMouseDown = function(self, button)
                        if is_gui and button == 'RightButton' then
                            if c:IsShown() then
                                c:Hide()
                            else
                                c:Show()
                            end
                        elseif is_gui and button == 'LeftButton' then
                            set_frame_stack(_, c)
                        elseif type(c) == 'table' and button == 'LeftButton' then
                            print_table(c)
                        end
                    end,

                    OnMouseUp = function() end
                }

            local text = btn[1].Text
            text:ClearAllPoints()
            text:SetPoint('LEFT', btn[1], 'LEFT', 0, 0)
            text:SetFont('Fonts/ARIALN.TTF', 12)
            
            if not is_gui then
                text:SetTextColor(0.5, 0.5, 0.5)
            elseif c == smallest then
                text:SetTextColor(1, 1, 0.5)
            elseif c.IsShown and not c:IsShown() then
                text:SetTextColor(0.7, 0.7, 0.7)
            else
                text:SetTextColor(1, 1, 1)
            end

            if lastText then
                btn:SetPoint('TOPLEFT', lastText, 'BOTTOMLEFT', 0, -0)
            else
                btn:SetPoint('TOPLEFT', scroll, 'TOPLEFT', 10, -0)
            end
            lastText = btn[1]

            table.insert(scroll.children, btn[1])
        end
    end

    set_frame_stack(nil, UIParent)

    editorWindow'.Bg=Texture'
        :SetColorTexture(0.05,0.05,0.05,1)
        :SetPoint('TOPLEFT', editorWindow, 'TOPLEFT', 4, -4)
        :SetPoint('BOTTOMRIGHT', editorWindow, 'BOTTOMRIGHT', -4, 4)
        :SetDrawLayer('BACKGROUND', -7)

    editorWindow:SetBackdrop({
        -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment",
        -- bgFile = 'Interface/HELPFRAME/DarkSandstone-Tile',
        edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
        edgeSize = 12,
        tile = true,
        tileSize = 300,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    editorWindow:Show()

end



sorted_children = function(obj)

    local t = {}

    local SORT_ATTR = '|c00000000'
    local SORT_DATA = '|c00000001'
    local SORT_GUI = '|c00000002'
    local SORT_FN = '|c00000003'
    local SORT_MT = '|c00000004'

    table.insert(t, {
        nil,
        SORT_ATTR ..
        '|cffaaaaaatype |cffffffff' .. obj:GetObjectType()
    })

    if obj:GetName() then
        table.insert(t, {
            nil,
            SORT_ATTR ..
            '|cffaaaaabname |cffffffff' .. obj:GetName()
        })
    end

    if obj.GetTexture then
        table.insert(t, {
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
            table.insert(t, {
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
    table.insert(t, {
        parent,
        SORT_ATTR ..
        '|cffaaaaabparent |cffffffff' .. tostring(parent and (parent:GetName() or parent:GetObjectType()))
    })

    local idx = 1
    local visited = {}
    for k, v in pairs(obj) do
        visited[v] = true
        if type(v) == 'table' then
            if v.GetObjectType and v.GetTop and v.GetLeft then
                table.insert(t, {
                    v,
                    SORT_GUI ..
                    '|cff' .. string.format('%06x', 10000 - idx) ..
                    '|cffffaaff' .. v:GetObjectType() .. ' ' ..
                    '|cffffffff' .. k .. ' ' ..
                    '|cffaaaaaa' .. (v.GetName and (v:GetName() or '') .. ' ' or '') ..
                    '|c00000000' -- ..
                    -- tostring(-(v:GetTop() or 999999)) .. ' ' ..
                    -- tostring(-(v:GetLeft() or 999999))
                })
                idx = idx - 1
            else
                table.insert(t, { v, SORT_DATA .. '|cffffffff' .. k .. ' = |cffffaaaatable'})
            end
        elseif type(v) == 'function' then
            table.insert(t, { v, SORT_FN .. '|cffffafaa fn |cffaaaaff' .. k })
        else
            table.insert(t, {
                v,
                SORT_DATA ..
                '|cffffffff' .. k .. ' = ' ..
                '|cffffaaaa' .. type(v) .. '|cffaaaaaa ' .. tostring(v) })
        end

    end

    if obj.has_lqt then
        for c in obj'.*' do
            if not visited[c] then
                table.insert(t, {
                    c,
                    SORT_GUI ..
                    '|cff' .. string.format('%06x', 10000 - idx) ..
                    '|cffffaaff' .. c:GetObjectType() .. ' ' ..
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

                table.insert(t, { nil,
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
                            table.insert(t, { v,
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
                            table.insert(t, { v,
                                SORT_MT ..
                                SORT_TYPE ..
                                SORT_FN ..
                                ' |cfaaaaaaa Is' ..
                                '|cffaafaff' .. k:sub(3) ..
                                '|cffaaaaaa = ' ..
                                attribute_str_values(obj, k)
                            })
                        else
                            fn_visited[k] = true
                            table.insert(t, { v,
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

    table.sort(t, function(a, b) return a[2] < b[2] end)

    return t
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



