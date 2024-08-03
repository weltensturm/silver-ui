---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local matches = LQT.matches

local query = LQT.query
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Script = LQT.Script
local Event = LQT.Event
local Style = LQT.Style
local Texture = LQT.Texture
local Frame = LQT.Frame


local WIDTH = 420
local MIN_HEIGHT = 150


local Hide = Style:Hide()


local function byVisible(e)
    return e:IsVisible()
end


local CORNER_TO_VEC = {
    TOPLEFT = { 1, -1 },
    TOPRIGHT = { -1, -1 },
    BOTTOMLEFT = { 1, 1 },
    BOTTOMRIGHT = { -1, 1 },
    TOP = { 0, 1 },
    BOTTOM = { 0, -1 },
    LEFT = { -1, 0 },
    RIGHT = { 1, 0 },
    CENTER = { 0, 0 }
}

function CornerOffset(self, x, y)
    local from, parent, to, _, _ = self:GetPoint()
    if not to then return end
    local offset = CORNER_TO_VEC[to]
    self:SetPoint(to, parent, to, offset[1]*x, offset[2]*y)
end


local function Strip(self, ...)
    if ... then
        local name = self:GetName() or ''
        for i=1, select('#', ...) do
            local v = select(i, ...)
            local obj = self[v] or _G[name .. v]
            if obj and obj.GetChildren then
                Strip(obj)
            elseif obj and obj:GetObjectType() == 'Texture' then
                obj:SetTexture('')
                obj:SetAtlas('')
            end
        end
    else
        for frame in query(self, '@Frame') do
            Strip(frame)
        end
        query(self, '@Texture'):SetTexture(''):SetAtlas('')
    end
end


function FitToChildren(self)
    local height = 0
    local parent_top = self:GetTop()
    if parent_top then
        for child in query(self, '.*') do
            if child:IsShown() and (child:GetObjectType() ~= "Frame" or child:GetChildren() or child:GetRegions()) then
                local bottom = child:GetBottom()
                if bottom and parent_top-bottom > height then
                    height = parent_top-bottom
                end
            end
        end
        self:SetHeight(height + self:GetEffectiveScale())
    end
end


local function InlineListLayout(selection, filter, margin)
    local previous_match = nil
    local before = nil
    local after = nil
    for element in selection.sort() do
        if element:IsShown() then
            if filter and not matches(element, filter) then
                if previous_match then
                    local anchor = select(2, element:GetPoint())
                    -- print('PREVIOUS', element:GetName() or element:GetObjectType(), '->', previous_match:GetName() or previous_match:GetObjectType())
                    element:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -(anchor:GetBottom() - previous_match:GetBottom()) - margin.inner)
                    previous_match = nil
                    before = nil
                    after = nil
                elseif previous_match and not after then
                    after = element
                end
                if not after then
                    before = element
                end
            else
                if previous_match or before then
                    local anchor = select(2, element:GetPoint())
                    -- print('ANCHOR', element:GetName() or element:GetObjectType(), '->', (previous_match or before):GetName() or (previous_match or before):GetObjectType())
                    element:ClearAllPoints()
                    element:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -(anchor:GetBottom() - (previous_match or before):GetBottom()) - margin.inner)
                    previous_match = element
                else
                    before = element
                end
            end
        end
    end
    if after and previous_match then
        local anchor = select(2, after:GetPoint())
        -- print('AFTER', after:GetName(), '->', previous_match:GetName())
        after:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -(anchor:GetBottom() - previous_match:GetBottom()) - margin.inner)
    end
end


local ListLayout = Style {
    function(self)
        local height = 0
        for element in query(self, '.*').sort() do
            if element:IsShown() then
                element:ClearAllPoints()
                element:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, -5 - height)
                height = height + element:GetHeight()
            end
        end
    end
}


local function HideIfEmpty(self)
    if not self:GetChildren() and not self:GetRegions() then
        self:Hide()
    end
end


