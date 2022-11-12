
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

SilverUI.RegisterScript(
    'Silver UI',
    'Player Frame',
    {
        enabled = true
    },
[[

local     PARENT,     Style,     Frame,     Texture,     MaskTexture,     AnimationGroup,     Animation
    = LQT.PARENT, LQT.Style, LQT.Frame, LQT.Texture, LQT.MaskTexture, LQT.AnimationGroup, LQT.Animation


local StylePlayerFrame = Style
    :Size(300, 300/4)
{
    Frame'.SilverUI'
        :AllPoints(PlayerFrame)   
        :FrameLevel(10)
    {
        Texture'.BarOverlay'
            :Texture 'Interface/AddOns/silver-ui/art/playerframe'
            :AllPoints(PlayerFrame)
            :VertexColor(0.1, 0.1, 0.1, 0.7)
    },
    Frame'.SilverUIBg'
        :AllPoints(PlayerFrame)
        :FrameLevel(0)
    {
        Texture'.BarBackground'
            :AllPoints(PlayerFrame)
            :Texture 'Interface/AddOns/silver-ui/art/playerframe-bg'
            :VertexColor(0.1, 0.1, 0.1, 0.9)
    },
    Style'.PlayerFrameContainer':Hide(),
    Style'.PlayerFrameContent' {
        Style'.PlayerFrameContentMain' {
            Style'.StatusTexture':Texture '',
            Style'.PlayerName':Hide(),
            Style'.PlayerLevelText':Hide(),
            Style'.PlayerHitIndicator':Scale(0.3),
            
            Style'.HealthBarMask'
                :Show()
                :Texture'Interface/AddOns/silver-ui/art/playerframe-hp-mask'
                :AllPoints(PlayerFrame),
            Style'.HealthBarArea' {
                Style'.PlayerFrameHealthBar'
                    :Points {
                        TOPLEFT = PlayerFrame:TOPLEFT(21, -38.5),
                        BOTTOMRIGHT = PlayerFrame:BOTTOMRIGHT(-21, 21.5)
                    }
                {
                    Style'.FontString':Scale(0.9),
                    Style'.LeftText':Points { LEFT = PARENT:LEFT(10, 0) },
                    Style'.RightText':Points { RIGHT = PARENT:RIGHT(-10, 0) }
                }
            },

            Style'.ManaBarMask'
                :Show()
                :Texture 'Interface/AddOns/silver-ui/art/playerframe-power-mask'
                :AllPoints(PlayerFrame),
            Style'.ManaBarArea' {
                Style'.PlayerFrameManaBar'
                    :Points {
                        TOPLEFT = PlayerFrame:TOPLEFT(31.5, -26),
                        BOTTOMRIGHT = PlayerFrame:BOTTOMRIGHT(-31.5, 39)
                    }
                {
                    Style'.FontString':Scale(0.8),
                    Style'.LeftText':Points { LEFT = PARENT:LEFT(10, 0) },
                    Style'.RightText':Points { RIGHT = PARENT:RIGHT(-10, 0) }
                }
            }

        },
        Style'.PlayerFrameContentContextual' {
            Style'.PlayerPortraitCornerIcon':Hide(),
            Style'.PlayerRestLoop'
                :Points {
                    BOTTOMLEFT = PlayerFrame:TOPRIGHT(-31, -32)
                },
            Style'.PrestigePortrait'
                :Points {
                    BOTTOMRIGHT = PlayerFrame:TOPLEFT(33, -48)
                }
                :Size(32, 32),
            Style'.PrestigeBadge'
                :Size(20, 20),
            Style'.PlayerRoleIcon'
                :Points { RIGHT = PARENT.GroupIndicator:LEFT() },
        }
    },

    Style'.PlayerFrameBottomManagedFramesContainer'
        :Points { TOP = PlayerFrame:BOTTOM(0, 22) }
    {
        Style'.*'
            :Scale(0.7)
    },

    Frame'.Gcd'
        :FrameLevel(11)
        :Points { TOPLEFT = PlayerFrame:TOPLEFT(33, -35),
                    BOTTOMLEFT = PlayerFrame:TOPLEFT(33, -39) }
        :Scripts {
            OnUpdate = function(self)
                local gcdStart, gcdDuration = GetSpellCooldown(61304)
                local gcdNow = gcdStart + gcdDuration - GetTime()
                local endCast = select(5, UnitCastingInfo('player')) or select(5, UnitChannelInfo('player'))
                if gcdNow > 0 and (not endCast or endCast/1000 < gcdStart + gcdDuration) then
                    local parent = self:GetParent()
                    self:SetWidth((1 - gcdNow/gcdDuration)*parent:GetWidth()-60)
                else
                    self:SetWidth(0)
                    self:Hide()
                end
            end
        }
        :Events {
            SPELL_UPDATE_COOLDOWN = function(self, ...)
                local gcdStart, gcdDuration = GetSpellCooldown(61304)
                if gcdStart + gcdDuration > GetTime() then
                    local endCast = select(5, UnitCastingInfo('player')) or select(5, UnitChannelInfo('player'))
                    if not endCast or endCast/1000 < gcdStart + gcdDuration then
                        self:Show()
                    end
                end
            end
        }
    {
        Texture'.GcdSpark'
            -- :Texture 'Interface/CastingBar/UI-CastingBar-Spark'
            :Texture 'Interface/UNITPOWERBARALT/Generic1Target_Horizontal_Spark'
            :Width(20)
            :BlendMode 'ADD'
            .init(function(self, parent)
                self:SetPoints {
                    TOP = parent:TOPRIGHT(),
                    BOTTOM = parent:BOTTOMRIGHT()
                }
            end)
    }
}


local function update()
    StylePlayerFrame(PlayerFrame)
end

-- hooksecurefunc('PlayerFrame_ToVehicleArt', update)
hooksecurefunc('PlayerFrame_ToPlayerArt', update)
hooksecurefunc('PlayerFrame_UpdateArt', update)
hooksecurefunc('PlayerFrame_UpdateStatus', update)
hooksecurefunc('PlayerFrame_UpdateRolesAssigned', update)

update()


-- Cast Bar

local Hide = Style:Hide()


local StyleCastBar = Style -- need to wait until PLAYER_ENTERING_WORLD, otherwise edit mode breaks
    .filter(function(self)
        return self.attachedToPlayerFrame and not self.Selection:IsShown()
    end)
    :FrameLevel(11)
    :Points { TOPLEFT = PlayerFrame:TOPLEFT(26, -35),
              BOTTOMRIGHT = PlayerFrame:BOTTOMRIGHT(-26, 35) }
{
    Hide'.Icon',
    Hide'.Border',
    Hide'.Background',
    Hide'.EnergyGlow':Texture '',
    Style'.Text'
        :Scale(0.8)
        :Points { TOP = PARENT:TOP() },
    MaskTexture'.BarMask'
        :Texture 'Interface/AddOns/silver-ui/art/playerframe-castbar-mask'
        :AllPoints(PlayerFrame),
    Style'.Texture:NOATTR:NONAME' {
        function(self)
            if not self.HasMask then
                self:AddMaskTexture(self:GetParent().BarMask)
                self.HasMask = true
            end
        end
    }
}
    .reapply('UNIT_SPELLCAST_START', function(self, unit) return unit == 'player' end)
    .reapply('UNIT_SPELLCAST_CHANNEL_START', function(self, unit) return unit == 'player' end)


Frame
    :Events {
        PLAYER_ENTERING_WORLD = function()
            StyleCastBar(PlayerCastingBarFrame)
        end
    }
    .new()


hooksecurefunc(EditModeManagerFrame, 'EnterEditMode', function()
    PlayerCastingBarFrame:ResetToDefaultPosition()
    EditModeManagerFrame:SetHasActiveChanges(false);
end)


-- XP/rep bars

hooksecurefunc(StatusTrackingBarManager, 'UpdateBarsShown', function()
    StatusTrackingBarManager:Hide()
end)


]]
)