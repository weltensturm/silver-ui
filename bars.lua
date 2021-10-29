local _, ns = ...

local lqt = ns.lqt


local function range(name, start, end_)

    local mul = 1
    if not MultiBarBottomRightButton1:IsVisible() then
        mul = 1.0258
    end

    for i = start, end_ do
        local btn = _G[name .. i]
        local prev = _G[name .. i-1]

        if prev then
            btn:ClearAllPoints()
            btn:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', 6*mul, 0)
        end

        btn:SetSize(38.65 * mul, 38.65 * mul)

        btn:Texture'ButtonEmboss'
            :SetTexture('Interface/AddOns/custom-gossip/actionbar-button-overlay')
            :SetPoint('BOTTOMLEFT', btn, 'BOTTOMLEFT', -2.75*mul, -3*mul)
            :SetPoint('TOPRIGHT', btn, 'TOPRIGHT', 3.25*mul, 3*mul)
            :SetMask('')

        btn:Texture'Bg'
            :SetTexture('Interface/Buttons/UI-EmptySlot-Disabled')
            :SetDrawLayer('BACKGROUND', -1)
            :SetPoint('BOTTOMLEFT', btn, 'BOTTOMLEFT', -0, -0)
            :SetPoint('TOPRIGHT', btn, 'TOPRIGHT', 0, 0)
            :SetTexCoord(0.2, 0.75, 0.21, 0.75)

        btn.NormalTexture:SetTexture('')

        btn.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

        btn.HideGrid = function() end
		btn:SetAttribute("showgrid", bit.bor(btn:GetAttribute("showgrid"), 1024));
        btn:Show()

        btn'.HotKey'
            :SetFont('Fonts/ARIALN.TTF', 14, 'OUTLINE')

    end

end


local function portrait_area()

    PlayerFrameTexture:SetTexture('')
    PlayerPortrait:Hide()
    PlayerStatusTexture:SetTexture('')

    MainMenuBar:Texture'ArtLeft'
        :SetTexture('Interface/AddOns/custom-gossip/actionbar-art-left')
        :SetPoint('RIGHT', MainMenuBar, 'LEFT', 0, 3)
        :SetPoint('BOTTOM', UIParent, 'BOTTOM')
        :SetSize(90, 90)
        :SetDrawLayer('OVERLAY')

    -- PlayerLevelText:ClearAllPoints()
    -- PlayerLevelText:SetPoint('BOTTOMRIGHT', MainMenuBar.ArtLeft, 'BOTTOMRIGHT', -5, 5)

    MainMenuBar:Texture'PlayerPortrait'
        :SetPoint('RIGHT', MainMenuBar.ArtLeft, 'RIGHT', 12, 2)
        :SetSize(85, 85)
        --:SetSize(70, 70)
        --:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    SetPortraitTexture(MainMenuBar.PlayerPortrait, 'PLAYER')
    
    local portraitmask = PlayerFrame:CreateMaskTexture()
    portraitmask:SetAllPoints(MainMenuBar.ArtLeft)
    portraitmask:SetTexture('Interface/AddOns/custom-gossip/actionbar-art-left-portraitmask')
    MainMenuBar.PlayerPortrait:AddMaskTexture(portraitmask)

    PlayerFrame:SetFrameStrata('HIGH')
    PlayerFrame:SetHeight(40)

    if not PlayerFrame.SetBackdrop then
        _G.Mixin(PlayerFrame, _G.BackdropTemplateMixin)
        PlayerFrame:HookScript('OnSizeChanged', PlayerFrame.OnBackdropSizeChanged)
    end
    PlayerFrame:SetBackdrop({
        edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
        edgeSize = 12
    })
    --window:SetBackdropColor(0.7, 0.7, 0.7, 1)


    PlayerRestIcon:ClearAllPoints()
    PlayerRestIcon:SetPoint('RIGHT', MainMenuBar.ArtLeft, 'TOP', 2, -10)

    PlayerLevelText:ClearAllPoints()
    PlayerLevelText:SetPoint('TOPRIGHT', MainMenuBar.ArtLeft, 'TOPRIGHT', -5, -12)

    PlayerStatusGlow:ClearAllPoints()
    PlayerStatusGlow:SetPoint('CENTER', PlayerRestIcon, 'CENTER', 0, -2)

    PlayerName:ClearAllPoints()
    PlayerName:SetPoint('BOTTOMRIGHT', MainMenuBar.ArtLeft, 'BOTTOMRIGHT', 0, 5)
    PlayerName:SetWidth(63)

    PlayerPrestigeBadge:ClearAllPoints()
    PlayerPrestigeBadge:SetPoint('CENTER', MainMenuBar.ArtLeft, 'CENTER', -18, 3)
    PlayerPrestigePortrait:ClearAllPoints()
    PlayerPrestigePortrait:SetPoint('CENTER', MainMenuBar.ArtLeft, 'CENTER', -18, 3)
    PlayerPVPIcon:ClearAllPoints()
    PlayerPVPIcon:SetPoint('CENTER', MainMenuBar.ArtLeft, 'CENTER', -18, 3)
    
    PlayerFrameBackground:SetPoint('TOPLEFT', PlayerFrame, 'TOPLEFT', 5, -5)
    PlayerFrameBackground:SetPoint('BOTTOMRIGHT', PlayerFrame, 'BOTTOMRIGHT', -5, 5)
    PlayerFrameBackground:Hide()

    PlayerFrameHealthBar:ClearAllPoints()
    PlayerFrameHealthBar:SetPoint('TOPLEFT', PlayerFrame, 'TOPLEFT', 5, -4)
    PlayerFrameHealthBar:SetPoint('RIGHT', PlayerFrame, 'RIGHT', -5, 0)
    PlayerFrameHealthBar:SetHeight(20)
    -- PlayerFrameHealthBar:SetFrameStrata('MEDIUM')

    PlayerFrameManaBar:ClearAllPoints()
    PlayerFrameManaBar:SetPoint('TOPLEFT', PlayerFrameHealthBar, 'BOTTOMLEFT')
    PlayerFrameManaBar:SetPoint('RIGHT', PlayerFrame, 'RIGHT', -5, 0)
    PlayerFrameManaBar:SetHeight(10)
    -- PlayerFrameManaBar:SetFrameStrata('MEDIUM')

    -- ComboPointPlayerFrame.SetPoint = function(...) assert(false, tostring(...)) end
    -- ComboPointPlayerFrame:ClearAllPoints()
    -- ComboPointPlayerFrame:SetPoint('TOPRIGHT', PlayerFrame, 'BOTTOMRIGHT')

    PlayerFrameHealthBar:SetStatusBarTexture('Interface/RAIDFRAME/Raid-Bar-Hp-Fill')
    -- PlayerFrameHealthBar:SetStatusBarTexture('Interface/CHARACTERFRAME/BarFill')
