-- StepButton.lua by HerrVincling, 05.06.2022

StepButton = class( nil )
StepButton.maxChildCount = 0
StepButton.maxParentCount = 0
StepButton.connectionInput = sm.interactable.connectionType.none
StepButton.connectionOutput = sm.interactable.connectionType.none -- none, logic, power, bearing, seated, piston, any
StepButton.colorNormal = sm.color.new(0x26BF26ff)
StepButton.colorHighlight = sm.color.new(0x41D841ff)

StepButton.poseWeightCount = 1
dofile("controller.lua")

--[[ client ]]
function StepButton.client_onInteract(self, character, state )
    if state then
        sm.audio.play("Button on", self.shape.worldPosition)
        self.interactable:setPoseWeight(0, 1)
        self.network:sendToServer("sv_makeStep", {})
    else
        sm.audio.play("Button off", self.shape.worldPosition)
        self.interactable:setPoseWeight(0, 0)
    end
end

function StepButton.client_onTinker(self, character, state)
    if state then
        self.network:sendToServer("sv_changeSpeed", character:isCrouching())
    end
end


--[[ server ]]
function StepButton.sv_changeSpeed(self, crouching)
    if crouching then
        if controllerspeed > 1 then
            controllerspeed = controllerspeed / 2
        else
            controllerspeed = 0
        end
    else
        if controllerspeed >= 1 then
            controllerspeed = controllerspeed * 2
        else
            controllerspeed = 1
        end
    end
    controller_saveSpeed()
    if controllerspeed == 0 then
        sm.gui.chatMessage("Speed Factor: Single Step")
    else
        sm.gui.chatMessage("Speed Factor: " .. tostring(controllerspeed) .. "x")
    end
    --print(controllerspeed)
end

function StepButton.sv_makeStep(self, _)
    if controllerspeed > 0 then
        controllerspeed = 0
        sm.gui.chatMessage("Speed Factor: Single Step")
    end
    controller2(1)
end

function StepButton.server_onFixedUpdate(self, deltaTime )
    if controllerlastupdate ~= sm.game.getCurrentTick() then
        local a = controller2(controllerspeed)
    end
end