local function tableLen(layer)
    local count = 0
    if layer then
        for _, _ in pairs(layer) do
            count = count + 1
        end
    end
    return count
end

local function getChildsOfTable(parents)
    local childs = {}
    for parent, _ in pairs(parents) do
        local parentchilds = childcache[parent]
        if parentchilds then
            for i = 1, #parentchilds do
                childs[parentchilds[i]] = true
            end
        end
    end
    return childs
end

local function getParentsOfTable(childs)
    local parents = {}
    for child, _ in pairs(childs) do
        local childparents = parentcache[child]
        if childparents then
            for i = 1, #childparents do
                parents[childparents[i]] = true
            end
        end
    end
    return parents
end

local function tableCollision(layer1, layer2)
    for part, _ in pairs(layer1) do
        if layer2[part] then
            return true
        end
    end
    return false
end

local function table2PartOfTable1(table1, table2)
    for part, _ in pairs(table2) do
        if table1[part] == nil then
            return
        end
    end
    return true
end

local function getLayerDown(parents, knownparts)
    local childs = getChildsOfTable(parents)
    --[[if tableLen(childs) == 0 then
        return
    end]]
    if tableCollision(childs, knownparts) then
        return
    end
    local parentlen = tableLen(parents)
    local newparents = getParentsOfTable(childs)
    local newparentlen = tableLen(newparents)
    if parentlen < newparentlen then
        return
    end
    if parentlen == 0 then
        return
    end
    if table2PartOfTable1(parents, newparents) then
        return childs
    end
end

local function getLayerUp(childs, knownparts)
    local parents = getParentsOfTable(childs)
    --[[if tableLen(parents) == 0 then
        return
    end]]
    if tableCollision(parents, knownparts) then
        return
    end
    local childlen = tableLen(childs)
    local newchilds = getChildsOfTable(parents)
    local newchildlen = tableLen(newchilds)
    if childlen < newchildlen then
        return
    end
    if childlen == 0 then
        return
    end
    if table2PartOfTable1(childs, newchilds) then
        return parents
    end
end

local function layerPair(layer)
    local parents = layer
    local parentcount = tableLen(parents)
    local childs = getChildsOfTable(parents)
    local childcount = tableLen(childs)
    if tableCollision(parents, childs) or childcount == 0 then
        return
    end

    for i = 1, 100000 do
        local newparents = getParentsOfTable(childs)
        local newpcount = tableLen(newparents)
        if newpcount == parentcount then
            break
        end
        if tableCollision(newparents, childs) then
            return
        end
        parents = newparents
        parentcount = newpcount

        local newchilds = getChildsOfTable(parents)
        local newccount = tableLen(newchilds)
        if newccount == childcount then
            break
        end
        if tableCollision(newchilds, parents) then
            return
        end
        childs = newchilds
        childcount = newccount
    end
    return {parents, childs}
end

local function addList2ToList1(list1, list2)
    for id, _ in pairs(list2) do
        list1[id] = true
    end
end

local function moveIndexUp(table1)
    for i = #table1, 1, -1 do
        table1[i+1] = table1[i]
    end
end

local function getBalancedCircuit(layer1)
    local layers = layerPair(layer1)
    if layers == nil then
        return
    end
    local knownparts = {}
    for i = 1, #layers do
        addList2ToList1(knownparts, layers[i])
    end
    for i = 2, 1000 do
        local newlayerdown = getLayerDown(layers[i], knownparts)
        if tableLen(newlayerdown) > 0 then
            addList2ToList1(knownparts, newlayerdown)
            layers[i+1] = newlayerdown
        else
            break
        end
    end
    for i = 1, 1000 do
        local newlayerup = getLayerUp(layers[1], knownparts)
        if tableLen(newlayerup) > 0 then
            addList2ToList1(knownparts, newlayerup)
            moveIndexUp(layers)
            layers[1] = newlayerup
        else
            break
        end
    end
    return { layers = layers, partcount = tableLen(knownparts) }
end

