---@class Addon
local Addon = select(2, ...)

---@class Addon.Templates
Addon.Templates = Addon.Templates or {}

local LQT = Addon.LQT
local Script = LQT.Script
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture



Addon.Templates.BarShaped = Frame {
    parent = PARENT,
    value = 0,
    valueMax = 0,
    maskAspect = 4096 / 64,

    SetTexture = function(self, texture)
        self.Bar:SetTexture(texture)
    end,

    SetMask = function(self, texture, aspect)
        self.MaskLeft:SetTexture(texture, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        self.MaskRight:SetTexture(texture, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        self.maskAspect = aspect
    end,

    GetEndcap = function(self)
        local w, h = self:GetSize()
        return
            h/2,
            self.valueMax/(h/2*h + w*h)*h/2*h
    end,

    [Script.OnSizeChanged] = function(self, w, h)
        local huge_width = math.max(0.01, h) * self.maskAspect
        PixelUtil.SetWidth(self.MaskLeft, huge_width)
        PixelUtil.SetWidth(self.MaskRight, huge_width)
        self.endcapWidth, self.endcapValue = self:GetEndcap()
    end,

    SetValue = function(self, value, max)
        local width = self:GetWidth()

        if max ~= self.valueMax then
            self.endcapWidth, self.endcapValue = self:GetEndcap()
        end

        local shapeWidth = 0
        if value > self.endcapValue*2 then
            shapeWidth = self.endcapWidth*2 + (value-self.endcapValue*2)
                                              /(max-self.endcapValue*2)*(width-self.endcapWidth*2)
        else
            shapeWidth = math.sqrt(value/self.endcapValue/2) * self.endcapWidth*2
        end
        local offset = PixelUtil.GetNearestPixelSize((width-shapeWidth)/2, self:GetEffectiveScale())
        self.MaskLeft:SetPoint('LEFT', self, 'LEFT', offset, 0)
        self.MaskRight:SetPoint('RIGHT', self, 'RIGHT', -offset, 0)

    end,

    MaskLeft = MaskTexture
        .TOP:TOP()
        .BOTTOM:BOTTOM()
        .LEFT:LEFT()
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),

    MaskRight = MaskTexture
        .TOP:TOP()
        .BOTTOM:BOTTOM()
        .RIGHT:RIGHT()
        :Texture('Interface/AddOns/silver-ui/art/hp-sharp', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'),

    Bar = Texture
        -- .TOPLEFT:TOPLEFT(-4, 0)
        -- .BOTTOMRIGHT:BOTTOMRIGHT(4, 0)
        -- .TOP:TOP()
        -- .BOTTOM:BOTTOM()
        :AllPoints(PARENT)
        -- :ColorTexture(1, 0, 0, 1)
        -- :Texture 'Interface/BUTTONS/GreyscaleRamp64'
        -- :Texture 'Interface/TARGETINGFRAME/UI-StatusBar'
        -- :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        -- :Texture 'Interface/AddOns/silver-ui/art/bar'
        :Texture 'Interface/AddOns/silver-ui/art/bar-bright'
        :TexCoord(0.3, 0.7, 0.1, 0.9)
        :DrawLayer('ARTWORK', 2)
        :AddMaskTexture(PARENT.MaskLeft)
        :AddMaskTexture(PARENT.MaskRight),

}

