---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Script = LQT.Script
local SELF = LQT.SELF
local EditBox = LQT.EditBox


Addon.RenameBox = EditBox
    :TextInsets(10, 0, 0, 0)
    :AutoFocus(false)
    :Font('Fonts/ARIALN.TTF', 12, '')
    :Disable()
    :EnableMouse(false)
{
    Edit = function(self)
        self:Enable()
        self:EnableMouse(true)
        self:SetFocus()
        self:HighlightText()
        self:SetCursorPosition(#self:GetText())
        self.origText = self:GetText()
    end,
    Save = function(self)
        self:Disable()
        self:EnableMouse(false)
        self:ClearHighlightText()
        self:SetCursorPosition(0)
    end,
    Cancel = function(self)
        self:Disable()
        self:EnableMouse(false)
        self:ClearHighlightText()
        self:SetText(self.origText)
        self:SetCursorPosition(0)
    end,
    [Script.OnEditFocusLost] = SELF.Save,
    [Script.OnEnterPressed] = SELF.Save,
    [Script.OnEscapePressed] = SELF.Cancel,
}

