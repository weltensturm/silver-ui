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


function uiext:Texture(name)
    self[name] = self[name] or self:CreateTexture(nil)
    return method_chain_wrapper(self[name])
end


function uiext:Script(scripts)
    self.lqt_scripts = self.lqt_scripts or {}
    for k, new in pairs(scripts) do
        if not self.lqt_scripts[k] then
            self.lqt_scripts[k] = new
            local old = self:GetScript(k) or function() end
            self:SetScript(k, function(self, ...)
                new(self, old, ...)
            end)
        end
    end
end


function uiext:Hook(hooks)
    self.lqt_hooks = self.lqt_hooks or {}
    for k, new in pairs(hooks) do
        if not self.lqt_hooks[k] then
            self.lqt_hooks[k] = new
            self:HookScript(k, function(...)
                new(...)
            end)
        end
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
    CreateFrame('CheckButton'),
    CreateFrame('EditBox')
}) do
    v:Hide()
    local meta = getmetatable(v)
    print(meta, v:GetObjectType())
    for k_ext, v_ext in pairs(uiext) do
        meta.__index[k_ext] = v_ext
    end
end