end


local function init()

    MainMenuBarArtFrame:Strip()

    -- MainMenuBar:Texture'ButtonEmboss'
    --     -- :SetAtlas('hud-MainMenuBar-small')
    --     -- :SetTexCoord(0, 0.929, 0, 1)
    --     -- :SetTexture('Interface/RAIDFRAME/UI-RaidFrame-GroupBg', true, true)
    --     -- :SetTexture('Interface/FrameGeneral/UI-Background-Rock', true, true)
    --     -- :SetTexture('Interface/ItemTextFrame/ItemText-Stone-TopLeft', true, true)
    --     :SetColorTexture(0.376, 0.376, 0.376, 1)
    --     -- :SetDrawLayer('OVERLAY', 7)

    --     -- :SetTexture('Interface/RAIDFRAME/UI-RaidInfo-Header', true, true)

    --     -- :SetTexture('Interface/ContainerFrame/UI-Bag-1x4')
    --     -- :SetTexCoord(0.3058, 0.96, 0.37, 0.69)

    --     :SetVertTile(true)
    --     :SetHorizTile(true)

    --     :SetPoint('BOTTOMLEFT', MainMenuBar, 'BOTTOMLEFT', 6, 0)
    --     -- :SetPoint('TOPRIGHT', MultiBarBottomLeft, 'TOPRIGHT', 1, 25)
    --     :SetPoint('TOPRIGHT', MainMenuBar, 'TOPRIGHT', -6, 39)
    --     -- :SetPoint('TOPRIGHT', ActionButton4, 'TOPRIGHT', 5, 5)

    MultiBarBottomLeftButton1:ClearAllPoints()
    MultiBarBottomLeftButton1:SetPoint('BOTTOMLEFT', ActionButton1, 'TOPLEFT', 0, 6)

    ActionButton1:ClearAllPoints()
    ActionButton1:SetPoint('BOTTOMLEFT', MainMenuBar, 'BOTTOMLEFT', 2.75, 2)

    range('ActionButton', 1, 12)
    range('MultiBarBottomLeftButton', 1, 12)
    range('MultiBarBottomRightButton', 1, 12)

    MultiBarBottomRightButton7:ClearAllPoints()
    MultiBarBottomRightButton7:SetPoint('BOTTOMLEFT', MultiBarBottomRightButton1, 'TOPLEFT', 0, 6)

    MultiBarBottomRightButton1:ClearAllPoints()
    MultiBarBottomRightButton1:SetPoint('BOTTOMLEFT', ActionButton12, 'BOTTOMRIGHT', 6.15, 0)

    -- StatusTrackingBarManager:SetFrameStrata('HIGH')
    
    ActionBarUpButton:Hide()
    ActionBarDownButton:Hide()
    MainMenuBarArtFrame.PageNumber:Hide()

    StanceBarFrame:ClearAllPoints()
    StanceBarFrame:SetPoint('BOTTOM', UIParent, 'TOP')

    local mask = MultiBarBottomLeftButton1:CreateMaskTexture()
    mask:SetAllPoints(MultiBarBottomLeftButton1.ButtonEmboss)
    mask:SetTexture('Interface/AddOns/custom-gossip/actionbar-button-overlay-mask-tl')
    MultiBarBottomLeftButton1.ButtonEmboss:AddMaskTexture(mask)

    local mask = MultiBarBottomRightButton12:CreateMaskTexture()
    mask:SetAllPoints(MultiBarBottomRightButton12.ButtonEmboss)
    mask:SetTexture('Interface/AddOns/custom-gossip/actionbar-button-overlay-mask-tr')
    MultiBarBottomRightButton12.ButtonEmboss:AddMaskTexture(mask)

    -- StatusTrackingBarManager:SetWidth(50)
    -- for v in StatusTrackingBarManager'.*' do
    --     v:SetSize(50, 10)
    --     v:ClearAllPoints()
    --     v:SetPoint('BOTTOMRIGHT', MainMenuBar, 'BOTTOMLEFT')
    --     if v.StatusBar then
    --         v.StatusBar:SetSize(50, 10)
    --         v.StatusBar:ClearAllPoints()
    --         v.StatusBar:SetPoint('BOTTOMRIGHT', MainMenuBar, 'BOTTOMLEFT')
    --     end
    -- end

    -- StatusTrackingBarManager:ClearAllPoints()
    -- StatusTrackingBarManager:SetPoint('BOTTOMRIGHT', MainMenuBar, 'BOTTOMLEFT')

    portrait_area()
end


MultiBarBottomRight:Hook {
    OnShow = init,
    OnHide = init
}


init()