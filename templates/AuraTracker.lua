---@class Addon
local Addon = select(2, ...)

local LQT = Addon.LQT
local Hook = LQT.Hook
local UnitEvent = LQT.UnitEvent
local Style = LQT.Style


---@class Addon.Templates
Addon.Templates = Addon.Templates or {}


local function CheckUnitAuras(self, unit)
    local ADD = 1
    local KEEP = 2
    local UPDATE = 3
    local REMOVE = 4

    for _, v in pairs(self.trackedAuras) do
        v[1] = REMOVE
    end
    for _, filter in pairs { 'HELPFUL', 'HARMFUL' } do
        local i = 1 ---@type integer?
        while i do
            local
                name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal,
                spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod
                    = UnitAura(unit, i, filter)
            if name then
                local instance = string.format('%s/%s/%s/%i/%s', unit, filter, name, icon, source or '')
                if self.trackedAuras[instance] then
                    local aura = self.trackedAuras[instance]
                    if
                        aura.icon ~= icon
                        or aura.applications ~= (count or 0)
                        or aura.duration ~= duration
                        or aura.expirationTime ~= expirationTime
                        or aura.index ~= i
                    then
                        aura[1] = UPDATE
                        aura.icon = icon
                        aura.applications = count or 0
                        aura.duration = duration
                        aura.expirationTime = expirationTime
                        aura.index=i
                    else
                        aura[1] = KEEP
                    end
                else
                    self.trackedAuras[instance] = {
                        ADD,
                        auraInstanceID=instance,
                        isHelpful=filter == 'HELPFUL',
                        isHarmful=filter == 'HARMFUL',
                        isStealable=isStealable,
                        source=source,
                        icon=icon,
                        applications=count or 0,
                        duration=duration,
                        expirationTime=expirationTime,
                        spellId=spellId,

                        index=i,
                        filter=filter,
                    }
                end
                i = i+1
            else
                i = nil
            end
        end
    end
    for k, v in pairs(self.trackedAuras) do
        if v[1] == ADD then
            self:AuraAdd(k, v)
        elseif v[1] == UPDATE then
            self:AuraUpdate(k, v)
        elseif v[1] == REMOVE then
            self:AuraRemove(k, v)
            self.trackedAuras[k] = nil
        end
    end
end



Addon.Templates.AuraTracker = Style {

    AuraAdd = function(self, instance, aura) end,
    AuraUpdate = function(self, instance, aura) end,
    AuraRemove = function(self, instance) end,

    trackedAuras = {},

    [UnitEvent.UNIT_AURA] = CheckUnitAuras,
    [Hook.SetEventUnit] = CheckUnitAuras

}
