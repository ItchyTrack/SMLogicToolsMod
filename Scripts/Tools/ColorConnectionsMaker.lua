-- Version 1.1 of ColorConnectionsMaker by HerrVincling, 12.03.2022
dofile "toolslib/output.lua"
dofile "toolslib/color.lua"

CCM = class( nil )
CCM.maxChildCount = -1
CCM.maxParentCount = -1
CCM.connectionInput = sm.interactable.connectionType.logic
CCM.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
CCM.colorNormal = sm.color.new(0x7F7F7Fff)
CCM.colorHighlight = sm.color.new(0xa4a4a4ff)
--GenericClass.poseWeightCount = 1

--[[ client ]]
function CCM.client_onCreate(self )
end

function CCM.client_onRefresh(self )
 self:client_onCreate()
end

function CCM.client_onUpdate(self, deltaTime )
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6 + self.var1)
    else
        self.interactable:setUvFrameIndex(0 + self.var1)
    end
end

function CCM.client_onInteract(self, character, state )
    if state then
        self.network:sendToServer("server_trigger", {character = character})
    end
end

function CCM.client_canInteract(self )
    local namestr = "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Color Connect</p>"
    sm.gui.setInteractionText("", namestr)
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true),"Connect")
    return true
end

function CCM.client_displayAlert(self, message)
    sm.gui.displayAlertText(message)
end



--[[ server ]]
function CCM.server_trigger(self, data)
    self.character = data.character
    self:server_applyTool()
end

function CCM.server_onCreate(self )
    self.var1 = 0
    self.wasactive = false
    self.tool = "Color Connect"
end

function CCM.server_onRefresh(self )
    dofile "output.lua"
    dofile "color.lua"
    self:server_onCreate()
end

function CCM.server_onFixedUpdate(self, deltaTime )
    local parents = self.interactable:getParents()
    local active = false
    for _, parent in pairs(parents) do
        if parent:isActive() then
            active = true
        end
    end

    if active then
        if not self.wasactive then
            self.character = nil
            self:server_applyTool()
            self.wasactive = true
        end
    else
        self.wasactive = false
    end
end

function CCM.server_applyTool(self )
    local func = function(self, s0, s1, color1, color2)
        local connections = 0
        for _, i0 in pairs(color1) do
            local ichilds = i0:getChildren()
            local existingconnectionout = {}
            for _, child in pairs(ichilds) do
                existingconnectionout[child:getId()] = true
            end
            local iparents = i0:getParents()
            local existingconnectionin = {}
            for _, parent in pairs(iparents) do
                existingconnectionin[parent:getId()] = true
            end
            for _, i1 in pairs(color2) do
                if not existingconnectionout[i1:getId()] and not existingconnectionin[i1:getId()] then
                    i0:connect(i1)
                    connections = connections + 1
                end
            end
        end
        server_message(self, {character = self.character, text = "#CCCCCCMade " .. tostring(connections) .. " color connections" .. getColorIndicatorText({color1 = s0:getColor(), color2 = s1:getColor()})})
    end
    colorTool(self, func)
end