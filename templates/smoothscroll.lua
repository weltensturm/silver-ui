local ADDON, Addon = ...


local Frame, ScrollFrame = LQT.Frame, LQT.ScrollFrame


Addon.FrameSmoothScroll = ScrollFrame
    .data { scrollSpeed = 0, overShoot = 50 }
    :Scripts {
        OnSizeChanged = function(self)
            self.Content:SetSize(self:GetSize())
        end,
        OnMouseWheel = function(self, delta)
            local current = self:GetVerticalScroll()
            local max = self:GetVerticalScrollRange()
            if current <= 0 and delta > 0 or current >= max-0.01+self.overShoot and delta < 0 then
                self.scrollSpeed = self.scrollSpeed - delta*0.3
            else
                self.scrollSpeed = self.scrollSpeed - delta
            end
        end,
        OnUpdate = function(self, dt)
            if self.scrollSpeed ~= 0 then
                local current = self:GetVerticalScroll()
                local max = self:GetVerticalScrollRange()+self.overShoot
                if current < 0 then
                    current = current + math.min(-current, 2048*dt)
                elseif current > max then
                    current = current - math.min(current - max, 2048*dt)
                end
                self:SetVerticalScroll(current + self.scrollSpeed*dt*512)
                if self.scrollSpeed > 0 then
                    self.scrollSpeed = math.max(0, self.scrollSpeed - (4 + math.abs(self.scrollSpeed*5))*dt)
                else
                    self.scrollSpeed = math.min(0, self.scrollSpeed + (4 + math.abs(self.scrollSpeed*5))*dt)
                end
            end
        end,
        OnVerticalScroll = function(self, offset)
            self.Content:SetHitRectInsets(0, 0, offset, (self.Content:GetHeight() - offset - self:GetHeight()))
        end
    }
{
    Frame'.Content'
        .init(function(self, parent)
            parent:SetScrollChild(self)
            self.children = {}
        end)
        :Height(200)
        :EnableMouse(true)
}
