---@class Addon
local Addon = select(2, ...)

local FrameSmoothScroll = Addon.FrameSmoothScroll

local LQT = Addon.LQT
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Script = LQT.Script
local Style = LQT.Style
local Frame = LQT.Frame
local Texture = LQT.Texture
local FontString = LQT.FontString
local EditBox = LQT.EditBox

local tinsert = tinsert

local function slice(table, start, end_)
    return { unpack(table, start, end_) }
end

Addon.CodeEditor = Frame {

    CtrlEnter = function(text) end,
    OnError = function(error) end,

    ClearHistory = function(self)
        self.Editor.History = {}
        self.Editor.HistoryIndex = 1
        self.Editor.HistoryCursor = {}
    end,

    -- ClickBackground = Frame
    --     :AllPoints(PARENT)
    --     :EnableMouse(true)
    -- {
    --     [Script.OnMouseDown] = function(self)
    --         local editor = self:GetParent().Editor
    --         editor:SetFocus()
    --         editor:SetCursorPosition(#editor:OrigGetText())
    --     end
    -- },

    Shadow = FontString
        .TOPLEFT:TOPLEFT(40,-3)
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
        :JustifyH("LEFT")
        :JustifyV("TOP")
        :TextColor(0.7, 0.7, 0.7),

    Editor = EditBox
        .TOPLEFT:TOPLEFT(40,-3)
        :Width(9999)
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
        :FrameLevel(5)
        :JustifyH("LEFT")
        :JustifyV("TOP")
        :MultiLine(true)
    {
        function(self, parent)
            self.parent = parent
            self.OrigGetText = self.GetText
            self.OrigSetText = self.SetText
            LqtIndentationLib.enable(self, nil, 4)

            while parent do
                if parent:GetObjectType() == 'ScrollFrame' then
                    self.scroller = parent
                    parent = nil
                else
                    parent = parent:GetParent()
                end
            end
        end,

        History = {},
        HistoryIndex = 1,
        HistoryCursor = {},

        Save = function(text) end,

        CursorIntoView = function(self, x, y, w, h)
            if self.scroller then
                local offsetY = self.scroller.Content:GetTop() - self:GetTop()
                local height = -y + offsetY
                local scrollerHeight = self.scroller:GetHeight()
                local currentScroll = self.scroller:GetVerticalScroll()
                if currentScroll > height-50 then
                    self.scroller:SetVerticalScroll(math.max(height - 50, 0))
                elseif currentScroll+scrollerHeight < height+50 then
                    self.scroller:SetVerticalScroll(height - scrollerHeight + 50)
                end

                local scrollerWidth = self.scroller:GetWidth()
                local currentScrollX = self.scroller:GetHorizontalScroll()
                local offsetX = self.scroller.Content:GetLeft() - self:GetLeft()
                local width = x - offsetX
                self.scroller:SetHorizontalScroll(math.max(width - scrollerWidth+50, 0))
            end
        end,

        [Script.OnShow] = function(self)
            self:SetFocus()
        end,
        [Script.OnEnterPressed] = function(self)
            if not IsControlKeyDown() then
                self:Insert('\n')
            else
                self.parent:CtrlEnter(self:GetText())
            end
        end,
        [Script.OnTabPressed] = function(self)
            if IsControlKeyDown() then return end
            if IsShiftKeyDown() then
                local pos = self:GetCursorPosition()
                local text = self:OrigGetText()
                local line_start = pos
                local char = text:sub(pos, pos)

                while char ~= '\n' and line_start > 1 do
                    line_start = line_start - 1
                    char = text:sub(line_start, line_start)
                end

                local delete_end = line_start+1
                local delete_count = 0
                for i = 0, 3 do
                    char = text:sub(delete_end, delete_end)
                    if char ~= ' ' then
                        break
                    else
                        delete_end = delete_end + 1
                        delete_count = delete_count + 1
                    end
                end
                self:OrigSetText(text:sub(1, line_start) .. text:sub(delete_end))
                self:SetCursorPosition(math.max(pos - delete_count, line_start))
            else
                self:Insert('    ')
            end
        end,
        [Script.OnKeyDown] = function(self, key)
            if
                key == 'ESCAPE'
                or IsControlKeyDown() and key == 'TAB'
            then
                self:SetPropagateKeyboardInput(true)
            else
                self:SetPropagateKeyboardInput(false)
            end
            if IsControlKeyDown() then
                if key == 'R' then
                    ReloadUI()
                elseif key == 'F' then
                    hoverFrame:start()
                elseif key == 'Z' then
                    if self.dirty then
                        self:SetText(self.History[#self.History])
                    elseif self.HistoryIndex < #self.History then
                        self.HistoryIndex = self.HistoryIndex + 1
                        self:SetText(self.History[#self.History - self.HistoryIndex])
                        self:SetCursorPosition(self.HistoryCursor[#self.HistoryCursor - self.HistoryIndex] or 0)
                    end
                elseif key == 'Y' then
                    if self.HistoryIndex > 0 then
                        self.HistoryIndex = self.HistoryIndex - 1
                        self:SetText(self.History[#self.History - self.HistoryIndex])
                        self:SetCursorPosition(self.HistoryCursor[#self.HistoryCursor - self.HistoryIndex])
                    end
                end
            end
        end,
        [Script.OnKeyUp] = function(self, key)
            if key == 'ESCAPE' then
                self:SetPropagateKeyboardInput(true)
            end
        end,
        [Script.OnCursorChanged] = SELF.CursorIntoView,
        [Script.OnCursorChanged] = function(self, x, y, w, h)
            if #self.HistoryCursor > 0 then
                self.HistoryCursor[#self.HistoryCursor - self.HistoryIndex] = self:GetCursorPosition()
            end
        end,
        [Script.OnTextChanged] = function(self, userInput)
            self.dirty = true
            self.parent.Shadow:SetText(self:OrigGetText())
            self.parent.Shadow:Show()
            local n = self.parent.Shadow:GetNumLines()
            local lines = ''
            for i = 1, n do
                lines = lines .. string.rep(' ', 4 - string.len('' .. i)) .. i .. '\n'
            end
            self.parent.LineNumbers:SetText(lines)
            local fn, error = loadstring('return function() ' .. self:GetText() .. '\n end', "silver editor")
            if fn then
                self.parent:OnError()
                -- self.parent.Error:Hide()
                -- self.parent.Red:Hide()
                local text = self:GetText()
                if #self.History == 0 or userInput and text ~= self.History[#self.History-self.HistoryIndex] then
                    if self.HistoryIndex > 0 then
                        self.History = slice(self.History, 1, #self.History-self.HistoryIndex)
                        self.HistoryCursor = slice(self.HistoryCursor, 1, #self.HistoryCursor-self.HistoryIndex)
                        self.HistoryIndex = 0
                    end
                    tinsert(self.History, text)
                    tinsert(self.HistoryCursor, self:GetCursorPosition())
                end
                self.Save(text)
                self.dirty = false
            else
                -- self.parent.Error:SetText(error)
                -- self.parent.Red:Show()
                -- self.parent.Error:Show()
                self.parent:OnError(error)
            end
            self.parent:SetHeight(self:GetHeight())
        end,
    },

    LineNumbers = FontString
        .TOPRIGHT:TOPLEFT(PARENT.Editor, -4, 0)
        :JustifyH('LEFT')
        :TextColor(0.7, 0.7, 0.7)
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, ''),

}
