

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


local function find_first_scroll_frame(frame)
    for _, child in pairs({ frame:GetChildren() }) do
        if child:GetObjectType() == "ScrollFrame" and child:IsVisible() then
            return { child }
        else
            local v = find_first_scroll_frame(child)
            if #v > 0 then
                return v
            end
        end
    end
    return {}
end


local function merge(...)
    local result = {}
    for _, t in pairs({...}) do
        for _, v in pairs(t) do
            table.insert(result, v)
        end
    end
    return result
end


local StripTexturesBlizzFrames = {
	'Inset',
	'inset',
	'InsetFrame',
	'LeftInset',
	'RightInset',
	'NineSlice',
	'BG',
	'border',
	'Border',
	'BorderFrame',
	'bottomInset',
	'BottomInset',
	'bgLeft',
	'bgRight',
	'FilligreeOverlay',
	'PortraitOverlay',
	'ArtOverlayFrame',
	'Portrait',
	'portrait',
	'ScrollFrameBorder',
}

local STRIP_TEX = 'Texture'
local STRIP_FONT = 'FontString'
local function StripRegion(which, object, kill, alpha)
	if kill then
		object:Kill()
	elseif which == STRIP_TEX then
		object:SetTexture('')
		object:SetAtlas('')
	elseif which == STRIP_FONT then
		object:SetText('')
	end

	if alpha and object.SetAlpha then
		object:SetAlpha(0)
	end
end

local function StripType(which, object, kill, alpha)
    print("strip", object:GetName())
	if object:IsObjectType(which) then
		StripRegion(which, object, kill, alpha)
	else
		if which == STRIP_TEX then
			local FrameName = object.GetName and object:GetName()
			for _, Blizzard in pairs(StripTexturesBlizzFrames) do
				local BlizzFrame = object[Blizzard] or (FrameName and _G[FrameName..Blizzard])
				if BlizzFrame and type(BlizzFrame) == "table" then
					StripType(STRIP_TEX, BlizzFrame, kill, alpha)
				end
			end
		end

		if object.GetNumRegions then
			for i = 1, object:GetNumRegions() do
				local region = select(i, object:GetRegions())
				if region and region.IsObjectType and region:IsObjectType(which) then
					StripRegion(which, region, kill, alpha)
				end
			end
		end
	end
end


local QuestStrip = {
    'EmptyQuestLogFrame',
    'QuestDetailScrollChildFrame',
    'QuestDetailScrollFrame',
    'QuestFrame',
    'QuestFrameDetailPanel',
    'QuestFrameGreetingPanel',
    'QuestFrameProgressPanel',
    'QuestFrameRewardPanel',
    'QuestGreetingScrollFrame',
    'QuestInfoItemHighlight',
    'QuestProgressScrollFrame',
    'QuestRewardScrollChildFrame',
    'QuestRewardScrollFrame',
    'QuestRewardScrollFrame',
    'GossipFrameGreetingPanel',
    'GossipGreetingScrollFrame'
}

for _, object in pairs(QuestStrip) do
    StripType(STRIP_TEX, _G[object])
end


