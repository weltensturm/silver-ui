local ADDON, Addon = ...

local Animation = Addon.Animation

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


local db = nil
local FrameBigBag = nil
SilverUIBigBag = nil


local GetContainerNumFreeSlots = GetContainerNumFreeSlots or C_Container.GetContainerNumFreeSlots
local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
local GetContainerItemID = GetContainerItemID or C_Container.GetContainerItemID
local GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
local GetContainerItemInfo = GetContainerItemInfo or function(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not info then return end
    return
        info.iconFileID,
        info.stackCount,
        info.isLocked,
        info.quality,
        info.isReadable,
        info.hasLoot,
        info.hyperlink,
        info.isFiltered,
        info.hasNoValue,
        info.itemID,
        info.isBound
end
local IsBattlePayItem = IsBattlePayItem or C_Container.IsBattlePayItem


local QUALITY_COLORS = {}
do
    local colorSelect = CreateFrame('ColorSelect') -- Convert RGB <-> HSV (:
    QUALITY_COLORS[0] = { 0, 0, 0, 0 }
    for i = 1, Enum.ItemQualityMeta.NumValues - 1 do
        local r, g, b = GetItemQualityColor(i)
        local brightness = (0.2126*r + 0.7152*g + 0.0722*b)*1.2
        colorSelect:SetColorRGB(r, g, b)
        local h, s, v = colorSelect:GetColorHSV()
        v = v > 0.7 and v/brightness or 0.3
        colorSelect:SetColorHSV(h, s, v)
        r, g, b = colorSelect:GetColorRGB()
        QUALITY_COLORS[i] = { r, g, b, 0.7 }

        QUALITY_COLORS[i] = { r, g, b, 0.7 }
    end
end


SilverUI.Storage {
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
        db = character
        SilverUIBigBag = FrameBigBag.new()
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
        :AllPoints(PARENT),
    Texture'.hoverBg'
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        :AllPoints(PARENT),
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
        :AllPoints(PARENT),
    
    Frame'.BgOverlayFrame'
        -- :FrameLevel(6)
        :AllPoints(PARENT)
    {
        Texture'.Bg'
            -- :ColorTexture(1,1,1,0.5)
            -- :Texture 'Interface/ContainerFrame/UI-Bag-4x4'
            -- :VertexColor(0.8,0.8,0.8)
            -- :TexCoord(122/256, (122+40)/256, 90/256, (90+39)/256)
            :Texture 'Interface/AddOns/silver-ui/art/itemslot'
            :Alpha(0.7)
            :AllPoints(PARENT),
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
            self.info = self.info or {}
            self.isValid = slot <= GetContainerNumSlots(bag)
            if not self.isValid then
                self:UpdateItemLevel()
                return
            end
            self.itemId = GetContainerItemID(bag, slot)
            local newLink = GetContainerItemLink(bag, slot)
            if newLink ~= self.itemLink then
                self.itemLink = newLink
                self:UpdateItemInfo()
                self:UpdateItemLevel()
                self.hasItem = not not self.itemId
                local icon, _, _, quality, _, _, itemLink = GetContainerItemInfo(bag, slot)
                self.texture = icon
                self.quality = quality
                self.bagFamily = select(2, GetContainerNumFreeSlots(bag))
                self.icon:SetTexture(self.texture)
                self.icon:SetAllPoints(self)
                self:UpdateQuality()
            end
            self.BattlepayItemTexture:SetShown(IsBattlePayItem(bag, slot))
            self.BattlepayItemTexture:SetAllPoints(self)
            self:UpdateCount()
            if self.UpdateCooldown then
                self:UpdateCooldown(self.texture)
            end
        end,
        UpdateItemInfo = function(self)
            if self.itemId then
                local info = self.info
                info.itemName, info.itemLink, info.itemQuality, info.itemLevel, info.itemMinLevel,
                    info.itemType, info.itemSubType, info.itemStackCount, info.itemEquipLoc, info.itemTexture,
                    info.sellPrice, info.classID, info.subclassID, info.bindType, info.expacID, info.setID, info.isCraftingReagent
                        = GetItemInfo(self.itemLink)
                info.itemLevel = GetDetailedItemLevelInfo(self.itemLink)
            else
                self.info = {}
            end
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
        UpdateItemLevel = function(self)
            if self.info.itemType == 'Armor' or self.info.itemType == 'Weapon' and self.info.itemLevel then
                self.ItemLevel:SetText(self.info.itemLevel)
            else
                self.ItemLevel:SetText('')
            end
        end,
        UpdateQuality = function(self)
            if self.quality then
                local percBrightness = 1 -- 0.299*r + 0.587*g + 0.114*b
                -- if self.quality == 5 or self.quality == 6 then
                --     percBrightness = 1
                -- end
                -- print(unpack(QUALITY_COLORS[self.quality] or {}))
                self.QualityGlow:Show()
                self.QualityGlow:SetTexture 'Interface/AddOns/silver-ui/art/itemslot_glow'
                local r, g, b, a = unpack(QUALITY_COLORS[self.quality] or { 0.5, 0.5, 0.5, 1 })
                self.QualityGlow:SetVertexColor(r, g, b, a)
            else
                -- print('hide')
                self.QualityGlow:Hide()
            end
        end
    }
{
    Style'.*NormalTexture'
        :Texture 'Interface/AddOns/silver-ui/art/itemslot'
        :AllPoints(PARENT)
        :DrawLayer('ARTWORK', 0),
    Style'.IconBorder':Texture '',
    Texture'.QualityGlow'
        :AllPoints(PARENT)
        :DrawLayer('ARTWORK', 1),
    Frame'.ItemLevel'
        :Points { TOPLEFT = PARENT:TOPLEFT(3, -3),
                  BOTTOMRIGHT = PARENT:BOTTOMRIGHT() }
        .init {
            SetText = function(self, text)
                self.Text.ItemLevel:SetText(text)
                self.Text.ItemLevelBg:SetText(text)
                -- self.Shadow'.*':Hide()
                -- for i=1, 9 do
                --     local x = math.cos(math.pi*i/4.5)
                --     local y = math.sin(math.pi*i/4.5)
                --     self.Shadow {
                --         FontString('.ItemLevelShadow' .. i)
                --             :Font('Fonts/ARIALN.TTF', 12, '')
                --             :Points { TOPLEFT = PARENT:TOPLEFT(x*0.75, y*0.75) }
                --             :TextColor(0, 0, 0, 1)
                --             :Text(text)
                --             :Show()
                --     }
                -- end
            end
        }
    {
        Frame'.Shadow'
            :AllPoints(PARENT)
            -- :IsFrameBuffer(true)
            :Alpha(0.7),
        Frame'.Text'
            :AllPoints(PARENT)
        {
            FontString'.ItemLevel'
                :Font('Fonts/ARIALN.TTF', 12, '')
                :TextColor(0.7, 0.7, 0.7, 1)
                :ShadowOffset(0.5, -0.5)
                :ShadowColor(0, 0, 0, 0.7)
                :Points { TOPLEFT = PARENT:TOPLEFT() },
            FontString'.ItemLevelBg'
                :Font('Fonts/ARIALN.TTF', 12, '')
                :TextColor(1, 1, 1, 1)
                :ShadowOffset(0, 0)
                :ShadowColor(0, 0, 0, 0)
                :Points { TOPLEFT = PARENT:TOPLEFT() },
        }
    }
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


local AnchorFrame = Frame
    :Movable(true)
    :UserPlaced(false)
    :Points { CENTER = UIParent:CENTER() }
    :Size(1, 1)
    .new()


FrameBigBag = Frame
    :Hide()
    :Width(450)
    :Height(450 / 12 * 16 + 18.5)
    :EnableMouse(true)
    :Point('CENTER', AnchorFrame, 'CENTER')
    -- :FrameLevel(2)
    :FlattensRenderLayers(true)
    :IsFrameBuffer(true)
    .init {
        padding = 5,
        spacing = 4,
        rowRemoveButtons = {},
        rowAddButtons = {},
        bags = {},
        items = {},
        itemsByName = {},
        slots = {},
        sortedSlots = {},
        rowsCreated = 0,
        columnsCreated = 0,

        function(self)
            Mixin(self, BackdropTemplateMixin)
            self:HookScript('OnSizeChanged', self.OnBackdropSizeChanged)

            self.origOpenAllBags = function() end -- OpenAllBags
            self.origOpenBackpack = function() end -- OpenBackpack
            self.origCloseBackpack = function() end
            self.origOpenBag = function() end -- OpenBag
            self.origCloseAllBags = function() end -- CloseAllBags
            self.origToggleAllBags = function() end -- ToggleAllBags
            self.origToggleBackpack = function() end -- ToggleBackpack
            self.origToggleBag = ToggleBag
            
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
                self.AnimOut:Play()
            end
            ToggleAllBags = function()
                self:Toggle()
            end

        end,

        Initialize = function(self)
            self:StealBagItemButtons()
            self:UpdateCount()
            self:CreateSlots()
            self:LoadConfig()
            self:BindUnbound()
        end,

        StealBagItemButtons = function(self)
            for container = 0, 4 do
                local bag = {}
                table.insert(self.bags, bag)
                self {
                    Frame('.Bag' .. container)
                        :AllPoints(self)
                        :SetID(container)
                }
                for slot = 1, 36 do
                    -- local button = _G['ContainerFrame' .. (container+1) .. 'Item' .. slot]
                    local button = CreateFrame('ItemButton', nil, self['Bag' .. container], 'ContainerFrameItemButtonTemplate')
                    if button and not button.isExtended then
                        button:UnregisterAllEvents()
                        StyleItem(button)
                        button.parent = self['Bag' .. container]
                        button.name = 'ContainerFrame' .. (container+1) .. 'Item' .. slot
                        button:SetID(slot)
                        -- button:SetBagID(container) -- taint hell
                        button.bag = container
                        button.slot = slot
                        button:Update()
                        table.insert(self.items, button)
                        table.insert(bag, button)
                        self.itemsByName[button.name] = button
                    end
                end
            end
        end,

        EnsureSize = function(self)
            while self.countMax > db.columns * db.rows do
                self:AddRow()
            end
        end,

        Toggle = function(self)
            if self:IsShown() then
                self.AnimOut:Play()
            else
                self:Show()
                self.update = true
            end
        end,
        
        LoadConfig = function(self)
            if db.anchor then
                local from, to, x, y = unpack(db.anchor)
                AnchorFrame:SetPoint(from, UIParent, to, x, y)
            end
            local slotsFilled = {}
            for itemName, slotName in pairs(db.mapping) do
                if not slotsFilled[slotName] then
                    slotsFilled[slotName] = true
                    if self.slots[slotName] then
                        self:BindToSlot(self.itemsByName[itemName], self.slots[slotName])
                        -- self.slots[slotName].item = self.itemsByName[itemName]
                    else
                        db.mapping[itemName] = nil
                        for _, slot in pairs(self.slots) do
                            if not slot.item then
                                self:BindToSlot(self.itemsByName[itemName], slot)
                                -- slot.item = self.itemsByName[itemName]
                                -- db.mapping[itemName] = slot.name
                            end
                        end
                    end
                else
                    db.mapping[itemName] = nil
                end
            end
        end,

        CreateSlots = function(self)
            local rows = db.rows
            db.rows = 0
            for row = 1, rows do
                self:AddRow(row)
            end
            self:EnsureSize()
        end,

        BindUnbound = function(self)
            for _, slot in pairs(self.sortedSlots) do
                if not slot.item then
                    item = self:GetUnboundItem()
                    if item then
                        self:BindToSlot(item, slot)
                        StyleItem(item)
                    end
                end
            end
        end,

        SortEmpty = function(self)
            if not self.initialized then
                return
            end
            for _, slot in pairs(self.sortedSlots) do
                if slot.item and not slot.item.hasItem then
                    db.mapping[slot.item.name] = nil
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
                            if item:IsShown() and item.isValid and not item.extendedFrame and not item.hasItem and not db.mapping[item.name] then
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
        end,

        GetUnboundItem = function(self)
            for _, item in pairs(self.items) do
                if item.isValid and not db.mapping[item.name] and not item.extendedFrame then
                    return item
                end
            end
        end,

        BindToSlot = function(self, item, slot)
            local oldSlot = db.mapping[item.name]
            if oldSlot then
                self.slots[oldSlot].item = nil
            end
            slot.item = item
            db.mapping[item.name] = slot.name
            item:SetAllPoints(slot)
            item:Show()
        end,

        EmptyItemToSlot = function(self, newSlot)
            for itemName, slotName in pairs(db.mapping) do
                local item = self.itemsByName[itemName]
                if item:IsShown() and item.isValid and not item.hasItem and not item.extendedFrame then
                    self.slots[slotName].item = nil
                    self:BindToSlot(item, newSlot)
                    return
                end
            end
        end,

        RemoveRow = function(self, removeRow)
            if self.countMax > db.columns * (db.rows-1) then
                return
            end

            for row = 1, db.rows do
                if row == removeRow then
                    for column = 1, db.columns do
                        local name = 'Slot' .. row .. '-' .. column
                        local slot = self.slots[name]
                        if slot.item and slot.item.hasItem then
                            return
                        end
                    end
                    for column = 1, db.columns do
                        local name = 'Slot' .. row .. '-' .. column
                        local slot = self.slots[name]
                        if slot.item then
                            db.mapping[slot.item.name] = nil
                            slot.item = nil
                        end
                    end
                elseif row > removeRow then
                    for column = 1, db.columns do
                        local slot = self.slots['Slot' .. row .. '-' .. column]
                        local slotUp = self.slots['Slot' .. row-1 .. '-' .. column]
                        if slot.item then
                            self:BindToSlot(slot.item, slotUp)
                        end
                    end
                end
            end
            db.rows = db.rows - 1
            for row = db.rows+1, self.rowsCreated do
                for column = 1, db.columns do
                    local slot = self.slots['Slot' .. row .. '-' .. column]
                    slot:Hide()
                end
            end
            self:UpdateSize()
            self:SortEmpty()
        end,

        AddRow = function(self, where)
            db.rows = db.rows + 1
            if not self.slots['Slot' .. db.rows .. '-1'] then
                self.rowsCreated = self.rowsCreated + 1
                local row = db.rows
                for column = 1, db.columns do
                    local name = 'Slot' .. row .. '-' .. column
                    local size = (self:GetWidth() - self.padding*2)/db.columns
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
                for column = 1, db.columns do
                    local slot = self.slots['Slot' .. db.rows .. '-' .. column]
                    slot:Show()
                end
            end
            if where then
                for row = db.rows, where, -1 do
                    for column = 1, db.columns do
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
        end,

        UpdateSize = function(self)
            local size = (self:GetWidth() - self.padding*2)/db.columns
            self:SetHeight(19 + size*db.rows + self.padding*2)
        end,

        UpdateCount = function(self)
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
        end,
    }
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
    :Backdrop {
        bgFile = "Interface/FrameGeneral/UI-Background-Rock",
        edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
        edgeSize = 12,
        tile = true,
        tileSize = 200,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }
    :Hooks {
        OnShow = function(self)
            if not self.initialized then
                self.initialized = true
                self:Initialize()
            end
            self.AnimIn:Play()
        end,
        OnUpdate = function(self)

            if self.dragging then
                if not GetCursorInfo() then
                    self.dragging = nil
                end
            end
            if not self.update or not self.slots then return end
            self.update = false

            Style(ContainerFrame1MoneyFrame)
                :Parent(self)
                :Points { TOPLEFT = self:TOPLEFT(12, -9) }
            {
                Style'.Border':Hide()
            }

            -- for _, bag in pairs(self.bags) do
            --     for _, item in pairs(bag) do
            --         item:SetParent(item.parent)
            --     end
            -- end

            -- for _, slot in pairs(self.sortedSlots) do
            --     if slot.item then
            --         slot.item:SetAllPoints(slot)
            --         slot.item:Show()
            --         slot.item:SetFrameLevel(5)
            --     end
            -- end

            if self.delaySortEmpty then
                self.delaySortEmpty = false
                self:SortEmpty()
            end
        end
    }
    :Scripts {
        OnKeyDown = function(self, key)
            if key == 'ESCAPE' then
                self:SetPropagateKeyboardInput(false)
                self.AnimOut:Play()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end
    }
    :EventHooks {
        BAG_UPDATE_DELAYED = function(self)
            self.delaySortEmpty = true
        end
    }
{
    Frame'.SlotManager':AllPoints(PARENT),
    
    Frame'.Items'
        :FrameStrata 'MEDIUM'
        :AllPoints(PARENT),

    Btn'.closeBtn'
        :SetText('X')
        -- :FrameLevel(6)
        :Scripts { OnClick = function(self) CloseAllBags() end }
        :Points { TOPRIGHT = PARENT:TOPRIGHT(-6, -5) },

    Texture'.TitleBg'
        :Height(25)
        :ColorTexture(0.07, 0.07, 0.07, 0.5)
        :DrawLayer('BACKGROUND', 1)
        :Points { TOPLEFT = PARENT:TOPLEFT(3, -3),
                  RIGHT = PARENT:RIGHT(-3, 0) },

    Frame'.TitleMoveHandler'
        :Height(25)
        -- :FrameLevel(5)
        :Points { TOPLEFT = PARENT:TOPLEFT(3, -3),
                  TOPRIGHT = PARENT:TOPRIGHT(3, -3) }
        :Scripts {
            OnMouseDown = function(self, button)
                if button == 'LeftButton' then
                    AnchorFrame:StartMoving()
                end
            end,
            OnMouseUp = function(self, button)
                if button == 'LeftButton' then
                    AnchorFrame:StopMovingOrSizing()
                    local from, _, to, x, y = AnchorFrame:GetPoint()
                    db.anchor = { from, to, x, y }
                end
            end,
        },

    FontString'.Count'
        -- :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 12)
        :Font('Fonts/ARIALN.TTF', 12),
    
    Animation'.AnimIn'
        :Ease 'CUBIC_OUT'
        :Duration(0.25)
        :Translate({ 50, 0 }, { 0, 0 })
        :Alpha(0, 1)
        -- :Scale(0.9, 1)
        :OnPlay(function() PlaySound(SOUNDKIT.IG_BACKPACK_OPEN) end),

    Animation'.AnimOut'
        :Ease 'CUBIC_IN'
        :Duration(0.25)
        :Translate({ 0, 0 }, { 50, 0 })
        :Alpha(1, 0)
        -- :Scale(1, 0.9)
        :OnFinished(function(self) self:GetParent():Hide() end)
        :OnPlay(function() PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE) end)

}

