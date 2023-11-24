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


local defaultScripts = {}
local defaultScriptNames = {}

function SilverUI.RegisterScript(addon, name, settings, script)
    -- TODO: handle addon
    defaultScriptNames[name] = script
    table.insert(defaultScripts, { name, script, settings })
end


function SilverUI.Addons()
    local k, v = nil, nil
    return function()
        k, v = next(SilverUISavedVariablesAccount.addons, k)
        if k ~= nil then
            return k, v, SilverUISavedVariablesCharacter.addons[k]
        end
    end
end

function SilverUI.ExecuteScript(addon, script, code)
    local func = assert(loadstring('return function(Addon) ' .. code .. '\n end', addon .. '/' .. script))
    func()(Addon)
end

function SilverUI.ResetScript(addon, script)
    assert(script.code_original)
    script.code = script.code_original
    SilverUI.ExecuteScript(addon, script.name, script.code)
end

function SilverUI.NewScript(addon)
    local index = 0
    local name = 'New script'
    while SilverUI.HasScript(addon, name) do
        index = index + 1
        name = 'New script ' .. index
    end
    table.insert(
        SilverUISavedVariablesAccount.addons[addon].scripts,
        {
            name = name,
            code = '',
            code_original = ''
        }
    )
    SilverUISavedVariablesCharacter.addons[addon].scripts[name] = { enabled = false }
    return name
end

function SilverUI.CopyScript(addon, script, settings)
    local index = 1
    local name = script.name .. ' ' .. index
    while SilverUI.HasScript(addon, name) do
        index = index + 1
        name = script.name .. ' ' .. index
    end
    local newScript = {
        name = name,
        code = script.code,
        code_original = script.code
    }
    table.insert(SilverUISavedVariablesAccount.addons[addon].scripts, newScript)
    SilverUISavedVariablesCharacter.addons[addon].scripts[name] = { enabled = settings.enabled }
    return name, newScript
end

function SilverUI.HasScript(addon, name)
    for _, script in pairs(SilverUISavedVariablesAccount.addons[addon].scripts) do
        if script.name == name then
            return true
        end
    end
end

function SilverUI.DeleteScript(addon, script)
    if not defaultScriptNames[script.name] then
        for i, v in ipairs(SilverUISavedVariablesAccount.addons[addon].scripts) do
            if v.name == script.name then
                table.remove(SilverUISavedVariablesAccount.addons[addon].scripts, i)
                break
            end
        end
        SilverUISavedVariablesCharacter.addons[addon].scripts[script.name] = nil
    end
end


function SilverUI.DeleteAllScripts()
    SilverUISavedVariablesAccount.addons = nil
    SilverUISavedVariablesCharacter.addons = nil
end


Module:HookScript('OnEvent', function(self, event, addon)
    if event == "ADDON_LOADED" and addon == "silver-ui" then

        local account = SilverUISavedVariablesAccount
        local character = SilverUISavedVariablesCharacter

        SilverUI.db = {
            account = account,
            character = character
        }
        account.addons = account.addons or {}
        character.addons = character.addons or {}
        account.addons['Silver UI'] = account.addons['Silver UI'] or { scripts = {} }
        character.addons['Silver UI'] = character.addons['Silver UI'] or { scripts = {}, enabled = true }

        for i, script in ipairs(defaultScripts) do
            local name, code, settings = script[1], script[2], script[3]

            local found = false
            for _, script in pairs(account.addons['Silver UI'].scripts) do
                if script.name == name then
                    found = true
                    script.code_original = code
                    script.imported = true
                end
            end
            if not found then
                table.insert(
                    account.addons['Silver UI'].scripts,
                    {
                        name = name,
                        code_original = code,
                        hash_original = '',
                        hash_edited = '',
                        code = code,
                        imported = true
                    }
                )
            end
            character.addons['Silver UI'].scripts[name] = character.addons['Silver UI'].scripts[name] or settings
        end

        for name, addonAccount, addonCharacter in SilverUI.Addons() do
            if addonCharacter.enabled then
                for _, script in pairs(addonAccount.scripts) do
                    if not addonCharacter.scripts[script.name] then
                        addonCharacter.scripts[script.name] = { enabled = true }
                    end
                    if addonCharacter.scripts[script.name].enabled then
                        SilverUI.ExecuteScript(name, script.name, script.code)
                    end
                end
            end
        end
    end
end)