local StyleQuestInfoRewardsFrame = Style {
    ['.QuestInfoRewardsFrame'] = Style {
        ['.:Button'] = Style
            .filter(function(self) return not self.PortraitFrame end)
            :Size(200, 20)
            :HitRectInsets(0, 0, 0, 0)
        {

            [Script.OnClick] = function(self)
                if QuestFrameRewardPanel:IsShown() and not IsModifierKeyDown() then
                    QuestFrameCompleteQuestButton:Click()
                    QuestInfoItemHighlight:SetPoint('TOPLEFT', self, 'TOPLEFT', -10, -2.5)
                end
            end,
            [Script.OnEnter] = function(self)
                if QuestFrameRewardPanel:IsShown() then
                    Style
                        :SetHeight(20)
                        :SetPoint('TOPLEFT', self, 'TOPLEFT', -10, -2.5)
                        :Show()(QuestInfoItemHighlight)
                end
            end,
            [Script.OnLeave] = function(...)
                QuestInfoItemHighlight:Hide()
            end,

            ['.:Texture'] = Style:Hide(),

            ['.Name'] = Style
                .TOPLEFT:TOPLEFT(0, -2)
                .RIGHT:RIGHT(PARENT:GetParent(), -20, 0),

            ['.Icon'] = Style
                :Show()
                :Size(20, 20)
                .TOPLEFT:TOPLEFT(),

            ['.:FontString'] = Style
                :Size(180, 20)
                :TextColor(0.1, 0, 0, 1)
                :ShadowOffset(0, 0)
                .TOPLEFT:TOPLEFT(27, 0)
                .RIGHT:RIGHT(PARENT:GetParent()),

            ['.RewardAmount'] = Style
                :TextColor(1, 1, 1, 1),

            ['.NameFrame'] = Style
                .TOPLEFT:TOPLEFT(0, -2)
                .RIGHT:RIGHT(PARENT:GetParent(), -20, 0)
                :Show()
                :Texture 'Interface/Buttons/UI-Listbox-Highlight2'
                :DrawLayer('BACKGROUND', -7 )
                :BlendMode 'ADD'
                :VertexColor(1,1,1,0.2)
                :Height(16)
            {
                function(self)
                    local parent = self:GetParent()
                    local show = QuestFrameRewardPanel:IsShown() and parent:IsShown() and parent.Icon and parent:GetNumPoints() > 0
                    self:SetAlpha(show and 0.2 or 0)
                end,
            },

            ['.Count'] = Style
                :TextColor(1, 1, 1)
                :JustifyH 'LEFT'
                :TextScale(0.85)
                .TOPLEFT:TOPLEFT(PARENT.Icon, 0,-5)
                .BOTTOMRIGHT:BOTTOMRIGHT(PARENT.Icon, 10,-5)
        },

        function(self)
            InlineListLayout(query(self, '.*'), ':Button', { left=0, inner=5, after=10 })
            -- if self.ItemReceiveText then
            --     for btn in self'.Button' do
            --         self.ItemReceiveText:SetPoints { TOPLEFT = btn:BOTTOMLEFT(0, -5 )}
            --     end
            -- end
            if QuestInfoRewardsFrame:IsShown() then
                QuestFrameCompleteQuestButton:Show()
                for btn in query(self, '.Button').filter(byVisible) do
                    local show = btn.Icon and btn:GetNumPoints() > 0 -- don't ask me
                    if show then
                        QuestFrameCompleteQuestButton:Hide()
                    end
                end
            end
            FitToChildren(self)
        end
    }
}


local StyleItemTextFrame = Style {

    [Script.OnMouseWheel] = function(self, delta)
        if delta > 0 then
            query(ItemTextFrame, ':ItemTextPrevPageButton'):Click()
        else
            query(ItemTextFrame, ':ItemTextNextPageButton'):Click()
        end
    end,

    ['.\0:\0@Texture'] = Hide,
    ['.ItemTextFramePageBg'] = Hide,
    ['.PortraitBorderTexture'] = Hide,
    [':ItemTextMaterial*'] = Style:Texture '',

    ['.TitleText, .ItemTextTitleText'] = Style
        .TOPLEFT:TOPLEFT(70, -15)
        .TOPRIGHT:TOPRIGHT(-10, -15)
        :TextColor(1, 1, 1, 1)
        :ShadowColor(0, 0, 0, 1)
        :ShadowOffset(1, -1)
        :JustifyH 'LEFT',

    [':ItemTextPrevPageButton'] = Style
        .BOTTOMLEFT:BOTTOMLEFT(15, 10),

    [':ItemTextNextPageButton'] = Style
        .BOTTOMRIGHT:BOTTOMRIGHT(-15, 10),

    [':ItemTextCurrentPage'] = Style
        .BOTTOM:BOTTOM(0, 20),

    ['@ScrollFrame > @Texture'] = Hide,

    ['@ScrollFrame, @ScrollBox'] = Style
        :Size(WIDTH-20, 10)
        :EnableMouseWheel(false)
    {
        ['@Frame'] = Style
            :Width(WIDTH-20)
        {
            ['.SimpleHTML'] = Style
                :Width(WIDTH-20)
                .TOPLEFT:TOPLEFT(10, -10)
            {
                ['.*'] = Style:Width(WIDTH-40),
                FitToChildren
            },
            FitToChildren
        },
        ['.ScrollBar'] = Style:Hide(),
        FitToChildren
    }

}


