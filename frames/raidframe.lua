---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Frame, Style, Texture, Cooldown = LQT.Frame, LQT.Style, LQT.Texture, LQT.Cooldown


Style(CompactRaidFrameManager) {
    ['.containerResizeFrame'] = Style:FrameStrata('HIGH'),
    ['.Texture'] = Style:Texture '':Alpha(0)
}
