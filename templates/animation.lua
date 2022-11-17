local ADDON, Addon = ...

local Frame = LQT.Frame


local EASE = {
    IN = function(x)
        return 1-math.sin((x+1)*math.pi/2)
    end,
    OUT = function(x)
        return math.sin(x*math.pi/2)
    end,
    IN_OUT = function(x)
        return (math.sin((x+3/2)*math.pi)+1)/2
    end
}


Addon.Animation = Frame
    .init {
        function(self, parent)
            self.parent = parent
            self.OnPlay = function() end
            self.OnFinished = function() end
        end,
        
        start = nil,
        ease = EASE.IN_OUT,

        SetDuration = function(self, duration)
            self.duration = duration
        end,

        SetEase = function(self, ease)
            self.ease = EASE[ease]
        end,

        Play = function(self)
            self:OnPlay()
            self.start = GetTime()
            if self.translateFrom then
                local _, _, _, x, y = self.parent:GetPoint()
                self.translateStart = { x, y }
            end
            self:SetScript('OnUpdate', self.OnUpdate)
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
