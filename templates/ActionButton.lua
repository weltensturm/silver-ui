---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT

---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


local Style = LQT.Style


Addon.Templates.ActionButton = Style
    .constructor(function(parent, globalName, ...)
        local frame = CreateFrame('Button', globalName, parent, 'SecureActionButtonTemplate, SecureHandlerStateTemplate')
        return frame
    end)
    :RegisterForClicks 'AnyUp'
    :RegisterForDrag('LeftButton', 'RightButton')

