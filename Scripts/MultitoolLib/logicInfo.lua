--  by HerrVincling, 04.07.2022
LogicInfo = {}
--[[ client ]]
LogicInfo.cl_onCreate = function(self )
    LogicInfo.mode = 0
    LogicInfo.active = false

    LogicInfo.lasttick = 0
    LogicInfo.painter = {}
    LogicInfo.painter.paintcounter = 0
    LogicInfo.painter.erasecounter = 0
    LogicInfo.painter.pickcounter = 0
    LogicInfo.painter.reloadcounter = 0
    LogicInfo.painter.paintmode = false --Surface/Piercing
    LogicInfo.hammer = {}
    LogicInfo.hammer.defensecounter = 0
    LogicInfo.oscillo = {}
    LogicInfo.oscillo.ticksOn = 0
    LogicInfo.oscillo.ticksOff = 0
    LogicInfo.oscillo.lastTick = sm.game.getCurrentTick()

    if LogicInfo.lastTick == nil then
        LogicInfo.lastTick = sm.game.getCurrentTick()
    end

    --Dynamic Config
    if LogicInfo.guidata == nil then
        LogicInfo.guidata = {}
        LogicInfo.guidata.connect = {}
        LogicInfo.guidata.connect.maintoggle = false
        LogicInfo.guidata.connect.buttons = {false, false, false}
        LogicInfo.guidata.connect.maintogglename = "Connect Tool Extension"
        LogicInfo.guidata.connect.togglenames = {"Show Amount of Connections", "Show Frequency", "Show Connection Limit"}

        LogicInfo.guidata.paint = {}
        LogicInfo.guidata.paint.maintoggle = false
        LogicInfo.guidata.paint.buttons = {false}
        LogicInfo.guidata.paint.maintogglename = "Paint Tool Extension"
        LogicInfo.guidata.paint.togglenames = {"Piercing Paint Mode (Toggle on R)"}

        LogicInfo.guidata.hammer = {}
        LogicInfo.guidata.hammer.maintoggle = false
        LogicInfo.guidata.hammer.buttons = {false}
        LogicInfo.guidata.hammer.maintogglename = "Sledgehammer Extension"
        LogicInfo.guidata.hammer.togglenames = {"Open #aaffffTHIS#ffffff GUI by blocking"}

        LogicInfo.guidata.tab = 1
        LogicInfo.guidata.tabs = {"", "connect", "paint", "hammer"}
    end

    --Static GUI initialization
    if LogicInfo.gui ~= nil then
        LogicInfo.gui:destroy()
    end
    LogicInfo.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/AdvancedTools.layout")
    LogicInfo.gui:setIconImage("Icon2", sm.uuid.new("8c7efc37-cd7c-4262-976e-39585f8527bf")) --Connect
    LogicInfo.gui:setIconImage("Icon3", sm.uuid.new("c60b9627-fc2b-4319-97c5-05921cb976c6")) --Paint
    LogicInfo.gui:setIconImage("Icon4", sm.uuid.new("ed185725-ea12-43fc-9cd7-4295d0dbf88b")) --Hammer

    LogicInfo.gui:setButtonCallback("BTN_MAIN_ON_true", "cl_LogicInfo_onButtonPress")
    LogicInfo.gui:setButtonCallback("BTN_MAIN_ON_false", "cl_LogicInfo_onButtonPress")
    LogicInfo.gui:setButtonCallback("BTN_MAIN_OF_true", "cl_LogicInfo_onButtonPress")
    LogicInfo.gui:setButtonCallback("BTN_MAIN_OF_false", "cl_LogicInfo_onButtonPress")
    for i = 1, 4, 1 do --The 4 Toggle Buttons & Tabs
        LogicInfo.gui:setButtonCallback("BTN" .. tostring(i) .. "_ON_" .. tostring(true), "cl_LogicInfo_onButtonPress")
        LogicInfo.gui:setButtonCallback("BTN" .. tostring(i) .. "_ON_" .. tostring(false), "cl_LogicInfo_onButtonPress")
        LogicInfo.gui:setButtonCallback("BTN" .. tostring(i) .. "_OF_" .. tostring(true), "cl_LogicInfo_onButtonPress")
        LogicInfo.gui:setButtonCallback("BTN" .. tostring(i) .. "_OF_" .. tostring(false), "cl_LogicInfo_onButtonPress")
        LogicInfo.gui:setButtonCallback("Tab" .. tostring(i), "cl_LogicInfo_onTabPress")
    end

    LogicInfo.onTabChange(self, "Tab" .. tostring(LogicInfo.guidata.tab))

