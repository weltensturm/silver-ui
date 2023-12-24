---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local query = LQT.query
local Event = LQT.Event
local Script = LQT.Script
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Frame = LQT.Frame
local Style = LQT.Style
local Cooldown = LQT.Cooldown
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture
local FontString = LQT.FontString

local PixelSize = Addon.Templates.PixelSize

local load


local _, db = SilverUI.Storage {
    name = 'Buff Frame',
    character = {
        enabled = true
    },
    onload = function(account, character)
        if character.enabled then
            load()
        end
    end
}


SilverUI.Settings 'Buff Frame' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Buff Frame',

    Addon.CheckBox
        :Label 'Enable'
        :Get(function(self) return db.enabled end)
        :Set(function(self, value) db.enabled = value end),

}


local MailFrame = MiniMapMailFrame or MinimapCluster.IndicatorFrame.MailFrame


local StyleMailIcon = Style { PixelSize }
    :Size(32, 32)
{
    ['.MiniMapMailBorder'] = Style:Hide(),
    ['.MiniMapMailIcon'] = Style
        :AllPoints()
        :Texture 'Interface/Icons/INV_Letter_15',
    ['.Icon'] = Style
        .CENTER:CENTER()
        :Size(30, 30),
    Mask = MaskTexture
        -- :Texture 'Interface/Masks/CircleMaskScalable'
        :Texture 'Interface/COMMON/portrait-ring-withbg'
        .TOPLEFT:TOPLEFT(-7, 7)
        .BOTTOMRIGHT:BOTTOMRIGHT(7, -7)
    {
        function(self, parent)
            if parent then
                MiniMapMailIcon:AddMaskTexture(self)
            end
        end
    },
    BgFrame = Frame
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        :AllPoints(PARENT)
    {
        Bg = Texture
            :AllPoints(PARENT)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },

}


local StyleLfgButton = Style { PixelSize }
    :Size(32, 32)
{
    ['.Eye'] = Style {
        ['.Texture'] = Style { PixelSize }
            :Size(32, 32)
    },
    Mask = MaskTexture
        .TOPLEFT:TOPLEFT(-4, 4)
        .BOTTOMRIGHT:BOTTOMRIGHT(4, -4)
        -- :Texture 'Interface/Masks/CircleMaskScalable'
        :Texture 'Interface/COMMON/portrait-ring-withbg'
    {
        function(self, parent)
            if parent then
                query(parent.Eye, '.Frame.Texture'):AddMaskTexture(self)
            end
        end
    },
    BgFrame = Frame
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        :AllPoints(PARENT)
    {
        Bg = Texture
            :AllPoints(PARENT)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },

}

