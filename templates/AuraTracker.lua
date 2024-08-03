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

    for k, _ in pairs(self.aurasTracked) do
        self.aurasTracked[k] = REMOVE
    end
    for _, filter in pairs { 'HELPFUL', 'HARMFUL' } do
        local i = 1 ---@type integer?
        while i do
            local info = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
            if info then
                if self.aurasTracked[info.auraInstanceID] then
                    local current = self.aurasData[info.auraInstanceID]
                    if
                        current.icon ~= info.icon
                        or current.applications ~= (info.charges or 0)
                        or current.duration ~= info.duration
                        or current.expirationTime ~= info.expirationTime
                    then
                        self.aurasTracked[info.auraInstanceID] = UPDATE
                        self.aurasData[info.auraInstanceID] = info
                    else
                        self.aurasTracked[info.auraInstanceID] = KEEP
                    end
                else
                    self.aurasTracked[info.auraInstanceID] = ADD
                    self.aurasData[info.auraInstanceID] = info
                end
                i = i+1
            else
                i = nil
            end
        end
    end
    for instance, action in pairs(self.aurasTracked) do
        if action == ADD then
            self:AuraAdd(instance, self.aurasData[instance])
        elseif action == UPDATE then
            self:AuraUpdate(instance, self.aurasData[instance])
        elseif action == REMOVE then
            self:AuraRemove(instance, self.aurasData[instance])
            self.aurasTracked[instance] = nil
            self.aurasData[instance] = nil
        end
    end
end



Addon.Templates.AuraTracker = Style { LQT.UnitEventBase } {

    AuraAdd = function(self, instance, aura) end,
    AuraUpdate = function(self, instance, aura) end,
    AuraRemove = function(self, instance) end,

    aurasTracked = {},
    aurasData = {},

    [UnitEvent.UNIT_AURA] = CheckUnitAuras,
    [Hook.SetEventUnit] = CheckUnitAuras

}
