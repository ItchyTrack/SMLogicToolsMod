-- color.lua by HerrVincling, 13.03.2022
__uuids = {
    ["931dfeb6-5286-464d-a965-d310889df33c"] = true, --Color Connection Maker
    ["aa26c947-bf15-4bc2-98ae-e8bb49af9c70"] = true, --Color Connection Remover
    ["cd30fbe7-5bf8-4e82-91dc-ea951b91fad7"] = true  --Relative Color Connection Maker
}


function colorTool(self, func)
    local s0
    local s1
    --Check if the tool is wired up correctly
    local childs = self.interactable:getChildren()
    local childcount = 0
    for _, child in pairs(childs) do
        if child:getShape():getShapeUuid() == self.shape:getShapeUuid() then
            --Find tool partner & both colors
            --Will only persist if there's exactly 1 partner (aborts if childs/parents > 1)
            s0 = self.shape
            s1 = child:getShape()
            childcount = childcount + 1
        end
    end

    local parents = self.interactable:getParents()
    local parentcount = 0
    for _, parent in pairs(parents) do
        if parent:getShape():getShapeUuid() == self.shape:getShapeUuid() then
            --Find tool partner & both colors
            --Will only persist if there's exactly 1 partner (aborts if childs/parents > 1)
            s0 = parent:getShape()
            s1 = self.shape
            parentcount = parentcount + 1
        end
    end

    --Make sure there's only 1 partner tool
    if childcount == 0 and parentcount == 0 then
        server_message(self, {character = self.character, text = "#D02525No connections (connect 2 together)", tool = "#D02525[" .. self.tool .. "]"})
        return
    elseif childcount>1 and parentcount<2 then
        server_message(self, {character = self.character, text = "#D02525Too many outgoing connections (connect 2 together)", tool = "#D02525[" .. self.tool .. "]"})
        return
    elseif childcount<2 and parentcount>1 then
        server_message(self, {character = self.character, text = "#D02525Too many incoming connections (connect 2 together)", tool = "#D02525[" .. self.tool .. "]"})
        return
    elseif childcount>1 and parentcount>1 then
        server_message(self, {character = self.character, text = "#D02525Too many connections (connect 2 together)", tool = "#D02525[" .. self.tool .. "]"})
        return
    end

    --Apply tool to all shapes of the creation
    local shapes = self.shape:getBody():getCreationShapes()
    if #shapes == 0 then
        return
    end

    local color1list = {}
    local color2list = {}

    --Find all valid interactables
    for _, shape in pairs(shapes) do
        local interactable = shape:getInteractable()
        local uuid = shape:getShapeUuid()
        --Don't disconnect the tools ("scripted" includes the "color connect" & other tools)
        if interactable and uuid ~= self.shape:getShapeUuid() and not __uuids[uuid:__tostring()] then
            if shape:getColor() == s0:getColor() then
                if shape ~= s0 and shape ~= s1 then
                    table.insert(color1list, interactable)
                end
            end
            if shape:getColor() == s1:getColor() then
                if shape ~= s0 and shape ~= s1 then
                    table.insert(color2list, interactable)
                end
            end
        end
    end

    func(self, s0, s1, color1list, color2list)
end