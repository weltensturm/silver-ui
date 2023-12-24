---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local query = LQT.query
local Script = LQT.Script
local Style = LQT.Style
local Frame = LQT.Frame
local Button = LQT.Button
local EditBox = LQT.EditBox
local Texture = LQT.Texture
local FontString = LQT.FontString
local SELF = LQT.SELF
local PARENT = LQT.PARENT

local TypeInfo = Addon.TypeInfo
local MixinInfo = Addon.MixinInfo

local FrameSmoothScroll = Addon.FrameSmoothScroll



local SortedChildren
local SetFrameStack


local function IsUIObject(table)
    return
        type(table) == 'table'
        and table.GetObjectType
        and type(select(2, pcall(table.GetObjectType, table))) == 'string'
        -- and not table:IsForbidden()
    -- if type(table) ~= 'table' then return end
    -- if type(table[0]) ~= 'userdata' then return end
    -- local meta = getmetatable(table)
    -- return
    --     meta
    --     and meta.__index
    --     and meta.__index.GetObjectType ~= nil
end


local function slice(table, start, end_)
    return { unpack(table, start, end_) }
end


local function NiceFrameName(obj)
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



local FramePicker = Frame
    :SetFrameStrata('TOOLTIP')
    :SetFrameLevel(9999)
    :Hide()
{
    Start = function(self)
        self:SetScript('OnUpdate', self.OnUpdate)
        self:SetAllPoints(UIParent)
        self:EnableMouse(true)
        self:Show()
    end,
    Stop = function(self, smallest)
        self:SetScript('OnUpdate', nil)
        self:EnableMouse(false)
        self:GetParent():SetFrameStack(smallest)
        self:Hide()
        self.name:Hide()
    end,
    Hover = function(self, smallest)
        self.smallest = smallest
        self.name:SetText(smallest:GetDebugName())
        self.name:Show()
        self.tex:SetAllPoints(smallest)
    end,
    OnUpdate = function(self, time)
        local stack = C_System.GetFrameStack()
        if stack ~= self.lastStack then
            self.lastStack = stack
            local smallest = UIParent --[[@as ScriptRegion]]
            for k, v in pairs(stack) do
                if v ~= self.tex and v ~= self.name then
                    local w, h = v:GetSize()
                    local w_c, h_c = smallest:GetSize()
                    if w*h < w_c*h_c then
                        smallest = v
                    end
                end
            end
            if self.smallest ~= smallest then
                self:Hover(smallest)
            end
        end
    end,

    [Script.OnMouseDown] = function(self, button)
        if button == 'LeftButton' then
            self:Stop(self.smallest)
        end
    end,

    tex = Texture
        :DrawLayer 'OVERLAY'
        :ColorTexture(0, 1, 0, 0.3)
        :AllPoints(PARENT),

    name = FontString
        .BOTTOM:TOP(PARENT.tex, 0, 2)
        :Font('Fonts/ARIALN.TTF', 12, '')
        :ShadowOffset(1, -1)
        :Hide()

}


local Btn = Button {
    [Script.OnEnter] = function(self)
        self.hoverBg:Show()
    end,
    [Script.OnLeave] = function(self)
        self.hoverBg:Hide()
    end,
    SetText = function(self, ...)
        self.Text:SetText(...)
    end,
    Text = FontString
        :SetFont('Fonts/FRIZQT__.ttf', 12)
        :TextColor(1, 1, 1)
        :Font('Fonts/FRIZQT__.ttf', 12)
        .LEFT:LEFT(10, 0)
        .RIGHT:RIGHT(-10, 0),
    hoverBg = Texture
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        :AllPoints(PARENT)
}


