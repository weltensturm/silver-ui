local ADDON, Addon = ...


local PARENT, Frame, Texture = LQT.PARENT, LQT.Frame, LQT.Texture


Addon.BoxShadow = Frame
    :Points { TOPLEFT = PARENT:TOPLEFT(-8, 8),
            BOTTOMRIGHT = PARENT:BOTTOMRIGHT(8, -8) }
{
    Texture'.TopLeft'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(0, 1/4, 0, 1/4)
        :Points { TOPLEFT = PARENT:TOPLEFT(),
                  BOTTOMRIGHT = PARENT:GetParent():TOPLEFT() },
    Texture'.BottomLeft'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(0, 1/4, 3/4, 1)
        :Points { BOTTOMLEFT = PARENT:BOTTOMLEFT(),
                  TOPRIGHT = PARENT:GetParent():BOTTOMLEFT() },
    Texture'.TopRight'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(3/4, 1, 0, 1/4)
        :Points { TOPRIGHT = PARENT:TOPRIGHT(),
                  BOTTOMLEFT = PARENT:GetParent():TOPRIGHT() },
    Texture'.BottomRight'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(3/4, 1, 3/4, 1)
        :Points { BOTTOMRIGHT = PARENT:BOTTOMRIGHT(),
                  TOPLEFT = PARENT:GetParent():BOTTOMRIGHT() },
    Texture'.Left'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(0, 1/4, 1/4, 3/4)
        :Points { LEFT = PARENT:LEFT(),
                  TOPRIGHT = PARENT:GetParent():TOPLEFT(),
                  BOTTOMRIGHT = PARENT:GetParent():BOTTOMLEFT() },
    Texture'.Right'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(3/4, 1, 1/4, 3/4)
        :Points { RIGHT = PARENT:RIGHT(),
                  TOPLEFT = PARENT:GetParent():TOPRIGHT(),
                  BOTTOMLEFT = PARENT:GetParent():BOTTOMRIGHT() },
    Texture'.Top'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(1/4, 3/4, 0, 1/4)
        :Points { TOP = PARENT:TOP(),
                  BOTTOMLEFT = PARENT:GetParent():TOPLEFT(),
                  BOTTOMRIGHT = PARENT:GetParent():TOPRIGHT() },
    Texture'.Bottom'
        :Texture 'Interface/AddOns/silver-ui/art/shadow'
        :TexCoord(1/4, 3/4, 3/4, 1)
        :Points { BOTTOM = PARENT:BOTTOM(),
                  TOPLEFT = PARENT:GetParent():BOTTOMLEFT(),
                  TOPRIGHT = PARENT:GetParent():BOTTOMRIGHT() },
}
