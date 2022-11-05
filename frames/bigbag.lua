

local
    PARENT,
    Style,
    Frame,
    Button,
    ItemButton,
    Texture,
    MaskTexture,
    FontString
    =
        LQT.PARENT,
        LQT.Style,
        LQT.Frame,
        LQT.Button,
        LQT.ItemButton,
        LQT.Texture,
        LQT.MaskTexture,
        LQT.FontString


local session = nil
local FrameBigBag = nil
SilverUIBigBag = nil


local GetContainerNumFreeSlots = GetContainerNumFreeSlots or C_Container.GetContainerNumFreeSlots
local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
local GetContainerItemID = GetContainerItemID or C_Container.GetContainerItemID
local GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
local GetContainerItemInfo = GetContainerItemInfo or C_Container.GetContainerItemInfo


local QUALITY_COLORS = {}
do
    local colorSelect = CreateFrame('ColorSelect') -- Convert RGB <-> HSV (:
    for i = 0, Enum.ItemQualityMeta.NumValues - 1 do
        local r, g, b = GetItemQualityColor(i)
        colorSelect:SetColorRGB(r, g, b)
        local h, s, v = colorSelect:GetColorHSV()
        v = 0.8
        colorSelect:SetColorHSV(h, s, v)
        r, g, b = colorSelect:GetColorRGB()
        QUALITY_COLORS[i] = { r, g, b, 1 }
    end
end


SilverUI.Persistent {
    name = 'bigbag',
    account = {},
    character = {
        mapping = {},
        columns = 12,
        rows = 1,
        x = nil,
        y = nil
    },
    onload = function(account, character)
        session = character
        SilverUIBigBag = FrameBigBag.new()
    end
}


local ToParent = Style {
    function(self)
        self:SetAllPoints(self:GetParent())
    end
}


local Btn = Button
    :Hooks {
        OnEnter = function(self)
            self.hoverBg:Show()
        end,
        OnLeave = function(self)
            self.hoverBg:Hide()
        end
    }
    .data {
        SetText = function(self, ...)
            self.Text:SetText(...)
        end
    }
{
    FontString'.Text'
        :Font('Fonts/ARIALN.TTF', 12)
        .. ToParent,
    Texture'.hoverBg'
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        .. ToParent,
    Style:SetSize(20, 20)
}


local FrameSlot = Frame
    -- :FrameLevel(4)
    :EnableMouse(true)
    :Hooks {
        OnEnter = function(self)
            if not self.item and GetCursorInfo() then
                SilverUIBigBag:EmptyItemToSlot(self)
            end
        end,
        OnReceiveDrag = function(self)
            if SilverUIBigBag.dragging then
                SilverUIBigBag:BindToSlot(SilverUIBigBag.dragging, self)
                ClearCursor()
            end
        end,
        OnMouseDown = function(self, button)
            if button == 'LeftButton' and SilverUIBigBag.dragging then
                SilverUIBigBag:BindToSlot(SilverUIBigBag.dragging, self)
                ClearCursor()
            end
        end
    }
{
    
    Texture'.Bg'
        :Texture 'Interface/ContainerFrame/UI-Bag-4x4'
        :VertexColor(0.9,0.9,0.9)
        :TexCoord(122/256, (122+40)/256, 90/256, (90+39)/256)
        .. ToParent,
    
    Frame'.BgOverlayFrame'
        -- :FrameLevel(6)
        .. ToParent
    {
        Texture'.Bg'
            -- :ColorTexture(1,1,1,0.5)
            -- :Texture 'Interface/ContainerFrame/UI-Bag-4x4'
            -- :VertexColor(0.8,0.8,0.8)
            -- :TexCoord(122/256, (122+40)/256, 90/256, (90+39)/256)
            :Texture 'Interface/AddOns/silver-ui/art/itemslot'
            :Alpha(0.7)
            .. ToParent,
    }
        
    -- MaskTexture'.Mask'
    --     :Texture 'Interface/AddOns/silver-ui/art/actionbutton-mask'
    --     .init(function(self, parent)
    --         parent.Bg:AddMaskTexture(self)
    --         self:SetAllPoints(parent.Bg)
    --     end),
}


local StyleItem = Style
    :Scripts {
        OnShow = function(self)
            self:Update()
        end,
        OnHide = function(self)

        end
    }
    :Hooks {
        OnDragStart = function(self, button)
            if button == 'LeftButton' then
                SilverUIBigBag.dragging = self
            end
        end
    }
    :Events {
        BAG_UPDATE_DELAYED = function(self)
            self:Update()
        end,
        BAG_UPDATE_COOLDOWN = function(self)
            if self.texture and self.UpdateCooldown then
                self:UpdateCooldown(self.texture)
            end
        end
    }
    .data {
        Update = function(self)
            local bag, slot = self.bag, self.slot
            self.isValid = slot <= GetContainerNumSlots(bag)
            if not self.isValid then
                return
            end
            self.itemId = GetContainerItemID(bag, slot)
            self.itemLink = GetContainerItemLink(bag, slot)
            self.hasItem = not not self.itemId
            icon, _, _, quality = GetContainerItemInfo(bag, slot)
            self.texture = icon
            self.quality = quality
            self.bagFamily = select(2, GetContainerNumFreeSlots(bag))
            self.icon:SetTexture(self.texture)
            self.icon:SetAllPoints(self)
            self.BattlepayItemTexture:SetShown(IsBattlePayItem(bag, slot))
            self.BattlepayItemTexture:SetAllPoints(self)
            self:UpdateCount()
            if self.UpdateCooldown then
                self:UpdateCooldown(self.texture)
            end
            self:UpdateQuality()
        end,
        UpdateCount = function(self)
            self.count = select(2, GetContainerItemInfo(self.bag, self.slot)) or 0
            if self.count > 1 then
                self.Count:SetText(self.count)
                self.Count:Show()
            else
                self.Count:Hide()
            end
        end,
        UpdateQuality = function(self)
            if self.quality then
                local percBrightness = 1 -- 0.299*r + 0.587*g + 0.114*b
                -- if self.quality == 5 or self.quality == 6 then
                --     percBrightness = 1
                -- end
                self.IconGlow:SetTexture 'Interface/AddOns/silver-ui/art/itemslot_glow'
                self.IconGlow:SetVertexColor(unpack(QUALITY_COLORS[self.quality] or { 0.5, 0.5, 0.5, 1 }))
                self.IconGlow:Show()
            else
                self.IconGlow:Hide()
            end
        end
    }
{
    Style'.*NormalTexture'
        :Texture 'Interface/AddOns/silver-ui/art/itemslot'
        :AllPoints(PARENT),
    Style'.IconBorder':Texture '',
    Texture'.IconGlow'
        :AllPoints(PARENT),
}


local ButtonRemoveRow = Button
    :Alpha(0)
    :NormalTexture 'Interface/Buttons/UI-Panel-MinimizeButton-Up'
    :PushedTexture 'Interface/Buttons/UI-Panel-MinimizeButton-Down'
    :Size(16, 16)
    :Scripts {
        OnEnter = function(self)
            self:SetAlpha(1)
        end,
        OnLeave = function(self)
            self:SetAlpha(0)
        end,
        OnClick = function(self)
            SilverUIBigBag:RemoveRow(self.row)
        end
    }


local ButtonAddRow = ButtonRemoveRow
    :NormalTexture 'Interface/Buttons/UI-PlusButton-Up'
    :PushedTexture 'Interface/Buttons/UI-PlusButton-Down'
    :Scripts {
        OnClick = function(self)
            SilverUIBigBag:AddRow(self.row)
        end
    }


FrameBigBag = Frame
    :Hide()
    :Width(450)
    :Height(450 / 12 * 16 + 18.5)
    :EnableMouse(true)
    :Point('CENTER', 0, 0)
    -- :FrameLevel(2)
    .init(function(self)
        self.padding = 5
        self.spacing = 4
        self.rowRemoveButtons = {}
        self.rowAddButtons = {}

        self.origOpenAllBags = function() end -- OpenAllBags
        self.origOpenBackpack = function() end -- OpenBackpack
        self.origCloseBackpack = function() end
        self.origOpenBag = function() end -- OpenBag
        self.origCloseAllBags = function() end -- CloseAllBags
        self.origToggleAllBags = function() end -- ToggleAllBags
        self.origToggleBackpack = function() end -- ToggleBackpack
        self.origToggleBag = ToggleBag
        
        self.slots = {}
        self.sortedSlots = {}
        self.rowsCreated = 0
        self.columnsCreated = 0
        
        local letBlizzard = false
        OpenAllBags = function(bag)
            self:Show()
        end
        ToggleBackpack = function()
            self:Toggle()
        end
        ToggleBag = function(bag)
            if bag < 1 or bag > 4 then
                self.origToggleBag(bag)
                self.update = true
            else
                self:Toggle()
            end
        end
        CloseAllBags = function(bag)
            letBlizzard = true
            self.origCloseAllBags(bag)
            letBlizzard = false
            self:Hide()
        end
        ToggleAllBags = function()
            self:Toggle()
        end

        -- hooksecurefunc('UIParent_ManageFramePositions', function() self.update = true end)
        
        self.bags = {}
        self.items = {}
        for container = 0, 4 do
            local bag = {}
            table.insert(self.bags, bag)
            self {
                Frame('.Bag' .. container)
                    :AllPoints(self)
                    :SetID(container)
            }
            for slot = 1, 36 do
                local button = _G['ContainerFrame' .. (container+1) .. 'Item' .. slot]
                if button and not button.isExtended then
                    button:UnregisterAllEvents()
                    StyleItem(button)
                    button.parent = self['Bag' .. container]
                    button:SetID(slot)
                    -- button:SetBagID(container) -- taint hell
                    button.bag = container
                    button.slot = slot
                    table.insert(self.items, button)
                    table.insert(bag, button)
                end
            end
        end

        if not self.SetBackdrop then
            _G.Mixin(self, _G.BackdropTemplateMixin)
            self:HookScript('OnSizeChanged', self.OnBackdropSizeChanged)
        end

        function self:Initialize()
            self:UpdateCount()
            self:CreateSlots()
            self:LoadConfig()
            self:BindUnbound()
        end

        function self:EnsureSize()
            while self.countMax > session.columns * session.rows do
                self:AddRow()
            end
        end

        function self:Toggle()
            if self:IsShown() then
                self:Hide()
            else
                self:Show()
                self.update = true
            end
        end
        
        function self:LoadConfig()
            if session.x and session.y then
                SilverUIBigBag:SetPoints { CENTER = UIParent:CENTER(session.x, session.y) }
            end
            local slotsFilled = {}
            for itemName, slotName in pairs(session.mapping) do
                if not slotsFilled[slotName] then
                    slotsFilled[slotName] = true
                    if self.slots[slotName] then
                        -- self:BindToSlot(_G[itemName], )
                        self.slots[slotName].item = _G[itemName]
                    else
                        session.mapping[itemName] = nil
                        for _, slot in pairs(self.slots) do
                            if not slot.item then
                                slot.item = _G[itemName]
                                session.mapping[itemName] = slot.name
                            end
                        end
                    end
                else
                    session.mapping[itemName] = nil
                end
            end
        end

        function self:CreateSlots()
            local rows = session.rows
            session.rows = 0
            for row = 1, rows do
                self:AddRow(row)
            end
            self:EnsureSize()
        end

        function self:BindUnbound()
            for _, slot in pairs(self.sortedSlots) do
                if not slot.item then
                    item = self:GetUnboundItem()
                    if item then
                        self:BindToSlot(item, slot)
                        StyleItem(item)
                    end
                end
            end
        end

        function self:SortEmpty()
            if not self.initialized then
                return
            end
            for _, slot in pairs(self.sortedSlots) do
                if slot.item and not slot.item.hasItem then
                    session.mapping[slot.item:GetName()] = nil
                    slot.item = nil
                end
            end
            for _, slot in pairs(self.sortedSlots) do
                if not slot.item then
                    for _, bag in pairs(self.bags) do
                        local done = false
                        -- for i=#bag, 1, -1 do
                        for i=1, #bag do
                            local item = bag[i]
                            if item:IsShown() and item.isValid and not item.extendedFrame and not item.hasItem and not session.mapping[item:GetName()] then
                                self:BindToSlot(item, slot)
                                done = true
                                break
                            end
                        end
                        if done then
                            break
                        end
                    end
                end
            end
            self.update = true
        end

        function self:GetUnboundItem()
            for _, item in pairs(self.items) do
                if item.isValid and not session.mapping[item:GetName()] and not item.extendedFrame then
                    return item
                end
            end
        end

        function self:BindToSlot(item, slot)
            local oldSlot = session.mapping[item:GetName()]
            if oldSlot then
                self.slots[oldSlot].item = nil
            end
            local size = (self:GetWidth() - self.padding*2)/session.columns
            slot.item = item
            session.mapping[item:GetName()] = slot.name
            item:SetPoints { CENTER = slot:CENTER() }
            item:SetScale((size-1) / item:GetWidth())
        end

        function self:EmptyItemToSlot(newSlot)
            for itemName, slotName in pairs(session.mapping) do
                local item = _G[itemName]
                if item:IsShown() and item.isValid and not item.hasItem and not item.extendedFrame then
                    self.slots[slotName].item = nil
                    self:BindToSlot(item, newSlot)
                    return
                end
            end
        end

        function self:RemoveRow(removeRow)
            if self.countMax > session.columns * (session.rows-1) then
                return
            end

            for row = 1, session.rows do
                if row == removeRow then
                    for column = 1, session.columns do
                        local name = 'Slot' .. row .. '-' .. column
                        local slot = self.slots[name]
                        if slot.item and slot.item.hasItem then
                            return
                        end
                    end
                    for column = 1, session.columns do
                        local name = 'Slot' .. row .. '-' .. column
                        local slot = self.slots[name]
                        if slot.item then
                            session.mapping[slot.item:GetName()] = nil
                            slot.item = nil
                        end
                    end
                elseif row > removeRow then
                    for column = 1, session.columns do
                        local slot = self.slots['Slot' .. row .. '-' .. column]
                        local slotUp = self.slots['Slot' .. row-1 .. '-' .. column]
                        if slot.item then
                            self:BindToSlot(slot.item, slotUp)
                        end
                    end
                end
            end
            session.rows = session.rows - 1
            for row = session.rows+1, self.rowsCreated do
                for column = 1, session.columns do
                    local slot = self.slots['Slot' .. row .. '-' .. column]
                    slot:Hide()
                end
            end
            self:UpdateSize()
            self:SortEmpty()
        end

        function self:AddRow(where)
            session.rows = session.rows + 1
            if not self.slots['Slot' .. session.rows .. '-1'] then
                self.rowsCreated = self.rowsCreated + 1
                local row = session.rows
                for column = 1, session.columns do
                    local name = 'Slot' .. row .. '-' .. column
                    local size = (self:GetWidth() - self.padding*2)/session.columns
                    Style(self.Items) {
                        FrameSlot('.' .. name)
                            :Points {
                                TOPLEFT = self.Items:TOPLEFT((column-1)*size + self.padding, -(row-1)*size - self.padding - 20),
                                BOTTOMRIGHT = self.Items:TOPLEFT(column*size + self.padding, -row*size - self.padding - 20)
                            },
                    }
                    self.slots[name] = self.Items[name]
                    self.slots[name].name = name
                    table.insert(self.sortedSlots, self.slots[name])
                end

                local rowFirstSlot = 'Slot' .. row .. '-1'
                local slot = self.slots[rowFirstSlot]
                self.SlotManager {
                    ButtonRemoveRow('.Remover-' .. rowFirstSlot)
                        :Show()
                        :Points { RIGHT = slot:LEFT(-4, 0) }
                        .data { row = row },
                    ButtonAddRow('.Adder-' .. rowFirstSlot)
                        :Show()
                        :Points { RIGHT = slot:TOPLEFT(-4, 0) }
                        .data { row = row }
                }
            else
                for column = 1, session.columns do
                    local slot = self.slots['Slot' .. session.rows .. '-' .. column]
                    slot:Show()
                end
            end
            if where then
                for row = session.rows, where, -1 do
                    for column = 1, session.columns do
                        local slot = self.slots['Slot' .. row .. '-' .. column]
                        local slotDown = self.slots['Slot' .. row+1 .. '-' .. column]
                        if slot.item then
                            self:BindToSlot(slot.item, slotDown)
                        end
                    end
                end
            end
            self:UpdateSize()
            self:SortEmpty()
        end

        function self:UpdateSize()
            local size = (self:GetWidth() - self.padding*2)/session.columns
            self:SetHeight(19 + size*session.rows + self.padding*2)
        end

        function self:UpdateCount()
            local free, max = 0, 0
            for i=0, 4 do
                free = free + GetContainerNumFreeSlots(i)
                max = max + GetContainerNumSlots(i)
            end
            self.countFree = free
            self.countMax = max
            self.Count:SetPoints { RIGHT = self.closeBtn:LEFT(-3, 0) }
            self.Count:SetText('' .. max-free .. '/' .. max)
            self.Count:SetTextColor(1,1,1,1)
            if free == 0 then
                self.Count:SetTextColor(1, 0.3, 0.3,1)
            end
        end

    end)
    :Events {
        BAG_UPDATE_DELAYED = function(self)
            self:UpdateCount()
            self:EnsureSize()
        end,
        MERCHANT_SHOW = function(self)
            self.update = true
        end,
        MAIL_SHOW = function(self)
            self.update = true
        end,
        PLAYER_ENTERING_WORLD = function(self)
            self:Hide()
        end
    }
    :SetBackdrop({
        -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment",
        -- bgFile = "Interface/QuestionFrame/question-background",
        -- bgFile = "Interface/Collections/CollectionsBackgroundTile",
        -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-StatsBackground",
        -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Parchment-Horizontal-Desaturated",
        -- bgFile = "Interface/AdventureMap/AdventureMapParchmentTile",
        bgFile = "Interface/FrameGeneral/UI-Background-Rock",
        -- bgFile = "Interface/FrameGeneral/UI-Background-Marble",
        -- edgeFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-WoodBorder",
        -- edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        -- edgeFile = "Interface/GLUES/COMMON/TextPanel-Border",
        edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
        edgeSize = 12,
        tile = true,
        tileSize = math.max(200, 200),
        -- insets = { left = 8, right = 8, top = 5, bottom = 8 }
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    :Hooks {
        OnShow = function(self)
            if not self.initialized then
                self:Initialize()
                self.initialized = true
            end
            PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
        end,
        OnHide = function(self)
            PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
        end,
        OnUpdate = function(self)
            if self.dragging then
                if not GetCursorInfo() then
                    self.dragging = nil
                end
            end
            if not self.update or not self.slots then return end
            self.update = false

            local size = (self:GetWidth() - self.padding*2)/session.columns

            Style(ContainerFrame1MoneyFrame)
                :Parent(self)
                :Points { TOPLEFT = self:TOPLEFT(12, -9) }
            {
                Style'.Border':Hide()
            }

            for _, bag in pairs(self.bags) do
                for _, item in pairs(bag) do
                    item:SetParent(item.parent)
                end
            end

            for _, slot in pairs(self.sortedSlots) do
                if slot.item then
                    slot.item:SetAllPoints(slot)
                    slot.item:Show()
                    slot.item:SetFrameLevel(5)
                end
            end

        end
    }
    :Scripts {
        OnKeyDown = function(self, key)
            if key == 'ESCAPE' then
                self:SetPropagateKeyboardInput(false)
                self:Hide()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end
    }
    :EventHooks {
        BAG_UPDATE_DELAYED = function(self)
            self:SortEmpty()
        end
    }
{
    Frame'.SlotManager'
        .. ToParent,
    
    Frame'.Items'
        :FrameStrata 'MEDIUM'
        -- :FrameLevel(4)
        .. ToParent,

    Btn'.closeBtn'
        :SetText('X')
        -- :FrameLevel(6)
        :Scripts { OnClick = function(self) CloseAllBags() end }
        .init(function(self, parent) self:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -6, -5) end),

    Texture'.TitleBg'
        :Height(25)
        :ColorTexture(0.07, 0.07, 0.07, 0.5)
        :DrawLayer('BACKGROUND', 1)
        .init(function(self, parent)
            self:SetPoints {
                TOPLEFT = parent:TOPLEFT(3, -3),
                RIGHT = parent:RIGHT(-3, 0)
            }
        end),

    Frame'.TitleMoveHandler'
        :Height(25)
        -- :FrameLevel(5)
        .init(function(self, parent)
            self:SetPoints { TOPLEFT = parent:TOPLEFT(3, -3),
                             TOPRIGHT = parent:TOPRIGHT(3, -3) }
        end)
        :Scripts {
            OnMouseDown = function(self, button)
                if button == 'LeftButton' then
                    self.dragging = true
                    local x, y = GetCursorPosition()
                    local _, _, _, px, py = self:GetParent():GetPoint()
                    local scale = self:GetEffectiveScale()
                    self.dragOffset = { x/scale - px, y/scale - py }
                end
            end,
            OnMouseUp = function(self, button)
                if button == 'LeftButton' then
                    self.dragging = false
                end
            end,
            OnUpdate = function(self, dt)
                if self.dragging then
                    local x, y = GetCursorPosition()
                    local scale = self:GetEffectiveScale()
                    session.x = x/scale - self.dragOffset[1]
                    session.y = y/scale - self.dragOffset[2]
                    SilverUIBigBag:SetPoints { CENTER = UIParent:CENTER(session.x, session.y) }
                end
            end
        },

    FontString'.Count'
        -- :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 12)
        :Font('Fonts/ARIALN.TTF', 12)
}

