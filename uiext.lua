local _, ns = ...

ns.uiext = {}
local uiext = ns.uiext

local method_chain_wrapper = ns.util.method_chain_wrapper
local values = ns.util.values

local CORNER_TO_VEC = {
    TOPLEFT = { 1, -1 },
    TOPRIGHT = { -1, -1 },
    BOTTOMLEFT = { 1, 1 },
    BOTTOMRIGHT = { -1, 1 },
    TOP = { 0, 1 },
    BOTTOM = { 0, -1 },
    LEFT = { -1, 0 },
    RIGHT = { 1, 0 },
    CENTER = { 0, 0 }
}


function uiext:FitToChildren()
    local height = 0
    local parent_top = self:GetTop()
    if parent_top then
        for child in self'.*' do
            if child:IsShown() and (child:GetObjectType() ~= "Frame" or child:GetChildren() or child:GetRegions()) then
                local bottom = child:GetBottom()
                if bottom and parent_top-bottom > height then
                    height = parent_top-bottom
                end
            end
        end
        self:SetHeight(height)
    end
end


function uiext:FitToChildren2()
    -- top-to-bottom only
    local max_bottom = 0
    local anchors = {}
    -- print('FitToChildren', self:GetName())
    for child in self'.*' do
        if child:GetObjectType() ~= "Frame" or child:GetChildren() or child:GetRegions() then
            local from, target, to, local_x, local_y = child:GetPoint()
            if to then
                local top, height, bottom = 0, child:GetHeight(), 0
                if target == self then
                    top = local_y
                    bottom = local_y - height
                else
                    local target_rect = anchors[target] or { y=0, h=0 }
                    top = (target_rect.y - target_rect.h*CORNER_TO_VEC[to][2]) + local_y
                    bottom = top - height
                end
                anchors[child] = { y = top, h = height }
                -- print(' -', child:GetObjectType(), child:GetName(), height, top, bottom)
                if child:IsVisible() and bottom < max_bottom then
                    max_bottom = bottom
                end
            end
        end
    end
    print(max_bottom)
    self:SetHeight(-max_bottom)
end


function uiext:CornerOffset(x, y)
    local from, parent, to, _, _ = self:GetPoint()
    local offset = CORNER_TO_VEC[to]
    self:SetPoint(from, parent, to, offset[1]*x, offset[2]*y)
end

-- function uiext:SetHide(bool)
--     if bool then self:Hide() else self:Show() end
-- end

-- function uiext:SetShow(bool)
--     if bool then self:Show() else self:Hide() end
-- end

function uiext:Points(points)
    self:ClearAllPoints()
    for k, v in pairs(points) do
        self:SetPoint(k, unpack(v))
    end
end


uiext.SetPoints = uiext.Points


function uiext:LEFT(x, y)
    return { assert(self), 'LEFT', x, y }
end

function uiext:TOPLEFT(x, y)
    return { assert(self), 'TOPLEFT', x, y }
end

function uiext:BOTTOMLEFT(x, y)
    return { assert(self), 'BOTTOMLEFT', x, y }
end

function uiext:RIGHT(x, y)
    return { assert(self), 'RIGHT', x, y }
end

function uiext:TOPRIGHT(x, y)
    return { assert(self), 'TOPRIGHT', x, y }
end

function uiext:BOTTOMRIGHT(x, y)
    return { assert(self), 'BOTTOMRIGHT', x, y }
end

function uiext:TOP(x, y)
    return { assert(self), 'TOP', x, y }
end

function uiext:BOTTOM(x, y)
    return { assert(self), 'BOTTOM', x, y }
end

function uiext:CENTER(x, y)
    return { assert(self), 'CENTER', x, y }
end



function uiext:SetLEFT(other)
    self:SetPoint('LEFT', unpack(other))
end

function uiext:SetTOPLEFT(other)
    self:SetPoint('TOPLEFT', unpack(other))
end

function uiext:SetBOTTOMLEFT(other)
    self:SetPoint('BOTTOMLEFT', unpack(other))
end

function uiext:SetRIGHT(other)
    self:SetPoint('RIGHT', unpack(other))
end

function uiext:SetTOPRIGHT(other)
    self:SetPoint('TOPRIGHT', unpack(other))
end

function uiext:SetBOTTOMRIGHT(other)
    self:SetPoint('BOTTOMRIGHT', unpack(other))
