
---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Frame = LQT.Frame


local halfpi = math.pi/2
local halfthree = 3/2
local half = 1/2


local EASE = {
    IN = function(x)
        return 1-math.sin((x+1)*halfpi)
    end,
    OUT = function(x)
        return math.sin(x*halfpi)
    end,
    IN_OUT = function(x)
        return math.sin((x+halfthree)*math.pi)/2 + half
    end,
    CUBIC_IN = function(x)
        return x^3
    end,
    CUBIC_OUT = function(x)
        return 1-(1-x)^3
    end,
    CUBIC_IN_OUT = function(x)
        return x < 0.5
            and 4 * x^3
             or 1 - (-2 * x + 2)^3 / 2;
    end
}


Addon.Animation = Frame {
    function(self, parent)
        self.parent = parent
    end,

    OnPlay = function() end,
    OnFinished = function() end,
    start = nil,
    ease = EASE.IN_OUT,

    SetDuration = function(self, duration)
        self.duration = duration
    end,

    SetEase = function(self, ease)
        self.ease = EASE[ease]
    end,

    Play = function(self)
        if not self.parent:IsShown() then return end
        self:OnPlay()
        self.start = GetTime()
        if self.translateFrom then
            local _, _, _, x, y = self.parent:GetPoint()
            self.translateStart = { x, y }
        end
        self:SetScript('OnUpdate', self.OnUpdate)
    end,

    IsPlaying = function(self)
        local time = GetTime()
        return self.start and self.start <= time
                            and self.start + self.duration >= time
    end,

    SetOnPlay = function(self, fn)
        self.OnPlay = fn
    end,

    SetOnFinished = function(self, fn)
        self.OnFinished = fn
    end,

    SetAlpha = function(self, from, to)
        self.alphaFrom = from
        self.alphaTo = to
    end,

    SetTranslate = function(self, from, to)
        self.translateFrom = from
        self.translateTo = to
    end,

    SetScale = function(self, from, to)
        self.scaleFrom = from
        self.scaleTo = to
    end,

    OnUpdate = function(self)
        local time = GetTime()
        local progress = math.min(1, self.ease((time - self.start)/self.duration))
        local parent = self.parent

        if self.translateFrom then
            local x = self.translateStart[1] + self.translateFrom[1]*(1-progress) + self.translateTo[1]*progress
            local y = self.translateStart[2] + self.translateFrom[2]*(1-progress) + self.translateTo[2]*progress
            parent:ClearPointsOffset()
            parent:AdjustPointsOffset(x, y)
        end

        if self.alphaFrom then
            parent:SetAlpha(self.alphaFrom*(1-progress) + self.alphaTo*progress)
        end

        if self.scaleFrom then
            parent:SetScale(self.scaleFrom*(1-progress) + self.scaleTo*progress)
        end

        if time > self.start + self.duration then
            self:SetScript('OnUpdate', nil)
            if self.translateStart then
                parent:ClearPointsOffset()
                parent:AdjustPointsOffset(unpack(self.translateStart))
            end
            self:OnFinished()
        end
    end
}
