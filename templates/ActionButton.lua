---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT

---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


local
    PARENT,
    Style,
    Frame,
    CheckButton,
    Texture,
    MaskTexture,
    FontString,
    AnimationGroup,
    Animation
    =   LQT.PARENT,
        LQT.Style,
        LQT.Frame,
        LQT.CheckButton,
        LQT.Texture,
        LQT.MaskTexture,
        LQT.FontString,
        LQT.AnimationGroup,
        LQT.Animation


Addon.Templates.ActionButton = Style
    .constructor(function(parent, globalName, ...)
        local frame = CreateFrame('Button', globalName, parent, 'SecureActionButtonTemplate, SecureHandlerStateTemplate')
        return frame
    end)
    :RegisterForClicks 'AnyUp'
    :RegisterForDrag('LeftButton', 'RightButton')

