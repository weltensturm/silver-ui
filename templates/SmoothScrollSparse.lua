---@class Addon
local Addon = select(2, ...)

---@class Addon.Templates
Addon.Templates = Addon.Templates or {}

local LQT = Addon.LQT
local Script = LQT.Script
local SELF = LQT.SELF
local Style = LQT.Style
local Frame = LQT.Frame


local Clamp = Clamp
local tinsert = tinsert
local tremove = tremove


local function FindScrollView(data, height, tops, top, bottom)
    if #data > 0 then
        local topIndex = math.max(1, ceil(top / height * #data))
        while topIndex < 1 or tops[topIndex] < top do
            topIndex = topIndex + 1
        end
        while tops[topIndex] > top and topIndex > 1 do
            topIndex = topIndex - 1
        end

        local bottomIndex = math.min(#data, floor(bottom / height * #data))
        while tops[bottomIndex] > bottom do
            bottomIndex = bottomIndex - 1
        end
        while tops[bottomIndex] < bottom and bottomIndex < #data do
            bottomIndex = bottomIndex + 1
        end

        return topIndex, bottomIndex
    end
end


Addon.Templates.SmoothScrollSparse = Addon.FrameSmoothScroll {

    scrollData = {},
    scrollActive = {},
    scrollTops = {},
    scrollIndexTop = 0,
    scrollIndexBottom = 0,
    scrollPaddingBottom = 0,

    SetElementTemplate = function(self, template)
        self.template = template
    end,

    SetElementHeight = function(self, height)
        self.elementHeight = height
    end,

    ElementHeight = function(self, element)
        return self.elementHeight
    end,

    SetScrollPaddingBottom = function(self, padding)
        self.scrollPaddingBottom = padding
    end,

    SetScrollData = function(self, data, shared)
        self.scrollIndexTop = 0
        self.scrollIndexBottom = 0
        self.scrollData = data
        self.scrollDataShared = shared
        for i=1, #self.scrollActive do
            self.scrollActive[i]:SetPoint('TOPLEFT', self.Content, 'TOPLEFT')
            self.scrollActive[i]:Hide()
        end
        local height = 0
        for i, entry in pairs(data) do
            self.scrollTops[i] = height
            height = height + self:ElementHeight(entry)
        end
        self.contentHeight = height
        self.Content.Space:SetHeight(height + self.scrollPaddingBottom)
        self:UpdateScrollView()
    end,

    ShowElement = function(self, index, activeIndex)
        local data = self.scrollData[index]
        local element = self.scrollActive[activeIndex]
        element:SetPoint('TOPLEFT', self.Content, 'TOPLEFT', 0, -self.scrollTops[index])
        element:SetPoint('RIGHT', self.Content, 'RIGHT', 0, -self.scrollTops[index])
        element:SetHeight(self:ElementHeight(data))
        element:ScrollShow(data, self.scrollDataShared)
        element:Show()
    end,

    UpdateScrollView = function(self)
        local top = self:GetVerticalScroll()
        local bottom = top + self:GetHeight()
        local indexTop, indexBottom = FindScrollView(self.scrollData, self.contentHeight, self.scrollTops, top, bottom)
        if indexTop and indexTop > 0 then

            local count = indexBottom - indexTop + 1
            for i=#self.scrollActive+1, count do
                self.scrollActive[i] = self.template:Hide().new(self.Content)
            end

            local showTop = Clamp(self.scrollIndexTop - indexTop, -count, count)
            local showBottom = Clamp(indexBottom - self.scrollIndexBottom, -count, count)

            for i=1, showTop do
                local element = tremove(self.scrollActive, #self.scrollActive)
                tinsert(self.scrollActive, 1, element)
                self:ShowElement(indexTop+showTop-i, 1)
            end
            for i=1, -showTop do
                self.scrollActive[i]:Hide()
                local element = tremove(self.scrollActive, 1)
                tinsert(self.scrollActive, element)
            end

            for i=1, showBottom do
                self:ShowElement(indexBottom-showBottom+i, count-showBottom+i)
            end

            self.scrollIndexTop = indexTop
            self.scrollIndexBottom = indexBottom
        end
    end,
    [Script.OnSizeChanged] = SELF.UpdateScrollView,
    [Script.OnVerticalScroll] = SELF.UpdateScrollView,

    ['.Content'] = Style {
        Space = Frame
            .TOPLEFT:TOPLEFT()
            .TOPRIGHT:TOPRIGHT()
    }

}