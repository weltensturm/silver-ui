---@class Addon
local Addon = select(2, ...)

---@type LQT
Addon.LQT = _G['LQT-1.0']
assert(Addon.LQT, 'LQT-1.0 was not detected but is required for this addon')
