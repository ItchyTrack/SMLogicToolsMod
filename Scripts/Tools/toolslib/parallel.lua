-- parallel.lua by HerrVincling, 13.03.2022

__allowedParallelTypes = {scripted = true, logic = true, timer = true, button = true, lever = true, sensor = true, survivalSensor = true}

function parallelTool(self, func)
    local shapes = self.shape:getBody():getCreationShapes()
    if #shapes == 0 then
        return
    end

    local validparts = {}
    for _, shape in pairs(shapes) do
        local i0 = shape:getInteractable()
        --Dark-gray & allowed type
        if i0 and shape:getColor() == sm.color.new(0x4A4A4Aff) and __allowedParallelTypes[i0:getType()] then

            for _, child in pairs(i0:getChildren()) do
                --Is connected to light grey
                if child:getShape():getColor() == sm.color.new(0x7F7F7Fff) and __allowedParallelTypes[child:getType()] then
                    table.insert(validparts, {i0 = i0, i1 = child})
                end
            end
        end
    end

    for _, partspair in pairs(validparts) do
        local black = findParallelChain(self, partspair.i0, sm.color.new(0x222222ff))
        if black == 1 then --ERROR
            partspair.i1:getShape():setColor(sm.color.new(0xEEEEEEff))
            return
        end

        local white = findParallelChain(self, partspair.i1, sm.color.new(0xEEEEEEff))
        if white == 1 then --ERROR
            partspair.i1:getShape():setColor(sm.color.new(0xEEEEEEff))
            return
        end

        if (#black == #white) then
            func(self, partspair.i0, partspair.i1, black, white)
        else
            server_message(self, {text = "#D02525Error: Black & White amount mismatch", tool = "#D02525[" .. self.tool .. "]"})
        end
        partspair.i1:getShape():setColor(sm.color.new(0xEEEEEEff))
    end
end



function findParallelChain(self, interactable, color)
    local chain = {}
    local search = true
    local newNeighbours = interactable:getShape():getNeighbours()
    local neighbours = newNeighbours
    local newLG = false
    while search do
        neighbours = newNeighbours
        search = false
        local counter = 0
        for _, neighbour in pairs(neighbours) do
            if neighbour:getInteractable() and neighbour:getColor() == color then
                counter = counter + 1
            end
        end
        if counter > 2 then
            server_message(self, {text = "#D02525Error: Failed to follow chain of gates, no matrices allowed!", tool = "#D02525[" .. self.tool .. "]"})
            return 1
        end
        for _, neighbour in pairs(neighbours) do
            local i1 = neighbour:getInteractable()
            if i1 and neighbour:getColor() == color then
                newLG = true
                for _, blackLG in pairs(chain) do
                    if blackLG == i1 then
                        newLG = false
                    end
                end
                if newLG then
                    newNeighbours = neighbour:getNeighbours()
                    table.insert(chain, i1)
                    search = true
                end
            end
        end
    end
    return chain
end