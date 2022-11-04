
local Frame, Style, Cooldown, Texture, MaskTexture = LQT.Frame, LQT.Style, LQT.Cooldown, LQT.Texture, LQT.MaskTexture


-- BUFF_WARNING_TIME = 0


-- UIParent_UpdateTopFramePositions = function() end
-- UIParent_ManageFramePositions = function() end


local scale = UIParent:GetScale()


local BUFF_TIMES = {}


local StyleMailIcon = Style
    :Size(32 + scale, 32 + scale)
{
    Style'.MiniMapMailBorder':Hide(),
    Style'.MiniMapMailIcon'
        :AllPoints(MiniMapMailFrame)
        :Texture 'Interface/Icons/INV_Letter_15',
    MaskTexture'.Mask'
        -- :Texture 'Interface/Masks/CircleMaskScalable'
        :Texture 'Interface/COMMON/portrait-ring-withbg'
        .init(function(self, parent)
            MiniMapMailIcon:AddMaskTexture(self)
            
            self:SetPoints { TOPLEFT = parent:TOPLEFT(-7, 7),
                             BOTTOMRIGHT = parent:BOTTOMRIGHT(7, -7) }
        end),
    Style('.Icon') {
        function(self)
            self:SetPoints { CENTER = self:GetParent():CENTER() }
            self:SetSize(30, 30)
        end
    },
    Frame'.BgFrame'
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        .init(function(self, parent) self:SetAllPoints(parent) end)
    {
        Texture'.Bg'
            .init(function(self, parent)
                self:SetAllPoints(parent)
            end)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },
    
}


local StyleLfgButton = Style
    :Size(32 + scale, 32 + scale)
{
    Style'.Frame' {
        Style'.Texture'
            :Size(32 + scale, 32 + scale)
    },
    MaskTexture'.Mask'
        -- :Texture 'Interface/Masks/CircleMaskScalable'
        :Texture 'Interface/COMMON/portrait-ring-withbg'
        .init(function(self, parent)
            parent.Eye'.Frame.Texture':AddMaskTexture(self)
            self:SetPoints { TOPLEFT = parent:TOPLEFT(-4, 4),
                             BOTTOMRIGHT = parent:BOTTOMRIGHT(4, -4) }
        end),
    Frame'.BgFrame'
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        .init(function(self, parent) self:SetAllPoints(parent) end)
    {
        Texture'.Bg'
            .init(function(self, parent)
                self:SetAllPoints(parent)
            end)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },
    
}

