local _, ns = ...
local lqt = ns.lqt

local Frame, Style, Cooldown, Texture, MaskTexture = lqt.Frame, lqt.Style, lqt.Cooldown, lqt.Texture, lqt.MaskTexture


-- BUFF_WARNING_TIME = 0


UIParent_UpdateTopFramePositions = function() end
UIParent_ManageFramePositions = function() end


local StyleBuffIcon = Style
    :Size(32, 32)
    :Hooks {
        OnUpdate = function(self)
            self:SetAlpha(1.0);
        end
    }
{
    MaskTexture'.Mask'
        :Texture('Interface/Masks/CircleMaskScalable')
        .init(function(self, parent)
            parent.Icon:AddMaskTexture(self)
            
            self:Points { TOPLEFT = parent:TOPLEFT(1, -1),
                          BOTTOMRIGHT = parent:BOTTOMRIGHT(-1, 1) }
        end),

    Texture'.Bg'
        .init(function(self, parent)
            self:SetAllPoints(parent)
        end)
        :Texture('Interface/Masks/CircleMaskScalable')
        :DrawLayer('BACKGROUND', 0)
        :VertexColor(0,0,0),
    
    Cooldown'.CooldownBg'
        :UseCircularEdge(true)
        -- :SwipeTexture('Interface/GUILDFRAME/GuildLogoMask_L')
        :SwipeTexture('Interface/Masks/CircleMaskScalable')
        :SwipeColor(1, 1, 1, 1)
        :DrawEdge(false)
        :FrameStrata('BACKGROUND', 1)
        :Rotation(math.rad(180))
        :HideCountdownNumbers(true)
        .init(function(self, parent)
            -- self:Points { TOPLEFT = parent:TOPLEFT(-2, 2),
            --               BOTTOMRIGHT = parent:BOTTOMRIGHT(2, -2) }
            self:SetAllPoints(parent)
        end),

    function(self)
        if self.timeLeft then
            if self.savedTime ~= self.expirationTime then
                self.savedTime = self.expirationTime
                self.CooldownBg:SetCooldown(self.expirationTime - self.timeLeft, self.timeLeft)
            end
            self.CooldownBg:Show()
            self.Bg:Hide()
        else
            self.CooldownBg:Hide()
            self.Bg:Show()
        end
    end
}


local StyleDebuffIcon = Style
    :Size(32, 32)
{
    Style'.Border':Hide(),
    
    Style'.Icon':TexCoord(0.05, 0.95, 0.05, 0.95),

    MaskTexture'.Mask'
        .init(function(self, parent)
            self:Points { TOPLEFT = parent:TOPLEFT(1, -1),
                          BOTTOMRIGHT = parent:BOTTOMRIGHT(-1, 1) }
            parent.Icon:AddMaskTexture(self)
        end)
        :Texture('Interface/Masks/CircleMaskScalable'),

    Texture'.Bg'
        .init(function(self, parent)
            self:SetAllPoints(parent)
        end)
        :Texture('Interface/Masks/CircleMaskScalable')
        :DrawLayer('BACKGROUND')
        :VertexColor(1,0,0)
}


Frame
    .init {
        update = function()

            BuffFrame:Points { TOPRIGHT = MinimapCluster:TOPLEFT(-10, -25) }

            Style(TemporaryEnchantFrame):Points {
                TOPRIGHT = MinimapCluster:TOPLEFT()
            }
        
            local sorted = {}
            local sorted_timed = {}
        
            for button in BuffFrame'.BuffButton#' do
                if button:IsVisible() then
                    if not button.Icon then
                        button.Icon = _G[button:GetName() .. 'Icon']
                    end
                    if button.timeLeft then
                        table.insert(sorted_timed, button)
                    else
                        table.insert(sorted, button)
                    end
                end
            end
        
            
            table.sort(sorted, function(a, b)
                local ascore =
                    (a.count and tonumber(a.count:GetText() or '0'))*10000000
                    + a.Icon:GetTexture()
                local bscore =
                    (b.count and tonumber(b.count:GetText() or '0'))*10000000
                    + b.Icon:GetTexture()
                return ascore < bscore
            end)
        
            for i, button in ipairs(sorted or {}) do
                button:Points { TOPRIGHT = BuffFrame:TOPRIGHT(-5 - (i-1)*40, 0) }
                StyleBuffIcon(button)
            end
        

            table.sort(sorted_timed, function(a, b)
                return a.timeLeft > b.timeLeft
            end)
        
            for i, button in ipairs(sorted_timed or {}) do
                button:Points { TOPRIGHT = BuffFrame:TOPRIGHT(-5-20 - (i-1)*40, -40) }
                StyleBuffIcon(button)
            end

            
            for i, button in ipairs(BuffFrame'.DebuffButton#') do
                if not button.Icon then
                    local name = button:GetName()
                    button.Icon = _G[name .. 'Icon']
                    button.Border = _G[name .. 'Border']
                end
                button:Points { TOPRIGHT = BuffFrame:TOPRIGHT(-5 - (i-1)*40, -80) }
                StyleDebuffIcon(button)
            end
        
        end
    }
    :EventHook {

        PLAYER_ENTERING_WORLD = function(self) self.update() end,

        UNIT_AURA = function(self, unit)
            if unit == 'player' then
                self.update()
            end
        end

    }
    .new()
