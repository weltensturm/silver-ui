local ADDON, Addon = ...


local PARENT, Frame, Texture = LQT.PARENT, LQT.Frame, LQT.Texture


local ShadowTexture = Texture:Texture 'Interface/AddOns/silver-ui/art/shadow'


Addon.BoxShadow = Frame
    .TOPLEFT:TOPLEFT(-8, 8)
    .BOTTOMRIGHT:BOTTOMRIGHT(8, -8)
{
    ShadowTexture'.TopLeft'
        :TexCoord(0, 1/4, 0, 1/4)
        .TOPLEFT:TOPLEFT()
        .BOTTOMRIGHT:TOPLEFT(PARENT:GetParent()),
    ShadowTexture'.BottomLeft'
        :TexCoord(0, 1/4, 3/4, 1)
        .BOTTOMLEFT:BOTTOMLEFT()
        .TOPRIGHT:BOTTOMLEFT(PARENT:GetParent()),
    ShadowTexture'.TopRight'
        :TexCoord(3/4, 1, 0, 1/4)
        .TOPRIGHT:TOPRIGHT()
        .BOTTOMLEFT:TOPRIGHT(PARENT:GetParent()),
    ShadowTexture'.BottomRight'
        :TexCoord(3/4, 1, 3/4, 1)
        .BOTTOMRIGHT:BOTTOMRIGHT()
        .TOPLEFT:BOTTOMRIGHT(PARENT:GetParent()),
    ShadowTexture'.Left'
        :TexCoord(0, 1/4, 1/4, 3/4)
        .LEFT:LEFT()
        .TOPRIGHT:TOPLEFT(PARENT:GetParent())
        .BOTTOMRIGHT:BOTTOMLEFT(PARENT:GetParent()),
    ShadowTexture'.Right'
        :TexCoord(3/4, 1, 1/4, 3/4)
        .RIGHT:RIGHT()
        .TOPLEFT:TOPRIGHT(PARENT:GetParent())
        .BOTTOMLEFT:BOTTOMRIGHT(PARENT:GetParent()),
    ShadowTexture'.Top'
        :TexCoord(1/4, 3/4, 0, 1/4)
        .TOP:TOP()
        .BOTTOMLEFT:TOPLEFT(PARENT:GetParent())
        .BOTTOMRIGHT:TOPRIGHT(PARENT:GetParent()),
    ShadowTexture'.Bottom'
        :TexCoord(1/4, 3/4, 3/4, 1)
        .BOTTOM:BOTTOM()
        .TOPLEFT:BOTTOMLEFT(PARENT:GetParent())
        .TOPRIGHT:BOTTOMRIGHT(PARENT:GetParent()),
}
