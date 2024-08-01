-- ColorConnectionsMaker by HerrVincling, 19.09.2022
dofile "toolslib/output.lua"
dofile "toolslib/color.lua"

CTP = class( nil )
CTP.maxChildCount = -1
CTP.maxParentCount = 1
CTP.connectionInput = sm.interactable.connectionType.logic
CTP.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
CTP.colorNormal = sm.color.new(0x7F7F7Fff)
CTP.colorHighlight = sm.color.new(0xa4a4a4ff)
--GenericClass.poseWeightCount = 1
CTP.modes = {
	"Relative Position",
	"State"
	--"Direction" nvm this only makes sense for copy/paste
	--"Mode (Quick Gate only)"
	--"Part Uuid"
}
CTP.submodes = {
	State = {"Active", "Inactive"},
	["Mode (Quick Gate only)"] = {"AND", "OR", "XOR", "NAND", "NOR", "XNOR"}
	--Direction = {"Outgoing", "Incoming"} nvm this only makes sense for copy/paste
}
--[[ client ]]
function CTP.client_onCreate(self)
	self.mode = 1
	self.submode = 1
	self.modes = CTP.modes
	self.submodes = CTP.submodes
end

function CTP.client_onUpdate(self, deltaTime)
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6)
    else
        self.interactable:setUvFrameIndex(0)
    end
end

function CTP.client_onInteract(self, character, state)
    if state then
        self.network:sendToServer("sv_changeMode", {character = character})
    end
end

function CTP.client_onTinker(self, character, state)
    if state then
        self.network:sendToServer("sv_changeSubmode", {character = character})
    end
end

function CTP.client_canInteract(self)
    sm.gui.setInteractionText("", "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Color Tool Peripheral</p>")
	if self.submodes[self.modes[self.mode]] then
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true), "Condition/Filter: <p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>" .. self.modes[self.mode] .. "</p>", sm.gui.getKeyBinding("Tinker", true), "Toggle <p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>" .. self.submodes[self.modes[self.mode]][self.submode] .. "</p>")
	else
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true), "Condition/Filter:", "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>" .. self.modes[self.mode] .. "</p>")
	end
    return true
end

function CTP.client_displayAlert(self, message)
    sm.gui.displayAlertText(message)
end

function CTP.client_onClientUpdate(self, data)
	self.mode = data.mode
	self.submode = data.submode
end



--[[ server ]]
function CTP.sv_changeMode(self, data)
	if data.character:isCrouching() then
		self.mode = self.mode - 1
		if self.mode <= 0 then
			self.mode = #self.modes
		end
	else
		self.mode = self.mode + 1
		if self.mode > #self.modes then
			self.mode = 1
		end
	end
	if self.submodes[self.modes[self.mode]] == nil then
		self.submode = 1
	end
	self.storage:save({mode = self.mode, submode = self.submode})
	self.network:setClientData({mode = self.mode, submode = self.submode})
end

function CTP.sv_changeSubmode(self, data)
	local submodes = self.submodes[self.modes[self.mode]]
	if submodes == nil then
		return
	end
	if data.character:isCrouching() then
		self.submode = self.submode - 1
		if self.submode <= 0 then
			self.submode = #submodes
		end
	else
		self.submode = self.submode + 1
		if self.submode > #submodes then
			self.submode = 1
		end
	end
	--print(self.submode)
	self.storage:save({mode = self.mode, submode = self.submode})
	self.network:setClientData({mode = self.mode, submode = self.submode})
end

function CTP.server_onCreate(self)
	self.modes = CTP.modes
	self.submodes = CTP.submodes

    self.wasactive = false
    self.tool = "Color Connect"
	if self.storage:load() then
		self.mode = self.storage:load().mode
		self.submode = self.storage:load().submode
	else
		self.mode = 1
		self.submode = 1
		self.storage:save({mode = self.mode, submode = self.submode})
	end
end

function CTP.server_onRefresh(self)
    self:server_onCreate()
end

function CTP.server_onFixedUpdate(self, deltaTime)
	local data = {}
	
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:getShape():getShapeUuid() == self.shape:getShapeUuid() then
			local parentdata = parent:getPublicData()
			for i = 1, #parentdata do
				data[#data + 1] = parentdata[i]
			end
		end
	end
	
	if self.submodes[self.modes[self.mode]] then
		data[#data + 1] = {self.modes[self.mode], self.submodes[self.modes[self.mode]][self.submode]}
	else
		data[#data + 1] = {self.modes[self.mode], true}
	end
	self.interactable:setPublicData(data)
end