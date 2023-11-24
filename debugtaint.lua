

local function getSystem(id)
    local layout = EditModeManagerFrame:GetActiveLayoutInfo()
    for _, system in pairs(layout.systems) do
        if system.system == id then
            return system
        end
    end
end

function DebugTaint()
    for _, systemFrame in pairs(EditModeManagerFrame.registeredSystemFrames) do
        local system = getSystem(systemFrame.system)
        
        if system then
            for k, v in pairs(system.anchorInfo) do
                local secure, addon = issecurevariable(system.anchorInfo, k)
                assert(secure, (addon or 'unknown') .. ': ' .. systemFrame:GetName() .. ' anchorInfo.' .. k .. ' tainted')
            end
            for setting_k, setting in pairs(system.settings) do
                for k, v in pairs(setting) do
                    local secure, addon = issecurevariable(setting, k)
                    assert(secure, (addon or 'unknown') .. ': ' .. systemFrame:GetName() .. ' settings.' .. setting_k .. '.' .. k .. ' tainted')
                end
            end
        end

    end

end