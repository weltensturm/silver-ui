local LQT = Addon.LQT
local Script = LQT.Script
local Frame = LQT.Frame
local Texture = LQT.Texture

local frameTimes = {}
local index = 1
local count = 320
local columnWidth = 2
local heightPerSecond = 2000


local frame = Frame
    :SetIgnoreParentScale(true)
    :SetScale(768 / (select(2, GetPhysicalScreenSize())))
    .BOTTOMLEFT:BOTTOMLEFT(25, 25)
    :Size(columnWidth*count, 1)
{
    function(self)
        for i = 1, count do
            frameTimes[i] = self:CreateTexture()
            frameTimes[i]:SetColorTexture(1, i % 2 == 0 and 0.7 or 1, 0)
            frameTimes[i]:SetSize(columnWidth, 1)
            frameTimes[i]:SetPoint('BOTTOMLEFT',
                                   frameTimes[i-1] or self,
                                   frameTimes[i-1] and 'BOTTOMRIGHT' or 'BOTTOMLEFT')
        end
    end,

    [Script.OnUpdate] = function(self, dt)
        frameTimes[index]:SetHeight(dt*heightPerSecond)
        local next = frameTimes[index+1] or frameTimes[1]
        next:SetHeight(0)
        index = index + 1
        if index > count then
            index = 1
        end
    end,

    fps60 = Texture
        :ColorTexture(0.5, 0.5, 0.5, 0.7)
        :Height(1)
        .BOTTOMLEFT:BOTTOMLEFT(0, heightPerSecond*0.01666666)
        .RIGHT:RIGHT(),

    fps30 = Texture
        :ColorTexture(0.5, 0.5, 0.5, 0.7)
        :Height(1)
        .BOTTOMLEFT:BOTTOMLEFT(0, heightPerSecond*0.03333333)
        .RIGHT:RIGHT()
}
    .new()


