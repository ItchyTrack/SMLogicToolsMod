-- quickGateConverter.lua by HerrVincling
Converter = {}

local function replace_char(pos, str, r)
    return str:sub(1, pos-1) .. r .. str:sub(pos+1)
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function Converter.cl_aim(self, primaryState, secondaryState, raycastResult)
    if raycastResult.valid then
        local targetBody
        if raycastResult.type == "joint" then
            targetBody = raycastResult:getJoint().shapeA.body
        elseif raycastResult.type == "body" then
            targetBody = raycastResult:getBody()
        end
        --print(targetBody)
        if targetBody then
            if targetBody:isOnLift() then
                sm.gui.setInteractionText("Creation can't be on lift")
                return
            end
            sm.visualization.setCreationBodies(targetBody:getCreationBodies())
            sm.visualization.setCreationFreePlacement( false )
            sm.visualization.setCreationValid( true, true )
            sm.visualization.setLiftValid( true )
            sm.visualization.setCreationVisible( true )


            if primaryState == 1 then
                if self.confirmed == 1 then
                    self.confirmed = 0
                    self.network:sendToServer("sv_convertBody", {body = targetBody, wantedType = "QuickLogic"})
                    --sm.gui.displayAlertText("Successfully converted to Quick Logic")
                else
                    self.confirmed = 1
                    --sm.gui.displayAlertText("Convert to Quick Logic? Click again to confirm")
                end
            elseif secondaryState == 1 then
                if self.confirmed == 2 then
                    self.confirmed = 0
                    self.network:sendToServer("sv_convertBody", {body = targetBody, wantedType = "VanillaLogic"})
                    --sm.gui.displayAlertText("Successfully converted to Vanilla Logic")
                else
                    self.confirmed = 2
                    --sm.gui.displayAlertText("Convert to Vanilla Logic? Click again to confirm")
                end
            end

            if self.confirmed == 1 then
                sm.gui.setInteractionText("Convert to #00FF00Quick Logic#ffffff? Click again to confirm")
            elseif self.confirmed == 2 then
                sm.gui.setInteractionText("Convert to #DF7F00Vanilla Logic#ffffff? Click again to confirm")
            else
                sm.gui.setInteractionText("Convert EVERY part:", sm.gui.getKeyBinding("Create", true), "to #00FF00Quick Logic#ffffff", sm.gui.getKeyBinding("Attack", true), "to #DF7F00Vanilla Logic#ffffff")
            end

        else
            self.confirmed = 0
            sm.gui.setInteractionText("Aim at a creation")
        end
    else
        sm.gui.setInteractionText("Aim at a creation")
    end
end

