ParallelConnect = ParallelConnect or {}

function ParallelConnect.onCreate(self)
    self.ParallelConnect = {}
    self.ParallelConnect.data = {}
    self.ParallelConnect.data.step = 0
    self.ParallelConnect.data.selected = {}

    self.ParallelConnect.data.nameTagData = {}
    self.ParallelConnect.data.nameTagData.nameTags = {}
    self.ParallelConnect.data.nameTagData.counter = 1
end

--ParallelConnect.data.nameTags[0] = false
local function nameTagManager(self, worldPosition, text)
    --table = {[1] = {worldPosition, text}, ...}
    local data = self.ParallelConnect.data.nameTagData

    if data.nameTags[data.counter] then
        data.nameTags[data.counter]:setWorldPosition(worldPosition)
        data.nameTags[data.counter]:setText("Text", text)
    else
        data.nameTags[data.counter] = baseLib.createNameTag(self, worldPosition, text)
    end
    data.counter = data.counter + 1

    self.ParallelConnect.data.nameTagData = data
end

local function nameTagCleanup(self)
    local data = self.ParallelConnect.data.nameTagData
    for i = data.counter, #data.nameTags do
        data.nameTags[i]:destroy()
        data.nameTags[i] = nil
    end
    self.ParallelConnect.data.nameTagData = data
end

local function getLocalCenter(shape)
    return shape:getLocalPosition() + shape.xAxis * 0.5 + shape.yAxis * 0.5 + shape.zAxis * 0.5
end

