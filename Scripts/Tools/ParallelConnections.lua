-- ParallelConnections by HerrVincling, 13.03.2022
dofile "toolslib/output.lua"
dofile "toolslib/parallel.lua"

PCS = class( nil )
PCS.maxChildCount = 0
PCS.maxParentCount = 1
PCS.connectionInput = sm.interactable.connectionType.logic
PCS.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
PCS.colorNormal = sm.color.new(0x0A3EE2ff)
PCS.colorHighlight = sm.color.new(0x4C6FE3ff)
--GenericClass.poseWeightCount = 1

--[[ client ]]
function PCS.client_onCreate(self )
end

function PCS.client_onRefresh(self )
 self:client_onCreate()
end

function PCS.client_onUpdate(self, deltaTime )
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6 + self.mode)
    else
        self.interactable:setUvFrameIndex(0 + self.mode)
    end
end

function PCS.client_onInteract(self, character, state )
    self.character = character:getPlayer()
    if state then
        self.active = not self.active
    end
end

function PCS.client_canInteract(self )
    local namestr = "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Parallel Connect</p>"
    sm.gui.setInteractionText("", namestr)
    if self.interactable.active then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true), "Deactivate")
    else
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true), "Activate")
    end
    return true
end

function PCS.client_displayAlert(self, message)
    sm.gui.displayAlertText(message)
end



--[[ server ]]
function PCS.server_onCreate(self )
    self.mode = 0
    self.active = false
    self.tool = "Parallel Connect"
end

function PCS.server_onRefresh(self )
    dofile "output.lua"
    dofile "parallel.lua"
    self:server_onCreate()
end

function PCS.server_onFixedUpdate(self, deltaTime )
    local parents = self.interactable:getParents()
    local active = false
    for _, parent in pairs(parents) do
        if parent:isActive() then
            active = true
        end
    end
    if active then
        if not self.wasactive then
            self.active = not self.active
            self.wasactive = true
        end
    else
        self.wasactive = false
    end

    self.interactable.active = self.active
    if self.active then
        self:server_applyTool()
    end
end

function PCS.server_applyTool(self )
    local func = function(self, i0, i1, black, white)
        local connections = 0
        for i = 1, #black, 1 do
            local ichilds = black[i]:getChildren()
            local existingconnectionout = {}
            for _, child in pairs(ichilds) do
                existingconnectionout[child:getId()] = true
            end
            local iparents = black[i]:getParents()
            local existingconnectionin = {}
            for _, parent in pairs(iparents) do
                existingconnectionin[parent:getId()] = true
            end
            if not existingconnectionout[white[i]:getId()] and not existingconnectionin[white[i]:getId()] then
                black[i]:connect(white[i])
                connections = connections + 1
            end
        end
        server_message(self, {text = "#ADC1FCMade " .. tostring(connections) .. " parallel connections"})
    end
    parallelTool(self, func)
end