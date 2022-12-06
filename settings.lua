local ADDON, Addon = ...


-- local OptionsPanel = CreateFrame('Frame')
local OptionsPanel = Addon.FrameSmoothScroll.new()
OptionsPanel.name = "Silver UI"
OptionsPanel.lastOption = nil
SilverUI.OptionsPanel = OptionsPanel

InterfaceOptions_AddCategory(OptionsPanel)


local settingsLoaded = false
local settings = {}


function SilverUI.Storage(table)
    if not settingsLoaded then
        settings[table.name] = { table.account or {}, table.character or {}, table.onload }
    else
        SilverUISavedVariablesAccount[table.name] = SilverUISavedVariablesAccount[table.name] or table.account or {}
        SilverUISavedVariablesCharacter[table.name] = SilverUISavedVariablesCharacter[table.name] or table.character or {}
        if settings.onload then
            settings.onload(SilverUISavedVariablesAccount[table.name], SilverUISavedVariablesCharacter[table.name])
        end
    end
end


local settingGuis = {}


function SilverUI.Settings(name)
    return function(settings)
        table.insert(settingGuis, { name, settings })
    end
end


local function buildSettings()
    for setting=1, #settingGuis do
        local name = settingGuis[setting][1]
        local settings = settingGuis[setting][2]
        local lastOption = OptionsPanel.lastOption
        for i=1, #settings do
            local Entry = settings[i]
            local entry = Entry:Parent(OptionsPanel.Content).new()
            if lastOption then
                entry:SetPoint('TOPLEFT', lastOption, 'BOTTOMLEFT', 0, -10)
            else
                entry:SetPoint('TOPLEFT', OptionsPanel.Content, 'TOPLEFT', 10, -10)
            end
            lastOption = entry
            OptionsPanel.lastOption = entry
        end
    end
end


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
    local func = assert(loadstring('return function() ' .. code .. '\n end', addon .. '/' .. script))
    func()()
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
    SilverUISavedVariablesCharacter.addons[addon].scripts[name] = { enabled = true }
    return name
end

function SilverUI.CopyScript(addon, script, settings)
    local index = 1
    local name = script.name .. ' ' .. index
    while SilverUI.HasScript(addon, name) do
        index = index + 1
        name = script.name .. ' ' .. index
    end
    table.insert(
        SilverUISavedVariablesAccount.addons[addon].scripts,
        {
            name = name,
            code = script.code,
            code_original = script.code
        }
    )
    SilverUISavedVariablesCharacter.addons[addon].scripts[name] = { enabled = settings.enabled }
    return name
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


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == "silver-ui" then
        settingsLoaded = true
        if not SilverUISavedVariablesAccount then
            SilverUISavedVariablesAccount = {}
        end
        if not SilverUISavedVariablesCharacter then
            SilverUISavedVariablesCharacter = {}
        end
        for name, s in pairs(settings) do
            local defaultAccount, defaultCharacter, callback = s[1], s[2], s[3]
            SilverUISavedVariablesAccount[name] = SilverUISavedVariablesAccount[name] or defaultAccount
            SilverUISavedVariablesCharacter[name] = SilverUISavedVariablesCharacter[name] or defaultCharacter
            if callback then
                callback(SilverUISavedVariablesAccount[name], SilverUISavedVariablesCharacter[name])
            end
        end

        buildSettings()

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

        for name, account, character in SilverUI.Addons() do
            if character.enabled then
                for _, script in pairs(account.scripts) do
                    if not character.scripts[script.name] then
                        character.scripts[script.name] = { enabled = true }
                    end
                    if character.scripts[script.name].enabled then
                        SilverUI.ExecuteScript(name, script.name, script.code)
                    end
                end
            end
        end
    end
end)

