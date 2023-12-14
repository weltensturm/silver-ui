---@class Addon
local Addon = select(2, ...)

local FrameSmoothScroll = Addon.FrameSmoothScroll
local Event = Addon.Event

local LQT = Addon.LQT
local query = LQT.query
local Script = LQT.Script
local Style = LQT.Style
local Frame = LQT.Frame
local Texture = LQT.Texture
local FontString = LQT.FontString
local EditBox = LQT.EditBox
local PARENT = LQT.PARENT


local TraceReceived = Event()
Addon.TraceReceived = TraceReceived


local function IsUIObject(table)
    return
        type(table) == 'table'
        and table.GetObjectType
        and pcall(table.GetObjectType, table)
        and not table:IsForbidden()
end


local FrameTracer = Frame {
    function(self, parent) self.parent = parent end,
    SetData = function(self, tracer)
        local frameName = tracer[2] and IsUIObject(tracer[2]) and (tracer[2]:GetName() or tracer[2]:GetDebugName()) or 'table'
        self.Name:SetText(frameName .. '/' .. tracer[3])
        local text = ''
        for _, stack in pairs(tracer[4]) do
            text = text .. stack[2] .. 'x\n' .. stack[1] .. '\n'
        end
        self.Traces:SetText(text)
        self:SetHeight(self.Traces:GetHeight() + self.Name:GetHeight())
    end,
    Name = FontString
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 12, '')
        .TOPLEFT:TOPLEFT(10, 0)
        .TOPRIGHT:TOPRIGHT(-10, 0)
        :JustifyH 'LEFT'
        :Height(16),
    Traces = EditBox
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
        -- :Size(400, 400)
        .TOPLEFT:BOTTOMLEFT(PARENT.Name)
        .RIGHT:RIGHT(-5, 0)
        :JustifyH 'LEFT'
        :JustifyV 'TOP'
        :MultiLine(true)
        :AutoFocus(false)
    {
        shadow = Addon.BoxShadow
            :EdgeSize(4)
            :Alpha(0.5),
        bg = Texture
            :AllPoints()
            :ColorTexture(0.3, 0.3, 0.3, 0.5),
    }
}



local FrameTraceWindow = FrameSmoothScroll {
    tracers = {},
    update = false,
    StartTrace = function(self, frameOrFunctionName, functionName)
        local frame
        if functionName then
            frame = frameOrFunctionName
            assert(frame[functionName], 'Frame has no function ' .. tostring(functionName))
        else
            functionName = frameOrFunctionName
            assert(_G[functionName], 'No function ' .. tostring(functionName) .. ' found')
        end
        local tracer = self:GetTrace(frame, functionName)

        if not tracer then
            local stacks = {}
            tracer = { true, frame, functionName, stacks }
            if frame then
                hooksecurefunc(frame, functionName, function(...)
                    if tracer[1] then
                        self:LogCall(stacks, ...)
                    end
                end)
            else
                hooksecurefunc(functionName, function(...)
                    if tracer[1] then
                        self:LogCall(stacks, ...)
                    end
                end)
            end
            table.insert(self.tracers, tracer)
        end

        tracer[1] = true

        self.update = true
    end,
    GetTrace = function(self, frame, functionName)
        for _, tracer in pairs(self.tracers) do
            if frame == tracer[2] and functionName == tracer[3] then
                return tracer
            end
        end
    end,
    StopTrace = function(self, frame, functionName)
        self:GetTrace(frame, functionName)[1] = false
    end,
    StopAll = function(self, frame)
        for _, tracer in pairs(self.tracers) do
            if tracer[2] == frame then
                tracer[1] = false
            end
        end
    end,
    LogCall = function(self, stacks, ...)
        local newStack = debugstack(4)
        for _, stack in pairs(stacks) do
            if stack[1] == newStack then
                stack[2] = stack[2] + 1
                TraceReceived(stack)
                self.update = true
                return
            end
        end
        table.insert(stacks, {
            newStack,
            1
        })
        self.update = true
    end,

    [Script.OnUpdate] = function(self)
        if self.update then
            self.update = false
            query(self.Content, '.Tracer#'):Hide()
            local previous = nil
            for i, t in pairs(self.tracers) do
                Style(self.Content) {
                    ['Tracer' .. i] = FrameTracer
                        :Data(t)
                        :Show()
                }
                local tracer = self.Content['Tracer' .. i]
                if previous then
                    tracer:SetPoint('TOPLEFT', previous, 'BOTTOMLEFT')
                    tracer:SetPoint('TOPRIGHT', previous, 'BOTTOMRIGHT')
                else
                    tracer:SetPoint('TOPLEFT', self.Content, 'TOPLEFT')
                    tracer:SetPoint('TOPRIGHT', self.Content, 'TOPRIGHT')
                end
                previous = tracer
            end
            if #self.tracers > 0 then
                self.NoTracers:Hide()
            end
        end
    end,

    NoTracers = FontString
        :Font('Fonts/FRIZQT__.ttf', 12, '')
        .TOPLEFT:TOPLEFT(10, -10)
        .TOPRIGHT:TOPRIGHT(-10, -10)
        :Text 'No tracers attached.\nYou can attach one by left clicking a function in the frame inspector,\nor by calling trace([frame,] functionName)',
}


Addon.FrameTraceWindow = FrameTraceWindow

