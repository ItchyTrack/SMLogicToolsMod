-- nToNConnectTool.lua by HerrVincling
NtoNConnect = {}

function NtoNConnect.onCreate(self)
    self.NtoNConnect = {}
    self.NtoNConnect.data = {}
    self.NtoNConnect.data.step = 0
    self.NtoNConnect.data.selected = {}
end

local nameTagAdd, nameTagCleanup, nameTagNextTick = baseLib.createNameTagManager()

function table_concat3(t1, t2, t3)
    local t4 = {}
    for i=1,#t1 do
        t4[#t4+1] = t1[i]
    end
    for i=1,#t2 do
        t4[#t4+1] = t2[i]
    end
    for i=1,#t3 do
        t4[#t4+1] = t3[i]
    end
    return t4
end


function NtoNConnect.sv_connectLines(self, toolData)
    if toolData.mode then
        local fulllist1 = table_concat3({toolData.selected[1]}, toolData.row1, {toolData.selected[2]})
        local fulllist2 = table_concat3({toolData.selected[3]}, toolData.row2, {toolData.selected[4]})

        for i = 1, #fulllist1 do
            for j = 1, #fulllist2 do
                fulllist1[i]:getInteractable():disconnect(fulllist2[j]:getInteractable())
            end
        end
    else
        local fulllist1 = table_concat3({toolData.selected[1]}, toolData.row1, {toolData.selected[2]})
        local fulllist2 = table_concat3({toolData.selected[3]}, toolData.row2, {toolData.selected[4]})

        for i = 1, #fulllist1 do
            for j = 1, #fulllist2 do
                fulllist1[i]:getInteractable():connect(fulllist2[j]:getInteractable())
            end
        end
    end
end

function NtoNConnect.main(self, primaryState, secondaryState, forceBuild)
    nameTagNextTick(self)
    local toolData = self.NtoNConnect.data


    if toolData.step == 0 then

    end
    if toolData.step >= 1 then
        nameTagAdd(self, toolData.selected[1].worldPosition, "#00ff00O")
    end
    if toolData.step >= 2 then
        nameTagAdd(self, toolData.selected[2].worldPosition, "#00ff00O")
        local lineShapes = baseLib.getLineShapes(self, toolData.selected[1], toolData.selected[2])
        if lineShapes then
            for i = 1, #lineShapes do
                nameTagAdd(self, lineShapes[i].worldPosition, tostring(i + 1))
            end
        end
    end
    if toolData.step >= 3 then
        nameTagAdd(self, toolData.selected[3].worldPosition, "#00ff00O")
    end
    if toolData.step >= 4 then
        nameTagAdd(self, toolData.selected[4].worldPosition, "#00ff00O")
        local lineShapes = baseLib.getLineShapes(self, toolData.selected[3], toolData.selected[4])
        if lineShapes then
            for i = 1, #lineShapes do
                nameTagAdd(self, lineShapes[i].worldPosition, tostring(i + 1))
            end
        end
    end

    if toolData.step == 0 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the start of the 1st row of Logic Parts")
        local lookAt = baseLib.lookAtConnectDot(self)
        if lookAt then
            nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
        end

        if primaryState == 1 and lookAt then
            toolData.selected[1] = lookAt
            toolData.step = toolData.step + 1
        end
    elseif toolData.step == 1 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the end of the 1st row of Logic Parts")
        local lookAt = baseLib.lookAtConnectDot(self)
        local lineShapes
        if lookAt then
            nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
            lineShapes = baseLib.getLineShapes(self, toolData.selected[1], lookAt)
            if lineShapes then
                for i = 1, #lineShapes do
                    nameTagAdd(self, lineShapes[i].worldPosition, tostring(i + 1))
                end
            end
        end

        if primaryState == 1 and lookAt then
            toolData.row1 = lineShapes or {}
            toolData.selected[2] = lookAt
            toolData.step = toolData.step + 1
        elseif secondaryState == 1 then
            toolData.selected[1] = nil
            toolData.step = toolData.step - 1
        end
    elseif toolData.step == 2 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the start of the 2nd row of Logic Parts")
        local lookAt = baseLib.lookAtConnectDot(self)
        if lookAt then
            nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
        end

        if primaryState == 1 and lookAt then
            toolData.selected[3] = lookAt
            toolData.step = toolData.step + 1
        elseif secondaryState == 1 then
            toolData.selected[2] = nil
            toolData.step = toolData.step - 1
        end
    elseif toolData.step == 3 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the end of the 2nd row of Logic Parts")
        local lookAt = baseLib.lookAtConnectDot(self)
        local lineShapes
        if lookAt then
            nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
            lineShapes = baseLib.getLineShapes(self, toolData.selected[3], lookAt)
            if lineShapes then
                for i = 1, #lineShapes do
                    nameTagAdd(self, lineShapes[i].worldPosition, tostring(i + 1))
                end
            end
        end

        if primaryState == 1 and lookAt then
            toolData.row2 = lineShapes or {}
            toolData.selected[4] = lookAt
            toolData.step = toolData.step + 1
        elseif secondaryState == 1 then
            toolData.selected[3] = nil
            toolData.step = toolData.step - 1
        end
    elseif toolData.step == 4 then
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
            self.network:sendToServer("sv_connectNtoNLines", { mode = toolData.mode, selected = toolData.selected, row1 = toolData.row1, row2 = toolData.row2 })
            NtoNConnect.onUnequip(self)
            toolData.step = 0
        elseif secondaryState == 1 then
            toolData.selected[4] = nil
            toolData.step = toolData.step - 1
        end
    end




    toolData.lastF = forceBuild
    self.NtoNConnect.data = toolData
    nameTagCleanup(self)
end

function NtoNConnect.onUnequip(self)
    local toolData = self.NtoNConnect.data
    toolData.step = 0
    toolData.selected = {}
    toolData.row1 = {}
    toolData.row2 = {}
    self.NtoNConnect.data = toolData
    nameTagNextTick(self)
    nameTagCleanup(self)
end