local StyleWindow = Style {

    ['.\0:\0@Texture'] = Style:Texture '',
    ['.\0:*Background*@Texture'] = Style:Texture '',

    ['.*FramePortrait'] = Style
        .LEFT:TOPLEFT(4, -7)
        :Size(65, 65),
        -- :DrawLayer 'ARTWORK',

    ['.PortraitContainer'] = Style
        .LEFT:TOPLEFT(4, -7)
        :Size(65, 65)
    {
        ['.CircleMask'] = Style:Hide(),
        ['.portrait'] = Style
            :AllPoints(PARENT)
            :Show()
    },

    [':*NameFrame, .TitleContainer'] = Style
        .TOPLEFT:TOPLEFT(80, -13)
        .TOPRIGHT:TOPRIGHT(-10, -13)
        :Height(14)
    {
        ['@FontString'] = Style
            -- AllPoints = '$parent',
            :TextColor(1, 1, 1, 1)
            :ShadowColor(0, 0, 0, 1)
            :ShadowOffset(1, -1)
            :JustifyH 'LEFT'
            :AllPoints(PARENT)
    },

    ['.GreetingPanel'] = Style:AllPoints(),

    -- Frame'.ScrollBoxAnchor'
    --     :Width(WIDTH-20),
    ['@Frame > .ScrollBar'] = Style:Hide(),
    ['@Frame > .ScrollBox'] = Style
        :Padding(0, 0, 0, 0, 0)
        :Width(WIDTH-20)
        :Height(800) -- just leave it at 800, otherwise blizzard starts hiding scroll content
        .TOPLEFT:TOPLEFT(10, -50)
        .TOPRIGHT:TOPRIGHT(-10, -50)
    {
        ['.Shadows'] = Style:Hide(),
        ['.ScrollTarget'] = Style
            :Width(WIDTH-20)
            :Height(800)
            .TOPLEFT:TOPLEFT()
            .TOPRIGHT:TOPRIGHT()
        {
            ['.*'] = Style
                :Width(WIDTH-40)
            {
                ['@FontString'] = Style
                    :Width(WIDTH-45)
                {
                    function(self)
                        local tl1, to, tl2, x, y = self:GetPoint()
                        self:SetPoint(tl1, to, tl2, x, -1)
                        self:GetParent():SetHeight(self:GetHeight()+3)
                    end,
                }
            },

            function(self)
                ListLayout(self)
                FitToChildren(self)
            end
        },
    },

    PortraitBorderTexture = Texture
        :DrawLayer 'OVERLAY'
        :Texture 'Interface/MINIMAP/UI-MINIMAP-BORDER'
        :TexCoord(0, 1, 0.11, 1)
    {
        function(self)
            local parent = self:GetParent()
            local portrait = query(parent, '.*FramePortrait, .PortraitContainer > .portrait')[1]
            self:ClearAllPoints()
            self:SetPoint('TOPLEFT', portrait, 'TOPLEFT', -49, 4)
            self:SetPoint('BOTTOMRIGHT', portrait, 'BOTTOMRIGHT', 10, -41)
        end,
    },

    NameBackground = Texture
        :DrawLayer('ARTWORK', -1)
        :Texture 'Interface/Common/ShadowOverlay-Corner'
        :VertexColor(1, 1, 1, 0.5)
        .TOPLEFT:TOPLEFT(5, -4.5)
        :Size(410, 30),

    NameBorder = Texture
        :DrawLayer('ARTWORK', -2)
        :Texture 'Interface/Common/ShadowOverlay-Left'
        :VertexColor(1, 1, 1, 1)
        :Size(410, 1.2)
    {
        function(self, parent)
            if parent then
                self:SetPoint("TOPLEFT", parent.NameBackground, "BOTTOMLEFT")
            end
        end
    },

}


