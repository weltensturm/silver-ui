
local query, SELF, PARENT, Frame, Style, Cooldown, Texture, MaskTexture = LQT.query, LQT.SELF, LQT.PARENT, LQT.Frame, LQT.Style, LQT.Cooldown, LQT.Texture, LQT.MaskTexture


local scale = UIParent:GetScale()


local Size = function(w, h)
    return Style {
        function(self)
            PixelUtil.SetSize(self, w, h)
        end
    }
end


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
        .TOPLEFT:TOPLEFT(-7, 7)
        .BOTTOMRIGHT:BOTTOMRIGHT(7, -7)
        .init(function(self, parent)
            MiniMapMailIcon:AddMaskTexture(self)
        end),
    Style'.Icon'
        .CENTER:CENTER()
        :Size(30, 30),
    Frame'.BgFrame'
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        :AllPoints(PARENT)
    {
        Texture'.Bg'
            :AllPoints(PARENT)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },
    
}


local StyleLfgButton = Style
    .. Size(32, 32)
{
    Style'.Eye' {
        Style'.Texture'
            .. Size(32, 32)
    },
    MaskTexture'.Mask'
        .TOPLEFT:TOPLEFT(-4, 4)
        .BOTTOMRIGHT:BOTTOMRIGHT(4, -4)
        -- :Texture 'Interface/Masks/CircleMaskScalable'
        :Texture 'Interface/COMMON/portrait-ring-withbg'
        .init(function(self, parent)
            query(parent.Eye, '.Frame.Texture'):AddMaskTexture(self)
        end),
    Frame'.BgFrame'
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        :AllPoints(PARENT)
    {
        Texture'.Bg'
            :AllPoints(PARENT)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },
    
}

