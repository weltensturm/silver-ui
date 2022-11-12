local ADDON, Addon = ...

local FrameSmoothScroll = Addon.FrameSmoothScroll

local     PARENT,     Style,     Frame,     Texture,     FontString,     EditBox
    = LQT.PARENT, LQT.Style, LQT.Frame, LQT.Texture, LQT.FontString, LQT.EditBox


Addon.CodeEditor = FrameSmoothScroll
    :Points { TOPLEFT = PARENT.TitleBg:BOTTOMLEFT(),
              BOTTOMRIGHT = PARENT:BOTTOMRIGHT(-330, 0) }
    :Hide()
{
    Style'.Content' {

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

        FontString'.CursorHelper'
            :Points { TOPLEFT = PARENT:TOPLEFT(40,-3), TOPRIGHT = PARENT:TOPRIGHT() }
            :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
            :JustifyH("LEFT")
            :JustifyV("TOP")
            :Text ''
            :Alpha(0),
        
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
                    self:SetPropagateKeyboardInput(false)
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
                    else
                        self:CursorIntoView()
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
                        self:SetPropagateKeyboardInput(true)
                        -- editorWindow:Hide()
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
                end,
                CursorIntoView = function(self)
                    self.parent.CursorHelper:SetText(self:OrigGetText():sub(1, self:GetCursorPosition()))
                    local height = self.parent.CursorHelper:GetHeight()
                    local scroller = self.parent:GetParent()
                    local scrollerHeight = scroller:GetHeight()
                    local currentScroll = scroller:GetVerticalScroll()
                    if currentScroll > height-50 then
                        scroller:SetVerticalScroll(math.max(height - 50, 0))
                    elseif currentScroll+scrollerHeight < height+50 then
                        scroller:SetVerticalScroll(height - scrollerHeight + 50)
                    end
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
}
