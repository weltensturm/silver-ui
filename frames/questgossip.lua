local _, ns = ...
local lqt = ns.lqt
local matches = lqt.matches

local Style = lqt.Style

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
                -- print(element:GetName(), '->', (previous_match or before):GetName())
                element:SetPoint('TOPLEFT', previous_match or before, 'BOTTOMLEFT', 0, -margin.inner)
                previous_match = element
            end
        end
    end
    if after then
        -- print('AFTER', after:GetName(), '->', previous_match:GetName())
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


addon:HookScript("OnEvent", function(self, event)

    local byVisible = function(e) return e:IsVisible() end

    for window in UIParent'.TalkWindow'
        .filter(byVisible)
        :Strip('Bg', 'Background', 'NineSlice', 'Inset', 'TopTileStreaks')
        :ClearAllPoints()
        :SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 200)
        :SetWidth(WIDTH)
    do
        local height = 0

        window'.Button':CornerOffset(5, 5)

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

        for portrait in window'.Portrait'
            :ClearAllPoints()
            :SetPoint('LEFT', window, 'TOPLEFT', 4, -7)
            :SetDrawLayer('ARTWORK')
        do
            window'.PortraitBorderTexture=Texture'
                :SetDrawLayer('OVERLAY')
                :SetTexture('Interface/MINIMAP/UI-MINIMAP-BORDER')
                :SetPoint("CENTER", portrait, "CENTER", -20, -18)
                :SetTexCoord(0, 1, 0.11, 1)
                :SetWidth(120)
                :SetHeight(120*0.89)
        end

        window {
                
            ['.Name'] = {
                Points = {{ TOPLEFT = window:TOPLEFT(80, -13),
                            TOPRIGHT = window:TOPRIGHT(-10, -13) }},
                            
                ['.FontString'] = {
                    -- AllPoints = '$parent',
                    TextColor = { 1, 1, 1, 1 },
                    ShadowColor = { 0, 0, 0, 1 },
                    ShadowOffset = { 1, -1 },
                    JustifyH = { 'LEFT' },
                }

            },

            ['.NameBackground=Texture'] = {
                DrawLayer = { 'ARTWORK', -1 },
                Texture = 'Interface/Common/ShadowOverlay-Corner',
                VertexColor = { 1, 1, 1, 0.5 },
                Point = { "TOPLEFT", window, "TOPLEFT", 5, -4.5 },
                Width = 410,
                Height = 30,
            },

        }

        window {

            ['.NameBorder=Texture'] = {
                DrawLayer = { 'ARTWORK', -2 },
                Texture = 'Interface/Common/ShadowOverlay-Left',
                VertexColor = { 1, 1, 1, 1 },
                Point = { "TOPLEFT", window.NameBackground, "BOTTOMLEFT" },
                Width = { 410 },
                Height = { 1.2 },
            }

        }

        -- window'.Frame':Strip('Bg', 'SealMaterialBG', 'MaterialTopLeft', 'MaterialTopRight', 'MaterialBotLeft')
        window'.Frame.Texture':Hide()

        if window == ItemTextFrame then

            window'.ItemTextFramePageBg':Hide()
            ItemTextMaterialTopLeft:SetTexture ''
            ItemTextMaterialTopRight:SetTexture ''
            ItemTextMaterialBotLeft:SetTexture ''
            ItemTextMaterialBotRight:SetTexture ''
            
            window {
                
                ['.TitleText'] = {
                    Points = {{ TOPLEFT = window:TOPLEFT(70, -15),
                                TOPRIGHT = window:TOPRIGHT(-10, -15) }},
                    TextColor = { 1, 1, 1, 1 },
                    ShadowColor = { 0, 0, 0, 1 },
                    ShadowOffset = { 1, -1 },
                    JustifyH = { 'LEFT' },
                },

                Style'.ItemTextPrevPageButton':Points {
                    BOTTOMLEFT = window:BOTTOMLEFT(15, 10)
                },
                Style'.ItemTextNextPageButton':Points {
                    BOTTOMRIGHT = window:BOTTOMRIGHT(-15, 10)
                },

                Style'.ItemTextCurrentPage':Points {
                    BOTTOM = window:BOTTOM(0, 20)
                },

            }

            window:Script {
                OnMouseWheel = function(self, delta)
                    if delta > 0 then
                        window'.ItemTextPrevPageButton':Click()
                    else
                        window'.ItemTextNextPageButton':Click()
                    end
                end
            }

            height = height + 5

            for container in window'.ScrollFrame'
                :SetWidth(WIDTH)
                :Points { TOPLEFT = ItemTextFrame:TOPLEFT(0, -50) }
                :SetHeight(10)
                :EnableMouseWheel(false)
            do
                container'.Frame':SetWidth(WIDTH-20)
                for frame in container'.Frame.SimpleHTML':SetWidth(WIDTH-20) do
                    for content in frame'.*' do
                        content:SetWidth(WIDTH-40)
                        local point, relativeTo, relativePoint, xOfs, yOfs = content:GetPoint()
                        height = height + content:GetHeight() - yOfs
                    end
                    frame:SetHeight(height)
                    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
                    height = height - yOfs
                end
                container:SetHeight(height)
                container'.Slider':Hide()
            end

            for btn in window'.Button'.filter(byVisible) do
                if btn ~= window.CloseButton then
                    height = height + btn:GetHeight()
                    break
                end
            end
            
        end

        window'.*.ScrollFrame':Strip('Top', 'Middle', 'Bottom') {
            Width = WIDTH-10,
            Points = {{ TOPLEFT = window:TOPLEFT(10, -40) }}
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

                for item in content'.QuestProgressItem'
                    :SetSize(200, 20)
                do
                    item'.ItemBackground':Hide()
                    item {
                        ['.Texture'] = { Size = { 20, 20 } },
                        ['.FontString'] = {
                            Size =  { 180, 20 },
                            TextColor =  { 0, 0, 0, 1 },
                            ShadowOffset =  { 0, 0 },
                        },
                        ['.Count'] = {
                            TextColor = { 1, 1, 1 },
                            Points = {{ 
                                TOPLEFT = item.Icon:TOPLEFT(),
                                BOTTOMRIGHT = item.Icon:BOTTOMRIGHT()
                            }}
                        }
                    }
                end
                inline_list_layout(content'.*', 'QuestProgressItem', { inner=5, after=10 })

                content'QuestInfoItemHighlight.Texture'
                    :SetSize(360, 15)
                    --:SetTexture('Interface/QUESTFRAME/UI-QuestLogTitleHighlight')
                    :SetTexture('Interface/FriendsFrame/UI-FriendsFrame-HighlightBar')
                    :SetVertexColor(1, 1, 1, 0.3)
                    -- :SetTexCoord(0, 1, 0, 1)

                for rewards in content'.QuestInfoRewardsFrame'.filter(byVisible) do

                    local has_quest_buttons = false

                    for button in rewards'.Button' do
                        content'QuestInfoItemHighlight'
                            :SetPoint('TOPLEFT', button, 'TOPLEFT', -10, -2.5)

                        if button:IsShown() and button.Icon and not button.PortraitFrame then
                            has_quest_buttons = true
                            
                            button:SetSize(200, 20)
                            button {
                                ['.Texture'] = {
                                    Size = { 20, 20 },
                                    Point = { 'TOPLEFT', button, 'TOPLEFT', 0, 0 },
                                },

                                ['.FontString'] = {
                                    Point =  { 'TOPLEFT', button, 'TOPLEFT', 27, 0 },
                                    Size =  { 180, 20 },
                                    TextColor =  { 0.1, 0, 0, 1 },
                                    ShadowOffset =  { 0, 0 },
                                },

                                ['.NameFrame'] = {
                                    Texture = { 'Interface/Buttons/UI-Listbox-Highlight2' },
                                    DrawLayer = { 'BACKGROUND', -7 },
                                    BlendMode = { 'ADD' },
                                    VertexColor = { 1,1,1,0.2 },
                                    Points = {{ TOPLEFT = button:TOPLEFT(0, -2),
                                                RIGHT = container:RIGHT(-20, 0) }},
                                    Height = 16,
                                    Alpha = container == QuestRewardScrollFrame and 0.2 or 0,
                                },
                                
                                ['.Count'] = {
                                    TextColor = { 1, 1, 1 },
                                    Points = {{ 
                                        TOPLEFT = button.Icon:TOPLEFT(),
                                        BOTTOMRIGHT = button.Icon:BOTTOMRIGHT()
                                    }}
                                }
                            }
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
                    
                    inline_list_layout(rewards'.*', 'Button', { inner=5, after=10 })

                    rewards:FitToChildren()
                end

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

        window'.BackgroundOverlay=Texture' {
            -- ColorTexture = { 1, 0.7, 0.5, 0.4 },
            ColorTexture = { 1, 0.8, 0.55, 0.6 },
            Points = {{ TOPLEFT = window:TOPLEFT(5, -5),
                        BOTTOMRIGHT = window:BOTTOMRIGHT(-5, 5) }},
            DrawLayer = { 'BORDER', -7 },
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
            tileSize = math.max(355, height+40),
            -- insets = { left = 8, right = 8, top = 5, bottom = 8 }
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        --window:SetBackdropColor(0.7, 0.7, 0.7, 1)
    
    end

end)

