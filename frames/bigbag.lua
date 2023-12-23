---@class Addon
local Addon = select(2, ...)

local Animation = Addon.Animation

local LQT = Addon.LQT
local Override = LQT.Override
local Event = LQT.Event
local Script = LQT.Script
local SELF = LQT.SELF
local PARENT = LQT.PARENT
local Style = LQT.Style
local Frame = LQT.Frame
local Button = LQT.Button
local Texture = LQT.Texture
local MaskTexture = LQT.MaskTexture
local FontString = LQT.FontString
local EditBox = LQT.EditBox

local FrameBigBag = nil


local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE


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
    QUALITY_COLORS[0] = { 0, 0, 0, 0.5 }
    for i = 1, Enum.ItemQualityMeta.NumValues - 1 do
        local r, g, b = GetItemQualityColor(i)
        local brightness = (0.2126*r + 0.7152*g + 0.0722*b)*1.2
        colorSelect:SetColorRGB(r, g, b)
        local h, s, v = colorSelect:GetColorHSV()
        v = v > 0.7 and v/brightness or 0.3
        colorSelect:SetColorHSV(h, s, v)
        r, g, b = colorSelect:GetColorRGB()
        QUALITY_COLORS[i] = { r, g, b, 0.5 }
    end
end


local _, db = SilverUI.Storage {
    name = 'bigbag',
    account = {},
    character = {
        mapping = {},
        columns = 12,
        rows = 1,
        x = nil,
        y = nil
    },
    onload = function()
        FrameBigBag.new(UIParent, 'SilverUIBigBag')
    end
}


local MoneyFrame = Frame {
    Update = function(self)
        local money = (GetMoney() - GetCursorMoney() - GetPlayerTradeMoney())

        local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
        local goldDisplay = BreakUpLargeNumbers(gold);
        local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
        local copper = mod(money, COPPER_PER_SILVER);

        self.Text:SetText(
            (gold > 0 and ('|cffffd700' .. goldDisplay .. ' ') or '')
            .. (silver > 0 and ('|cffc0c0c0' .. silver .. ' ') or '')
            .. '|cffb87333' .. copper
        )
    end,
    [Event.PLAYER_MONEY] = SELF.Update,
    [Event.PLAYER_ENTERING_WORLD] = SELF.Update,

    Text = FontString
        :Font('Fonts/ARIALN.TTF', 14)
        :AllPoints(PARENT)
        :JustifyH 'LEFT'
}


local CloseButton = Button {
    Style:Size(20, 20),

    [Script.OnEnter] = function(self)
        self.hoverBg:Show()
    end,
    [Script.OnLeave] = function(self)
        self.hoverBg:Hide()
    end,

    SetText = function(self, ...)
        self.Text:SetText(...)
    end,

    Text = FontString
        :Font('Fonts/ARIALN.TTF', 12)
        :AllPoints(PARENT),

    hoverBg = Texture
        -- :ColorTexture(0.3, 0.3, 0.3)
        :Texture 'Interface/BUTTONS/UI-Listbox-Highlight2'
        :BlendMode 'ADD'
        :VertexColor(1,1,1,0.2)
        :Hide()
        :AllPoints(PARENT),
}


