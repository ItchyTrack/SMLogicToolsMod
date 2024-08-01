-- ColorConnectionsMaker by HerrVincling, 19.09.2022
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
function CCM.client_onCreate(self)
	self.connect = true
end

function CCM.client_onUpdate(self, deltaTime)
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6)
    else
        self.interactable:setUvFrameIndex(0)
    end
end

function CCM.client_onInteract(self, character, state)
    if state then
        self.network:sendToServer("server_trigger", {character = character})
    end
end

function CCM.client_onTinker(self, character, state)
	if state then
		self.network:sendToServer("sv_changeMode", {})
	end
end

function CCM.client_canInteract(self)
    sm.gui.setInteractionText("", "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Color Connect</p>")
	if self.connect == true then
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true),"<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Connect</p>", sm.gui.getKeyBinding("Tinker", true), "Toggle Mode")
	else
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true),"<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Disconnect</p>", sm.gui.getKeyBinding("Tinker", true), "Toggle Mode")
	end
	
    return true
end

function CCM.client_displayAlert(self, message)
    sm.gui.displayAlertText(message)
end

function CCM.client_onClientUpdate(self, data)
	self.connect = data.connect
end

--[[ server ]]
function CCM.sv_changeMode(self, data)
	self.connect = not self.connect
	self.storage:save({connect = self.connect})
	self.network:setClientData({connect = self.connect})
end

function CCM.server_trigger(self, data)
    self.character = data.character
    self:server_applyTool()
end

function CCM.server_onCreate(self)
    self.wasactive = false
    self.tool = "Color Connect"
	if self.storage:load() then
		self.connect = self.storage:load().connect
	else
		self.connect = true
		self.storage:save({connect = self.connect})
	end
end

function CCM.server_onRefresh(self)
    self:server_onCreate()
end

function CCM.server_onFixedUpdate(self, deltaTime)
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

function CCM.server_applyTool(self)
    local func = function(self, interpairs)
        local connections = 0
        for i = 1, #interpairs do
			local interpair = interpairs[i]
			local i0 = interpair[1]
			local i1 = interpair[2]
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

			if self.connect then
				if not existingconnectionout[i1:getId()] and not existingconnectionin[i1:getId()] then
					i0:connect(i1)
					connections = connections + 1
				end
			else
                if existingconnectionout[i1:getId()] then
                    i0:disconnect(i1)
                    connections = connections + 1
                end
			end
        end
        if self.connect then
            return "Made " .. connections .. " color connections"
        else
            return "Removed " .. connections .. " color connections"
        end
    end
    colorTool2(self, func)
end