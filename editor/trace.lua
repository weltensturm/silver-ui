local ADDON, Addon = ...


local FrameSmoothScroll = Addon.FrameSmoothScroll


local     Style,     Frame,     Button,     Texture,     FontString,     EditBox,     ScrollFrame,
          SELF,     PARENT,     ApplyFrameProxy,     FrameProxyMt
    = LQT.Style, LQT.Frame, LQT.Button, LQT.Texture, LQT.FontString, LQT.EditBox, LQT.ScrollFrame,
      LQT.SELF, LQT.PARENT, LQT.ApplyFrameProxy, LQT.FrameProxyMt


local tuples = Addon.util.tuples


local FrameTracer = Frame
    .init {
        function(self, parent) self.parent = parent end,
        SetData = function(self, tracer)
            local frameName = tracer[2] and (tracer[2]:GetName() or tracer[2]:GetDebugName()) or ''
            self.Name:SetText(frameName .. '/' .. tracer[3])
            local text = ''
            for _, stack in pairs(tracer[4]) do
                text = text .. stack[2] .. 'x\n' .. stack[1] .. '\n'
            end
            self.Traces:SetText(text)
            self:SetHeight(self.Traces:GetHeight() + self.Name:GetHeight())
        end
    }
{
    FontString'.Name'
        :Font('Fonts/FRIZQT__.ttf', 12, '')
        :Points { TOPLEFT = PARENT:TOPLEFT(10, 0), TOPRIGHT = PARENT:TOPRIGHT(-10, 0) }
        :JustifyH 'LEFT'
        :Height(16),
    EditBox'.Traces'
        :Font('Interface/AddOns/silver-ui/Fonts/iosevka-regular.ttf', 11, '')
        -- :Size(400, 400)
        :Points { TOPLEFT = PARENT.Name:BOTTOMLEFT(), RIGHT = PARENT:RIGHT(200, 0) }
        :JustifyH 'LEFT'
        :JustifyV 'TOP'
        :MultiLine(true)
        :AutoFocus(false)
}



local FrameTraceWindow = FrameSmoothScroll
    .init {
        tracers = {},
        update = false,
        StartTrace = function(self, frameOrFunctionName, functionName)
            local frame
            if functionName then
                frame = frameOrFunctionName
            else
                functionName = frameOrFunctionName
            end
            assert(trace == nil or frame[functionName], 'Frame has no function ' .. functionName)
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
            self:GetTrace(frame, funcitonName)[1] = false
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
                    self.update = true
                    return
                end
            end
            table.insert(stacks, {
                newStack,
                1
            })
            self.update = true
        end
    }
    :Hooks {
        OnUpdate = function(self)
            if self.update then
                self.update = false
                self.Content'.Tracer#':SetPoints {}:Hide()
                local previous = nil
                for i, tracer in pairs(self.tracers) do
                    self.Content {
                        FrameTracer('.Tracer' .. i)
                            :Points(previous and { TOPLEFT = previous:BOTTOMLEFT(), TOPRIGHT = previous:BOTTOMRIGHT() }
                                              or { TOPLEFT = self.Content:TOPLEFT(), TOPRIGHT = self.Content:TOPRIGHT() })
                            :Data(tracer)
                            :Show()
                    }
                    previous = self.Content['Tracer' .. i]
                end
                if #self.tracers > 0 then
                    self.NoTracers:Hide()
                end
            end
        end
    }
{
    FontString'.NoTracers'
        :Font('Fonts/FRIZQT__.ttf', 12, '')
        :Points { TOPLEFT = PARENT:TOPLEFT(10, -10), TOPRIGHT = PARENT:TOPRIGHT(-10, -10) }
        :Text 'No traces running.\nYou can start one by right clicking a function in the frame inspector,\nor by calling trace([frame,] functionName)',

}


Addon.FrameTraceWindow = FrameTraceWindow

