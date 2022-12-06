
if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end


local
    PARENT,
    Style,
    Frame,
    CheckButton,
    Texture,
    MaskTexture,
    FontString,
    AnimationGroup,
    Animation
    =   LQT.PARENT,
        LQT.Style,
        LQT.Frame,
        LQT.CheckButton,
        LQT.Texture,
        LQT.MaskTexture,
        LQT.FontString,
        LQT.AnimationGroup,
        LQT.Animation


local db
local load


SilverUI.Storage {
    name = 'Player Frame',
    character = {
        enabled = true
    },
    onload = function(account, character)
        db = character
        if character.enabled then
            load()
        end
    end
}


SilverUI.Settings 'Player Frame' {

    Frame:Size(4, 4),

    FontString
        :Font('Fonts/FRIZQT__.ttf', 16, '')
        :TextColor(1, 0.8196, 0)
        :Text 'Player Frame',

    CheckButton
        :Size(24, 24)
        :NormalTexture 'Interface/Buttons/UI-CheckBox-Up'
        :PushedTexture 'Interface/Buttons/UI-CheckBox-Down'
            :HighlightTexture 'Interface/Buttons/UI-CheckBox-Highlight'
        :CheckedTexture 'Interface/Buttons/UI-CheckBox-Check'
        :DisabledCheckedTexture 'Interface/Buttons/UI-CheckBox-Check-Disabled'
        :HitRectInsets(-4, -100, -4, -4)
        :Hooks {
            OnClick = function(self)
                db.enabled = self:GetChecked()
            end
        }
    {
        function(self)
            self:SetChecked(db.enabled)
        end,
        FontString'.Label'
            .LEFT:RIGHT()
            :Font('Fonts/FRIZQT__.ttf', 12, '')
            :Text 'Enable'
    }

}


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
            Style'.TotalAbsorbBar':SetVertexColor(1,1,1),
            Style'.TotalAbsorbBar.overlay':SetVertexColor(1,1,1),
            
            Style'.HealthBarArea' {
                Style'.HealthBar'
                    .TOPLEFT:TOPLEFT(PlayerFrame, 21, -38.5)
                    .BOTTOMRIGHT:BOTTOMRIGHT(PlayerFrame, -21, 21.5)
                {
                    Style'.FontString':Scale(0.9),
                    Style'.LeftText'.LEFT:LEFT(10, 0),
                    Style'.RightText'.RIGHT:RIGHT(-10, 0),
                    Style'.HealthBarMask'
                        :Show()
                        :Texture'Interface/AddOns/silver-ui/art/playerframe-hp-mask'
                        :AllPoints(PlayerFrame),
                }
            },

            Style'.ManaBarArea' {
                Style'.ManaBar'
                    -- :StatusBarTexture 'Interface/RAIDFRAME/Raid-Bar-Hp-Fill'
                    -- :StatusBarColor(1, 1, 0)
                    .TOPLEFT:TOPLEFT(PlayerFrame, 31.5, -26)
                    .BOTTOMRIGHT:BOTTOMRIGHT(PlayerFrame, -31.5, 39)
                {
                    Style'.FontString':Scale(0.8),
                    Style'.LeftText'.LEFT:LEFT(10, 0),
                    Style'.RightText'.RIGHT:RIGHT(-10, 0),
                    Style'.ManaBarMask'
                        :Show()
                        :Texture 'Interface/AddOns/silver-ui/art/playerframe-power-mask'
                        :AllPoints(PlayerFrame),
                }
            }

        },
        Style'.PlayerFrameContentContextual' {
            Style'.PlayerPortraitCornerIcon':Hide(),
            Style'.PlayerRestLoop'
                .BOTTOMLEFT:TOPRIGHT(PlayerFrame, -31, -32),
            Style'.PrestigePortrait'
                .BOTTOMRIGHT:TOPLEFT(PlayerFrame, 33, -48)
                :Size(32, 32),
            Style'.PrestigeBadge'
                :Size(20, 20),
            Style'.RoleIcon'
                .RIGHT:LEFT(PARENT.GroupIndicator),
        }
    },

    Style'.PlayerFrameBottomManagedFramesContainer' {
        Style'.PlayerFrameAlternateManaBar' {
            Style'.DefaultBorder*'
                :VertexColor(0.1, 0.1, 0.1, 0.7)
        },
        Style'.PaladinPowerBarFrame' {
            Style'.Texture:NOATTR':VertexColor(0.1, 0.1, 0.1, 0.7),
            Style'.bankBG':VertexColor(0.1, 0.1, 0.1, 0.7)
        },
        Style'.MageArcaneChargesFrame'
            .TOP:BOTTOM(PlayerFrame, 0, 30)
            :Scale(0.7),
    }
        .reapply('PlayerFrame_AdjustAttachments'),

    Frame'.Gcd'
        :FrameLevel(11)
        .TOPLEFT:TOPLEFT(33, -35)
        .BOTTOMLEFT:TOPLEFT(33, -39)
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
            .TOP:TOPRIGHT()
            .BOTTOM:BOTTOMRIGHT()
    }
}
    .reapply('PlayerFrame_ToPlayerArt')
    .reapply('PlayerFrame_UpdateArt')
    .reapply('PlayerFrame_UpdateStatus')
    .reapply('PlayerFrame_UpdateRolesAssigned')


-- Cast Bar

local Hide = Style:Hide()


local SetPoint = getmetatable(PlayerCastingBarFrame).__index.SetPoint

local function SetPointHack(self)
    SetPoint(self, 'TOPLEFT', PlayerFrame, 'TOPLEFT', 26, -35)
    SetPoint(self, 'BOTTOMRIGHT', PlayerFrame, 'BOTTOMRIGHT', -26, 35)
end


local StyleCastBar = Style
    .filter(function(self)
        return self.attachedToPlayerFrame ~= false and not self.Selection:IsShown()
    end)
    -- .data { system = nil }
    :FrameLevel(11)
    { SetPointHack }
    -- :PointBase('TOPLEFT', PlayerFrame, 'TOPLEFT', 26, -35)
    -- :PointBase('BOTTOMRIGHT', PlayerFrame, 'BOTTOMRIGHT', -26, 35)
    .reapply('PlayerFrame_AdjustAttachments')
{
    Hide'.Icon':Alpha(0),
    Style'.Text'
        :Scale(0.8)
        .TOP:TOP(),
    MaskTexture'.BarMask'
        :Texture 'Interface/AddOns/silver-ui/art/playerframe-castbar-mask'
        :AllPoints(PlayerFrame),
    Style'.Texture' {
        function(self)
            if not self.maskApplied and self ~= self:GetParent().Spark then
                self:AddMaskTexture(self:GetParent().BarMask)
                self.maskApplied = true
            end
        end
    }
}
    .reapply('UNIT_SPELLCAST_START', function(self, unit) return unit == 'player' end)
    .reapply('UNIT_SPELLCAST_CHANNEL_START', function(self, unit) return unit == 'player' end)



load = function()
    StylePlayerFrame(PlayerFrame)
    StyleCastBar(PlayerCastingBarFrame)
        
    -- XP/rep bars
    hooksecurefunc(StatusTrackingBarManager, 'UpdateBarsShown', function()
        StatusTrackingBarManager:Hide()
    end)
end