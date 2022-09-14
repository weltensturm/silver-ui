local _, ns = ...
local lqt = ns.lqt
local matches = lqt.matches

local Style, Texture = lqt.Style, lqt.Texture

local WIDTH = 420
local MIN_HEIGHT = 150


local Hide = Style:Hide()


local function ToParent(from, to, x, y)
    return function(self)
        self:SetPoint(from, self:GetParent(), to, x, y)
    end
end


local function AllParent()
    return function(self)
        self:SetAllPoints(self:GetParent())
    end
end


local function byVisible(e)
    return e:IsVisible()
end


local function inline_list_layout(selection, filter, margin)
    local previous_match = nil
    local before = nil
    local after = nil
    for element in selection do
        if element:IsVisible() then
            if not matches(element, filter) then
                if previous_match then
                    element:SetPoint('TOPLEFT', previous_match, 'BOTTOMLEFT', 0, -margin.inner)
                    previous_match = nil
                    before = nil
                    after = nil
                elseif previous_match and not after then
                    after = element 
                end
                -- if not after then
                --     before = element
                -- end
            else
                if not before then
                    before = select(2, element:GetPoint())
                end
                if previous_match or before then
                    element:SetPoint('TOPLEFT', previous_match or before, 'BOTTOMLEFT', 0, -margin.inner)
                    previous_match = element
                end
            end
        end
    end
    -- if after then
    --     -- print('AFTER', after:GetName(), '->', previous_match:GetName())
    --     after:SetPoint('TOPLEFT', previous_match, 'BOTTOMLEFT', 0, -margin.after)
    -- end
end


local function override(element)
    return function(table)
        for k, v in pairs(table) do
            if not element['override_' .. k] then
                local old_func = element:GetScript(k) or function() end
                local new_func = function(...)
                    v(old_func, ...)
                end
                element['override_' .. k] = new_func
                element:SetScript(k, new_func)
            end
        end
    end
end


local and_then = {}
local and_then_meta = {
    __index = function(t, k)
        if t == and_then then
            t = {}
            setmetatable(t, and_then_meta)
        end
        return function(self, ...)
            table.insert(self, { k, {...} })
            return self
        end
    end
}
setmetatable(and_then, and_then_meta)


local StyleQuestInfoRewardsFrame = Style {
    Style'.Button'
        .filter(function(self) return not self.PortraitFrame end)
        :Size(200, 20)
        :Hooks {
            OnClick = function(self)
                if QuestFrameRewardPanel:IsShown() and not IsModifierKeyDown() then
                    QuestFrameCompleteQuestButton:Click()
                    QuestInfoItemHighlight:SetPoint('TOPLEFT', self, 'TOPLEFT', -10, -2.5)
                end
            end,
            OnEnter = function(self)
                if QuestFrameRewardPanel:IsShown() then
                    Style(QuestInfoItemHighlight)
                        :SetHeight(20)
                        :SetPoint('TOPLEFT', self, 'TOPLEFT', -10, -2.5)
                        :Show()
                end
            end,
            OnLeave = function(...)
                QuestInfoItemHighlight:Hide()
            end
        }
    {
        Style'.Texture':Hide(),

        Style'.Name' .. function(self)
            local parent = self:GetParent()
            self:Points { TOPLEFT = parent:TOPLEFT(0, -2),
                          RIGHT = parent:GetParent():RIGHT(-20, 0) }
        end,

        Style'.Icon'
            :Show()
            :Size(20, 20)
            .. ToParent('TOPLEFT', 'TOPLEFT', 0, 0),

        Style'.FontString'
            :Size(180, 20)
            :TextColor(0.1, 0, 0, 1)
            :ShadowOffset(0, 0)
            .. ToParent('TOPLEFT', 'TOPLEFT', 27, 0),

        Style'.NameFrame'
            :Show()
            :Texture 'Interface/Buttons/UI-Listbox-Highlight2'
            :DrawLayer('BACKGROUND', -7 )
            :BlendMode 'ADD'
            :VertexColor(1,1,1,0.2)
            :Height(16)
            ..
                function(self)
                    local parent = self:GetParent()
                    local show = QuestFrameRewardPanel:IsShown() and parent:IsShown() and parent.Icon and parent:GetNumPoints() > 0
                    self:Points { TOPLEFT = parent:TOPLEFT(0, -2),
                                  RIGHT = parent:GetParent():RIGHT(-20, 0) }
                    self:SetAlpha(show and 0.2 or 0)
                end,
        
        Style'.Count'
            :TextColor(1, 1, 1)
            :JustifyH 'LEFT'
            :TextScale(0.85)
            ..
                function(self)
                    local parent = self:GetParent()
                    self:Points { TOPLEFT = parent.Icon:TOPLEFT(0,-5),
                                  BOTTOMRIGHT = parent.Icon:BOTTOMRIGHT(10,-5) }
                end
    },

    function(self)
        if QuestRewardScrollFrame:IsShown() then
            QuestFrameCompleteQuestButton:Show()
            for btn in self'.Button'.filter(byVisible) do
                local show = btn.Icon and btn:GetNumPoints() > 0 -- don't ask me
                if show then
                    QuestFrameCompleteQuestButton:Hide()
                end
            end
        end
    end,

    function(self)
        inline_list_layout(self'.*', 'Button', { inner=5, after=10 })
        self:FitToChildren()
    end
}