end

function uiext:SetTOP(other)
    self:SetPoint('TOP', unpack(other))
end

function uiext:SetBOTTOM(other)
    self:SetPoint('BOTTOM', unpack(other))
end

function uiext:SetCENTER(other)
    self:SetPoint('CENTER', unpack(other))
end



function uiext:Override(overrides)
    self.lqt_overrides = self.lqt_overrides or {}
    for k, new in pairs(overrides) do
        if not self.lqt_overrides[k] then
            self.lqt_overrides[k] = new
            local old = self:GetScript(k) or function() end
            self:SetScript(k, function(self, ...)
                new(self, old, ...)
            end)
        end
    end
end


function uiext:Scripts(scripts)
    for k, fn in pairs(scripts) do
        self:SetScript(k, fn)
    end
end


local chain_functions = function(t)
    local fn = nil
    for _, f in pairs(t) do
        local fn_old = fn
        if fn then
            fn = function(...)
                fn_old(...)
                f(...)
            end
        else
            fn = f
        end
    end
    return fn
end


function uiext:Hooks(hooks, context)
    self.lqtHooks = self.lqtHooks or {}
    self.lqtHookLibrary = self.lqtHookLibrary or {}
    self.lqtHookLibrary[context or '_'] = hooks
    for k, f in pairs(hooks) do
        if not self.lqtHooks[k] then
            local hooks = self.lqtHooks
            self:HookScript(k, function(self, ...)
                hooks[k](self, ...)
            end)
        end

        local build = {}
        for context, t in pairs(self.lqtHookLibrary) do
            if t[k] then
                table.insert(build, t[k])
            end
        end
        self.lqtHooks[k] = chain_functions(build)
    end
end


function uiext:UnhookAll()
    for k, f in pairs(self.lqtHooks) do
        self.lqtHooks[k] = function() end
    end
    self.lqtHookLibrary = {}
end


function uiext:Event(handlers)
    if not self.OnEventHandler then
        self.OnEventHandler = function(self, event, ...)
            local handler = self[event]
            if handler then
                handler(self, ...)
            end
        end
        self:SetScript('OnEvent', self.OnEventHandler)
    end
    for k, handler in pairs(handlers) do
        if not self[k] then
            self:RegisterEvent(k)
        end
        self[k] = handler
    end
end


function uiext:EventHook(handlers)
    if not self.OnEventHookHandler then
        self.OnEventHookHandler = function(self, event, ...)
            local handler = self[event]
            if handler then
                handler(self, ...)
            end
        end
        self:SetScript('OnEvent', self.OnEventHookHandler)
    end
    for k, handler in pairs(handlers) do
        if not self[k] then
            self:RegisterEvent(k)
        end
        self[k] = handler
    end
end


function uiext:Data(data)
    for k, v in pairs(data) do
        self[k] = v
    end
end


function uiext:Strip(...)
    if ... then
        local name = self:GetName() or ''
        for v in values({...}) do
            local obj = self[v] or _G[name .. v]
            if obj and obj.GetChildren then
                obj:Strip()
            elseif obj and obj:GetObjectType() == 'Texture' then
                obj:SetTexture('')
                obj:SetAtlas('')
            end
        end
    else
        self'.Frame':Strip()
        self'.Texture':SetTexture(''):SetAtlas('')
    end
end


for _, v in pairs({
    CreateFrame('Frame'),
    CreateFrame('ScrollFrame'),
    CreateFrame('Button'),
    CreateFrame('Slider'),
    CreateFrame('StatusBar'),
    CreateFrame('CheckButton'),
    CreateFrame('EditBox'),
    CreateFrame('Cooldown'),
    CreateFrame('SimpleHTML'),
    CreateFrame('Frame'):CreateTexture(),
    CreateFrame('Frame'):CreateFontString(),
    CreateFrame('Frame'):CreateMaskTexture()
}) do
    v:Hide()
    local meta = getmetatable(v)
    for k_ext, v_ext in pairs(uiext) do
        meta.__index[k_ext] = v_ext
    end
end

for _, v in pairs {
    Minimap,
    GameTooltip
} do
    local mt = getmetatable(v)
    for k_ext, v_ext in pairs(uiext) do
        mt.__index[k_ext] = v_ext
    end
end