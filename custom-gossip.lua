local _, ns = ...

local lqt = ns.lqt
local matches = lqt.matches

local WIDTH = 420
local MIN_HEIGHT = 150


local addon = CreateFrame("Frame", nil, UIParent)

for _, event in pairs({
    'GOSSIP_SHOW',
    'QUEST_ACCEPTED',
    'QUEST_COMPLETE',
    'QUEST_DETAIL',
    'QUEST_FINISHED',
    'QUEST_GREETING',
    'QUEST_PROGRESS',
    'ITEM_TEXT_BEGIN',
    'ITEM_TEXT_READY',
}) do addon:RegisterEvent(event) end


local function inline_list_layout(selection, filter, margin)
    local previous_match = nil
    local before = nil
    local after = nil
    for element in selection do
        if element:IsVisible() then
            local ignore = not matches(element, filter)
            if ignore then
                if previous_match and not after then
                    after = element 
                end
                if not after then
                    before = element
                end
            else
                --print(element:GetName(), '->', (previous_match or before):GetName())
                element:SetPoint('TOPLEFT', previous_match or before, 'BOTTOMLEFT', 0, -margin.inner)
                previous_match = element
            end
        end
    end
    if after then
        after:SetPoint('TOPLEFT', previous_match, 'BOTTOMLEFT', 0, -margin.after)
    end
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


