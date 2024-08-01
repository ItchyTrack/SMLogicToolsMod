--[[
local newlines
        if lookAt then
            if lookAt.body == data.selected[3].body then

                local lookAtPoint = baseLib.getLocalCenter(lookAt)
                local lookAtLines
                for k = 1, #data.row2 do
                    local row = data.row2[k]
                    local rowaxis = baseLib.getPointsAxis(row[1], row[#row])
                    for i = 1, #row do
                        local point = row[i]
                        local axis = baseLib.getPointsAxis(lookAtPoint, point)
                        if axis and axis ~= rowaxis then

                            lookAtLines = {}
                            local offset = lookAtPoint - point
                            if sm.vec3.length(offset) ~= 0 then
                                for j = 1, #data.row2 do
                                    local newrow = {}
                                    local line = data.row2[j]
                                    for l = 1, #line do
                                        newrow[l] = line[l] + offset
                                    end
                                    lookAtLines[j] = newrow
                                end
                            end

                        end
                    end
                end
                --lookAtLines will be the same length as data.row2!! (showPointsAsLine can handle nil values / gaps in the list)


                if lookAtLines then
                    --showPointsAsLine(self, lookAtLine, getshape, "") --show "end line"
                    newlines = {}
                    for i = 1, #data.row2 do
                        local row = data.row2[i]
                        for j = 1, #row do
                            local newline = baseLib.getLinePoints(row[j], lookAtLines[i][j])
                            if newline then
                                newlines[#newlines+1] = newline
                                showPointsAsLine(self, newline, getshape, "", false)
                            else
                                print("NO NEW LINE!?")
                            end
                        end
                    end
                else
                    for i = 1, #data.row2 do
                        showPointsAsLine(self, data.row2[i], getshape, "", false)
                    end
                end
            end
        end

        if primaryState == 1 and lookAt then --and lineShapes then
            --[[data.row2 = newlines
            data.selected[3] = lookAt
            data.step = data.step + 1] ]
        elseif secondaryState == 1 then
            data.selected[3] = nil
            data.step = data.step - 1
        end





]]