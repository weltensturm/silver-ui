---@class Addon
local Addon = select(2, ...)

local Event, Script = Addon.LQT.Event, Addon.LQT.Script


local settingsLoaded = false


local Module = CreateFrame("Frame")
Module:RegisterEvent("ADDON_LOADED")

Module:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == "silver-ui" then
        settingsLoaded = true
        if not SilverUISavedVariablesAccount then
            SilverUISavedVariablesAccount = {}
        end
        if not SilverUISavedVariablesCharacter then
            SilverUISavedVariablesCharacter = {}
        end
    end
end)


local function FillUnsetDefaults(settings, defaults)
    for k, v in pairs(defaults) do
        if settings[k] == nil then
            settings[k] = v
        end
        if type(settings[k]) == 'table' then
            FillUnsetDefaults(settings[k], defaults[k])
        end
    end
end


---@param table table
---@return table, table
function SilverUI.Storage(table)
    if settingsLoaded then
        error('Storage needs to be declared in module root')
    end

    Module:HookScript('OnEvent', function(self, event, addon)
        if event == "ADDON_LOADED" and addon == "silver-ui" then
            local account = SilverUISavedVariablesAccount
            local character = SilverUISavedVariablesCharacter
            account[table.name] = account[table.name] or {}
            FillUnsetDefaults(account[table.name], table.account or {})
            character[table.name] = character[table.name] or {}
            FillUnsetDefaults(character[table.name], table.character or {})
            if table.onload then
                table.onload(account[table.name], character[table.name])
            end
        end
    end)

    local name = table.name;
    local db_wrapper = {
        __index = function(self, index)
            local t = _G[rawget(self, '__target')]
            if not t then
                error('Addon is not yet loaded, cannot access db.')
            end
            return t[name][index]
        end,
        __newindex = function(self, index, value)
            local t = _G[rawget(self, '__target')]
            if not t then
                error('Addon is not yet loaded, cannot access db.')
            end
            t[name][index] = value
        end
    }
    return
        setmetatable({ __target='SilverUISavedVariablesAccount' }, db_wrapper),
        setmetatable({ __target='SilverUISavedVariablesCharacter' }, db_wrapper)
end
function Addon:Storage(table)
    return SilverUI.Storage(table)
end


local settingGuis = {}


function SilverUI.Settings(name)
    return function(settings)
        table.insert(settingGuis, { name, settings })
    end
end
function Addon:Settings(name)
    return SilverUI.Settings(name)
end


SilverUI.OptionsPanel = Addon.FrameSmoothScroll {
    [Script.OnShow] = function(self)
        if not self.loaded then
            for setting=1, #settingGuis do
                local name = settingGuis[setting][1]
                local settings = settingGuis[setting][2]
                local lastOption = self.lastOption
                for i=1, #settings do
                    local WidgetDefinition = settings[i]
                    local widget = WidgetDefinition:Parent(self.Content).new()
                    if lastOption then
                        widget:SetPoint('TOPLEFT', lastOption, 'BOTTOMLEFT', 0, -10)
                    else
                        widget:SetPoint('TOPLEFT', self.Content, 'TOPLEFT', 10, -10)
                    end
                    lastOption = widget
                    self.lastOption = widget
                end
            end
            self.loaded = true
        end
    end
}
    .new()

local category = Settings.RegisterCanvasLayoutCategory(SilverUI.OptionsPanel, "Silver UI")
Settings.RegisterAddOnCategory(category)