local FrameInspectorButton = Btn
    :Height(17.5)
    :Show()
    :RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp')
    :FrameLevel(10)
{
    inspector = nil,
    reference = nil,
    parents = nil,
    referenceName = nil,
    is_gui = nil,
    SetReference = function(self, reference, parents, referenceName)
        self.reference = reference
        self.parents = parents
        self.referenceName = referenceName
        self.is_gui = IsUIObject(reference) and reference.GetNumPoints
        if self.is_gui then
            if self.reference:IsProtected() then
                self.Text:SetTextColor(1, 0.5, 0.5)
            else
                self.Text:SetTextColor(1, 0.666, 1)
            end
        else
            self.Text:SetTextColor(1, 1, 1)
        end
    end,
    ScrollShow = function(self, data, parents)
        self.inspector = self:GetParent():GetParent()
        local reference = data[1]
        local name = data[2]
        local attrName = data[3]

        self:SetReference(reference, parents, attrName)
        self:SetText(name)
        self.Text:SetJustifyH 'LEFT'
        self.Text:ClearAllPoints()
        self.Text:SetPoint('LEFT', self, 'LEFT', 10, 0)
    end,
    Reset = function(self)
        self:ClearAllPoints()
        self:Hide()
    end,
    [Script.OnEnter] = function(self)
        local hoverFrame = self.inspector.FramePicker
        if self.is_gui and self.reference ~= hoverFrame and self.reference ~= hoverFrame.tex and self.reference ~= UIParent then
            hoverFrame.tex:SetAllPoints(self.reference)
            hoverFrame:Show()
        end
    end,

    [Script.OnLeave] = function(self)
        local hoverFrame = self.inspector.FramePicker
        hoverFrame.tex:ClearAllPoints()
        hoverFrame:Hide()
    end,

    [Script.OnClick] = function(self, button)
        if self.is_gui and button == 'RightButton' then
            if self.reference:IsShown() then
                self.reference:Hide()
            else
                self.reference:Show()
            end
        elseif button == 'LeftButton' then
            if self.is_gui then
                self.inspector:SetFrameStack(self.reference)
            elseif type(self.reference) == 'table' then
                local parents = {}
                for _, v in ipairs(self.parents) do
                    table.insert(parents, v)
                end
                table.insert(parents, 1, { self.reference, self.referenceName })
                self.inspector:SetFrameStack(self.reference, parents)
            else
                if self.referenceName and self.parents[1][1][self.referenceName] then
                    self.inspector:ClickEntry(self.parents[1][1], self.referenceName)
                end
            end
        end
    end,

    ['.Text'] = Style
        :Alpha(1)
        :Font('Fonts/ARIALN.TTF', 12, '')
        -- :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11)
}


