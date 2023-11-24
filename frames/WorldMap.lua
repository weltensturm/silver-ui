---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local query, Style, Frame = LQT.query, LQT.Style, LQT.Frame


local hide = Frame:Hide().new()

WorldMapFrame:SetScale(0.85)
WorldMapFrame.BlackoutFrame:SetParent(hide)