end

LogicInfo.onTabChange = function(self, tabName)
    local tab = 0
    for i = 1, 4, 1 do
        local name = "Tab" .. tostring(i)
        LogicInfo.gui:setButtonState(name, name == tabName)
        if name == tabName then
            tab = i
        end
    end
    if tabName ~= "Tab1" then --Tabs2-4
        local tools = LogicInfo.guidata.tabs
        local data = LogicInfo.guidata[tools[tab]]
        LogicInfo.gui:setText("TEXT_MAIN", data.maintogglename)
        for i = 1, 4, 1 do
            local text = data.togglenames[i]
            if text then
                LogicInfo.gui:setText("TEXT" .. tostring(i), text)
                LogicInfo.setToggleState(self, "BTN" .. tostring(i), data.buttons[i])
                LogicInfo.gui:setVisible("BTN" .. tostring(i) .. "_none", true)
            else
                LogicInfo.gui:setText("TEXT" .. tostring(i), "")
                LogicInfo.setToggleInvisibile(self, "BTN" .. tostring(i))
                LogicInfo.gui:setVisible("BTN" .. tostring(i) .. "_none", false)
            end
        end
        LogicInfo.gui:setText("BTN1_ON_true", "ON") --Reset from tab1
        LogicInfo.gui:setText("BTN1_OF_false", "OFF")

        LogicInfo.gui:setVisible("Panel_none", not data.maintoggle)
        LogicInfo.gui:setVisible("Panel_BTN", data.maintoggle)
        LogicInfo.setToggleState(self, "BTN_MAIN", data.maintoggle)
    else --Tab1
        LogicInfo.gui:setText("TEXT_MAIN", "check out the other Tabs")
        for i = 1, 4, 1 do
            LogicInfo.gui:setText("TEXT" .. tostring(i), "")
            LogicInfo.gui:setVisible("BTN" .. tostring(i) .. "_none", i == 1)
            LogicInfo.setToggleInvisibile(self, "BTN" .. tostring(i))
        end
        LogicInfo.gui:setVisible("BTN1_ON_true", true)
        LogicInfo.gui:setText("BTN1_ON_true", "SAVE")
        LogicInfo.gui:setVisible("BTN1_OF_false", true)
        LogicInfo.gui:setText("BTN1_OF_false", "LOAD")

        LogicInfo.gui:setVisible("Panel_none", false)
        if LogicInfo.network then
            --print("block")
            --LogicInfo.gui:setText("TEXT1", "Store Config. in this Block")  --DEACTIVATED for Handheld version
            LogicInfo.gui:setVisible("Panel_BTN", true)
        else
            --print("hammer")
            --LogicInfo.gui:setText("TEXT1", "Store Config. in Block [no block]")  --DEACTIVATED for Handheld version
            LogicInfo.gui:setVisible("Panel_BTN", false)
        end
        LogicInfo.setToggleInvisibile(self, "BTN_MAIN")
    end
    LogicInfo.guidata.tab = tab
end

LogicInfo.onButtonPress = function(self, btnName)
    if LogicInfo.guidata.tab == 1 then
        if LogicInfo.network then
            if btnName == "BTN1_ON_true" then --SAVE
                local data = {}
                data.connect = {}
                data.connect.maintoggle = LogicInfo.guidata.connect.maintoggle
                data.connect.buttons = LogicInfo.guidata.connect.buttons
                data.paint = {}
                data.paint.maintoggle = LogicInfo.guidata.paint.maintoggle
                data.paint.buttons = LogicInfo.guidata.paint.buttons
                data.hammer = {}
                data.hammer.maintoggle = LogicInfo.guidata.hammer.maintoggle
                data.hammer.buttons = LogicInfo.guidata.hammer.buttons

                self.network:sendToServer("guiExchange", {op = "SAVE", guidata = data})
            elseif btnName == "BTN1_OF_false" then --LOAD
                LogicInfo.network:sendToServer("guiExchange", {op = "LOAD", character = sm.localPlayer.getPlayer()})
            end
        end
    else
        if btnName:sub(5,5) == "M" then --MAIN
            local bool = LogicInfo.autoToggleState(self, btnName, 8)
            LogicInfo.gui:setVisible("Panel_none", not bool)
            LogicInfo.gui:setVisible("Panel_BTN", bool)
            LogicInfo.guidata[LogicInfo.guidata.tabs[LogicInfo.guidata.tab]].maintoggle = bool --update global gui data
        else --BTN1-4
            local button = tonumber(btnName:sub(4, 4))
            local bool = LogicInfo.autoToggleState(self, btnName, 4)
            LogicInfo.guidata[LogicInfo.guidata.tabs[LogicInfo.guidata.tab]].buttons[button] = bool --update global gui data
            --print("success")
        end
    end
