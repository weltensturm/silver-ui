local ADDON, Addon = ...

local
    query,
    Style,
    Frame,
    Button,
    Texture,
    FontString,
    EditBox,
    ScrollFrame,
    SELF,
    PARENT,
    ApplyFrameProxy,
    FrameProxyMt
    =   LQT.query,
        LQT.Style,
        LQT.Frame,
        LQT.Button,
        LQT.Texture,
        LQT.FontString,
        LQT.EditBox,
        LQT.ScrollFrame,
        LQT.SELF,
        LQT.PARENT,
        LQT.ApplyFrameProxy,
        LQT.FrameProxyMt

local TypeInfo, FillTypeInfo = Addon.TypeInfo, Addon.FillTypeInfo

local FrameSmoothScroll = Addon.FrameSmoothScroll



local SortedChildren
local SetFrameStack



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
    :Hide()
    .init {
        Start = function(self)
            self:SetScript('OnUpdate', self.OnUpdate)
            self:SetAllPoints(UIPanel)
            self:EnableMouse(true)
            self:Show()
        end,
        Stop = function(self, smallest)
            self:SetScript('OnUpdate', nil)
            self:EnableMouse(false)
            self:GetParent():SetFrameStack(smallest)
            self:Hide()
        end,
        OnUpdate = function(self, time)
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
    }
    :Scripts {
        OnMouseDown = function(self, button)
            if button == 'LeftButton' then
                self:Stop(self.smallest)
            end
        end
    }
{
    Texture'.tex'
        :DrawLayer 'OVERLAY'
        :ColorTexture(0, 1, 0, 0.4)
        :AllPoints(PARENT)
}


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
        :TextColor(1, 1, 1)
        :Font('Fonts/FRIZQT__.ttf', 12)
        .LEFT:LEFT(10, 0)
        .RIGHT:RIGHT(-10, 0),
    Texture'.hoverBg'
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        :AllPoints(PARENT)
}


local FrameInspectorButton = Btn
    .data {
        inspector = nil,
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
        end,
        Reset = function(self)
            self:ClearAllPoints()
            self:Hide()
        end
     }
    :Height(17.5)
    :Show()
    :RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp')
    :Hooks {
        OnEnter = function(self)
            local hoverFrame = self.inspector.FramePicker
            if self.is_gui and self.reference ~= hoverFrame and self.reference ~= hoverFrame.tex and self.reference ~= UIParent then
                hoverFrame.tex:SetAllPoints(self.reference)
                hoverFrame:Show()
            end
        end,

        OnLeave = function(self)
            local hoverFrame = self.inspector.FramePicker
            hoverFrame.tex:ClearAllPoints()
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
                        self.inspector:ClickFunction(self.parents[1][1], self.referenceName)
                    end
                end
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


Addon.FrameInspector = FrameSmoothScroll
    .init {
        selected = nil,

        ClickFunction = function() end,
        SetClickFunction = function(self, fn)
            self.ClickFunction = fn
        end,

        PickFrame = function(self)
            self.FramePicker:Start()
        end,

        SetFrameStack = function(self, selected, parents)

            if selected ~= self.selected then
                self:SetVerticalScroll(0)
                self.selected = selected
            end

            if not parents then
                parents = {}
                local parent = selected
                while parent and parent.GetParent do
                    table.insert(parents, { parent, NiceFrameName(parent) })
                    parent = parent:GetParent()
                end
            end

            query(self, '.Parent#'):Reset()
            local previous = nil
            for i = 1, #parents do
                local reference = parents[i][1]

                FrameInspectorButton('.Parent' .. i)
                    .data { inspector = self }
                    :Reference(reference, slice(parents, i+1), parents[i][2])
                    :FrameLevel(10)
                    :ClearAllPoints()
                {
                    Style'.Text'
                        :Alpha(previous and 0.7 or 1)
                        :Text(parents[i][2]),
                    Style:Width(SELF.Text:GetStringWidth() + 20)
                }
                    .apply(self)

                local content = self['Parent' .. i]
                if previous then
                    content:SetPoint('TOPRIGHT', previous, 'TOPLEFT', 10, 0)
                else
                    content:SetPoint('BOTTOMLEFT', self, 'TOPLEFT')
                end
                previous = content
            end

            previous = nil
            query(self.Content, '.Member#'):Reset()
            for i, obj in pairs(SortedChildren(selected)) do
                local reference = obj[1]
                local name = obj[2]
                local attrName = obj[3]

                FrameInspectorButton('.Member' .. i)
                    .data { inspector = self }
                    :Reference(reference, parents, attrName)
                    :Text(name)
                    :Width(self:GetWidth() - 8)
                    .TOPLEFT:TOPLEFT(self.Content, 10, 0)
                {
                    Style'.Text'
                        .LEFT:LEFT()
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
                    .apply(self.Content)

                local content = self.Content['Member' .. i]
                if previous then
                    content:SetPoint('TOPLEFT', previous, 'BOTTOMLEFT')
                end
                previous = self.Content['Member' .. i]
            end
        end

    }
{
    FramePicker'.FramePicker'
}


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

    local WHITE = '|cffffffff'
    local GREY = '|cffaaaaaa'
    local TYPE = '|cffffaaff'
    local METHOD = '|cffaafaff'
    local FUNCTION = '|cffaaaaff'

    local idx = 10000
    local IDX = function()
        local c = '|cff' .. string.format('%06x', 10000 - idx)
        idx = idx - 1
        return c
    end
    local visited = {}
    local childAttributeNames = {}

    for k, v in pairs(obj) do
        if type(v) == "table" and v.GetParent and v:GetParent() == obj then
            childAttributeNames[v] = k
        else
            visited[v] = true
            if type(v) == 'table' then
                if v.GetObjectType and v.GetTop and v.GetLeft then
                    table.insert(result, {
                        v,
                        SORT_GUI ..
                        IDX() ..
                        TYPE .. v:GetObjectType() .. ' ' .. (v:IsShown() and '' or GREY .. 'H ') ..
                        WHITE .. k .. ' ' ..
                        GREY .. (v.GetName and (v:GetName() or '') .. ' ' or '') ..
                        '|c00000000',
                        k
                    })
                else
                    table.insert(result, { v, SORT_DATA .. WHITE .. k .. ' = |cffffaaaatable', k })
                end
            elseif type(v) == 'function' then
                table.insert(result, { v, SORT_FN .. '|cffffafaa fn |cffaaaaff' .. k, k })
            else
                table.insert(result, {
                    v,
                    SORT_DATA ..
                    WHITE .. k .. ' = ' ..
                    '|cffffaaaa' .. type(v) .. GREY .. ' ' .. tostring(v):gsub('\n', '\\n') })
            end
        end
    end

    if next(childAttributeNames) then
        table.insert(result, {
            v,
            SORT_GUI ..
            IDX() ..
            GREY .. 'Children'
        })
    end

    for c in LQT.query(obj, '.*').sort() do
        if not visited[c] then
            table.insert(result, {
                c,
                SORT_GUI ..
                IDX() ..
                TYPE .. c:GetObjectType() .. ' ' .. ((not c.IsShown or c:IsShown()) and '' or '|cffaaaaaaH ') ..
                WHITE .. (childAttributeNames[c] and childAttributeNames[c] .. ' ' or '') ..
                GREY .. (c.GetName and (c:GetName() or '') .. ' ' or '') ..
                '|c00000000' -- ..
                -- tostring(-(c:GetTop() or 999999)) .. ' ' ..
                -- tostring(-(c:GetLeft() or 999999))
            })
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
