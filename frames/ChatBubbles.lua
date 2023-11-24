---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Script = LQT.Script
local Frame = LQT.Frame
local Style = LQT.Style
local Texture = LQT.Texture
local Cooldown = LQT.Cooldown



local function ForTuple(fn, ...)
    for i=1, select('#', ...) do
        fn(select(i, ...))
    end
end

local function HandleChatBubble(bubble)
    if not bubble:IsForbidden() and not bubble:GetName() and not bubble.scaled then
        bubble:SetScale(UIParent:GetScale())
        bubble.scaled = true
    end
end

Frame {
    [Script.OnUpdate] = function()
        ForTuple(HandleChatBubble, WorldFrame:GetChildren())
    end
}
    .new()