local function getLineShapes(self, shape1, shape2)
    if shape1.body ~= shape2.body then
        return
    end
    local pos1 = getLocalCenter(shape1)
    local pos2 = getLocalCenter(shape2)
    local diffvec = pos2 - pos1
    local direction
    if diffvec.x ~= 0 then
        direction = diffvec:normalize()
    end
    if diffvec.y ~= 0 then
        if direction then
            return --direction isn't just on one axis
        end
        direction = diffvec:normalize()
    end
    if diffvec.z ~= 0 then
        if direction then
            return --direction isn't just on one axis
        end
        direction = diffvec:normalize()
    end
    if direction == nil then
        return
    end

    local bodyshapes = shape1.body:getShapes()
    local shapesOnAxis = {}

    if direction.x ~= 0 then
        for i = 1, #bodyshapes do
            if bodyshapes[i]:getInteractable() then
                local localPos = getLocalCenter(bodyshapes[i])
                if localPos.y == pos1.y and localPos.z == pos1.z then
                    if direction.x > 0 then
                        if localPos.x > pos1.x and localPos.x < pos2.x then
                            shapesOnAxis[#shapesOnAxis + 1] = bodyshapes[i]
                        end
                    else
                        if localPos.x < pos1.x and localPos.x > pos2.x then
                            shapesOnAxis[#shapesOnAxis + 1] = bodyshapes[i]
                        end
                    end
                end
            end
        end
        if direction.x > 0 then
            table.sort(shapesOnAxis, function(a,b) return getLocalCenter(a).x < getLocalCenter(b).x end)
        else
            table.sort(shapesOnAxis, function(a,b) return getLocalCenter(a).x > getLocalCenter(b).x end)
        end
    elseif direction.y ~= 0 then
        for i = 1, #bodyshapes do
            if bodyshapes[i]:getInteractable() then
                local localPos = getLocalCenter(bodyshapes[i])
                if localPos.x == pos1.x and localPos.z == pos1.z then
                    if direction.y > 0 then
                        if localPos.y > pos1.y and localPos.y < pos2.y then
                            print("hi")
                            shapesOnAxis[#shapesOnAxis + 1] = bodyshapes[i]
                        end
                    else
                        if localPos.y < pos1.y and localPos.y > pos2.y then
                            shapesOnAxis[#shapesOnAxis + 1] = bodyshapes[i]
                        end
                    end
                end
            end
        end
        if direction.y > 0 then
            table.sort(shapesOnAxis, function(a,b) return getLocalCenter(a).y < getLocalCenter(b).y end)
        else
            table.sort(shapesOnAxis, function(a,b) return getLocalCenter(a).y > getLocalCenter(b).y end)
        end
    elseif direction.z ~= 0 then
        for i = 1, #bodyshapes do
            if bodyshapes[i]:getInteractable() then
                local localPos = getLocalCenter(bodyshapes[i])
                if localPos.x == pos1.x and localPos.y == pos1.y then
                    if direction.z > 0 then
                        if localPos.z > pos1.z and localPos.z < pos2.z then
                            shapesOnAxis[#shapesOnAxis + 1] = bodyshapes[i]
                        end
                    else
                        if localPos.z < pos1.z and localPos.z > pos2.z then
                            shapesOnAxis[#shapesOnAxis + 1] = bodyshapes[i]
                        end
                    end
                end
            end
        end
        if direction.z > 0 then
            table.sort(shapesOnAxis, function(a,b) return getLocalCenter(a).z < getLocalCenter(b).z end)
        else
            table.sort(shapesOnAxis, function(a,b) return getLocalCenter(a).z > getLocalCenter(b).z end)
        end
    end
    return shapesOnAxis
end

function ParallelConnect.sv_connectLines(self, toolData)
    if toolData.mode then
        toolData.selected[1]:getInteractable():disconnect(toolData.selected[3]:getInteractable())
        toolData.selected[2]:getInteractable():disconnect(toolData.selected[4]:getInteractable())
        for i = 1, #toolData.row1 do
            toolData.row1[i]:getInteractable():disconnect(toolData.row2[i]:getInteractable())
        end
    else
        toolData.selected[1]:getInteractable():connect(toolData.selected[3]:getInteractable())
        toolData.selected[2]:getInteractable():connect(toolData.selected[4]:getInteractable())
        for i = 1, #toolData.row1 do
            toolData.row1[i]:getInteractable():connect(toolData.row2[i]:getInteractable())
        end
    end
end

function ParallelConnect.main(self, primaryState, secondaryState, forceBuild) --gets called every tick
    local toolData = self.ParallelConnect.data
    toolData.nameTagData.counter = 1

    --print(toolData.selected)

    --Display Nametags
    if toolData.step == 0 then

    end
    if toolData.step >= 1 then
        nameTagManager(self, toolData.selected[1].worldPosition, "#00ff00O")
    end
    if toolData.step >= 2 then
        nameTagManager(self, toolData.selected[2].worldPosition, "#00ff00O")
        local lineShapes = getLineShapes(self, toolData.selected[1], toolData.selected[2])
        if lineShapes then
            for i = 1, #lineShapes do
                nameTagManager(self, lineShapes[i].worldPosition, tostring(i + 1))
            end
        end
    end
    if toolData.step >= 3 then
        nameTagManager(self, toolData.selected[3].worldPosition, "#00ff00O")
    end
    if toolData.step >= 4 then
        nameTagManager(self, toolData.selected[4].worldPosition, "#00ff00O")
        local lineShapes = getLineShapes(self, toolData.selected[3], toolData.selected[4])
        if lineShapes then
            for i = 1, #lineShapes do
                if i <= #toolData.row1 then
                    nameTagManager(self, lineShapes[i].worldPosition, tostring(i + 1))
                else
                    nameTagManager(self, lineShapes[i].worldPosition, "#ff0000X")
                end
            end
        end
    end

    if toolData.step == 0 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the start of the 1st row of Logic Parts")
        local lookAt = baseLib.lookAtConnectDot(self)
        if lookAt then
            nameTagManager(self, lookAt.worldPosition, "#00ff00O")
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
            nameTagManager(self, lookAt.worldPosition, "#00ff00O")
            lineShapes = getLineShapes(self, toolData.selected[1], lookAt)
            if lineShapes then
                for i = 1, #lineShapes do
                    nameTagManager(self, lineShapes[i].worldPosition, tostring(i + 1))
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
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the start of the 2nd row of Logic Parts")
        local lookAt = baseLib.lookAtConnectDot(self)
        if lookAt then
            nameTagManager(self, lookAt.worldPosition, "#00ff00O")
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
            nameTagManager(self, lookAt.worldPosition, "#00ff00O")
            lineShapes = getLineShapes(self, toolData.selected[3], lookAt)
            if lineShapes then
                for i = 1, #lineShapes do
                    if i <= #toolData.row1 then
                        nameTagManager(self, lineShapes[i].worldPosition, tostring(i + 1))
                    else
                        nameTagManager(self, lineShapes[i].worldPosition, "#ff0000X")
                    end
                end
            end
        end

        if primaryState == 1 and lookAt and #lineShapes == #toolData.row1 then
            toolData.row2 = lineShapes
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
            self.network:sendToServer("sv_connectLines", { mode = toolData.mode, selected = toolData.selected, row1 = toolData.row1, row2 = toolData.row2 })
            ParallelConnect.onUnequip(self)
            toolData.step = 0
        elseif secondaryState == 1 then
            toolData.selected[4] = nil
            toolData.step = toolData.step - 1
        end
    end

    toolData.lastF = forceBuild
    nameTagCleanup(self)
    self.ParallelConnect.data = toolData
end

function ParallelConnect.onUnequip(self)
    local toolData = self.ParallelConnect.data
    toolData.step = 0
    toolData.selected = {}
    toolData.row1 = {}
    toolData.row2 = {}
    toolData.nameTagData.counter = 1
    nameTagCleanup(self)
    self.ParallelConnect.data = toolData
end