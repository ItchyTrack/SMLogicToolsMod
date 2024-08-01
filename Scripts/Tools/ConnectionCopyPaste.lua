-- Version 1.0 of ConnectionCopyPaste by HerrVincling, 13.03.2022
dofile "toolslib/output.lua"

FLG = class( nil )
FLG.maxChildCount = 0
FLG.maxParentCount = 1
FLG.connectionInput = sm.interactable.connectionType.logic
FLG.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
FLG.colorNormal = sm.color.new(0xCF11D2ff)
FLG.colorHighlight = sm.color.new(0xEE7BF0ff)
--GenericClass.poseWeightCount = 1

--[[ client ]]
function FLG.client_onCreate(self )
end

function FLG.client_onRefresh(self )
 self:client_onCreate()
end

function FLG.client_onUpdate(self, deltaTime )
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6 + self.mode)
    else
        self.interactable:setUvFrameIndex(0 + self.mode)
    end
end

function FLG.client_onInteract(self, character, state )
    if state then
        self.network:sendToServer("server_trigger", {character = character})
    end
end

function FLG.client_canInteract(self )
    local namestr = "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>Copy/Paste</p>"
    sm.gui.setInteractionText("", namestr)
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("Use", true), "Apply")
    return true
end

function FLG.client_displayAlert(self, message)
    sm.gui.displayAlertText(message)
end



--[[ server ]]
function FLG.server_trigger(self, data)
    self.character = data.character
    self:server_applyTool()
end

function FLG.server_onCreate(self )
    self.mode = 0
    self.tool = "Connection Copy/Paste"
end

function FLG.server_onRefresh(self )
    dofile "toolslib/output.lua"
    self:server_onCreate()
end

function FLG.server_onFixedUpdate(self, deltaTime )
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

function FLG.server_applyTool(self )
    local copygate
    local shapes = self.shape:getBody():getCreationShapes()

    for _, shape in pairs(shapes) do
        local i0 = shape:getInteractable()
        if i0 and shape:getColor() == sm.color.new(0xEE7BF0ff) then
            if copygate ~= nil then
                server_message(self, {character = self.character, text = "#D02525Error: More than 1 pink copy-gate, only 1 allowed", tool = "#D02525[" .. self.tool .. "]"})
                return
            end
            copygate = i0
        end
    end

    local pastecounter = 0
    if copygate then
        for _, shape in pairs(shapes) do
            local i0 = shape:getInteractable()
            if i0 and shape:getColor() == sm.color.new(0xEEAF5Cff) then
                pastecounter = pastecounter + 1

                local children = copygate:getChildren()
                for _, child in pairs(children) do
                    i0:connect(child)
                end
                local parents = copygate:getParents()
                for _, parent in pairs(parents) do
                    parent:connect(i0)
                end
            end
        end
        if pastecounter == 0 then
            server_message(self, {character = self.character, text ="#D02525Error: No orange block found", tool = "#D02525[" .. self.tool .. "]"})
            return
        end
        server_message(self, {character = self.character, text = "#F7B0F9Copied connections to " .. pastecounter .. " blocks"})
    else
        server_message(self, {character = self.character, text ="#D02525Error: No pink block found", tool = "#D02525[" .. self.tool .. "]"})
    end
end