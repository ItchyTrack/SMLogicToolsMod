baseLib = {}

function baseLib.lookAtConnectDot(self )
    local resultinter = {}
    local position = sm.camera.getPosition()
    local direction = sm.camera.getDirection()
    local endpoint = position + direction * 7.35
    for i = 0, 30, 1 do
        local hit, result = sm.physics.raycast(position, endpoint, sm.localPlayer.getPlayer():getCharacter())
        if hit then
            if result.type == "body" then
                local shape = result:getShape()
                local interactable = shape:getInteractable()
                if interactable then
                    resultinter[interactable:getId()] = shape
                end
            end
            position = result.pointWorld
        else
            break
        end
    end
    --print(resultinter)
    position = sm.camera.getPosition()
    local distancetable = {}
    local closest = 1
    local lookatinter
    for id, shape in pairs(resultinter) do
        local distance = baseLib.distancePointLine(self, shape.worldPosition, position, position + direction * 10)
        distancetable[id] = distance
        if distance < closest then
            lookatinter = shape
            closest = distance
        end
    end
    if lookatinter then
        --print(lookatinter:getId()) --0.125 is max radius/distance of connection dot
        if closest <= 0.125 then
            return lookatinter
            --self:manageNameTags({operation = "Set", vec = lookatinter.worldPosition, text = "Hi"})
        end
    end
end
--returns shape of interactable of connect dot you're looking at

function baseLib.getLocalCenter(shape)
    return shape:getLocalPosition() + shape.xAxis * 0.5 + shape.yAxis * 0.5 + shape.zAxis * 0.5
end

function baseLib.distancePointLine(self, point, linePoint1, linePoint2)
    local AB = linePoint2 - linePoint1
    local AC = point - linePoint1
    local area = sm.vec3.length(sm.vec3.cross(AB, AC))
    local CD = area / sm.vec3.length(AB)
    return CD
end

function baseLib.createNameTag(self, vec, text)
    local nametag = sm.gui.createNameTagGui()
    nametag:setWorldPosition(vec)
    nametag:setRequireLineOfSight(false)
    nametag:setMaxRenderDistance(30)
    nametag:setText("Text", text)
    nametag:open()
    return nametag
end

-- (i) nametag:destroy() to get rid of them again
function baseLib.createNameTagManager()
    local data = {}
    data.nameTags = {}
    data.counter = 1
    local function nextTick(self)
        data.counter = 1
    end

    local function nameTagAdd(self, worldPosition, text)
        if data.nameTags[data.counter] then
            data.nameTags[data.counter]:setWorldPosition(worldPosition)
            data.nameTags[data.counter]:setText("Text", text)
        else
            data.nameTags[data.counter] = baseLib.createNameTag(self, worldPosition, text)
        end
        data.counter = data.counter + 1
    end

    local function nameTagCleanup(self)
        for i = data.counter, #data.nameTags do
            data.nameTags[i]:destroy()
            data.nameTags[i] = nil
        end
    end
    return nameTagAdd, nameTagCleanup, nextTick
end




function baseLib.getPointsAxis(point1, point2)
    local diffvec = point1 - point2
    if sm.vec3.length(diffvec) == 0 then
        return
    end
    local diffvecnor = diffvec:normalize()
    if diffvecnor.y == 0 and diffvecnor.z == 0 then
        return "x"
    end
    if diffvecnor.x == 0 and diffvecnor.z == 0 then
        return "y"
    end
    if diffvecnor.x == 0 and diffvecnor.y == 0 then
        return "z"
    end
    return
end

function baseLib.pointsOnAxis(point1, point2)
    local diffvec = point1 - point2
    if sm.vec3.length(diffvec) == 0 then
        return false
    end
    local diffvecnor = diffvec:normalize()
    if diffvecnor.x ~= 0 and diffvecnor.x ~= 1 and diffvecnor.x ~= -1 then
        --print("not on axis")
        return false
    end
    if diffvecnor.y ~= 0 and diffvecnor.y ~= 1 and diffvecnor.y ~= -1 then
        --print("not on axis")
        return false
    end
    if diffvecnor.z ~= 0 and diffvecnor.z ~= 1 and diffvecnor.z ~= -1 then
        --print("not on axis")
        return false
    end
    return true
end

function baseLib.getLinePoints(pos1, pos2)
    if not baseLib.pointsOnAxis(pos1, pos2) then
        return
    end
    local diffvec = pos2 - pos1
    local diffvecnor = sm.vec3.normalize(diffvec)

    local points = {}
    points[#points+1] = pos1
    for i = 1, sm.vec3.length(diffvec) - 1 do
        points[#points+1] = pos1 + diffvecnor * i
    end
    points[#points+1] = pos2
    return points
end

function baseLib.getLineShapes2(self, shape1, shape2)
    --print("v2")
    if shape1.body ~= shape2.body then
        return
    end
    local getLocalCenter = baseLib.getLocalCenter
    local pos1 = getLocalCenter(shape1)
    local pos2 = getLocalCenter(shape2)
    if not baseLib.pointsOnAxis(pos1, pos2) then
        return
    end
    local diffvec = pos2 - pos1
    local diffvecnor = sm.vec3.normalize(diffvec)

    local bodyshapes = shape1.body:getShapes()
    local shapelookup = {}
    for i = 1, #bodyshapes do
        local shape = bodyshapes[i]
        if shape:getInteractable() then
            local localpos = getLocalCenter(shape)
            if shapelookup[localpos.x] == nil then
                shapelookup[localpos.x] = {}
            end
            if shapelookup[localpos.x][localpos.y] == nil then
                shapelookup[localpos.x][localpos.y] = {}
            end
            shapelookup[localpos.x][localpos.y][localpos.z] = shape
        end
    end

    local shapesOnAxis = {}
    shapesOnAxis[#shapesOnAxis+1] = shape1
    for i = 1, sm.vec3.length(diffvec) - 1 do
        local newvec = pos1 + diffvecnor * i
        local newshape = shapelookup[newvec.x][newvec.y][newvec.z]
        if newshape then
            shapesOnAxis[#shapesOnAxis+1] = newshape
        end
    end
    shapesOnAxis[#shapesOnAxis+1] = shape2
    return shapesOnAxis
end

--provided 2 shapes, it will look in the localgrid if their body has any shapes that are on the same axis and return them
function baseLib.getLineShapes(self, shape1, shape2)
    if shape1.body ~= shape2.body then
        return
    end
    local getLocalCenter = baseLib.getLocalCenter
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