function balanced_circuits(childcache, parentcache)
    --[[
    --Creates a parentcache with only QLogic Parts
    local parentcache2 = {}
    for id, parentlist in pairs(parentcache) do
        local newparentlist = {}
        if parentlist then
            for i = 1, #parentlist do
                local parent = parentlist[i]
                if classlookup[parent] then
                    newparentlist[#newparentlist+1] = parent
                end
            end
        end
        parentcache2[id] = newparentlist
    end

    local qgates = oldmemberlist["QuickLogicGate"]
    local randint = math.random(1, #qgates)
    local gate = qgates[randint]

    local layers = {}

    local function balanced(upperlayer) end

    local childs = childcache[gate]
    --if true then return end
    local childparents = {}
    if childs then
        for j = 1, #childs do
            local parents = parentcache2[childs[j] ]
            if parents then
                for k = 1, #parents do
                    childparents[parents[k] ] = true
                end
            end
        end
    end
    --print(childparents)

    if true then return end]]

    --print()
    if sm.game.getCurrentTick() % 40 == 0 then

        local balancedCircuits = {}
        local qgates = oldmemberlist["QuickLogicGate"]
        for i = 1, #qgates do
            local balancedCircuit = getBalancedCircuit({[qgates[i]] = true})
            if balancedCircuit then
                --print(qgates[i])
                balancedCircuit.starter = qgates[i]
                balancedCircuits[#balancedCircuits+1] = balancedCircuit
            end
            local shape = interlist[qgates[i]]:getShape()
            local defaultcolor = sm.item.getShapeDefaultColor(shape:getShapeUuid())
            shape:setColor(defaultcolor)
        end

        --now sort by size
        --[[for i = 1, #balancedCircuits do
            print(balancedCircuits[i])
        end]]
        table.sort(balancedCircuits, function(a,b) return a.partcount < b.partcount end)
        --local colors = {sm.color.new(0xff000000),sm.color.new(0xffff0000),sm.color.new(0x00ff0000),sm.color.new(0x00ffff00),sm.color.new(0x0000ff00),sm.color.new(0x00000000)}
        local colors = {}
        for i = 0, 3 do
            colors[#colors+1] = sm.color.new(0xff000000 + i * 0x00400000)
        end
        for i = 1, 3 do
            colors[#colors+1] = sm.color.new(0xffff0000 - i * 0x40000000)
        end
        for i = 1, 3 do
            colors[#colors+1] = sm.color.new(0x00ff0000 + i * 0x00004000)
        end
        for i = 1, 3 do
            colors[#colors+1] = sm.color.new(0x00ffff00 - i * 0x00400000)
        end
        --print(colors)
        --print(balancedCircuits[1])
        local circuits = {}
        local usedparts = {}
        for i = #balancedCircuits, 1, -1 do
            local circuitlayers = balancedCircuits[i].layers
            local add = true
            for j = 2, #circuitlayers do
                for part, _ in pairs(circuitlayers[j]) do
                    if usedparts[part] then
                        add = false
                        break
                    end
                end
            end
            local inputlen = tableLen(circuitlayers[i])
            local outputlen = tableLen(circuitlayers[#circuitlayers])
            if inputlen > 8 or outputlen > 64 then
                add = false
            end
            if add then--and (inputlen > 3 or outputlen > 3) then
                circuits[#circuits+1] = balancedCircuits[i]
                for j = 2, #circuitlayers do
                    addList2ToList1(usedparts, circuitlayers[j])
                end
            end
        end

        print(#balancedCircuits, #circuits)

        for k = 1, #circuits do
            print(circuits[k].starter)
            local layers = circuits[k].layers

            for i = 1, #layers do
                local layer = layers[i]
                print(tableLen(layer))
                for id, _ in pairs(layer) do
                    local shape = interlist[id]:getShape()
                    shape:setColor(colors[i])
                end
            end
            local shape = interlist[circuits[k].starter]:getShape()
            shape:setColor(sm.color.new(0xffffff00))
        end
    end
end