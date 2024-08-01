-- Version 1.0 of InstantLogicGate by HerrVincling, 25.08.2021

ChatLog = class( nil )
ChatLog.maxChildCount = 0
ChatLog.maxParentCount = 0
ChatLog.connectionInput = sm.interactable.connectionType.logic
ChatLog.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
ChatLog.colorNormal = sm.color.new(0xffffffff)
ChatLog.colorHighlight = sm.color.new(0x00000000)

--GenericClass.poseWeightCount = 1

--[[ client ]]
function ChatLog.client_onCreate(self )
end

function ChatLog.client_onRefresh(self )
    self:client_onCreate()
end

function ChatLog.client_onUpdate(self, deltaTime )
end

function ChatLog.client_onDestroy(self)
    if ChatLog.logger == nil then
        sm.gui.displayAlertText("Tool messages now show up here")
    end
end

--[[ server ]]
function ChatLog.server_onCreate(self )
    if ChatLog.logger then
        ChatLog.logger.shape:destroyPart()
    else
        sm.gui.chatMessage("Tool messages now show up here")
    end
    ChatLog.logger = self
end

function ChatLog.server_onRefresh(self )
    self:server_onCreate()
end

function ChatLog.server_onFixedUpdate(self, deltaTime )
    ChatLog.exists = true
end

function ChatLog.server_onDestroy(self )
    ChatLog.exists = false
    if ChatLog.logger == self then
        ChatLog.logger = nil
    end
end