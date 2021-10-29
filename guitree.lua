local _, ns = ...

local Q = ns.util.method_chain_wrapper

SLASH_GUITREE1 = '/guitree'
SLASH_GUITREE2 = '/gt'


local frame = nil


local function GetUIParentChildren()
    local found = {}
        
    local object = EnumerateFrames()
    while object do
        if not object:IsForbidden() and not found[object] and object:GetParent() == UIParent then
            found[object] = true
        end
        object = EnumerateFrames(object)
    end

    return found
end


local function load_children(parent)

end


local function spawn()

    frame = CreateFrame("FRAME", "GuiTree", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetWidth(1000)
    frame:SetHeight(600)
    frame:EnableMouse(true)

    -- local t = frame:CreateTexture(nil,"BACKGROUND")
    -- t:SetTexture("Interface/AdventureMap/AdventureMapTileBg")
    -- t:SetAllPoints(frame)
    -- frame.texture = t

    local hoverFrame = CreateFrame('Frame', nil, UIParent)
    hoverFrame:SetFrameStrata('TOOLTIP')
    local t = hoverFrame:CreateTexture(nil, "DIALOG")
    -- t:SetTexture("Interface/AdventureMap/AdventureMapTileBg")
    t:SetColorTexture(0, 1, 0, 0.2)
    t:SetAllPoints(hoverFrame)

    frame:SetPoint('CENTER', 0, 0)

    Q(CreateFrame('EditBox', nil, frame))
        :SetPoint('TOPLEFT', frame, 'TOPLEFT', 230, -15)
        :SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -20, 15)
        :Script {
            OnEnterPressed = function(self)
                if not self.KEY_LCTRL and not self.KEY_RCTRL then
                    self:Insert('\n')
                else
                    RunScript(self:GetText())
                end
            end,
            OnKeyDown = function(self, _, key)
                if key == 'LCTRL' or key == 'RCTRL' then
                    self['KEY_' .. key] = true
                end
            end,
            OnKeyUp = function(self, _, key)
                if key == 'LCTRL' or key == 'RCTRL' then
                    self['KEY_' .. key] = false
                end
                if key == 'ESCAPE' then
                    frame:Hide()
                end
            end
        }
        :SetFontObject("GameFontHighlight")
        :SetJustifyH("LEFT")
        :SetJustifyV("TOP")
        :SetMultiLine(true)

    local scrollSpeed = 0
    local sf = CreateFrame("ScrollFrame", nil, frame, 'UIPanelScrollFrameTemplate')
    sf:SetPoint('TOPLEFT', frame, 'TOPLEFT', 5, -10)
    -- sf:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -5, 10)
    sf:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMLEFT', 200, 10)

    local scroll = CreateFrame('Frame', nil, frame)
    
	sf:Script {
        OnSizeChanged = function(self)
            scroll:SetWidth(self:GetWidth())
            scroll:SetHeight(self:GetHeight())
	    end,
        OnMouseWheel = function(self, _, delta)
            scrollSpeed = scrollSpeed - delta
        end
    }
    sf:Hook {
        OnUpdate = function(self, time)
            self:SetVerticalScroll(self:GetVerticalScroll() + scrollSpeed*time*512)
            if scrollSpeed > 0 then
                scrollSpeed = math.max(0, scrollSpeed - (4 + math.abs(scrollSpeed*5))*time)
            else
                scrollSpeed = math.min(0, scrollSpeed + (4 + math.abs(scrollSpeed*5))*time)
            end
        end,
	    OnVerticalScroll = function(parent, offset)
		    scroll:SetHitRectInsets(0, 0, offset, (scroll:GetHeight() - offset - parent:GetHeight()))
	    end
    }

    scroll:SetWidth(sf:GetWidth())
    scroll:SetHeight(200)
    scroll:EnableMouse(true)

    sf:SetScrollChild(scroll)

    scroll.children = {}

    local toplevel = {}
    for v, _ in pairs(GetUIParentChildren()) do
        table.insert(toplevel, v)
    end
    table.sort(toplevel, function(a, b)
        return (a:GetName() or '') < (b:GetName() or '')
    end)

    local lastText = nil
    for _, c in pairs(toplevel) do
        -- local btn = CreateFrame('button', nil, frame, "UIPanelCloseButton")

        local btn = CreateFrame('Button', nil, scroll, 'UIPanelButtonTemplate')
        btn:SetText((c:GetName() or 'nil') .. ' ' .. c:GetObjectType())
        btn:SetWidth(sf:GetWidth() - 20)
        btn:Show()

        btn:Script {
            OnEnter = function()
                if c:GetTop() and c ~= hoverFrame then
                    hoverFrame:SetAllPoints(c)
                    hoverFrame:Show()
                end
            end,

            OnLeave = function()
                hoverFrame:SetAllPoints(frame)
                hoverFrame:Hide()
            end,

            OnMouseDown = function(self, _, button)
                if button == 'RightButton' then
                    if c:IsShown() then
                        c:Hide()
                    else
                        c:Show()
                    end
                end
            end
        }

        local text = btn:GetFontString()
        text:ClearAllPoints()
        text:SetPoint('LEFT', btn, 'LEFT', 10, 0)
        
        if not c:IsShown() then
            text:SetTextColor(0.7, 0.7, 0.7)
        end

        if lastText then
            btn:SetPoint('TOPLEFT', lastText, 'BOTTOMLEFT', 0, -0)
        else
            btn:SetPoint('TOPLEFT', scroll, 'TOPLEFT', 10, -0)
        end
        lastText = btn

        -- local titleText = scroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        -- -- titleText:SetText(c:GetObjectType() .. c:GetName())
        -- print(c)
        -- titleText:SetText((c:GetName() or 'nil') .. ' ' .. c:GetObjectType())
        -- titleText:Show()
        -- if lastText then
        --     titleText:SetPoint('TOPLEFT', lastText, 'BOTTOMLEFT', 0, -10)
        -- else
        --     titleText:SetPoint('TOPLEFT', scroll, 'TOPLEFT', 10, -10)
        -- end
        -- lastText = titleText

    end

    frame:SetBackdrop({
        -- bgFile = "Interface/ACHIEVEMENTFRAME/UI-GuildAchievement-Parchment",
        bgFile = 'Interface/HELPFRAME/DarkSandstone-Tile',
        edgeFile = "Interface/FriendsFrame/UI-Toast-Border",
        edgeSize = 12,
        tile = true,
        tileSize = 300,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:Show()

end


SlashCmdList['GUITREE'] = function(msg, editbox)
    
    if frame then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    else
        spawn()
    end

end