local FrameSlot = Frame
    :FrameLevel(1)
    :EnableMouse(true)
{
    [Script.OnEnter] = function(self)
        if not self.item and GetCursorInfo() then
            local type, item = GetCursorInfo()
            local craftingReagent = type == 'item' and select(17, GetItemInfo(item))
            SilverUIBigBag:EmptyItemToSlot(self, craftingReagent)
        end
    end,
    [Script.OnReceiveDrag] = function(self)
        if SilverUIBigBag.dragging then
            SilverUIBigBag:BindToSlot(SilverUIBigBag.dragging, self)
            ClearCursor()
        end
    end,
    [Script.OnMouseDown] = function(self, button)
        if button == 'LeftButton' and SilverUIBigBag.dragging then
            SilverUIBigBag:BindToSlot(SilverUIBigBag.dragging, self)
            ClearCursor()
        end
    end,

    Bg = Texture
        :Texture 'Interface/ContainerFrame/UI-Bag-4x4'
        :VertexColor(0.9,0.9,0.9)
        :TexCoord(122/256, (122+40)/256, 90/256, (90+39)/256)
        :AllPoints(PARENT),

    BgOverlayFrame = Frame
        :FrameLevel(3)
        :AllPoints(PARENT)
    {
        Overlay = Texture
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


local SearchField = EditBox
    :Font('Fonts/ARIALN.TTF', 12, '')
    :AutoFocus(false)
    -- :Disable()
{
    bar = Texture
        .BOTTOMLEFT:BOTTOMLEFT(0, 0.5)
        .BOTTOMRIGHT:BOTTOMRIGHT(0, 0.5)
        :Height(2)
        :ColorTexture(0.5, 0.5, 0.5, 0.3)
        :Hide(),

    icon = Texture
        :Texture 'Interface/AddOns/silver-ui/art/icons/search'
        :Alpha(0.7)
        .RIGHT:RIGHT()
        :Size(16, 16),

    [Script.OnEnter] = function(self)
        if not self:HasFocus() then
            self.bar:SetColorTexture(0.3, 0.3, 0.3, 0.3)
            self.bar:Show()
        end
    end,

    [Script.OnLeave] = function(self)
        if not self:HasFocus() then
            self.bar:Hide()
        end
    end,

    [Script.OnEditFocusGained] = function(self)
        self.bar:SetColorTexture(0.5, 0.5, 0.5, 0.3)
        self.bar:Show()
        self.icon:SetAlpha(1)
        self:HighlightText()
    end,

    [Script.OnEditFocusLost] = function(self)
        self.icon:SetAlpha(0.7)
        self.bar:Hide()
    end,

    [Script.OnEscapePressed] = function(self)
        self:ClearFocus()
        self:SetText('')
    end,

    [Script.OnTextChanged] = function(self)
        self:GetParent():SetSearch(self:GetText())
    end,

}


local ItemButton = Style
    .constructor(function(parent, globalName, ...)
        return CreateFrame(IsRetail and 'ItemButton' or 'Button', globalName, parent, 'ContainerFrameItemButtonTemplate')
    end)
    :UnregisterAllEvents()
    :FrameLevel(3)
{
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
        self.BattlepayItemTexture:Hide()
        self:UpdateCount()
        if self.UpdateCooldown then
            self:UpdateCooldown(self.texture)
        end
        self:SetShown(self.isValid)
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

    itemLevel = Frame
        .TOPLEFT:TOPLEFT(3, -3)
        .BOTTOMRIGHT:BOTTOMRIGHT()
    {
        SetText = function(self, text)
            self.Text.itemLevel:SetText(text)
            self.Text.ItemLevelBg:SetText(text)
        end,

        Text = Frame
            :AllPoints(PARENT)
        {
            itemLevel = FontString
                :Font('Fonts/ARIALN.TTF', 12, 'OUTLINE')
                :TextColor(0.7, 0.7, 0.7, 1)
                :ShadowOffset(0.5, -0.5)
                :ShadowColor(0, 0, 0, 0.7)
                .TOPLEFT:TOPLEFT(),
            ItemLevelBg = FontString
                :Font('Fonts/ARIALN.TTF', 12, 'OUTLINE')
                :TextColor(1, 1, 1, 0.7)
                :ShadowOffset(0, 0)
                :ShadowColor(0, 0, 0, 0)
                .TOPLEFT:TOPLEFT(),
        },
    },
    UpdateItemLevel = function(self)
        if self.info.itemType == 'Armor' or self.info.itemType == 'Weapon' and self.info.itemLevel then
            self.itemLevel:SetText(self.info.itemLevel)
        else
            self.itemLevel:SetText('')
        end
    end,

    qualityGlow = Texture
        :AllPoints(PARENT)
        :DrawLayer('ARTWORK', 1),
    UpdateQuality = function(self)
        if self.info.itemType == 'Quest' then
            self.qualityGlow:Show()
            self.qualityGlow:SetTexture 'Interface/AddOns/silver-ui/art/itemslot_glow'
            self.qualityGlow:SetVertexColor(1, 1, 0, 1)
        elseif self.quality then
            local percBrightness = 1 -- 0.299*r + 0.587*g + 0.114*b
            -- if self.quality == 5 or self.quality == 6 then
            --     percBrightness = 1
            -- end
            -- print(unpack(QUALITY_COLORS[self.quality] or {}))
            self.qualityGlow:Show()
            self.qualityGlow:SetTexture 'Interface/AddOns/silver-ui/art/itemslot_glow'
            local r, g, b, a = unpack(QUALITY_COLORS[self.quality] or { 0.5, 0.5, 0.5, 1 })
            self.qualityGlow:SetVertexColor(r, g, b, a)
        else
            -- print('hide')
            self.qualityGlow:Hide()
        end
    end,

    searchDarkenOverlay = Texture
        :AllPoints(PARENT)
        :ColorTexture(0, 0, 0, 0.5)
        :DrawLayer 'OVERLAY'
        :Hide(),
    UpdateSearch = function(self, search)
        -- search = strlower(search)
        local info = C_Container.GetContainerItemInfo(self.bag, self.slot)
        local match =
            not info
            or not info.isFiltered
            -- not self.info
            -- or #search == 0
            -- or strlower(self.info.itemName or ''):find(search)
            -- or strlower(self.info.itemType or ''):find(search)
            -- or strlower(self.info.itemSubType or ''):find(search)
            -- or strlower(self.info.itemEquipLoc or ''):find(search)
        self.searchDarkenOverlay:SetShown(not match)
        self.icon:SetDesaturation(match and 0 or 0.75)
        self.qualityGlow:SetDesaturation(match and 0 or 0.9)
        self.itemLevel.Text.itemLevel:SetTextColor(match and 1 or 0.3, match and 1 or 0.3, match and 1 or 0.3)
    end,
    [Event.INVENTORY_SEARCH_UPDATE] = SELF.UpdateSearch,

    ['.*NormalTexture'] = Style
        :Texture 'Interface/AddOns/silver-ui/art/itemslot'
        :AllPoints(PARENT)
        :DrawLayer('ARTWORK', 0),

    ['.IconBorder'] = Style:Texture '',

    slotExists = Frame
        :AllPoints(PARENT)
        :FrameLevel(2)
    {
        bg = Texture
            :AllPoints(PARENT)
            :ColorTexture(1, 1, 1, 0.05),
    },

    [Script.OnDragStart] = function(self, button)
        if button == 'LeftButton' then
            SilverUIBigBag.dragging = self
        end
    end,
    [Event.BAG_UPDATE_DELAYED] = function(self)
        self:Update()
    end,
    [Event.BAG_UPDATE_COOLDOWN] = function(self)
        if self.texture and self.UpdateCooldown then
            self:UpdateCooldown(self.texture)
        end
    end,
}


local ButtonRemoveRow = Button
    :Alpha(0)
    :NormalTexture 'Interface/Buttons/UI-Panel-MinimizeButton-Up'
    :PushedTexture 'Interface/Buttons/UI-Panel-MinimizeButton-Down'
    :Size(16, 16)
{
    [Script.OnEnter] = function(self)
        self:SetAlpha(1)
    end,
    [Script.OnLeave] = function(self)
        self:SetAlpha(0)
    end,
    [Script.OnClick] = SELF.OnClick,
    OnClick = function(self)
        SilverUIBigBag:RemoveRow(self.row)
    end,
    SetRow = function(self, row)
        self.row = row
    end
}


local ButtonAddRow = ButtonRemoveRow
    :NormalTexture 'Interface/Buttons/UI-PlusButton-Up'
    :PushedTexture 'Interface/Buttons/UI-PlusButton-Down'
{
    [Override.OnClick] = function(self)
        SilverUIBigBag:AddRow(self.row)
    end
}


local AnchorFrame = Frame
    :Movable(true)
    :UserPlaced(false)
    .CENTER:CENTER(UIParent)
    :Size(1, 1)
    .new()


FrameBigBag = Frame
    :Hide()
    :FrameLevel(0)
    :Width(450)
    :Height(450 / 12 * 16 + 18.5)
    :EnableMouse(true)
    .CENTER:CENTER(AnchorFrame)
    -- :FrameLevel(2)
    :FrameStrata 'HIGH'
    :Toplevel(true)
    :IsFrameBuffer(true)
{
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
        self.origOpenBag = OpenBag
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
            if bag < 0 or bag > 4 then
                self.origToggleBag(bag)
                self.update = true
            else
                self:Toggle()
            end
        end
        OpenBag = function(bag)
            if bag < 0 or bag > 4 then
                self.origOpenBag(bag)
                self.update = true
            else
                self:Show()
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

        self.initialized = true
        self:Initialize()
    end,

    Initialize = function(self)
        self:CreateItemButtons()
        self:UpdateCount()
        self:CreateSlots()
        self:LoadConfig()
        self:BindUnbound()
    end,

    CreateItemButtons = function(self)
        for container = 0, 4 do
            local bag = {}
            table.insert(self.bags, bag)
            Style(self) {
                ['Bag' .. container] = Frame
                    :FrameLevel(0)
                    :AllPoints(self)
                    :SetID(container)
            }
            for slot = 1, 36 do
                -- local button = _G['ContainerFrame' .. (container+1) .. 'Item' .. slot]
                -- local button = CreateFrame('ItemButton', nil, self['Bag' .. container], 'ContainerFrameItemButtonTemplate')

                -- local button = CreateFrame(IsRetail and 'ItemButton' or 'Button', nil, self['Bag' .. container], 'ContainerFrameItemButtonTemplate')
                local button = ItemButton.new(self['Bag'..container])
                if button and not button.isExtended then
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
            if self.itemsByName[itemName] and not slotsFilled[slotName] then
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
                local item = self:GetUnboundItem()
                if item then
                    self:BindToSlot(item, slot)
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
                        if item.isValid and not item.extendedFrame and not item.hasItem and not db.mapping[item.name] then
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

    EmptyItemToSlot = function(self, newSlot, craftingReagent)
        for itemName, slotName in pairs(db.mapping) do
            local item = self.itemsByName[itemName]
            if
                item:IsShown()
                and item.isValid
                and not item.hasItem
                and not item.extendedFrame
                and (craftingReagent or item.bag ~= 5)
            then
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
                    [name] = FrameSlot
                        .TOPLEFT:TOPLEFT((column-1)*size + self.padding, -(row-1)*size - self.padding - 20)
                        .BOTTOMRIGHT:TOPLEFT(column*size + self.padding, -row*size - self.padding - 20)
                }
                self.slots[name] = self.Items[name]
                self.slots[name].name = name
                table.insert(self.sortedSlots, self.slots[name])
            end

            local rowFirstSlot = 'Slot' .. row .. '-1'
            local slot = self.slots[rowFirstSlot]
            Style(self.SlotManager) {
                ['Remover-' .. rowFirstSlot] = ButtonRemoveRow
                    .RIGHT:LEFT(slot, -4, 0)
                    :Show()
                    :Row(row),
                ['Adder-' .. rowFirstSlot] = ButtonAddRow
                    .RIGHT:TOPLEFT(slot, -4, 0)
                    :Show()
                    :Row(row)
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
                    if slot.item and slotDown then
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
        self.Count:SetText('' .. max-free .. '/' .. max)
        self.Count:SetTextColor(1,1,1,1)
        if free == 0 then
            self.Count:SetTextColor(1, 0.3, 0.3,1)
        end
    end,

    SetSearch = function(self, search)
        C_Container.SetItemSearch(search)
        -- for _, item in pairs(self.items) do
        --     item:SetSearch(search)
        -- end
    end,

    [Event.MERCHANT_SHOW] = function(self)
        self.update = true
    end,

    [Event.MAIL_SHOW] = function(self)
        self.update = true
    end,

    [Event.PLAYER_ENTERING_WORLD] = function(self)
        self:Hide()
    end,

    [Event.BAG_UPDATE_DELAYED] = function(self)
        self.delaySortEmpty = true
        self:UpdateCount()
        self:EnsureSize()
    end,

    [Event.PLAYER_REGEN_DISABLED] = function(self)
        self:SetPropagateKeyboardInput(true)
    end,

    [Script.OnShow] = function(self)
        self.AnimIn:Play()
    end,

    [Script.OnUpdate] = function(self)
        if self.dragging then
            if not GetCursorInfo() then
                self.dragging = nil
            end
        end
        if not self.update or not self.slots then return end
        self.update = false
        --[[
        Style(ContainerFrame1MoneyFrame)
            :Parent(self)
            .TOPLEFT:TOPLEFT(12, -9)
        {
            Style'.Border':Hide()
        }
        ]]

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
    end,

    [Script.OnKeyDown] = function(self, key)
        if key == 'ESCAPE' and not self.AnimOut:IsPlaying() then
            self.AnimOut:Play()
            if not InCombatLockdown() then
                local propagate =
                    MerchantFrame:IsVisible()
                    or BankFrame:IsVisible()
                    or MailFrame:IsVisible()
                    or TradeFrame:IsVisible()
                    or (AuctionHouseFrame and AuctionHouseFrame:IsVisible() or false)
                    or (GuildBankFrame and GuildBankFrame:IsVisible() or false)
                    or (ItemUpgradeFrame and ItemUpgradeFrame:IsVisible() or false)
                self:SetPropagateKeyboardInput(propagate)
            end
        else
            if not InCombatLockdown() then
                self:SetPropagateKeyboardInput(true)
            end
        end
    end,

    SlotManager = Frame:AllPoints(PARENT):FrameLevel(0),

    Items = Frame
        :FrameLevel(0)
        :AllPoints(PARENT),

    closeBtn = CloseButton
        .TOPRIGHT:TOPRIGHT(-6, -5)
        :SetText('X')
        -- :FrameLevel(6)
    {
        [Script.OnClick] = function(self)
            CloseAllBags()
        end
    },

    TitleBg = Texture
        .TOPLEFT:TOPLEFT(3, -3)
        .RIGHT:RIGHT(-3, 0)
        :Height(25)
        :ColorTexture(0.07, 0.07, 0.07, 0.5)
        :DrawLayer('BACKGROUND', 1),

    TitleMoveHandler = Frame
        .TOPLEFT:TOPLEFT(3, -3)
        .TOPRIGHT:TOPRIGHT(3, -3)
        :Height(25)
        -- :FrameLevel(5)
    {
        [Script.OnMouseDown] = function(self, button)
            if button == 'LeftButton' then
                AnchorFrame:StartMoving()
            end
        end,
        [Script.OnMouseUp] = function(self, button)
            if button == 'LeftButton' then
                AnchorFrame:StopMovingOrSizing()
                local from, _, to, x, y = AnchorFrame:GetPoint()
                db.anchor = { from, to, x, y }
            end
        end,
    },

    Money = MoneyFrame
        .TOPLEFT:TOPLEFT(15, -5)
        :Size(100, 20),

    Count = FontString
        .RIGHT:LEFT(PARENT.closeBtn, -3, 0)
        -- :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 12)
        :Font('Fonts/ARIALN.TTF', 12),

    Search = SearchField
        .RIGHT:LEFT(PARENT.Count, -3, 0)
        :FrameLevel(5)
        :Size(100, 20),

    AnimIn = Animation
        :Ease 'CUBIC_OUT'
        :Duration(0.25)
        :Translate({ 50, 0 }, { 0, 0 })
        :Alpha(0, 1)
        -- :Scale(0.9, 1)
        :OnPlay(function() PlaySound(SOUNDKIT.IG_BACKPACK_OPEN) end),

    AnimOut = Animation
        :Ease 'CUBIC_IN'
        :Duration(0.25)
        :Translate({ 0, 0 }, { 50, 0 })
        :Alpha(1, 0)
        -- :Scale(1, 0.9)
        :OnFinished(function(self) self:GetParent():Hide() end)
        :OnPlay(function() PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE) end),

}
    :Backdrop {
        bgFile = "Interface/FrameGeneral/UI-Background-Rock",
        edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
        edgeSize = 12,
        tile = true,
        tileSize = 200,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    }