end

LogicInfo.updateGuiData = function(self, data)
    LogicInfo.guidata.connect.maintoggle = data.guidata.connect.maintoggle
    LogicInfo.guidata.connect.buttons = data.guidata.connect.buttons
    LogicInfo.guidata.paint.maintoggle = data.guidata.paint.maintoggle
    LogicInfo.guidata.paint.buttons = data.guidata.paint.buttons
    LogicInfo.guidata.hammer.maintoggle = data.guidata.hammer.maintoggle
    LogicInfo.guidata.hammer.buttons = data.guidata.hammer.buttons
end

LogicInfo.setToggleInvisibile = function(self, btnNameShort)
    LogicInfo.gui:setVisible(btnNameShort .. "_ON_true", false)
    LogicInfo.gui:setVisible(btnNameShort .. "_OF_true", false)
    LogicInfo.gui:setVisible(btnNameShort .. "_ON_false", false)
    LogicInfo.gui:setVisible(btnNameShort .. "_OF_false", false)
end

LogicInfo.setToggleState = function(self, btnNameShort, state)
    LogicInfo.gui:setVisible(btnNameShort .. "_ON_" .. tostring(state), true)
    LogicInfo.gui:setVisible(btnNameShort .. "_OF_" .. tostring(state), true)
    LogicInfo.gui:setVisible(btnNameShort .. "_ON_" .. tostring(not state), false)
    LogicInfo.gui:setVisible(btnNameShort .. "_OF_" .. tostring(not state), false)
end

LogicInfo.autoToggleState = function(self, btnName, nameLen)
    local state = btnName:sub(nameLen + 3, nameLen + 3) == "N" --ON
    local prevstate = btnName:sub(nameLen + 5, nameLen + 5) == "t" --true
    if state ~= prevstate then
        local btnNameShort = btnName:sub(1, nameLen)
        LogicInfo.gui:setVisible(btnNameShort .. "_ON_" .. tostring(state), true)
        LogicInfo.gui:setVisible(btnNameShort .. "_OF_" .. tostring(state), true)
        LogicInfo.gui:setVisible(btnNameShort .. "_ON_" .. tostring(not state), false)
        LogicInfo.gui:setVisible(btnNameShort .. "_OF_" .. tostring(not state), false)
    end
    return state
end

LogicInfo.client_onUpdate = function(self, deltaTime )
    if LogicInfo.interactionText1 then
        LogicInfo.cl_modifiedInteractionText(self, LogicInfo.interactionText1)
    end
    if LogicInfo.interactionText2 then
        LogicInfo.cl_modifiedInteractionText(self, LogicInfo.interactionText2)
    end
    --print(LogicInfo.interactionText1, LogicInfo.interactionText2)
end

LogicInfo.cl_modifiedInteractionText = function(self, table2)
    if #table2 == 1 then
        sm.gui.setInteractionText(table2[1])
    elseif #table2 == 2 then
        sm.gui.setInteractionText(table2[1], table2[2])
    elseif #table2 == 3 then
        sm.gui.setInteractionText(table2[1], table2[2], table2[3])
    elseif #table2 == 4 then
        sm.gui.setInteractionText(table2[1], table2[2], table2[3], table2[4])
    elseif #table2 == 5 then
        sm.gui.setInteractionText(table2[1], table2[2], table2[3], table2[4], table2[5])
    end
end