local StyleQuestInfoItemHighlight = Style {
    [':Texture'] = Style
        :SetSize(360, 15)
        --:SetTexture('Interface/QUESTFRAME/UI-QuestLogTitleHighlight')
        :SetTexture('Interface/FriendsFrame/UI-FriendsFrame-HighlightBar')
        :SetVertexColor(1, 1, 1, 0.3)
        -- :SetTexCoord(0, 1, 0, 1)
}


local function StyleAll()

    for window in query(UIParent, ':QuestFrame, :GossipFrame, :ItemTextFrame') -- QuestLogDetailFrame
        .filter(byVisible)
    do
        window.ignoreFramePositionManager = true

        local height = 0
        local additionalHeight = 0
        local scale = window:GetEffectiveScale()

        for btn in query(window, '@Button') do
            CornerOffset(btn, 5, 5)
        end

        Style
            .BOTTOM:CENTER(0, -250)
            :Width(WIDTH)
        {
            ['.FriendshipStatusBar'] = Style
                .TOPLEFT:TOPLEFT(60, 13)
                :SetFrameStrata 'LOW'
            {
                ['.icon'] = Style:Hide(),
                ['.BarCircle'] = Style:Hide(),
                ['.BarRingBackground'] = Style:Hide()
            }
        }(window)

        local conversationBtnHeight = {}
        for frame in query(window, '@Frame').filter(byVisible) do
            for btn in query(frame, '@Button') do
                if btn:GetName() then
                    CornerOffset(btn, 10, 10)
                    conversationBtnHeight[btn] = btn:GetHeight()
                elseif btn:IsVisible() and btn == frame.GoodbyeButton then
                    CornerOffset(btn, 10, 10)
                elseif btn:IsVisible() then
                    btn:GetFontString():SetWidth(WIDTH-45)
                    btn:SetWidth(WIDTH-40)
                    btn:SetHeight(btn:GetFontString():GetHeight() + 2)
                    additionalHeight = additionalHeight + btn:GetHeight() -- WHY BLIZZARD WHY ARE THESE NOT CHILDREN OF THE SCROLLFRAME
                end
            end
        end

        Strip(window, 'Bg', 'Background', 'NineSlice', 'Inset', 'TopTileStreaks')

        StyleWindow(window)

        for scroll in query(window, '@Frame > .ScrollBox > .ScrollTarget') do
            height = height + scroll:GetHeight()+20
        end

        query(window, '@Frame > @Texture')
            .filter(function(t) return t ~= (window.PortraitContainer or {}).portrait end)
            :Hide()

        if window == ItemTextFrame then
            StyleItemTextFrame(window)

            height = height + 5

            for btn in query(window, '@Button').filter(byVisible) do
                if btn ~= window.CloseButton then
                    additionalHeight = additionalHeight + btn:GetHeight()
                    break
                end
            end

        end

        for container in query(window, '@ScrollFrame, .* > @ScrollFrame').filter(byVisible) do
            Strip(container, 'Top', 'Middle', 'Bottom')
            Style
                :Width(WIDTH-10)
            {
                ['.ScrollBar'] = Style:Hide()
            }(container)

            container:ClearAllPoints()
            container:SetPoint('TOPLEFT', window, 'TOPLEFT', 10, -40)
            query(container, '.Slider > @Texture'):SetTexture '':SetAtlas ''
            query(container, '.Slider > @Button'):ClearAllPoints():SetPoint('BOTTOM', UIParent, 'TOP')

            for content in query(container, '@Frame').filter(byVisible) do
                -- Style
                --     :Width(WIDTH-20)
                -- {
                --     function(self)
                --         self:SetScript('OnSizeChanged', nil)
                --     end,
                --     ['.QuestProgressItem#'] = Style
                --         :Size(200, 20)
                --     {
                --         ['.QuestProgressItem#NameFrame, .QuestInfoRewardsFrameQuestInfoItem#NameFrame'] = Style:Hide(),
                --         ['.Texture'] = Style:Size(20, 20),
                --         ['.FontString'] = Style
                --             :Size(180, 20)
                --             :TextColor(0, 0, 0, 1)
                --             :ShadowOffset(0, 0),
                --         ['.QuestProgressItem#Count'] = Style
                --             :TextColor(1, 1, 1)
                --             :JustifyH 'CENTER'
                --             .TOPLEFT:TOPLEFT(PARENT.Icon, -10, -7)
                --             .BOTTOMRIGHT:BOTTOMRIGHT(PARENT.Icon, 10, -7)
                --     }
                -- }(content)
                InlineListLayout(query(content, '.*'), ':QuestProgressItem#', { left=10, inner=5, after=10 })

                StyleQuestInfoItemHighlight(QuestInfoItemHighlight)

                StyleQuestInfoRewardsFrame(content)

                if QuestFrameRewardPanel:IsShown() and not QuestInfoRewardsFrame:IsShown() then
                    QuestFrameCompleteQuestButton:Show()
                end

                for subchild in query(content, '.*').filter(byVisible) do
                    local point, relativeTo, relativePoint, xOfs, yOfs = subchild:GetPoint()
                    if subchild:GetObjectType() == 'Button' and subchild:GetFontString() then
                        subchild:GetFontString():SetWidth(WIDTH-45)
                        subchild:SetHeight(subchild:GetFontString():GetHeight() + 2)
                    end
                    if subchild:GetObjectType() ~= "Frame" or subchild:GetChildren() or subchild:GetRegions() then
                        subchild:SetWidth(WIDTH-40)
                    end
                end
                FitToChildren(content)

                height = content:GetHeight()
            end
            if container == QuestDetailScrollFrame and QuestInfoRewardsFrame:IsVisible() then
                height = height - QuestInfoRewardsFrame:GetHeight() - 1
            end
            container:SetHeight(height)

        end

        for k, v in pairs(conversationBtnHeight) do
            if k:IsShown() then
                height = height + v
                break
            end
        end

        window:SetHeight(math.max(MIN_HEIGHT, height+70+additionalHeight))

        Style {
            BackgroundOverlay = Texture
                -- ColorTexture = { 1, 0.7, 0.5, 0.4 },
                :ColorTexture(1, 0.8, 0.55, 0.6)
                .TOPLEFT:TOPLEFT(window, 5, -5)
                .BOTTOMRIGHT:BOTTOMRIGHT(window, -5, 5)
                :DrawLayer('BORDER', -7)
        }(window)

        if not window.SetBackdrop then
            Mixin(window, BackdropTemplateMixin)
            window:HookScript('OnSizeChanged', window.OnBackdropSizeChanged)
        end
        window:SetBackdrop({
            -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment",
            -- bgFile = "Interface/QuestionFrame/question-background",
            -- bgFile = "Interface/Collections/CollectionsBackgroundTile",
            bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-StatsBackground",
            -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Parchment-Horizontal-Desaturated",
            -- bgFile = "Interface/AdventureMap/AdventureMapParchmentTile",
            -- bgFile = "Interface/FrameGeneral/UI-Background-Rock",
            -- bgFile = "Interface/FrameGeneral/UI-Background-Marble",
            -- edgeFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-WoodBorder",
            -- edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            -- edgeFile = "Interface/GLUES/COMMON/TextPanel-Border",
            edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
            edgeSize = 12,
            tile = true,
            tileSize = math.max(WIDTH*scale, height*scale),
            -- insets = { left = 8, right = 8, top = 5, bottom = 8 }
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        --window:SetBackdropColor(0.7, 0.7, 0.7, 1)

    end

end


local doUpdate = true
local function update() doUpdate = true end

Frame {
    [Event.GOSSIP_SHOW] = update,
    [Event.GOSSIP_CLOSED] = update,
    [Event.QUEST_ACCEPTED] = update,
    [Event.QUEST_COMPLETE] = update,
    [Event.QUEST_DETAIL] = update,
    [Event.QUEST_FINISHED] = update,
    [Event.QUEST_GREETING] = update,
    [Event.QUEST_PROGRESS] = update,
    [Event.QUEST_ITEM_UPDATE] = update,
    [Event.ITEM_TEXT_BEGIN] = update,
    [Event.ITEM_TEXT_READY] = update,

    [Script.OnUpdate] = function()
        if doUpdate then
            doUpdate = false
            StyleAll()
        end
    end
}
    .new()

-- UIParent {
--     Style'QuestFrame, GossipFrame, ItemTextFrame' -- , QuestLogDetailFrame
--         :Hooks { OnShow = update }
-- }