local StyleBuffIcon = Style
    .. Size(32, 32)
    :Hooks {
        OnUpdate = function(self)
            self:SetAlpha(1.0);
        end
    }
{
    MaskTexture'.Mask'
        .TOPLEFT:TOPLEFT(-7, 7)
        .BOTTOMRIGHT:BOTTOMRIGHT(7, -7)
        -- :Texture 'Interface/Masks/CircleMaskScalable'
        :Texture 'Interface/COMMON/portrait-ring-withbg'
        .init(function(self, parent)
            parent.Icon:AddMaskTexture(self)
        end),

    Style('.Icon')
        .CENTER:CENTER()
        .. Size(30, 30),

    Frame'.BgFrame'
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        :AllPoints(PARENT)
    {
        Texture'.Bg'
            :AllPoints(PARENT)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },
    
    Cooldown'.CooldownBg'
        .TOPLEFT:TOPLEFT(1, -1)
        .BOTTOMRIGHT:BOTTOMRIGHT(-1, 1)
        :UseCircularEdge(true)
        -- :SwipeTexture('Interface/GUILDFRAME/GuildLogoMask_L')
        :SwipeTexture('Interface/Masks/CircleMaskScalable')
        :SwipeColor(1, 1, 1, 1)
        :DrawEdge(false)
        :FrameStrata 'BACKGROUND'
        :FrameLevel(1)
        :Rotation(math.rad(180))
        :HideCountdownNumbers(true),

    Frame'.CooldownInnerBorder'
        .TOPLEFT:TOPLEFT(2.7, -2.7)
        .BOTTOMRIGHT:BOTTOMRIGHT(-2.7, 2.7)
        :FrameStrata 'BACKGROUND'
        :FrameLevel(2)
    {
        Texture'.Bg'
            :AllPoints(PARENT)
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
            local info = self.buttonInfo
            self.CooldownBg:SetCooldown(info.expirationTime - info.duration, info.duration)
            self.CooldownBg:Show()
        else
            self.CooldownBg:Hide()
        end
    end
}


local StyleDebuffIcon = Style
    .. Size(32, 32)
{
    Style'.Border':Hide(),
    
    Style'.Icon'
        .CENTER:CENTER()
        :TexCoord(0.05, 0.95, 0.05, 0.95)
        .. Size(30, 30),

    MaskTexture'.Mask'
        .TOPLEFT:TOPLEFT(1, -1)
        .BOTTOMRIGHT:BOTTOMRIGHT(-1, 1)
        :Texture 'Interface/Masks/CircleMaskScalable'
        .init(function(self, parent)
            parent.Icon:AddMaskTexture(self)
        end),

    Texture'.Bg'
        :AllPoints(PARENT)
        :Texture('Interface/Masks/CircleMaskScalable')
        :DrawLayer('BACKGROUND')
        :VertexColor(1,0,0)
}


local function score(a)
    return
        (a.count and a.count:IsShown() and tonumber(a.count:GetText() or '0') or 0)*10000000
        + a.Icon:GetTexture()
end


local BuffManager = Frame
    .init {
        fullUpdate = function(self)
            local sorted = {}
            local sorted_timed = {}
        
            for _, button in pairs(BuffFrame.auraFrames) do --BuffFrame'.BuffButton#, .AuraContainer.Button' do
                if button:IsShown() then
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
                return score(a) < score(b)
            end)
        
            self.cacheBuffs = sorted
            
            table.sort(sorted_timed, function(a, b)
                return a.timeLeft > b.timeLeft
            end)
        
            self.cacheBuffsTimed = sorted_timed
            
            if DebuffFrame then
                self.cacheDebuffs = query(DebuffFrame, '.AuraContainer.Button').filter(function(self) return self:IsShown() end).all()
            else
                self.cacheDebuffs = query(BuffFrame, '.DebuffButton#').filter(function(self) return self:IsShown() end).all()
            end
        end,
        update = function(self, updatedAuras)
            if not updatedAuras or updatedAuras.addedAuras or updatedAuras.removedAuraInstanceIDs then
                self:fullUpdate()
            end

            if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
                BuffFrame:ClearAllPoints()
                BuffFrame:SetPoint('TOPRIGHT', MinimapCluster, 'TOPLEFT', -3, -25)
                TemporaryEnchantFrame:ClearAllPoints()
                TemporaryEnchantFrame:SetPoint('TOPRIGHT', MinimapCluster, 'TOPLEFT')
            else
                if BuffFrame.Selection:IsShown() then
                    return
                end
                BuffFrame.CollapseAndExpandButton:Hide()
            end

            for i, button in ipairs(self.cacheBuffs or {}) do
                StyleBuffIcon(button)
            end
        
            for i, button in ipairs(self.cacheBuffsTimed or {}) do
                StyleBuffIcon(button)
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
            self:SetScript('OnUpdate', function(self)
                self:SetScript('OnUpdate', nil)
                local mail = (MiniMapMailFrame or MinimapCluster.MailFrame):IsShown() and 1 or 0
                local lfg = (QueueStatusButton and QueueStatusButton:IsShown()) and 1 or 0

                if mail > 0 then
                    local frame = MiniMapMailFrame or MinimapCluster.MailFrame
                    frame:ClearAllPoints()
                    frame:SetPoint('TOPRIGHT', BuffFrame, 'TOPRIGHT', -5 - 35*lfg, 0)
                end
                if lfg > 0 then
                    QueueStatusButton:ClearAllPoints()
                    QueueStatusButton:SetPoint('TOPRIGHT', BuffFrame, 'TOPRIGHT', -5, 0)
                end

                for i, button in ipairs(self.cacheBuffs) do
                    button:ClearAllPoints()
                    button:SetPoint('TOPRIGHT', BuffFrame, 'TOPRIGHT', -5 - (i+mail+lfg-1)*35, 0)
                end
                for i, button in ipairs(self.cacheBuffsTimed) do
                    button:ClearAllPoints()
                    button:SetPoint('TOPRIGHT', BuffFrame, 'TOPRIGHT', -5-20 - (i-1)*35, -40)
                end
                for i, button in ipairs(self.cacheDebuffs) do
                    button:ClearAllPoints()
                    if DebuffFrame then
                        button:SetPoint('TOPRIGHT', DebuffFrame, 'TOPRIGHT', -5 - (i-1)*35, 0)
                    else
                        button:SetPoint('TOPRIGHT', BuffFrame, 'TOPRIGHT', -5 - (i-1)*35, -80)
                    end
                end
            end)
        end,
        updateMail = function(self)
            if (MiniMapMailFrame or MinimapCluster.MailFrame):IsShown() then
                StyleMailIcon((MiniMapMailFrame or MinimapCluster.MailFrame))
                self:updatePoints()
            end
        end,
        updateLfg = function(self)
            if QueueStatusButton:IsShown() then
                StyleLfgButton(QueueStatusButton)
                self:updatePoints()
            end
        end
    }
    :EventHooks {

        PLAYER_ENTERING_WORLD = function(self) self:update() end,

        UNIT_AURA = function(self, unit, args)
            if unit == 'player' then
                self:update(args)
            else
                self:updatePoints()
            end
        end,

        UPDATE_PENDING_MAIL = SELF.updateMail

    }
    .new()

SilverUI.BuffManager = BuffManager

if QueueStatusButton then
    hooksecurefunc(QueueStatusFrame, 'Update', function() BuffManager:updateLfg() end)
end

if MiniMapMailFrame_UpdatePosition then
    hooksecurefunc('MiniMapMailFrame_UpdatePosition', function() BuffManager:updateMail() end)
end

-- hooksecurefunc('UIParent_UpdateTopFramePositions', function() BuffManager:updatePoints() end)
-- hooksecurefunc('UIParent_ManageFramePositions', function() BuffManager:updatePoints() end)

hooksecurefunc(AuraFrameMixin, 'Update', function(self, buttonInfo, expanded)
    BuffManager:updatePoints()
end)