function Converter.sv_convertBody(self, data)
    --"QuickLogic" or "Vanilla"
    local body = data.body
    local wantedType = data.wantedType
    local jsontable = sm.creation.exportToTable(body, true, false) --'true, false' fix for qtimer reset bug?
    --print(jsontable.bodies)
    if wantedType == "QuickLogic" then
        for i = 1, #jsontable.bodies do
            --print(jsontable.bodies[i].childs)
            for j = 1, #jsontable.bodies[i].childs do
                if jsontable.bodies[i].childs[j].shapeId == "9f0f56e8-2c31-4d83-996c-d00a9b296c3f" then --Vanilla Gate
                    --print(jsontable.bodies[i].childs[j])
                    jsontable.bodies[i].childs[j].shapeId = "bc336a10-675a-4942-94ce-e83ecb4b501a"

                    local mode = jsontable.bodies[i].childs[j].controller.mode
                    local childdata
                    if mode == 0 then
                        childdata = "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgA"
                    elseif mode == 1 then
                        childdata = "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgB"
                    elseif mode == 2 then
                        childdata = "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgC"
                    elseif mode == 3 then
                        childdata = "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgD"
                    elseif mode == 4 then
                        childdata = "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgE"
                    elseif mode == 5 then
                        childdata = "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgF"
                    end

                    jsontable.bodies[i].childs[j].controller.data = childdata
                    jsontable.bodies[i].childs[j].controller.mode = nil
                    jsontable.bodies[i].childs[j].controller.active = nil
                    --print(jsontable.bodies[i].childs[j])
                end
                if jsontable.bodies[i].childs[j].shapeId == "8f7fd0e7-c46e-4944-a414-7ce2437bb30f" then --Vanilla Timer
                    --print(jsontable.bodies[i].childs[j])
                    jsontable.bodies[i].childs[j].shapeId = "a1180139-1b10-4e6a-8d6f-6aaf7b1785bc"

                    local childdata = "0ExVQQAAAAEFAAAAAgIFAPAHgHRpY2tzCAAEAAAAB3NlY29uZHMIAA"
                    local binarr = {}
                    local bincount = 1
                    for k = #childdata, 1, -1 do
                        local char = string.sub(childdata, k, k)
                        --print(char)
                        local index, _ = string.find(b, char)
                        --print(index)
                        for l = 0, 5 do
                            if bit.band(index, 2 ^ l) > 0 then
                                binarr[bincount] = 1
                                bincount = bincount + 1
                            else
                                binarr[bincount] = 0
                                bincount = bincount + 1
                            end
                        end
                    end

                    local seconds = 4 + jsontable.bodies[i].childs[j].controller.seconds
                    for i = 5, 10 do
                        if bit.band(seconds, 2 ^ (i-5)) > 0 then
                            binarr[i] = 1
                        else
                            binarr[i] = 0
                        end
                    end
                    local ticks = 16 + jsontable.bodies[i].childs[j].controller.ticks
                    for i = 117, 122 do
                        if bit.band(ticks, 2 ^ (i-117)) > 0 then
                            binarr[i] = 1
                        else
                            binarr[i] = 0
                        end
                    end

                    --print(childdata)
                    local newchilddata = childdata
                    bincount = 1
                    for k = #childdata, 1, -1 do
                        local index = 0
                        for l = 0, 5 do
                            if binarr[bincount] == 1 then
                                index = index + 2 ^ l
                            end
                            bincount = bincount + 1
                        end
                        --childdata[k] = b[index]
                        local char = string.sub(b, index, index)
                        newchilddata = replace_char(k, newchilddata, char)
                    end

                    --print(newchilddata)

                    -- Check for differences between newchilddata and childdata
                    --[[local tempstring = ""
                    for i = 1, #newchilddata do
                        if string.sub(newchilddata, i, i) ~= string.sub(childdata, i, i) then
                            tempstring = tempstring .. "^"
                        else
                            tempstring = tempstring .. " "
                        end
                    end
                    print(tempstring)]]
                    jsontable.bodies[i].childs[j].controller.data = newchilddata
                    jsontable.bodies[i].childs[j].controller.active = nil
                    jsontable.bodies[i].childs[j].controller.seconds = nil
                    jsontable.bodies[i].childs[j].controller.ticks = nil
                    --print(jsontable.bodies[i].childs[j])
                    --print()
                end
            end
        end
    elseif wantedType == "VanillaLogic" then
        for i = 1, #jsontable.bodies do
            for j = 1, #jsontable.bodies[i].childs do
                if jsontable.bodies[i].childs[j].shapeId == "bc336a10-675a-4942-94ce-e83ecb4b501a" then --qgate
                    --print(jsontable.bodies[i].childs[j])
                    jsontable.bodies[i].childs[j].shapeId = "9f0f56e8-2c31-4d83-996c-d00a9b296c3f"

                    local childdata = jsontable.bodies[i].childs[j].controller.data
                    local mode
                    if childdata == "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgA" then
                        mode = 0
                    elseif childdata == "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgB" then
                        mode = 1
                    elseif childdata == "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgC" then
                        mode = 2
                    elseif childdata == "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgD" then
                        mode = 3
                    elseif childdata == "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgE" then
                        mode = 4
                    elseif childdata == "gExVQQAAAAEFBQDAAgAAAAIAbW9kZQgF" then
                        mode = 5
                    else
                        sm.gui.chatMessage("#ff0000Fatal error while converting QGates, please send a screenshot of this to HerrVincling :)")
                        sm.gui.chatMessage(childdata)
                        return
                    end

                    jsontable.bodies[i].childs[j].controller.mode = mode
                    jsontable.bodies[i].childs[j].controller.active = false
                    jsontable.bodies[i].childs[j].controller.data = nil
                    --print(jsontable.bodies[i].childs[j])
                end
                if jsontable.bodies[i].childs[j].shapeId == "a1180139-1b10-4e6a-8d6f-6aaf7b1785bc" then --qtimer
                    --print(jsontable.bodies[i].childs[j])
                    -- LOTS of base64 converting and extracting corresponding bits of seconds & ticks

                    local childdata = jsontable.bodies[i].childs[j].controller.data

                    --print(childdata)
                    --WORKING 8BhMVUEAAAABBQAAAAICAAAAA4BzZWNvbmRzCAAEAAAABXRpY2tzCAg
                    --WORKING 8BhMVUEAAAABBQAAAAICAAAAA4BzZWNvbmRzCAAEAAAABXRpY2tzCBk
                    --NOT WORK 0ExVQQAAAAEFAAAAAgIFAPAHgHRpY2tzCAAEAAAAB3NlY29uZHMIAA
                    --NOT WORK 0ExVQQAAAAEFAAAAAgIFAPAHgHRpY2tzCAAEAAAAB3NlY29uZHMIAA
                    --childdata = string.sub(childdata, 1, -1)
                    --print(childdata)
                    --print(dec(childdata))
                    local binarr = {}
                    local bincount = 1
                    for k = #childdata, 1, -1 do
                        local char = string.sub(childdata, k, k)
                        --print(char)
                        local index, _ = string.find(b, char)
                        --print(index)
                        for l = 0, 5 do
                            if bit.band(index, 2 ^ l) > 0 then
                                binarr[bincount] = 1
                                bincount = bincount + 1
                            else
                                binarr[bincount] = 0
                                bincount = bincount + 1
                            end
                        end
                    end
                    --print(#childdata, #binarr)

                    -- Everything in strings
                    local binstr = table.concat(binarr)
                    --local secondbinstr = string.sub(binstr, 5, 10)
                    --local tickbinstr = string.sub(binstr, 117, 122)
                    --print(string.sub(binstr, 99, 104), string.sub(binstr, 3, 8))
                    --print(binstr)

                    -- Everything in tables
                    local seconds
                    local ticks
                    if string.sub(childdata, 1, 37) == '8BhMVUEAAAABBQAAAAICAAAAA4BzZWNvbmRzC' then
                        --8BhMVUEAAAABBQAAAAICAAAAA4BzZWNvbmRzC_AAEAAAABXRpY2tzCAg
                        --8BhMVUEAAAABBQAAAAICAAAAA4BzZWNvbmRzC_DAEAAAABXRpY2tzCCA
                        --8BhMVUEAAAABBQAAAAICAAAAA4BzZWNvbmRzC_DsEAAAABXRpY2tzCCg
                        --identical_different
                        --print('8B')
                        seconds = 0
                        for i = 99, 104 do -- used to be bits 5-10    |   99-104
                            if binarr[i] == 1 then
                                seconds = seconds + 2 ^ (i - 99) --used to be i - 5   |   i - 99
                            end
                        end
                        seconds = seconds - 16 --remove Offset
                        ticks = 0
                        for i = 3, 8 do -- used to be bits 117-122       |    3-8
                            if binarr[i] == 1 then
                                ticks = ticks + 2 ^ (i - 3) --used to be i - 117     |    i - 3
                            end
                        end
                        ticks = ticks - 16 --remove Offset --used to be -16
                    elseif string.sub(childdata, 1, 33) == '0ExVQQAAAAEFAAAAAgIFAPAHgHRpY2tzC' then
                        --0ExVQQAAAAEFAAAAAgIFAPAHgHRpY2tzC_AAEAAAAB3NlY29uZHMIAA
                        --0ExVQQAAAAEFAAAAAgIFAPAHgHRpY2tzC_CgEAAAAB3NlY29uZHMIOw
                        --print('0E')
                        seconds = 0
                        for i = 5, 10 do -- used to be bits 5-10    |   99-104
                            if binarr[i] == 1 then
                                seconds = seconds + 2 ^ (i - 5) --used to be i - 5   |   i - 99
                            end
                        end
                        seconds = seconds - 4 --remove Offset
                        ticks = 0
                        for i = 117, 122 do -- used to be bits 117-122       |    3-8
                            if binarr[i] == 1 then
                                ticks = ticks + 2 ^ (i - 117) --used to be i - 117     |    i - 3
                            end
                        end
                        ticks = ticks - 16 --remove Offset --used to be -16
                    else
                        sm.gui.chatMessage("#ff0000Fatal error while converting QTimers, please send a screenshot of this to HerrVincling :)")
                        sm.gui.chatMessage(childdata)
                        return
                    end

                    --print(seconds, ticks)
                    if (seconds < 0) or (seconds > 59) or (ticks < 0) or (ticks > 40) then
                        sm.gui.chatMessage("#ff0000Fatal error while converting QTimers, please send a screenshot of this to HerrVincling :)")
                        sm.gui.chatMessage(childdata .. " " .. seconds .. " " .. ticks)
                        return
                    end
                    jsontable.bodies[i].childs[j].shapeId = "8f7fd0e7-c46e-4944-a414-7ce2437bb30f"
                    jsontable.bodies[i].childs[j].controller.data = nil
                    jsontable.bodies[i].childs[j].controller.active = false
                    jsontable.bodies[i].childs[j].controller.seconds = seconds
                    jsontable.bodies[i].childs[j].controller.ticks = ticks
                    --print(jsontable.bodies[i].childs[j])
                end
            end
        end
    end

    --QGate  bc336a10-675a-4942-94ce-e83ecb4b501a
    --VGate  9f0f56e8-2c31-4d83-996c-d00a9b296c3f
    --QTimer a1180139-1b10-4e6a-8d6f-6aaf7b1785bc
    --VTimer 8f7fd0e7-c46e-4944-a414-7ce2437bb30f

    -- removing old body & spawning the new one
    local worldpos = body.worldPosition
    local worldrot = body.worldRotation
    local world = body:getWorld()

    local shapes = body:getCreationShapes()
    --print(shapes)
    for _, shape in pairs(shapes) do
        shape:destroyShape()
    end

    local jsonstring = sm.json.writeJsonString(jsontable)
    sm.creation.importFromString(world, jsonstring, worldpos, worldrot, false)
end
