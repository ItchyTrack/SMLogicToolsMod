-- color.lua by HerrVincling, 13.03.2022
dofile("output.lua")
__uuids = {
    ["931dfeb6-5286-464d-a965-d310889df33c"] = true, --Color Connection Maker
    ["aa26c947-bf15-4bc2-98ae-e8bb49af9c70"] = true, --Color Connection Remover
    ["cd30fbe7-5bf8-4e82-91dc-ea951b91fad7"] = true, --Relative Color Connection Maker
	["f52c3e45-8d5f-4c34-b9ff-0cef2516e0a4"] = true  --Color Connection Copy/Paste
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

local function findPeripherals(self, inter)
	local parents = inter:getParents()
	local data = {}
	for i = 1, #parents do
		local parent = parents[i]
		if parent:getShape():getShapeUuid() == sm.uuid.new("8f23b687-b62e-4b64-9323-e834111eb35d") then --Peripheral block
			local publicdata = parent:getPublicData()
            if publicdata then
                for j = 1, #publicdata do
                    data[publicdata[j][1]] = publicdata[j][2]
                end
            end
		end
	end

	return data
end

function colorTool2(self, func)
    --Look for peripheral parts
	local parents = self.interactable:getParents()
	local children = self.interactable:getChildren()
	local peripherals = {}
	local parenttools = {}
	local childtools = {}
	local toolpairs = {}

	for i = 1, #parents do
		local parentuuid = parents[i]:getShape():getShapeUuid()
		if parentuuid == self.shape:getShapeUuid() then
			toolpairs[#toolpairs + 1] = {parents[i], self.interactable}
		end
	end
	for i = 1, #children do
		local childuuid = children[i]:getShape():getShapeUuid()
		if childuuid == self.shape:getShapeUuid() then
			toolpairs[#toolpairs + 1] = {self.interactable, children[i]}
		end
	end

	local periphdata = {}
	for i = 1, #peripherals do
		local publicdata = peripherals[i]:getPublicData()
		for j = 1, #publicdata do
			periphdata[#periphdata + 1] = publicdata[j]
		end
	end

    local interpairs = {}
	local uuidblacklist = __uuids --{[self.shape:getShapeUuid():__tostring()] = true}
	for i = 1, #toolpairs do
		local toolpair = toolpairs[i]
		local data1 = findPeripherals(self, toolpair[1])
		local data2 = findPeripherals(self, toolpair[2])
		local inters1 = {}
		local inters2 = {}

		local creationshapes = self.shape.body:getCreationShapes()
		for i = 1, #creationshapes do
			local shape = creationshapes[i]
			local uuid = shape:getShapeUuid()
			local inter = shape:getInteractable()
			if inter and not uuidblacklist[uuid:__tostring()] then
				local color = shape:getColor()
				if color == toolpair[1]:getShape():getColor() then
					inters1[#inters1 + 1] = inter
					--inters1[inter.id] = inter
				end
				if color == toolpair[2]:getShape():getColor() then
					inters2[#inters2 + 1] = inter
					--inters2[inter.id] = inter
				end
			end
		end

		local relativePosition = data1["Relative Position"] or data2["Relative Position"]
		local stateFilter1 = data1["State"]
		local stateFilter1sub = data1["State"] == "Active"
		local stateFilter2 = data2["State"]
		local stateFilter2sub = data2["State"] == "Active"

		local diff1
		if relativePosition then
			local i1pos = toolpair[1]:getShape().worldPosition*4
			local i2pos = toolpair[2]:getShape().worldPosition*4
			diff1 = i1pos - i2pos
		end

		for i = 1, #inters1 do
			local inter1 = inters1[i]
			local continue1 = true

			--State Filter
			if continue1 and stateFilter1 then
				if inter1.active ~= stateFilter1sub then
					continue1 = false
				end
			end

			if continue1 then
				for j = 1, #inters2 do
					local inter2 = inters2[j]
					local continue2 = true
					--Relative Position
					if continue2 and relativePosition then
						local diff2 = inter1:getShape().worldPosition*4 - inter2:getShape().worldPosition*4
						local diffpos = diff1 - diff2
						diffpos = sm.vec3.new(math.floor(diffpos.x + 0.5), math.floor(diffpos.y + 0.5), math.floor(diffpos.z + 0.5))
						if diffpos:length() ~= 0 then
							continue2 = false
							--print("no length match")
						else
							--print("length match")
						end
					end

					--State Filter
					if continue2 and stateFilter2 then
						if inter2.active ~= stateFilter2sub then
							continue2 = false
						end
					end

					if continue2 then
                        interpairs[#interpairs+1] = {inter1, inter2}
						--[[if self.connect then
							inter1:connect(inter2)
						else
							inter1:disconnect(inter2)
						end]]
					end
				end
			end
		end
		--print(data1, data2)
	end

    local text = func(self, interpairs)
    local colors1 = {}
    local colors2 = {}
    local getColorIndicatorTextCharacter = getColorIndicatorTextCharacter
    for _, toolpair in pairs(toolpairs) do
        local i1 = toolpair[1]
        local i2 = toolpair[2]
        colors1[i1:getShape():getColor():getHexStr()] = true
        colors2[i2:getShape():getColor():getHexStr()] = true
    end
	local string1 = ""
	local string2 = ""
	for hexstr, _ in pairs(colors1) do
		string1 = string1 .. getColorIndicatorTextCharacter(hexstr)
	end
	for hexstr, _ in pairs(colors2) do
		string2 = string2 .. getColorIndicatorTextCharacter(hexstr)
	end


    server_message(self, {character = self.character, text = "#CCCCCC" .. text .. " (" .. string1 .. "#CCCCCC->" .. string2 .. "#CCCCCC)"})
end