function set_background(frame)
    
    if not frame.SetBackdrop then
        _G.Mixin(frame, _G.BackdropTemplateMixin)
        --frame:HookScript('OnSizeChanged', frame.OnBackdropSizeChanged)
    end
    frame:SetBackdrop({
        bgFile = "Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment",
        -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-StatsBackground",
        -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Parchment-Horizontal-Desaturated",
        -- bgFile = "Interface/AdventureMap/AdventureMapParchmentTile",
        -- edgeFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-WoodBorder",
        -- edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        -- edgeFile = "Interface/GLUES/COMMON/TextPanel-Border",
        edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
        edgeSize = 12,
        tile = true,
        tileSize = 420,
        -- insets = { left = 8, right = 8, top = 5, bottom = 8 }
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    --frame:SetBackdropColor(0.7, 0.7, 0.7, 1)

end


function set_portrait_background(region, frame)
    
    -- if not frame.SetBackdrop then
    --     _G.Mixin(frame, _G.BackdropTemplateMixin)
    -- end
    -- frame:SetBackdrop({
    --     --bgFile = "Interface/COMMON/GoldRing",
    --     bgFile = "Interface/MINIMAP/portrait-ring-withbg",
    --     insets = { left = -4, right = -4, top = -4, bottom = -4 }
    -- })
    -- frame:SetBackdropColor(0.5, 0.5, 0.5, 1)

    local ring = frame:CreateTexture(nil, 'ARTWORK')
    -- ring:SetTexture([[Interface/COMMON/portrait-ring-withbg]])
    ring:SetTexture([[Interface/COMMON/BlueMenuRing]])
    ring:SetPoint("CENTER", region, "CENTER", 11, -11)
    ring:SetWidth(120)
    ring:SetHeight(120)
    -- ring:Point('BOTTOM')
    -- ring:Size(326, 103)
    -- ring:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
    -- ring:SetVertexColor(1, 1, 1, 0.6)

    return ring
    
end


function reparent_buttons(frame, padding)
    for _, button in pairs(merge({ frame:GetChildren() }, { frame:GetRegions() })) do
        if button:GetObjectType() == "Button" then
            local point, relativeTo, relativePoint, xOfs, yOfs = button:GetPoint()
            local offset = {
                TOPLEFT = { padding, -padding },
                TOPRIGHT = { -padding, -padding },
                BOTTOMLEFT = { padding, padding },
                BOTTOMRIGHT = { -padding, padding }
            }
            offset = offset[relativePoint]
            button:SetPoint(point, relativeTo, relativePoint, offset[1], offset[2])
        end
    end
end


addon:SetScript("OnEvent", function(self, event)

    for _, main in pairs({ QuestFrame, GossipFrame, ItemTextFrame }) do
        if main:IsVisible() then

            -- for _, button in pairs(ALL_BUTTONS) do
            --     HandleButton(_G[button])
            -- end

            -- print("*", main:GetName())

            local height = 0

            main:ClearAllPoints()
            main:SetWidth(WIDTH)
            
            for _, child in pairs({ main:GetChildren() }) do
                reparent_buttons(child, 10)
            end

            if not main.portrait_border then
                for _, region in pairs({ main:GetRegions() }) do
                    if region:GetObjectType() == "Texture" then
                        region:ClearAllPoints()
                        region:SetPoint("LEFT", main, "TOPLEFT", 5, 0)
                        region:SetDrawLayer("OVERLAY")
                        main.portrait_border = set_portrait_background(region, main)
                    end
                end
            end

            for _, scrollparent in pairs(find_first_scroll_frame(main)) do
                -- print("- ", scrollparent:GetObjectType(), scrollparent:GetName())

                scrollparent:SetPoint("TOPLEFT", main, 15, -40)
                scrollparent:SetWidth(WIDTH-20)
                if scrollparent.SetBackdropBorderColor then
                    scrollparent:SetBackdropBorderColor(0, 0, 0, 0)
                elseif scrollparent.backdrop then
                    scrollparent.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
                end

                for i, scrollchild in ipairs({ scrollparent:GetChildren() }) do
                    -- print("-- ", scrollchild:GetObjectType(), scrollchild:GetName())

                    if scrollchild:GetObjectType() == "Slider" then
                        scrollchild:Hide()
                    elseif i == 2 then
                        scrollchild:SetWidth(WIDTH-20)

                        for _, subchild in pairs(merge({ scrollchild:GetChildren() }, { scrollchild:GetRegions() })) do
                            local point, relativeTo, relativePoint, xOfs, yOfs = subchild:GetPoint()
                            -- print("--- ", subchild:GetObjectType(), subchild:GetName(), point, relativeTo, relativePoint, xOfs, yOfs)
                            if subchild:IsVisible() then
                                subchild:SetWidth(WIDTH-45)
                                height = height + subchild:GetHeight() - (yOfs or 0)
                            end
                        end
                        scrollparent:SetHeight(height+40)
                        scrollchild:SetHeight(1)
                    end

                end
                
            end
        
            main:SetHeight(math.max(MIN_HEIGHT, height+85))
            main:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 200)

            set_background(main)
            reparent_buttons(main, 18)

        end
            
    end

end)