local function StyleAll(self, event)

    for window in UIParent'QuestFrame, GossipFrame, ItemTextFrame'
        .filter(byVisible)
        :Strip('Bg', 'Background', 'NineSlice', 'Inset', 'TopTileStreaks')
        :ClearAllPoints()
        :SetPoint('BOTTOM', UIParent, 'CENTER', 0, -250)
        :SetWidth(WIDTH)
    do
        local height = 0
        local scale = window:GetEffectiveScale()

        window'.Button':CornerOffset(5, 5)

        window'.NPCFriendshipStatusBar'
            :SetFrameStrata 'LOW'
            :Points { TOPLEFT = GossipFrame:TOPLEFT(60, 13) }
        {
            Style'.icon':Hide(),
            Style'.BarCircle':Hide(),
            Style'.BarRingBackground':Hide()
        }

        local conversationBtnHeight = {}
        for frame in window'.Frame'.filter(byVisible) do
            for btn in frame'.Button' do
                if btn:GetName() then
                    btn:CornerOffset(10, 10)
                    conversationBtnHeight[btn] = btn:GetHeight()
                elseif btn:IsVisible() then
                    btn:GetFontString():SetWidth(WIDTH-45)
                    btn:SetWidth(WIDTH-40)
                    btn:SetHeight(btn:GetFontString():GetHeight() + 2)
                    height = height + btn:GetHeight() -- WHY BLIZZARD WHY ARE THESE NOT CHILDREN OF THE SCROLLFRAME
                end
            end
        end

        Style(window) {

            Style'.*FramePortrait'
                :Points { LEFT = window:TOPLEFT(4, -7) }
                :Size(65, 65)
                :DrawLayer 'ARTWORK',

            Texture'.PortraitBorderTexture'
                :DrawLayer 'OVERLAY'
                :Texture 'Interface/MINIMAP/UI-MINIMAP-BORDER'
                :TexCoord(0, 1, 0.11, 1)
                :Size(120, 120*0.89)
                .init(function(self, parent) self:SetPoint("CENTER", parent'.*FramePortrait'[1], "CENTER", -20, -18) end),

            Style'.*NameFrame'
                :Points { TOPLEFT = window:TOPLEFT(80, -13),
                          TOPRIGHT = window:TOPRIGHT(-10, -13) }
            {
                Style'.FontString'
                    -- AllPoints = '$parent',
                    :TextColor(1, 1, 1, 1)
                    :ShadowColor(0, 0, 0, 1)
                    :ShadowOffset(1, -1)
                    :JustifyH 'LEFT'
                { function(self) self:SetAllPoints(self:GetParent()) end }
            },

            Texture'.NameBackground'
                :DrawLayer('ARTWORK', -1)
                :Texture 'Interface/Common/ShadowOverlay-Corner'
                :VertexColor(1, 1, 1, 0.5)
                :Points { TOPLEFT = window:TOPLEFT(5, -4.5) }
                :Size(410, 30),

            Texture'.NameBorder'
                :DrawLayer('ARTWORK', -2)
                :Texture 'Interface/Common/ShadowOverlay-Left'
                :VertexColor(1, 1, 1, 1)
                :Size(410, 1.2)
                .init(function(self, parent) self:SetPoint("TOPLEFT", parent.NameBackground, "BOTTOMLEFT") end)

        }

        -- window'.Frame':Strip('Bg', 'SealMaterialBG', 'MaterialTopLeft', 'MaterialTopRight', 'MaterialBotLeft')
        window'.Frame.Texture':Hide()

        if window == ItemTextFrame then

            Style(window)
                :Scripts {
                    OnMouseWheel = function(self, delta)
                        if delta > 0 then
                            window'.ItemTextPrevPageButton':Click()
                        else
                            window'.ItemTextNextPageButton':Click()
                        end
                    end
                }
            {
                Hide'.Texture:NOATTR:NONAME',

                Hide'.ItemTextFramePageBg',

                Hide'.PortraitBorderTexture',
                
                Style'.ItemTextMaterial*':Texture '',

                Style'.TitleText, .ItemTextTitleText'
                    :Points { TOPLEFT = window:TOPLEFT(70, -15),
                              TOPRIGHT = window:TOPRIGHT(-10, -15) }
                    :TextColor(1, 1, 1, 1)
                    :ShadowColor(0, 0, 0, 1)
                    :ShadowOffset(1, -1)
                    :JustifyH 'LEFT',
                
                Style'.ItemTextPrevPageButton'
                    :Points { BOTTOMLEFT = window:BOTTOMLEFT(15, 10) },

                Style'.ItemTextNextPageButton'
                    :Points { BOTTOMRIGHT = window:BOTTOMRIGHT(-15, 10) },

                Style'.ItemTextCurrentPage'
                    :Points { BOTTOM = window:BOTTOM(0, 20) },
                
                Hide'.ScrollFrame.Texture'
            }

            height = height + 5

            for scrollframe in window'.ScrollFrame'
                :SetWidth(WIDTH-30)
                :Points { TOPLEFT = ItemTextFrame:TOPLEFT(15, -30) }
                :SetHeight(10)
                :EnableMouseWheel(false)
            do
                scrollframe'.Frame':SetWidth(WIDTH-20)
                -- :Points { TOPLEFT = scrollframe:TOPLEFT(15, 0) }
                for frame in scrollframe'.Frame.SimpleHTML'
                    :SetWidth(WIDTH-20)
                do
                    frame'.*':SetWidth(WIDTH-40)
                    for t in frame'.Texture' do
                        if not t.origSetPoint then
                            t.origSetPoint = t.SetPoint
                            t.SetPoint = function(self, ...)
                                print(debugstack())
                                return self.origSetPoint(self, ...)
                            end
                        end
                    end
                    frame:FitToChildren()
                    height = height + frame:GetHeight()
                end
                scrollframe'.Frame':FitToChildren()
                scrollframe:FitToChildren()
                scrollframe'.Slider':Hide()
            end

            for btn in window'.Button'.filter(byVisible) do
                if btn ~= window.CloseButton then
                    height = height + btn:GetHeight()
                    break
                end
            end
            
        end

        Style(window) {
            Style'.*.ScrollFrame'
                :Strip('Top', 'Middle', 'Bottom')
                :Width(WIDTH-10)
                :Points { TOPLEFT = window:TOPLEFT(10, -40) }
            .. Hide'.Slider'
        }

        window'.*.ScrollFrame.Slider':Hide()
        
        for container in window'.*.ScrollFrame'
            .filter(byVisible)
            :Strip('Top', 'Middle', 'Bottom')
            :SetWidth(WIDTH-10)
            :SetHeight(1024)
            :SetPoint("TOPLEFT", window, 10, -40)
            ..and_then
                :FitToChildren()
        do
            container'.Slider':Hide()

            for content in container'.Frame'
                .filter(byVisible)
                :SetWidth(WIDTH-20)
            do

                content {
                    Style'.QuestProgressItem#'
                        :Size(200, 20)
                    {
                        Style'.QuestProgressItem#NameFrame, .QuestInfoRewardsFrameQuestInfoItem#NameFrame':Hide(),
                        Style'.Texture':Size(20, 20),
                        Style'.FontString'
                            :Size(180, 20)
                            :TextColor(0, 0, 0, 1)
                            :ShadowOffset(0, 0),
                        Style'.QuestProgressItem#Count'
                            :TextColor(1, 1, 1)
                            :JustifyH 'CENTER'
                            { function(self)
                                self:Points { TOPLEFT = self:GetParent().Icon:TOPLEFT(-10, -7),
                                              BOTTOMRIGHT = self:GetParent().Icon:BOTTOMRIGHT(10, -7) }
                            end }
                    }
                }
                inline_list_layout(content'.*', 'QuestProgressItem#', { inner=5, after=10 })

                content'QuestInfoItemHighlight.Texture'
                    :SetSize(360, 15)
                    --:SetTexture('Interface/QUESTFRAME/UI-QuestLogTitleHighlight')
                    :SetTexture('Interface/FriendsFrame/UI-FriendsFrame-HighlightBar')
                    :SetVertexColor(1, 1, 1, 0.3)
                    -- :SetTexCoord(0, 1, 0, 1)

                Style(content) {
                    Style'.QuestInfoRewardsFrame'
                        :Hooks {
                            OnShow = function(self)
                                StyleQuestInfoRewardsFrame(self)
                            end
                        }
                    .. StyleQuestInfoRewardsFrame
                }

                for subchild in content'.*'.filter(byVisible) do
                    local point, relativeTo, relativePoint, xOfs, yOfs = subchild:GetPoint()
                    if subchild:GetObjectType() == 'Button' and subchild:GetFontString() then
                        subchild:GetFontString():SetWidth(WIDTH-45)
                        subchild:SetHeight(subchild:GetFontString():GetHeight() + 2)
                    end
                    if subchild:GetObjectType() ~= "Frame" or subchild:GetChildren() or subchild:GetRegions() then
                        subchild:SetWidth(WIDTH-40)
                        height = height + subchild:GetHeight() - (yOfs or 0)
                    end
                end
                --container:SetHeight(height+40)
                content:SetHeight(height)
            end

        end

        for k, v in pairs(conversationBtnHeight) do
            if k:IsShown() then
                height = height + v
                break
            end
        end

        window:SetHeight(math.max(MIN_HEIGHT, height+70))

        Style(window) {
            Texture'.BackgroundOverlay'
                -- ColorTexture = { 1, 0.7, 0.5, 0.4 },
                :ColorTexture(1, 0.8, 0.55, 0.6)
                :Points { TOPLEFT = window:TOPLEFT(5, -5),
                          BOTTOMRIGHT = window:BOTTOMRIGHT(-5, 5) }
                :DrawLayer('BORDER', -7)
        }

        if not window.SetBackdrop then
            _G.Mixin(window, _G.BackdropTemplateMixin)
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


local addon = CreateFrame("Frame", nil, UIParent)

for _, event in pairs({
    'GOSSIP_SHOW',
    'GOSSIP_CLOSED',
    'QUEST_ACCEPTED',
    'QUEST_COMPLETE',
    'QUEST_DETAIL',
    'QUEST_FINISHED',
    'QUEST_GREETING',
    'QUEST_PROGRESS',
    'ITEM_TEXT_BEGIN',
    'ITEM_TEXT_READY',
}) do addon:RegisterEvent(event) end





local doUpdate = true

addon:HookScript("OnEvent", function() doUpdate = true end)

UIParent {
    Style'QuestFrame, GossipFrame, ItemTextFrame'
        :Hooks { OnShow = function() doUpdate = true end }
}

addon:Scripts {
    OnUpdate = function()
        if doUpdate then
            StyleAll()
            doUpdate = false
        end
    end
}