Addon.FrameInspector = Addon.Templates.SmoothScrollSparse --FrameSmoothScroll
    :ElementTemplate(FrameInspectorButton)
    :ElementHeight(17.5)
    :ScrollPaddingBottom(50)
{
    data = {},

    FramePicker = FramePicker,

    Search = Button
        :NormalTexture 'Interface/AddOns/silver-ui/art/icons/search'
        :Size(16, 16)
        :Alpha(0.5)
    {
        focus = {},
        FocusAdd = function(self, obj)
            self.focus[obj] = true
            self:SetAlpha(1)
        end,
        FocusRemove = function(self, obj)
            self.focus[obj] = nil
            if not next(self.focus) then
                self:SetAlpha(0.5)
            end
        end,
        [Script.OnEnter] = function(self)
            self:FocusAdd('mouse')
        end,
        [Script.OnLeave] = function(self)
            self:FocusRemove('mouse')
        end,
        [Script.OnClick] = function(self)
            self.Box:StartEditing()
        end,
        Box = EditBox
            .LEFT:RIGHT()
            :Size(100, 20)
            :AutoFocus(false)
            :Font('Fonts/ARIALN.TTF', 12, '')
            :Disable()
            :EnableMouse(false)
        {
            StartEditing = function(self)
                self:Enable()
                self:EnableMouse(true)
                self:SetFocus()
            end,
            StopEditing = function(self)
                self:ClearFocus()
                self:Disable()
                self:EnableMouse(false)
            end,
            [Script.OnTextChanged] = function(self)
                self:GetParent():GetParent():SetSearch(self:GetText())
            end,
            [Script.OnEditFocusGained] = function(self)
                self:HighlightText()
                self:GetParent():FocusAdd('keyboard')
                self.BorderBottom:Show()
            end,
            [Script.OnEditFocusLost] = function(self)
                self:GetParent():FocusRemove('keyboard')
                if self:GetText() == '' then
                    self:StopEditing()
                    self.BorderBottom:Hide()
                end
            end,
            [Script.OnEscapePressed] = function(self)
                self:SetText('')
                self:StopEditing()
            end,
            [Script.OnEnterPressed] = SELF.StopEditing,
            BorderBottom = Texture
                .BOTTOMLEFT:BOTTOMLEFT()
                .BOTTOMRIGHT:BOTTOMRIGHT()
                :Height(1.5)
                :ColorTexture(0.5, 0.5, 0.5, 0.5)
                :Hide(),

        }
    },

    selected = nil,

    ClickEntry = function() end,

    PickFrame = function(self)
        self.FramePicker:Start()
    end,

    SetSearch = function(self, text)
        self.searchText = text
        self.queueSearch = true
    end,

    [Script.OnUpdate] = function(self)
        if self.queueSearch then
            self.queueSearch = false
            local filter = self.searchText:lower()
            if #filter then
                local filtered = {}
                for i=1, #self.data do
                    if self.data[i][2]:lower():find(filter) then
                        filtered[#filtered+1] = self.data[i]
                    end
                end
                self:SetScrollData(filtered, self.parents)
                self:SetVerticalScroll(0)
            else
                self:SetScrollData(self.data, self.parents)
            end
        end
    end,

    SetFrameStack = function(self, selected, parents)
        assert(selected)

        self.Search.Box:SetText('')

        if selected ~= self.selected then
            self:SetVerticalScroll(0)
            self.selected = selected
        end

        if not parents then
            parents = {}
            local parent = selected
            if IsUIObject(parent) and parent.GetParent then
                while parent and parent.GetParent do
                    table.insert(parents, { parent, NiceFrameName(parent) })
                    parent = parent:GetParent()
                end
            else
                table.insert(parents, { parent, "table" })
            end
        end
        self.parents = parents

        query(self, '.Parent#'):Reset()
        local previous = nil
        for i = 1, #parents do
            local reference = parents[i][1]
            Style(self) {
                ['Parent' .. i] = FrameInspectorButton
                    :Reference(reference, slice(parents, i+1), parents[i][2])
                    :FrameLevel(10)
                    :ClearAllPoints()
                {
                    function(self, parent)
                        self.inspector = parent
                    end,
                    ['.Text'] = Style
                        :Alpha(previous and 0.7 or 1)
                        :Text(parents[i][2]),
                    Style:Width(SELF.Text:GetStringWidth() + 20)
                }
            }

            local content = self['Parent' .. i]
            if previous then
                content:SetPoint('TOPRIGHT', previous, 'TOPLEFT', 10, 0)
            else
                content:SetPoint('BOTTOMLEFT', self, 'TOPLEFT')
            end
            previous = content
        end
        self.Search:SetPoint('LEFT', self.Parent1, 'RIGHT', -5, 0)

        self.data = SortedChildren(selected)
        self:SetScrollData(self.data, parents)
    end
}


local FormatValue


local function FormatTableShort(t, length_target)
    length_target = length_target or 255
    local result = '|cffffaaaa{ '
    local done = false
    for k, v in pairs(t) do
        if #result > length_target then
            if not done then
                result = result .. "|cffaaaaaa... "
                done = true
            end
            break
        end
        if type(v) == 'string' then
            local key = type(k) == 'number' and '' or ('|cff999999' .. tostring(k) .. '=')
            result = result .. key .. FormatValue(v) .. ' '
            if #result > length_target then
                break
            end
        end
    end
    for k, v in pairs(t) do
        if #result > length_target then
            if #result > length_target then
                if not done then
                    result = result .. "|cffaaaaaa... "
                    done = true
                end
                break
            end
            break
        end
        if type(v) == 'table' then
            local key = type(k) == 'number' and '' or ('|cff999999' .. tostring(k) .. '=')
            if next(v) then
                result = result .. key .. "|cffffaaaa{...} "
            else
                result = result .. key .. "|cffffaaaa{} "
            end
        end
    end
    for k, v in pairs(t) do
        if #result > length_target then
            if #result > length_target then
                if not done then
                    result = result .. "|cffaaaaaa... "
                    done = true
                end
                break
            end
            break
        end
        if type(v) ~= 'table' and type(v) ~= 'string' then
            local key = type(k) == 'number' and '' or ('|cff999999' .. tostring(k) .. '=')
            result = result .. key .. FormatValue(v) .. ' '
        end
    end
    return result .. "|cffffaaaa}"
end


FormatValue = function(v)
    if type(v) == 'table' then
        return FormatTableShort(v)
    elseif type(v) == 'number' then
        return '|cff99aaff' .. tostring(v)
    elseif type(v) == 'boolean' then
        return '|cff99aaff' .. tostring(v)
    elseif type(v) == 'string' then
        return '|cffbbbbbb"|cffffaa55' .. v:gsub('\n', '\\n') .. '|cffbbbbbb"'
    elseif type(v) == 'function' then
        return '|cffffafaafn'
    else
        return '|cffbbbbbb' .. tostring(v)
    end
end


SortedChildren = function(obj)

    local result = {}

    local SORT_ATTR = '|c00000000'
    local SORT_DATA = '|c00000001'
    local SORT_GUI = '|c00000002'
    local SORT_FN = '|c00000003'
    local SORT_MIXIN = '|c00000004'
    local SORT_MT = '|c00000005'

    local isUI = IsUIObject(obj)

    if isUI then
        if obj.IsShown then
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
                    local relativeToName = relativeTo and relativeTo:GetName()
                                           or (relativeTo and relativeTo:GetObjectType() or '')
                    if relativeTo and obj:GetParent() == relativeTo then
                        relativeToName = 'parent'
                    end
                    table.insert(result, {
                        relativeTo,
                        SORT_ATTR ..
                        '|cffffff99' .. point_names[point] ..
                        ' |cffaaaaaa' ..
                        relativeToName .. '.' ..
                        '|cffffff99' .. point_names[relativePoint]
                        .. '|cffffffff(' .. format_float(x) .. ', ' .. format_float(y) .. ')'
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

    end

    local WHITE = '|cffffffff'
    local GREY = '|cffaaaaaa'
    local TYPE = '|cffffaaff'
    local METHOD = '|cffaafaff'
    local FUNCTION = '|cffaaaaff'

    local idx_gui = 10000
    local IDX_GUI = function()
        local c = '|cff' .. string.format('%06x', 10000 - idx_gui)
        idx_gui = idx_gui - 1
        return c
    end
    local idx_mixin = 10000
    local IDX_MIXIN = function()
        local c = '|cff' .. string.format('%06x', 10000 - idx_mixin)
        idx_mixin = idx_mixin - 1
        return c
    end
    local visited = {}
    local childAttributeNames = {}

    ----
    -- table members

    local mixins = {}

    for k, v in pairs(obj) do
        if IsUIObject(v) and v.GetParent and v:GetParent() == obj then
            childAttributeNames[v] = k
        else
            visited[v] = true
            if type(v) == 'table' then
                if IsUIObject(v) then
                    table.insert(result, {
                        v,
                        SORT_GUI ..
                        IDX_GUI() ..
                        '  ' .. TYPE .. v:GetObjectType() ..
                        ' ' .. (v.IsShown and v:IsShown() and '' or GREY .. 'H ') ..
                        WHITE .. tostring(k) ..
                        ' ' .. GREY .. (v.GetName and (v:GetName() or '') .. ' ' or '') ..
                        '|c00000000',
                        k
                    })
                else
                    local sort = ''
                    if type(k) == 'number' then
                        sort = string.format('|c%08x', k)
                    end
                    table.insert(result, { v, SORT_DATA .. sort .. WHITE .. '  ' .. tostring(k) .. ' ' .. FormatValue(v), k })
                end
            elseif type(v) == 'function' then
                if MixinInfo[v] then
                    local mixin = MixinInfo[v]
                    if not mixins[mixin[1]] then
                        mixins[mixin[1]] = mixin[2]
                    end
                elseif type(k) == 'string' then
                    table.insert(result, { v, SORT_FN .. '|cffffafaafn |cffaaaaff' .. k, k })
                else
                    table.insert(result, { v, SORT_FN .. '|cffffafaafn |cffaaaaff' .. FormatValue(k), k })
                end
            else
                local sort = ''
                if type(k) == 'number' then
                    sort = string.format('|c%08x', k)
                end
                table.insert(result, { v, SORT_DATA .. sort .. WHITE .. '  ' .. tostring(k) .. ' ' .. FormatValue(v), k })
            end
        end
    end

    for name, mixin in pairs(mixins) do
        table.insert(result, {
            nil,
            SORT_MIXIN ..
            IDX_MIXIN() ..
            GREY .. name
        })
        local idx = IDX_MIXIN()
        for fnName, fn in pairs(mixin) do
            table.insert(result, { fn, SORT_MIXIN .. idx .. ' |cffffafaa fn |cffaaaaff' .. fnName, fnName })
        end
    end

    ----
    -- children

    if next(childAttributeNames) then
        table.insert(result, {
            nil,
            SORT_GUI ..
            IDX_GUI() ..
            GREY .. 'Children'
        })
    end

    if IsUIObject(obj) then
        for c in LQT.query(obj, '.*').sort() do
            if not visited[c] then
                table.insert(result, {
                    c,
                    SORT_GUI ..
                    IDX_GUI() ..
                    '  ' ..
                    WHITE .. (childAttributeNames[c] and childAttributeNames[c] .. ' ' or '') ..
                    (IsUIObject(c)
                        and (TYPE .. c:GetObjectType() .. ' ' .. ((not c.IsShown or c:IsShown()) and '' or '|cffaaaaaaH ') ..
                            GREY .. (c.GetName and (c:GetName() or '') .. ' ' or ''))
                        or GREY .. '[forbidden]') ..
                    '|c00000000' -- ..
                    -- tostring(-(c:GetTop() or 999999)) .. ' ' ..
                    -- tostring(-(c:GetLeft() or 999999))
                })
            end
        end
    end

    ----
    -- functions

    if isUI then
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
                    GREY .. info[1]
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
                                METHOD .. k:sub(4) ..
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
                                ' ' .. GREY .. ' Is' ..
                                METHOD .. k:sub(3) ..
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
                                FUNCTION .. k ..
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
                                FUNCTION .. k,
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
