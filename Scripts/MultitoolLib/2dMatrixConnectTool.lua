Matrix2Connect = {}
Matrix2Connect.data = {}
Matrix2Connect.data.step = 0
Matrix2Connect.data.selected = {}

local nameTagAdd, nameTagCleanup, nameTagNextTick = baseLib.createNameTagManager()
--nameTagAdd(self, worldPosition, text), nameTagCleanup(self), nextTick(self)

local function showPointsAsLine(self, pointslist, getshape, text, skippoints)
    local shape1 = getshape(pointslist[1])
    if shape1 then
        nameTagAdd(self, shape1.worldPosition, "#00ff00O")
    end
    local count = 1
    for i = 2, #pointslist - 1 do
        local point = pointslist[i]
        local shape = getshape(point)
        if shape then
            if skippoints then
                nameTagAdd(self, shape.worldPosition, tostring(count + 1) .. text) --whole line
            else
                nameTagAdd(self, shape.worldPosition, tostring(i) .. text) --whole line
            end
            count = count + 1
        end
    end
    local shape2 = getshape(pointslist[#pointslist])
    if shape2 then
        nameTagAdd(self, shape2.worldPosition, "#00ff00O")
    end
end

local function showPointsAsLineSet(self, pointslist, getshape, text, skippoints)
    local shape1 = getshape(pointslist[1])
    if shape1 then
        nameTagAdd(self, shape1.worldPosition, "#00ffffO")
    end
    local count = 1
    for i = 2, #pointslist - 1 do
        local point = pointslist[i]
        local shape = getshape(point)
        if shape then
            if skippoints then
                nameTagAdd(self, shape.worldPosition, "#dddddd" .. tostring(count + 1) .. text) --whole line
            else
                nameTagAdd(self, shape.worldPosition, "#dddddd" .. tostring(i) .. text) --whole line
            end
            count = count + 1
        end
    end
    local shape2 = getshape(pointslist[#pointslist])
    if shape2 then
        nameTagAdd(self, shape2.worldPosition, "#00ffffO")
    end
end

local function showPointsAsLineNoNumbers(self, pointslist, getshape, text)
    local shape1 = getshape(pointslist[1])
    if shape1 then
        nameTagAdd(self, shape1.worldPosition, "#00ff00O")
    end
    local count = 1
    for i = 2, #pointslist - 1 do
        local point = pointslist[i]
        local shape = getshape(point)
        if shape then
            nameTagAdd(self, shape.worldPosition, "#ffffffO") --whole line
            count = count + 1
        end
    end
    local shape2 = getshape(pointslist[#pointslist])
    if shape2 then
        nameTagAdd(self, shape2.worldPosition, "#00ff00O")
    end
end

local function char(num)

    return string.char(string.byte("A")+num-1)
end


function Matrix2Connect.main(self, primaryState, secondaryState, forceBuild)
    local data = Matrix2Connect.data
    nameTagNextTick(self)

    local shapelookup
    if data.selected[1] then
        local bodyshapes = data.selected[1].body:getShapes()
        shapelookup = {}
        for i = 1, #bodyshapes do
            local shape = bodyshapes[i]
            if shape:getInteractable() then
                local localpos = baseLib.getLocalCenter(shape)
                if shapelookup[localpos.x] == nil then
                    shapelookup[localpos.x] = {}
                end
                if shapelookup[localpos.x][localpos.y] == nil then
                    shapelookup[localpos.x][localpos.y] = {}
                end
                shapelookup[localpos.x][localpos.y][localpos.z] = shape
            end
        end
        if data.selected[4] then
            bodyshapes = data.selected[4].body:getShapes()
            for i = 1, #bodyshapes do
                local shape = bodyshapes[i]
                if shape:getInteractable() then
                    local localpos = baseLib.getLocalCenter(shape)
                    if shapelookup[localpos.x] == nil then
                        shapelookup[localpos.x] = {}
                    end
                    if shapelookup[localpos.x][localpos.y] == nil then
                        shapelookup[localpos.x][localpos.y] = {}
                    end
                    shapelookup[localpos.x][localpos.y][localpos.z] = shape
                end
            end
        end
    end

    local function getshape(point)
        local shapelookup = shapelookup
        local ylist = shapelookup[point.x]
        if ylist then
            local zlist = ylist[point.y]
            if zlist then
                return zlist[point.z]
            end
        end
    end

    if data.step >= 3 then
        for i = 1, #data.row2 do
            showPointsAsLineSet(self, data.row2[i], getshape, "", false)
        end
    end

    if data.step >= 6 then
        for i = 1, #data.row4 do
            showPointsAsLineSet(self, data.row4[i], getshape, "", false)
        end
    end

    local lookAt = baseLib.lookAtConnectDot(self)
    if data.step == 0 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the 1st corner of the 1st plane of Logic Parts")
        if lookAt then
            nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
        end

        if primaryState == 1 and lookAt then
            data.selected[1] = lookAt
            data.step = data.step + 1
        end
    elseif data.step == 1 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the 2nd corner of the 1st plane of Logic Parts")

        local showdefault = false
        local linePoints
        if lookAt then
            if lookAt.body == data.selected[1].body then
                linePoints = baseLib.getLinePoints(baseLib.getLocalCenter(data.selected[1]), baseLib.getLocalCenter(lookAt))
                if linePoints then
                    showPointsAsLine(self, linePoints, getshape, "", false)
                else
                    showdefault = true
                end
            else
                showdefault = true
            end
        else
            showdefault = true
        end

        if showdefault then
            if lookAt then
                nameTagAdd(self, lookAt.worldPosition, "#00ff00O")           --point 2
            end
            nameTagAdd(self, data.selected[1].worldPosition, "#00ff00O") --point 1
        end

        if primaryState == 1 and lookAt and linePoints then
            data.row1 = linePoints
            data.selected[2] = lookAt
            data.step = data.step + 1
        elseif secondaryState == 1 then
            data.selected[1] = nil
            data.step = data.step - 1
        end
    elseif data.step == 2 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the 3nd corner of the 1st plane of Logic Parts")

        local showdefault = false
        local newlines
        if lookAt then
            if lookAt.body == data.selected[2].body then

                local lookAtPoint = baseLib.getLocalCenter(lookAt)
                local lookAtLine
                local rowaxis = baseLib.getPointsAxis(data.row1[1], data.row1[#data.row1])
                for i = 1, #data.row1 do
                    local point = data.row1[i]
                    local axis = baseLib.getPointsAxis(lookAtPoint, point)
                    if axis and axis ~= rowaxis then
                        lookAtLine = {}
                        local offset = lookAtPoint - point
                        if sm.vec3.length(offset) ~= 0 then
                            for j = 1, #data.row1 do
                                lookAtLine[j] = data.row1[j] + offset
                            end
                        end
                    end
                end
                --lookAtLine will be the same length as data.row1!! (showPointsAsLine can handle nil values / gaps in the list)


                if lookAtLine then
                    --showPointsAsLine(self, lookAtLine, getshape, "") --show "end line"
                    newlines = {}
                    for i = 1, #data.row1 do
                        local newline = baseLib.getLinePoints(data.row1[i], lookAtLine[i])
                        if newline then
                            newlines[#newlines+1] = newline
                            showPointsAsLine(self, newline, getshape, "", false)
                        else
                            print("NO NEW LINE!?")
                        end
                    end
                else
                    showdefault = true
                end
            else
                showdefault = true
            end
        else
            showdefault = true
        end

        if showdefault then
            if lookAt then
                nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
            end
            showPointsAsLine(self, data.row1, getshape, "", false)
        end

        if primaryState == 1 and lookAt and newlines then --and lineShapes then
            data.row2 = newlines
            data.selected[3] = lookAt
            data.step = data.step + 1
        elseif secondaryState == 1 then
            data.selected[2] = nil
            data.step = data.step - 1
        end
    elseif data.step == 3 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the 1st corner of the 2nd plane of Logic Parts")
        if lookAt then
            nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
        end

        if primaryState == 1 and lookAt then
            data.selected[4] = lookAt
            data.step = data.step + 1
        elseif secondaryState == 1 then
            data.selected[3] = nil
            data.step = data.step - 1
        end
    elseif data.step == 4 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the 2nd corner of the 2nd plane of Logic Parts")

        local showdefault = false
        local linePoints
        if lookAt then
            if lookAt.body == data.selected[4].body then
                linePoints = baseLib.getLinePoints(baseLib.getLocalCenter(data.selected[4]), baseLib.getLocalCenter(lookAt))
                if linePoints then
                    showPointsAsLine(self, linePoints, getshape, "", false)
                else
                    showdefault = true
                end
            else
                showdefault = true
            end
        else
            showdefault = true
        end

        if showdefault then
            if lookAt then
                nameTagAdd(self, lookAt.worldPosition, "#00ff00O")           --point 2
            end
            nameTagAdd(self, data.selected[4].worldPosition, "#00ff00O") --point 1
        end

        if primaryState == 1 and lookAt and linePoints and #linePoints == #data.row1 then
            data.row3 = linePoints
            data.selected[5] = lookAt
            data.step = data.step + 1
        elseif secondaryState == 1 then
            data.selected[4] = nil
            data.step = data.step - 1
        end
    elseif data.step == 5 then
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Select the 3nd corner of the 1st plane of Logic Parts")

        local showdefault = false
        local newlines
        if lookAt then
            if lookAt.body == data.selected[5].body then

                local lookAtPoint = baseLib.getLocalCenter(lookAt)
                local lookAtLine
                local rowaxis = baseLib.getPointsAxis(data.row3[1], data.row3[#data.row3])
                for i = 1, #data.row3 do
                    local point = data.row3[i]
                    local axis = baseLib.getPointsAxis(lookAtPoint, point)
                    if axis and axis ~= rowaxis then
                        lookAtLine = {}
                        local offset = lookAtPoint - point
                        if sm.vec3.length(offset) ~= 0 then
                            for j = 1, #data.row3 do
                                lookAtLine[j] = data.row3[j] + offset
                            end
                        end
                    end
                end
                --lookAtLine will be the same length as data.row3!! (showPointsAsLine can handle nil values / gaps in the list)


                if lookAtLine then
                    --showPointsAsLine(self, lookAtLine, getshape, "") --show "end line"
                    newlines = {}
                    for i = 1, #data.row3 do
                        local newline = baseLib.getLinePoints(data.row3[i], lookAtLine[i])
                        if newline then
                            newlines[#newlines+1] = newline
                            showPointsAsLine(self, newline, getshape, "", false)
                        else
                            print("NO NEW LINE!?")
                        end
                    end
                else
                    showdefault = true
                end
            else
                showdefault = true
            end
        else
            showdefault = true
        end

        if showdefault then
            if lookAt then
                nameTagAdd(self, lookAt.worldPosition, "#00ff00O")
            end
            showPointsAsLine(self, data.row3, getshape, "", false)
        end

        if primaryState == 1 and lookAt and newlines and #newlines[1] == #data.row2[1] then --and lineShapes then
            data.row4 = newlines
            data.selected[6] = lookAt
            data.step = data.step + 1
        elseif secondaryState == 1 then
            data.selected[5] = nil
            data.step = data.step - 1
        end
    elseif data.step == 6 then
        if forceBuild and not data.lastF then
            data.mode = not data.mode
        end
        local str = ""
        if data.mode then
            str = "Disconnect"
        else
            str = "Connect"
        end
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Toggle", "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='4'>" .. str .. "<p>")
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Confirm")

        if primaryState == 1 then
            self.network:sendToServer("sv_connectInlineLines", { mode = data.mode, selected = data.selected, row1 = data.row1})
            InlineConnect.onUnequip(self)
            data.step = 0
        elseif secondaryState == 1 then
            data.selected[6] = nil
            data.step = data.step - 1
        end
    end

    data.lastF = forceBuild
    nameTagCleanup(self)
    Matrix2Connect.data = data
end

function Matrix2Connect.onUnequip(self)
    local data = Matrix2Connect.data
    data.step = 0
    nameTagNextTick(self)
    nameTagCleanup(self)
    Matrix2Connect.data = data
end