addon:SetScript("OnEvent", function(self, event)

    for window in UIParent'.TalkWindow'
        :Strip('Bg', 'Background', 'NineSlice', 'Inset', 'TopTileStreaks')
        :ClearAllPoints()
        :SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 200)
        :SetWidth(WIDTH)
    do
        if window:IsVisible() then
            local height = 0

            window'.Button':CornerOffset(5, 5)

            window'.*.Button':CornerOffset(10, 10)

            for portrait in window'.Portrait'
                :ClearAllPoints()
                :SetPoint('LEFT', window, 'TOPLEFT', 4, -7)
                :SetDrawLayer('ARTWORK')
            do
                window:Texture'PortraitBorderTexture'
                    :SetDrawLayer('OVERLAY')
                    :SetTexture('Interface/MINIMAP/UI-MINIMAP-BORDER')
                    :SetPoint("CENTER", portrait, "CENTER", -20, -18)
                    :SetTexCoord(0, 1, 0.11, 1)
                    :SetWidth(120)
                    :SetHeight(120*0.89)
            end

            for name in window'.Name'
                :ClearAllPoints()
                :SetPoint('TOPLEFT', window, 'TOPLEFT', 80, -13)
                :SetPoint('TOPRIGHT', window, 'TOPRIGHT', -10, -13)
            do
                name'.FontString'
                    :SetAllPoints(name)
                    :SetTextColor(1, 1, 1, 1)
                    :SetShadowColor(0, 0, 0, 1)
                    :SetShadowOffset(1, -1)
                    :SetJustifyH('LEFT')
            end

            window:Texture'NameBackground'
                :SetDrawLayer('ARTWORK', -1)
                :SetTexture('Interface/Common/ShadowOverlay-Corner')
                :SetVertexColor(1, 1, 1, 0.5)
                :SetPoint("TOPLEFT", window, "TOPLEFT", 5, -4.5)
                :SetWidth(410)
                :SetHeight(30)

            window:Texture'NameBorder'
                :SetDrawLayer('ARTWORK', -2)
                :SetTexture('Interface/Common/ShadowOverlay-Left')
                :SetVertexColor(1, 1, 1, 1)
                :SetPoint("TOPLEFT", window.NameBackground, "BOTTOMLEFT")
                :SetWidth(410)
                :SetHeight(1.2)

            window'.Frame':Strip('Bg', 'SealMaterialBG')

            for container in window'.*.ScrollFrame'
                :Strip('Top', 'Middle', 'Bottom')
                :SetWidth(WIDTH-10)
                :SetPoint("TOPLEFT", window, 10, -40)
                ..and_then
                    :FitToChildren()
            do
                container'.Slider':Hide()

                for content in container'.Frame'
                    :SetWidth(WIDTH-20)
                do

                    for item in content'.QuestProgressItem'
                        :SetSize(200, 20)
                    do
                        item'.Texture':SetSize(20, 20)
                        item'.ItemBackground':Hide()
                        item'.FontString'
                            :SetSize(180, 20)
                            :SetTextColor(0, 0, 0, 1)
                            :SetShadowOffset(0, 0)
                        item'.Count':SetTextColor(1,1,1)
                    end
                    inline_list_layout(content'.*', 'QuestProgressItem', { inner=5, after=10 })

                    content'QuestInfoItemHighlight.Texture'
                        :SetSize(360, 15)
                        --:SetTexture('Interface/QUESTFRAME/UI-QuestLogTitleHighlight')
                        :SetTexture('Interface/FriendsFrame/UI-FriendsFrame-HighlightBar')
                        :SetVertexColor(1, 1, 1, 1)
                        :SetTexCoord(0, 1, -0, 1)

                    if QuestInfoRewardsFrame:IsVisible() then
                        local has_quest_buttons = false
                        for button in content'.QuestInfoRewardsFrame.Button'
                            :SetSize(200, 20)
                        do

                            if button:IsShown() then
                                
                                button'.Texture'
                                    :SetSize(20, 20)
                                    :SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)

                                button'.FontString'
                                    :SetPoint('TOPLEFT', button, 'TOPLEFT', 27, 0)
                                    :SetSize(180, 20)
                                    :SetTextColor(0.1, 0, 0, 1)
                                    :SetShadowOffset(0, 0)

                                button'.NameFrame'
                                    :SetTexture('Interface/Buttons/UI-Listbox-Highlight2')
                                    :SetDrawLayer('BACKGROUND', -7)
                                    :SetBlendMode('ADD')
                                    :SetVertexColor(1,1,1,0.2)
                                    :SetPoint('TOPLEFT', button, 'TOPLEFT', 0, -2)
                                    :SetPoint('RIGHT', container, 'RIGHT', -20, 0)
                                    :SetHeight(16)
                                
                                has_quest_buttons = true
                                override(button){
                                    OnClick = function(f, ...) f(...)
                                        if QuestFrameRewardPanel:IsShown() then
                                            QuestFrameCompleteQuestButton:Click()
                                            content'QuestInfoItemHighlight'
                                                :SetPoint('TOPLEFT', button, 'TOPLEFT', -10, -2.5)
                                        end
                                    end,
                                    OnEnter = function(f, ...) f(...)
                                        if QuestFrameRewardPanel:IsShown() then
                                            content'QuestInfoItemHighlight'
                                                :SetHeight(20)
                                                :SetPoint('TOPLEFT', button, 'TOPLEFT', -10, -2.5)
                                                :Show()
                                        end
                                    end,
                                    OnLeave = function(f, ...) f(...)
                                        content'QuestInfoItemHighlight':Hide()
                                    end
                                }
                                QuestFrameCompleteQuestButton:Hide()

                            end
                        end
                        if container == QuestRewardScrollFrame and not has_quest_buttons then
                            QuestFrameCompleteQuestButton:Show()
                        end
                        
                        inline_list_layout(content'.QuestInfoRewardsFrame.*', 'Button', { inner=5, after=10 })
                        QuestInfoRewardsFrame:FitToChildren()
                    end

                    for subchild in content'.*' do
                        local point, relativeTo, relativePoint, xOfs, yOfs = subchild:GetPoint()
                        if subchild:IsVisible() and (subchild:GetObjectType() ~= "Frame" or subchild:GetChildren() or subchild:GetRegions()) then
                            subchild:SetWidth(WIDTH-40)
                            height = height + subchild:GetHeight() - (yOfs or 0)
                        end
                        if subchild:IsShown() and subchild:GetObjectType() == 'Button' and subchild:GetFontString() then
                            subchild:GetFontString():SetWidth(WIDTH-45)
                            subchild:SetHeight(subchild:GetFontString():GetHeight() + 2)
                        end
                    end
                    --container:SetHeight(height+40)
                    content:SetHeight(height)
                end

            end

            window:SetHeight(math.max(MIN_HEIGHT, height+95))

            window:Texture'BackgroundOverlay'
                :SetColorTexture(1, 0.7, 0.5, 0.4)
                :SetPoint('TOPLEFT', window, 'TOPLEFT', 5, -5)
                :SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -5, 5)
                :SetDrawLayer('BORDER', -7)

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
                tileSize = math.max(355, height+40),
                -- insets = { left = 8, right = 8, top = 5, bottom = 8 }
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            --window:SetBackdropColor(0.7, 0.7, 0.7, 1)
        
        end
    end

end)

