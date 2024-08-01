InlineConnect = InlineConnect or {}

local nameTagAdd, nameTagCleanup, nameTagNextTick = baseLib.createNameTagManager()

function InlineConnect.onCreate(self)
    self.InlineConnect = {}
    self.InlineConnect.data = {}
    self.InlineConnect.data.step = 0
    self.InlineConnect.data.selected = {}
end

function InlineConnect.sv_connectLines(self, toolData)
    if toolData.mode then
        toolData.row1[#toolData.row1 + 1] = toolData.selected[2]
        toolData.selected[1]:getInteractable():disconnect(toolData.row1[1]:getInteractable())
        for i = 1, #toolData.row1 - 1 do
            toolData.row1[i]:getInteractable():disconnect(toolData.row1[i + 1]:getInteractable())
        end
    else
        toolData.row1[#toolData.row1 + 1] = toolData.selected[2]
        toolData.selected[1]:getInteractable():connect(toolData.row1[1]:getInteractable())
        for i = 1, #toolData.row1 - 1 do
            toolData.row1[i]:getInteractable():connect(toolData.row1[i + 1]:getInteractable())
        end
    end
end

function InlineConnect.main(self, primaryState, secondaryState, forceBuild) --gets called every tick
    local toolData = self.InlineConnect.data
    local getLineShapes = baseLib.getLineShapes
    nameTagNextTick(self)

    --print(toolData.selected)

    --Display Nametags
    if toolData.step == 0 then

    end
    if toolData.step >= 1 then
        nameTagAdd(self, toolData.selected[1].worldPosition, "#00ff00O")
    end
    if toolData.step >= 2 then
        nameTagAdd(self, toolData.selected[2].worldPosition, "#00ff00O")
        local lineShapes = getLineShapes(self, toolData.selected[1], toolData.selected[2])
        if lineShapes then
            for i = 1, #lineShapes do
                nameTagAdd(self, lineShapes[i].worldPosition, tostring(i + 1))
            end
        end
    end

    if toolData.step == 0 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the start of the row of Logic Parts")
        local lookAt = baseLib.lookAtConnectDot(self)
        if lookAt then
            nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
        end

        if primaryState == 1 and lookAt then
            toolData.selected[1] = lookAt
            toolData.step = toolData.step + 1
        end
    elseif toolData.step == 1 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the end of the row of Logic Parts")
        local lookAt = baseLib.lookAtConnectDot(self)
        local lineShapes
        if lookAt then
            nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
            lineShapes = getLineShapes(self, toolData.selected[1], lookAt)
            if lineShapes then
                for i = 1, #lineShapes do
                    nameTagAdd(self, lineShapes[i].worldPosition, tostring(i + 1))
                end
            end
        end

        if primaryState == 1 and lookAt and lineShapes then
            toolData.row1 = lineShapes
            toolData.selected[2] = lookAt
            toolData.step = toolData.step + 1
        elseif secondaryState == 1 then
            toolData.selected[1] = nil
            toolData.step = toolData.step - 1
        end
    elseif toolData.step == 2 then
        if forceBuild and not toolData.lastF then
            toolData.mode = not toolData.mode
        end
        local str = ""
        if toolData.mode then
            str = "Disconnect"
        else
            str = "Connect"
        end
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Toggle", "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='4'>" .. str .. "<p>")
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Confirm")

        if primaryState == 1 then
            self.network:sendToServer("sv_connectInlineLines", { mode = toolData.mode, selected = toolData.selected, row1 = toolData.row1})
            InlineConnect.onUnequip(self)
            toolData.step = 0
        elseif secondaryState == 1 then
            toolData.selected[2] = nil
            toolData.step = toolData.step - 1
        end
    end

    toolData.lastF = forceBuild
    nameTagCleanup(self)
    self.InlineConnect.data = toolData
end

function InlineConnect.onUnequip(self)
    local toolData = self.InlineConnect.data
    toolData.step = 0
    toolData.selected = {}
    toolData.row1 = {}
    nameTagNextTick(self)
    nameTagCleanup(self)
    self.InlineConnect.data = toolData
end