local StyleBuffIcon = Style
    :Size(32 + scale, 32 + scale)
    :Hooks {
        OnUpdate = function(self)
            self:SetAlpha(1.0);
        end
    }
{
    MaskTexture'.Mask'
        -- :Texture 'Interface/Masks/CircleMaskScalable'
        :Texture 'Interface/COMMON/portrait-ring-withbg'
        .init(function(self, parent)
            parent.Icon:AddMaskTexture(self)
            
            self:SetPoints { TOPLEFT = parent:TOPLEFT(-7, 7),
                             BOTTOMRIGHT = parent:BOTTOMRIGHT(7, -7) }
        end),

    Style('.Icon') {
        function(self)
            self:SetPoints { CENTER = self:GetParent():CENTER() }
            self:SetSize(30, 30)
        end
    },

    Frame'.BgFrame'
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        .init(function(self, parent) self:SetAllPoints(parent) end)
    {
        Texture'.Bg'
            .init(function(self, parent)
                self:SetAllPoints(parent)
            end)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },
    
    Cooldown'.CooldownBg'
        :UseCircularEdge(true)
        -- :SwipeTexture('Interface/GUILDFRAME/GuildLogoMask_L')
        :SwipeTexture('Interface/Masks/CircleMaskScalable')
        :SwipeColor(1, 1, 1, 1)
        :DrawEdge(false)
        :FrameStrata 'BACKGROUND'
        :FrameLevel(1)
        :Rotation(math.rad(180))
        :HideCountdownNumbers(true)
        .init(function(self, parent)
            -- self:SetPoints { TOPLEFT = parent:TOPLEFT(-0*2, 0*2),
            --               BOTTOMRIGHT = parent:BOTTOMRIGHT(0*2, -0*2) }
            self:SetPoints { TOPLEFT = parent:TOPLEFT(1, -1),
                          BOTTOMRIGHT = parent:BOTTOMRIGHT(-1, 1) }
        end),

    Frame'.CooldownInnerBorder'
        :FrameStrata 'BACKGROUND'
        :FrameLevel(2)
        .init(function(self, parent)
            -- self:SetPoints { TOPLEFT = parent:TOPLEFT(-scale, scale),
            --               BOTTOMRIGHT = parent:BOTTOMRIGHT(scale, -scale) }
            self:SetPoints { TOPLEFT = parent:TOPLEFT(2.1, -2.1),
                        BOTTOMRIGHT = parent:BOTTOMRIGHT(-2.1, 2.1) }
            -- self:SetPoints { TOPLEFT = parent:TOPLEFT(-2, 2),
            --             BOTTOMRIGHT = parent:BOTTOMRIGHT(9, -9) }
        end)
    {
        Texture'.Bg'
            .init(function(self, parent)
                self:SetAllPoints(parent)
            end)
            :Texture 'Interface/Masks/CircleMaskScalable'
            -- :SetTexelSnappingBias(0.3)
            -- :Texture 'Interface/COMMON/BlueMenuRing'
            -- :Texture 'Interface/GUILDFRAME/GuildLogoMask_L'
            :DrawLayer('BACKGROUND', 7)
            :VertexColor(0,0,0),
    },
    
    function(self)
        local icon = self.Icon:GetTexture()
        if self.timeLeft then
            local time = BUFF_TIMES[icon]
            if not time or self.timeLeft > time then
                time = self.timeLeft
                BUFF_TIMES[icon] = time
            end
            self.CooldownBg:SetCooldown(self.timeLeft + GetTime() - time, time)
            self.CooldownBg:Show()
        else
            BUFF_TIMES[icon] = nil
            self.CooldownBg:Hide()
        end
    end
}


local StyleDebuffIcon = Style
    :Size(32, 32)
{
    Style'.Border':Hide(),
    
    Style'.Icon':TexCoord(0.05, 0.95, 0.05, 0.95) {
        function(self)
            self:SetPoints { CENTER = self:GetParent():CENTER() }
            self:SetSize(30, 30)
        end
    },

    MaskTexture'.Mask'
        .init(function(self, parent)
            self:SetPoints { TOPLEFT = parent:TOPLEFT(1, -1),
                          BOTTOMRIGHT = parent:BOTTOMRIGHT(-1, 1) }
            parent.Icon:AddMaskTexture(self)
        end)
        :Texture('Interface/Masks/CircleMaskScalable'),

    Texture'.Bg'
        .init(function(self, parent)
            self:SetAllPoints(parent)
        end)
        :Texture('Interface/Masks/CircleMaskScalable')
        :DrawLayer('BACKGROUND')
        :VertexColor(1,0,0)
}