LogicInfo.cl_setInteractionText = function(self, lineNr, tbl)
    local table2 = {}
    for index, str1 in pairs(tbl) do
        if index % 2 == 1 then
            if str1 ~= "" then
                table.insert(table2, "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='5'>" .. str1 .. "</p>")
            else
                table.insert(table2, "")
            end
        else
            table.insert(table2, "<p textShadow='false' bg='gui_keybinds_bg_white' color='#222222' spacing='5'>" .. str1 .. "</p>")
        end
    end

    if lineNr == 1 then
        LogicInfo.interactionText1 = table2
    elseif lineNr == 2 then
        LogicInfo.interactionText2 = table2
    end
end

LogicInfo.client_onInteract = function(self, character, state )
    self.character = character
    if state then
        if character:isCrouching() then
            self.network:sendToServer("server_trigger", {character = character, crouching = true})
        else
            self.network:sendToServer("server_trigger", {character = character, crouching = false})
        end
        LogicInfo.network = self.network
        if LogicInfo.guidata.tab == 1 then
            self:onTabChange("Tab1")
        end
        LogicInfo.gui:open()
    end
end

LogicInfo.client_displayAlert = function(self, message)
    sm.gui.displayAlertText(message)
end

LogicInfo.tools = {
    [1] = function(self) --start_sledgehammer_guard_into
        LogicInfo.network = nil
        if LogicInfo.guidata.tab == 1 then
            LogicInfo.onTabChange(self, "Tab1")
        end
        LogicInfo.gui:open()
    end, --hammer open gui
    [2] = function(self, interactable) --holding_connect_tool connection count
        LogicInfo.cl_setInteractionText(self, 1, {"", "Connections"})
        LogicInfo.cl_setInteractionText(self, 2, {"", "Input", tostring(#interactable:getParents()), "Output", tostring(#interactable:getChildren())})
    end, --connect tool connection count
    [3] = function(self, interactable) --holding_connect_tool frequency measurement
        local id = interactable:getId()
        local currentTick = sm.game.getCurrentTick()
        if id ~= LogicInfo.oscillo.id then
            LogicInfo.oscillo.id = id
            LogicInfo.oscillo.hz = 0
            LogicInfo.oscillo.lastState = interactable.active
            LogicInfo.oscillo.lastTick = currentTick
            LogicInfo.oscillo.ticksOn = 0
            LogicInfo.oscillo.ticksOff = 0
        elseif LogicInfo.oscillo.lastState ~= interactable.active then
            LogicInfo.oscillo.lastState = interactable.active
            if interactable.active then
                LogicInfo.oscillo.ticksOff = currentTick - LogicInfo.oscillo.lastTick
            else
                LogicInfo.oscillo.ticksOn = currentTick - LogicInfo.oscillo.lastTick
            end
            LogicInfo.oscillo.lastTick = currentTick

            local oldhz = LogicInfo.oscillo.hz
            local ticksTotal = LogicInfo.oscillo.ticksOff + LogicInfo.oscillo.ticksOn
            if ticksTotal == 0 then
                LogicInfo.oscillo.hz = 0
            else
                LogicInfo.oscillo.hz = 1/(ticksTotal/40)
                LogicInfo.oscillo.hz = (0.2 * oldhz + 0.8 * LogicInfo.oscillo.hz)
                LogicInfo.oscillo.hz = math.floor((LogicInfo.oscillo.hz) * 100 + 0.5) / 100
            end
        elseif currentTick - LogicInfo.oscillo.lastTick > 400 then
            LogicInfo.oscillo.hz = 0
        end
        LogicInfo.cl_setInteractionText(self, 1, { "", "Signal Frequency" })
        LogicInfo.cl_setInteractionText(self, 2, { "", tostring(LogicInfo.oscillo.ticksOn) .. " | " .. tostring(LogicInfo.oscillo.ticksOff), "Ticks on|off", tostring(LogicInfo.oscillo.hz), "Hz" })
    end, --connect tool frequency
    [4] = function(self, interactable, lookat)
        local uuidtable = { ["9f0f56e8-2c31-4d83-996c-d00a9b296c3f"] = {input = 255, output = 255}, ["7cf717d7-d167-4f2d-a6e7-6b2c70aa3986"] = {input = 0, output = 255}, ["1e8d93a4-506b-470d-9ada-9c0a321e2db5"] = {input = 0, output = 255}, ["8f7fd0e7-c46e-4944-a414-7ce2437bb30f"] = {input = 1, output = 255}, ["1d4793af-cb66-4628-804a-9d7404712643"] = {input = 0, output = 255}, ["cf46678b-c947-4267-ba85-f66930f5faa4"] = {input = 0, output = 255}, ["90fc3603-3544-4254-97ef-ea6723510961"] = {input = 0, output = 255}, ["de018bc6-1db5-492c-bfec-045e63f9d64b"] = {input = 0, output = 255}, ["20dcd41c-0a11-4668-9b00-97f278ce21af"] = {input = 0, output = 255}, ["598d865c-324c-4129-9c57-21a6abd2cb2e"] = {input = 1, output = 0}, ["1872d83a-d1a1-4cb7-ad46-9e4468d2548c"] = {input = 1, output = 0}, ["6bb84152-c4d7-4644-bc37-a3becd79298d"] = {input = 1, output = 0}, ["2354cd24-3dd3-4db5-84ab-df64c32d2c72"] = {input = 1, output = 0}, ["a092359d-5cea-484d-a274-470d9a567632"] = {input = 1, output = 0}, ["df8528ed-15ad-4a39-a33a-698880684001"] = {input = 1, output = 0}, ["9fc793b2-250b-40ab-bcb3-97cf97c7b481"] = {input = 1, output = 0}, ["4c1cc8de-7af1-4f8e-a5c4-c583460af9e5"] = {input = 1, output = 0}, ["e6db321c-6f98-47f6-9f7f-4e6794a62cb8"] = {input = 1, output = 0}, ["a736ffdf-22c1-40f2-8e40-988cab7c0559"] = {input = 1, output = 0}}
        if interactable.type == "scripted" then
            local childCount = interactable:getMaxChildCount()
            local parentCount = interactable:getMaxParentCount()
            LogicInfo.cl_setInteractionText(self, 1, { "", "Connection Limit" })
            LogicInfo.cl_setInteractionText(self, 2, { "", "Input", tostring(parentCount), "Output", tostring(childCount) })
        else
            local io = uuidtable[lookat:getShapeUuid():__tostring()]
            if io then
                LogicInfo.cl_setInteractionText(self, 1, { "", "Connection Limit" })
                LogicInfo.cl_setInteractionText(self, 2, { "", "Input", tostring(io.input), "Output", tostring(io.output) })
            else
                LogicInfo.cl_setInteractionText(self, 1, { "", "Connection Limit" })
                LogicInfo.cl_setInteractionText(self, 2, { "", "Input", "?", "Output", "?" })
            end
        end
    end, --connect tool max connections
    [5] = function(self) --Gets called when R is pressed (Paint Tool)
        if LogicInfo.painter.paintmode then
            LogicInfo.painter.paintmode = false --Surface Mode (Default)
        else
            LogicInfo.painter.paintmode = true --Piercing Mode
        end
    end, --paint tool switch mode
    [6] = function(self, trigger)
        if LogicInfo.painter.paintmode then
            local direction = sm.camera.getDirection()
            local startpos = sm.camera.getPosition()
            local character = sm.localPlayer.getPlayer():getCharacter()
            local erase = trigger == "painttool_erase"
            local endpos = startpos + direction * 20
            local hit, result = sm.physics.raycast(startpos, endpos, character)
            if hit then
                local shape = result:getShape()
                if shape then
                    if sm.item.isPart(shape:getShapeUuid()) then
                        --print("piercing")
                        self.network:sendToServer("sv_pierceColor", {direction = direction, position = startpos, color = shape:getColor(), shape = shape, erase = erase})
                    else
                        --print("error3")
                    end
                else
                    --print("error2")
                end
            else
                --print("error1")
            end
        end
    end --paint tool apply paint
}





LogicInfo.main = function(self)
    local character = sm.localPlayer.getPlayer():getCharacter()
    local item = sm.localPlayer.getActiveItem()
    local uuids = {
        sledgehammer = sm.uuid.new("ed185725-ea12-43fc-9cd7-4295d0dbf88b"),
        painttool = sm.uuid.new("c60b9627-fc2b-4319-97c5-05921cb976c6"),
        connecttool = sm.uuid.new("8c7efc37-cd7c-4262-976e-39585f8527bf")
    }
    if self.animdata == nil then
        self.animdata = {}
    end

    if item == uuids.sledgehammer then --Sledgehammer

    elseif item == uuids.painttool then --Paint Tool

    elseif item == uuids.connecttool then --Connect Tool

    end
end







LogicInfo.cl_applyTools = function(self, trigger)
    --print(trigger)
    if trigger == "start_sledgehammer_guard_into" then
        if LogicInfo.guidata.hammer.buttons[1] and LogicInfo.guidata.hammer.maintoggle then
            LogicInfo.tools[1]()
        end
    elseif trigger == "holding_connect_tool" then
        local lookat = LogicInfo.findConnectDots(self)
        if lookat then
            local interactable = lookat:getInteractable()
            if LogicInfo.guidata.connect.buttons[1] and LogicInfo.guidata.connect.maintoggle then
                LogicInfo.tools[2](self, interactable)
            elseif LogicInfo.guidata.connect.buttons[2] and LogicInfo.guidata.connect.maintoggle then
                LogicInfo.tools[3](self, interactable)
            elseif LogicInfo.guidata.connect.buttons[3] and LogicInfo.guidata.connect.maintoggle then
                LogicInfo.tools[4](self, interactable, lookat)
            end
        else
            LogicInfo.interactionText1 = nil
            LogicInfo.interactionText2 = nil
        end
    elseif trigger == "start_painttool_reload" then
        if LogicInfo.guidata.paint.buttons[1] and LogicInfo.guidata.paint.maintoggle then
            LogicInfo.tools[5](self)
        end
    elseif trigger == "start_painttool_paint" or trigger == "painttool_erase" then
        if LogicInfo.guidata.paint.buttons[1] and LogicInfo.guidata.paint.maintoggle then
            LogicInfo.tools[6](self, trigger)
        end
    end
end

LogicInfo.sv_pierceColor = function(self, data)
    --print(data)
    local direction = data.direction
    local color = data.color
    local result = data.shape
    --result:setColor(self.shape:getColor()) --already painted by paint tool lol
    local search = true
    local refpos = result:getWorldPosition() + direction/4
    local neighbours = result:getNeighbours()
    while search do
        search = false
        local min = 10
        local nbresult
        for _, neighbour in pairs(neighbours) do
            local npos = neighbour:getWorldPosition()
            --print(neighbour, npos, refpos, sm.vec3.length(npos - refpos))
            if sm.vec3.length(npos - refpos) < 0.18 then
                min = sm.vec3.length(npos - refpos)
                nbresult = neighbour
            end
        end
        --print(nbresult)
        if nbresult ~= nil then
            if sm.item.isPart(nbresult:getShapeUuid()) then
                if data.erase then
                    nbresult:setColor(sm.item.getShapeDefaultColor(nbresult:getShapeUuid()))
                else
                    nbresult:setColor(color)
                end
                search = true
                refpos = nbresult:getWorldPosition() + direction/4
                min = 10
                neighbours = nbresult:getNeighbours()
            end
        end
        if nbresult == nil then
            search = false
        end
        nbresult = nil
        --nbresult:setColor(self.shape:getColor())
    end
end

LogicInfo.client_onFixedUpdate = function(self, deltaTime)
    if LogicInfo.lastTick ~= sm.game.getCurrentTick() then
        LogicInfo.lastTick = sm.game.getCurrentTick()
        LogicInfo.cl_findAnimations(self)
    end
end

LogicInfo.cl_findAnimations = function(self)
    local player = sm.localPlayer.getPlayer()
    local character = player:getCharacter()

    if sm.localPlayer.getActiveItem() == sm.uuid.new("8c7efc37-cd7c-4262-976e-39585f8527bf") then --Connect Tool
        local anims = character:getActiveAnimations()
        for _, anim in pairs(anims) do
            if anim.name:find("use", 1, true) then
                --print("using")
                --print(anim)
            end
        end
        LogicInfo.cl_applyTools(self, "holding_connect_tool")
    else
        LogicInfo.interactionText1 = nil
        LogicInfo.interactionText2 = nil
    end

    if sm.localPlayer.getActiveItem() == sm.uuid.new("ed185725-ea12-43fc-9cd7-4295d0dbf88b") then --Sledgehammer
        local anims = character:getActiveAnimations()
        for _, anim in pairs(anims) do
            if anim.name == "sledgehammer_guard_into" then
                if sm.game.getCurrentTick() - LogicInfo.hammer.defensecounter > 1 then
                    LogicInfo.cl_applyTools(self, "start_sledgehammer_guard_into")
                end
                LogicInfo.hammer.defensecounter = sm.game.getCurrentTick()
            end
        end
        LogicInfo.cl_applyTools(self, "holding_sledgehammer")
    end
    if sm.game.getCurrentTick() - LogicInfo.hammer.defensecounter == 1 then
        LogicInfo.cl_applyTools(self, "end_sledgehammer_guard_into")
    end

    if sm.localPlayer.getActiveItem() == sm.uuid.new("c60b9627-fc2b-4319-97c5-05921cb976c6") then --Paint Tool
        if LogicInfo.guidata.paint.buttons[1] and LogicInfo.guidata.paint.maintoggle then
            if LogicInfo.painter.paintmode then
                LogicInfo.interactionText1 = { "", sm.gui.getKeyBinding("Reload", true), "Piercing Mode" }
                --sm.gui.displayAlertText("Piercing Mode", 1)
            else
                LogicInfo.interactionText1 = { "", sm.gui.getKeyBinding("Reload", true), "Surface Mode (Default)" }
                --sm.gui.displayAlertText("Surface Mode (Default)", 1)
            end
        end
        local anims = character:getActiveAnimations()
        for _, anim in pairs(anims) do
            if anim.name == "painttool_paint" then --formerly "painttool_idle_select" --will be *while* holding LMB -> draggable surface (useful y/n?)
                if sm.game.getCurrentTick() - LogicInfo.painter.paintcounter > 1 then --painting
                    LogicInfo.cl_applyTools(self, "start_painttool_paint")
                end
                LogicInfo.painter.paintcounter = sm.game.getCurrentTick()
            end
            if anim.name == "painttool_erase" then --will trigger for a short period when releasing RMB (doesn't need all that trigger stuff)
                if sm.game.getCurrentTick() - LogicInfo.painter.erasecounter > 1 then --erasing
                    LogicInfo.cl_applyTools(self, "painttool_erase")
                end
                LogicInfo.painter.erasecounter = sm.game.getCurrentTick()
            end
            if anim.name == "painttool_colorpick_idle" then
                if sm.game.getCurrentTick() - LogicInfo.painter.pickcounter > 1 then --picking color
                    LogicInfo.cl_applyTools(self, "start_painttool_colorpick_idle")
                end
                LogicInfo.painter.pickcounter = sm.game.getCurrentTick()
            end
            if anim.name == "painttool_reload" then
                if sm.game.getCurrentTick() - LogicInfo.painter.reloadcounter > 1 then --reloading
                    LogicInfo.cl_applyTools(self, "start_painttool_reload")
                end
                LogicInfo.painter.reloadcounter = sm.game.getCurrentTick()
            end
        end
        LogicInfo.cl_applyTools(self, "holding_paint_tool")
    end
    if sm.game.getCurrentTick() - LogicInfo.painter.paintcounter == 1 then
        LogicInfo.cl_applyTools(self, "end_painttool_paint")
    end
    if sm.game.getCurrentTick() - LogicInfo.painter.pickcounter == 1 then
        LogicInfo.cl_applyTools(self, "end_painttool_colorpick_idle")
    end
    if sm.game.getCurrentTick() - LogicInfo.painter.reloadcounter == 1 then
        LogicInfo.cl_applyTools(self, "end_painttool_reload")
    end
end

LogicInfo.findConnectDots = function(self )
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
        local distance = LogicInfo.distancePointLine(self, shape.worldPosition, position, position + direction * 10)
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
    if LogicInfo.lookatinter ~= lookatinter then
        LogicInfo.lookatinter = lookatinter
    end
end

LogicInfo.distancePointLine = function(self, point, linePoint1, linePoint2)
    local AB = linePoint2 - linePoint1
    local AC = point - linePoint1
    local area = sm.vec3.length(sm.vec3.cross(AB, AC))
    local CD = area / sm.vec3.length(AB)
    return CD
end

--[[ server ]]
LogicInfo.guiExchange = function(self, data)
    if data.op == "SAVE" then
        self.storage:save({guidata = data.guidata})
    elseif data.op == "LOAD" then
        if not self.storage:load() then
            return
        end
        self.network:sendToClient(data.character, "updateGuiData", {guidata = self.storage:load().guidata})
    end
end