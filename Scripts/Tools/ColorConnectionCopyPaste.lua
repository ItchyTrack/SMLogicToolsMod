-- ColorConnectionsMaker by HerrVincling, 19.09.2022
dofile "toolslib/output.lua"
dofile "toolslib/color.lua"

CCCP = class( nil )
CCCP.maxChildCount = -1
CCCP.maxParentCount = -1
CCCP.connectionInput = sm.interactable.connectionType.logic
CCCP.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
CCCP.colorNormal = sm.color.new(0x7F7F7Fff)
CCCP.colorHighlight = sm.color.new(0xa4a4a4ff)
--GenericClass.poseWeightCount = 1

--[[ client ]]
function CCCP.client_onCreate(self)
	self.mode = false
end

function CCCP.client_onUpdate(self, deltaTime)
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6)
    else
        self.interactable:setUvFrameIndex(0)
    end
end

function CCCP.client_onInteract(self, character, state)
    if state then
        self.network:sendToServer("server_trigger", {character = character})
    end
end

function CCCP.client_onTinker(self, character, state)
	if state then
		self.network:sendToServer("sv_changeMode", {})
	end
end

function CCCP.client_canInteract(self)
    sm.gui.setInteractionText("", "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Color Copy/Paste</p>")
	if self.mode == true then
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true),"<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Relative</p>", sm.gui.getKeyBinding("Tinker", true), "Toggle Mode")
	else
		sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true),"<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Basic</p>", sm.gui.getKeyBinding("Tinker", true), "Toggle Mode")
	end
	
    return true
end

function CCCP.client_displayAlert(self, message)
    sm.gui.displayAlertText(message)
end

function CCCP.client_onClientUpdate(self, data)
	self.mode = data.mode
end

--[[ server ]]
function CCCP.sv_changeMode(self, data)
	self.mode = not self.mode
	self.storage:save({mode = self.mode})
	self.network:setClientData({mode = self.mode})
end

function CCCP.server_trigger(self, data)
    self.character = data.character
    self:server_applyTool()
end

function CCCP.server_onCreate(self)
    self.wasactive = false
    self.tool = "Color Copy/Paste"
	if self.storage:load() then
		self.mode = self.storage:load().mode
	else
		self.mode = false
		self.storage:save({mode = self.mode})
	end
end

function CCCP.server_onRefresh(self)
    self:server_onCreate()
end

function CCCP.server_onFixedUpdate(self, deltaTime)
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

function CCCP.server_applyTool(self)
    local func = function(self, interpairs)
        local connections = 0
        if not self.mode then
            for i = 1, #interpairs do
                local interpair = interpairs[i]
                local i0 = interpair[1]
                local i1 = interpair[2]
                local childs = i0:getChildren()
                for i = 1, #childs do
                    local child = childs[i]
                    i1:connect(child)
                end
                local parents = i0:getParents()
                for i = 1, #parents do
                    local parent = parents[i]
                    parent:connect(i1)
                end
                connections = connections + 1
            end
            return "Copied " .. connections .. " times"
        elseif self.mode then
            local creationshapes = self.shape.body:getCreationShapes()
            local interpositions = {}
            local creationinters = {}
            for _, shape in pairs(creationshapes) do
                local interactable = shape:getInteractable()
                if interactable then
                    interpositions[interactable:getId()] = shape.worldPosition * 4
                    creationinters[interactable:getId()] = interactable
                end
            end

            local interdata = {}

            for i = 1, #interpairs do
                local interpair = interpairs[i]
                local copyinter = interpair[1]
                local pasteinter = interpair[2]
                local data = interdata[interpair[1]:getId()]
                local parentpositions
                local childpositions
                if data == nil then
                    local parents = copyinter:getParents()
                    local childs = copyinter:getChildren()
                    parentpositions = {}
                    for j = 1, #parents do
                        local position = copyinter:getShape().worldPosition*4 - parents[j]:getShape().worldPosition*4
                        parentpositions[#parentpositions+1] = position
                    end
                    childpositions = {}
                    for j = 1, #childs do
                        local position = copyinter:getShape().worldPosition*4 - childs[j]:getShape().worldPosition*4
                        childpositions[#childpositions+1] = position
                    end
                    interdata[copyinter:getId()] = {childpos = childpositions, parentpos = parentpositions}
                else
                    parentpositions = data.parentpos
                    childpositions = data.childpos
                end

                local interpos = pasteinter:getShape().worldPosition*4
                local relativepos
                local diffpos
                for id, pos in pairs(interpositions) do
                    relativepos = interpos - pos
                    for i = 1, #childpositions do
                        diffpos = relativepos - childpositions[i]
                        diffpos = sm.vec3.new(math.floor(diffpos.x + 0.5), math.floor(diffpos.y + 0.5), math.floor(diffpos.z + 0.5))
                        if diffpos:length() == 0 then
                            --Relative position matches
                            pasteinter:connect(creationinters[id])
                        end
                    end
                    for i = 1, #parentpositions do
                        diffpos = relativepos - parentpositions[i]
                        diffpos = sm.vec3.new(math.floor(diffpos.x + 0.5), math.floor(diffpos.y + 0.5), math.floor(diffpos.z + 0.5))
                        if diffpos:length() == 0 then
                            --Relative position matches
                            creationinters[id]:connect(pasteinter)
                        end
                    end
                end
                connections = connections + 1
            end

            return "Copied " .. connections .. " times"
        end
    end
    colorTool2(self, func)
end