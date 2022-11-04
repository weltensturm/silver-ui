
local Frame, Style, Texture, Cooldown = LQT.Frame, LQT.Style, LQT.Texture, LQT.Cooldown


Style(CompactRaidFrameManager) {
    Style'.containerResizeFrame':FrameStrata('HIGH'),
    Style'.Texture':Texture '':Alpha(0)
}