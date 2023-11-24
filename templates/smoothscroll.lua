---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Script = LQT.Script
local Frame = LQT.Frame
local ScrollFrame = LQT.ScrollFrame


local function PixelSize(widget, size)
    local pixelFactor = PixelUtil.GetPixelToUIUnitFactor()
    local pixels = Round(size * widget:GetEffectiveScale() / pixelFactor)
    return pixels / widget:GetEffectiveScale() * pixelFactor
end


Addon.FrameSmoothScroll = ScrollFrame {

    scrollSpeed = 0,
    overShoot = 0,

    SetOvershoot = function(self, overShoot)
        self.overShoot = overShoot
    end,

    [Script.OnSizeChanged] = function(self)
        self.Content:SetSize(self:GetSize())
    end,
    [Script.OnMouseWheel] = function(self, delta)
        local current = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        if current <= 0 and delta > 0 or current >= max-0.01+self.overShoot and delta < 0 then
            self.scrollSpeed = self.scrollSpeed - delta*0.3
        else
            self.scrollSpeed = self.scrollSpeed - delta
        end
    end,
    [Script.OnUpdate] = function(self, dt)
        if self.scrollSpeed ~= 0 then
            local current = self:GetVerticalScroll()
            local max = self:GetVerticalScrollRange()+self.overShoot
            if current < 0 then
                current = current + math.min(-current, 2048*dt)
            elseif current > max then
                current = current - math.min(current - max, 2048*dt)
            end
            self:SetVerticalScroll(PixelSize(self, current + self.scrollSpeed*dt*512))
            if self.scrollSpeed > 0 then
                self.scrollSpeed = math.max(0, self.scrollSpeed - (4 + math.abs(self.scrollSpeed*5))*dt)
            else
                self.scrollSpeed = math.min(0, self.scrollSpeed + (4 + math.abs(self.scrollSpeed*5))*dt)
            end
        end
    end,
    [Script.OnVerticalScroll] = function(self, offset)
        self.Content:SetHitRectInsets(0, 0, offset, (self.Content:GetHeight() - offset - self:GetHeight()))
    end,

    Content = Frame
        :Height(200)
        :EnableMouse(true)
    {
        function(self, parent)
            parent:SetScrollChild(self)
            self.children = {}
        end
    }
}