local BuffManager = Frame
    .init {
        update = function(self)

            Style(BuffFrame) {
                Style'.CollapseAndExpandButton':Hide()
            }
            
            if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
                BuffFrame:SetPoints { TOPRIGHT = MinimapCluster:TOPLEFT(-3, -25) }
            end

            Style(TemporaryEnchantFrame):Points {
                TOPRIGHT = MinimapCluster:TOPLEFT()
            }
        
            local sorted = {}
            local sorted_timed = {}
        
            for button in BuffFrame'.BuffButton#, .AuraContainer.Button' do
                if button:IsVisible() then
                    if not button.Icon then
                        button.Icon = _G[button:GetName() .. 'Icon']
                    end
                    if button.timeLeft then
                        table.insert(sorted_timed, button)
                    else
                        table.insert(sorted, button)
                    end
                end
            end
        
            
            table.sort(sorted, function(a, b)
                local ascore =
                    (a.count and tonumber(a.count:GetText() or '0'))*10000000
                    + a.Icon:GetTexture()
                local bscore =
                    (b.count and tonumber(b.count:GetText() or '0'))*10000000
                    + b.Icon:GetTexture()
                return ascore < bscore
            end)
        
            self.cacheBuffs = sorted
            for i, button in ipairs(sorted or {}) do
                StyleBuffIcon(button)
            end
        

            table.sort(sorted_timed, function(a, b)
                return a.timeLeft > b.timeLeft
            end)
        
            self.cacheBuffsTimed = sorted_timed
            for i, button in ipairs(sorted_timed or {}) do
                StyleBuffIcon(button)
            end

            if DebuffFrame then
                self.cacheDebuffs = DebuffFrame'.AuraContainer.Button'.filter(function(self) return self:IsShown() end)
            else
                self.cacheDebuffs = BuffFrame'.DebuffButton#'.filter(function(self) return self:IsShown() end)
            end
            for i, button in ipairs(self.cacheDebuffs) do
                if not button.Icon then
                    local name = button:GetName()
                    button.Icon = _G[name .. 'Icon']
                    button.Border = _G[name .. 'Border']
                end
                StyleDebuffIcon(button)
            end
        
            self:updatePoints()
        end,
        cacheBuffs = {},
        cacheBuffsTimed = {},
        cacheDebuffs = {},
        updatePoints = function(self)

            local mail = (MiniMapMailFrame or MinimapCluster.MailFrame):IsShown() and 1 or 0
            local lfg = (QueueStatusButton and QueueStatusButton:IsShown()) and 1 or 0

            if mail > 0 then
                (MiniMapMailFrame or MinimapCluster.MailFrame):SetPoints { TOPRIGHT = BuffFrame:TOPRIGHT(-5 - 35*lfg, 0) }
            end
            if lfg > 0 then
                QueueStatusButton:SetPoints { TOPRIGHT = BuffFrame:TOPRIGHT(-5, 0) }
            end

            for i, button in ipairs(self.cacheBuffs) do
                button:SetPoints { TOPRIGHT = BuffFrame:TOPRIGHT(-5 - (i+mail+lfg-1)*35, 0) }
            end
            for i, button in ipairs(self.cacheBuffsTimed) do
                button:SetPoints { TOPRIGHT = BuffFrame:TOPRIGHT(-5-20 - (i-1)*35, -40) }
            end
            for i, button in ipairs(self.cacheDebuffs) do
                if DebuffFrame then
                    button:SetPoints { TOPRIGHT = DebuffFrame:TOPRIGHT(-5 - (i-1)*35, 0) }
                else
                    button:SetPoints { TOPRIGHT = BuffFrame:TOPRIGHT(-5 - (i-1)*35, -80) }
                end
            end
        end,
        updateMail = function(self)
            StyleMailIcon((MiniMapMailFrame or MinimapCluster.MailFrame))
            self:updatePoints()
        end,
        updateLfg = function(self)
            StyleLfgButton(QueueStatusButton)
            self:updatePoints()
        end
    }
    :EventHooks {

        PLAYER_ENTERING_WORLD = function(self) self:update() end,

        UNIT_AURA = function(self, unit)
            if unit == 'player' then
                self:update()
            else
                self:updatePoints()
            end
        end,

        UPDATE_PENDING_MAIL = function(self) self:updateMail() end

    }
    .new()

if QueueStatusButton then
    hooksecurefunc(QueueStatusFrame, 'Update', function() BuffManager:updateLfg() end)
end

if MiniMapMailFrame_UpdatePosition then
    hooksecurefunc('MiniMapMailFrame_UpdatePosition', function() BuffManager:updateMail() end)
end

hooksecurefunc('UIParent_UpdateTopFramePositions', function() BuffManager:updatePoints() end)
hooksecurefunc('UIParent_ManageFramePositions', function() BuffManager:updatePoints() end)