local StyleBuffIcon = Style { PixelSize }
    :Size(32, 32)
{
    [Script.OnUpdate] = function(self)
        self:SetAlpha(1.0);
    end,

    ['.Icon'] = Style { PixelSize }
        .CENTER:CENTER()
        :Size(30, 30),

    Mask = MaskTexture
        .TOPLEFT:TOPLEFT(-7, 7)
        .BOTTOMRIGHT:BOTTOMRIGHT(7, -7)
        -- :Texture 'Interface/Masks/CircleMaskScalable'
        :Texture 'Interface/COMMON/portrait-ring-withbg'
    {
        function(self, parent)
            if parent then
                parent.Icon:AddMaskTexture(self)
            end
        end
    },

    BgFrame = Frame
        :FrameStrata 'BACKGROUND'
        :FrameLevel(0)
        :AllPoints(PARENT)
    {
        Bg = Texture
            :AllPoints(PARENT)
            :Texture('Interface/Masks/CircleMaskScalable')
            :DrawLayer('BACKGROUND', 0)
            :VertexColor(0,0,0,0.7),
    },

    CooldownBg = Cooldown
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

    CooldownInnerBorder = Frame
        .TOPLEFT:TOPLEFT(2.7, -2.7)
        .BOTTOMRIGHT:BOTTOMRIGHT(-2.7, 2.7)
        :FrameStrata 'BACKGROUND'
        :FrameLevel(2)
    {
        Bg = Texture
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
        local info = self.buttonInfo
        if self.timeLeft and info then
            self.CooldownBg:SetCooldown(info.expirationTime - info.duration, info.duration)
            self.CooldownBg:Show()
        else
            self.CooldownBg:Hide()
        end
    end
}


local StyleDebuffIcon = Style { PixelSize }
    :Size(32, 32)
{
    ['.Border'] = Style:Hide(),

    ['.Icon'] = Style { PixelSize }
        .CENTER:CENTER()
        :Size(30, 30)
        :TexCoord(0.05, 0.95, 0.05, 0.95),

    ['.DebuffBorder'] = Style:Texture '',

    Bg = Texture
        :AllPoints(PARENT)
        :Texture('Interface/Masks/CircleMaskScalable')
        :DrawLayer('BACKGROUND')
        :VertexColor(1,0,0),

    Mask = MaskTexture
        .TOPLEFT:TOPLEFT(1, -1)
        .BOTTOMRIGHT:BOTTOMRIGHT(-1, 1)
        :Texture 'Interface/Masks/CircleMaskScalable'
    {
        function(self, parent)
            if parent then
                parent.Icon:AddMaskTexture(self)
            end
        end
    },

}


local function score(a)
    return
        (a.Count and a.Count:IsShown() and tonumber(a.Count:GetText() or '0') or 0)*10000000
        + a.Icon:GetTexture()
end


local BuffSystem = Frame {
    fullUpdate = function(self)
        local sorted = {}
        local sorted_timed = {}

        for button in query(BuffFrame, '.Button, .AuraContainer.Button') do
            -- for _, button in pairs(BuffFrame.auraFrames) do -- retail
            --BuffFrame'.BuffButton#, .AuraContainer.Button' do -- old classic
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
        self:updatePoints()
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

        -- self:updatePoints()
    end,
    cacheBuffs = {},
    cacheBuffsTimed = {},
    cacheDebuffs = {},
    updatePoints = function(self)
        self:SetScript('OnUpdate', function(self)
            self:SetScript('OnUpdate', nil)
            local mail = MailFrame:IsShown() and 1 or 0
            local lfg = (QueueStatusButton and QueueStatusButton:IsShown()) and 1 or 0

            if mail > 0 then
                local frame = MailFrame
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
        if MailFrame:IsShown() then
            StyleMailIcon(MailFrame)
            self:updatePoints()
        end
    end,
    updateLfg = function(self)
        if QueueStatusButton:IsShown() then
            StyleLfgButton(QueueStatusButton)
            self:updatePoints()
        end
    end,

    [Event.PLAYER_ENTERING_WORLD] = function(self) self:update() end,

    [Event.UNIT_AURA] = function(self, unit, args)
        if unit == 'player' then
            self:update(args)
        else
            self:updatePoints()
        end
    end,

    [Event.UPDATE_PENDING_MAIL] = SELF.updateMail

}


load = function()
    local system = BuffSystem.new()
    SilverUI.BuffSystem = system

    if QueueStatusButton then
        hooksecurefunc(QueueStatusFrame, 'Update', function() system:updateLfg() end)
    end

    if MiniMapMailFrame_UpdatePosition then
        hooksecurefunc('MiniMapMailFrame_UpdatePosition', function() system:updateMail() end)
    end

    -- hooksecurefunc('UIParent_UpdateTopFramePositions', function() system:updatePoints() end)
    -- hooksecurefunc('UIParent_ManageFramePositions', function() system:updatePoints() end)

    if BuffFrame.UpdateGridLayout then
        hooksecurefunc(BuffFrame, 'UpdateGridLayout', function(self, buttonInfo, expanded)
            system:updatePoints()
        end)
    end
end