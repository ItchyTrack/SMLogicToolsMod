-- QuickLogicGate.lua by HerrVincling, 05.06.2022

QuickLogicGate = class( nil )
QuickLogicGate.maxChildCount = -1
QuickLogicGate.maxParentCount = -1
QuickLogicGate.connectionInput = sm.interactable.connectionType.logic
QuickLogicGate.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
QuickLogicGate.colorNormal = sm.color.new(0x28BF4Eff) --4DBF86ff --0x26BF26ff
QuickLogicGate.colorHighlight = sm.color.new(0x40D666ff) --0x41D841ff

--GenericClass.poseWeightCount = 1
dofile("controller.lua")

QuickLogicGate.partFunction = function(ids, datalist, parentcache, childcache, oldstates, newstates, newmemberids)
    local timer0
    local timeloss = 0
    for index=1, #ids do
        local id = ids[index]
        local parents = parentcache[id]
        if #parents == 0 then
            newstates[id] = false
        else
            timer0 = os.clock()
            local mode = datalist[id].mode
            timeloss = timeloss + (os.clock()-timer0)
            if mode == 0 then  -- AND
                newstates[id] = true
                for i=1, #parents do
                    if not oldstates[parents[i].id] then
                        newstates[id] = false
                        break
                    end
                end
            elseif mode == 1 then  -- OR
                newstates[id] =  false
                for i=1, #parents do
                    if oldstates[parents[i].id] then
                        newstates[id] = true
                        break
                    end
                end
            elseif mode == 2 then  -- XOR
                local num = 0
                for i=1, #parents do
                    if oldstates[parents[i].id] then
                        num = num + 1
                    end
                end
                newstates[id] = num % 2 == 1
            elseif mode == 3 then  -- NAND
                newstates[id] = false
                for i=1, #parents do
                    if not oldstates[parents[i].id] then
                        newstates[id] = true
                        break
                    end
                end
            elseif mode == 4 then  -- NOR
                newstates[id] = true
                for i=1, #parents do
                    if oldstates[parents[i].id] then
                        newstates[id] = false
                        break
                    end
                end
            elseif mode == 5 then  -- XNOR
                local num = 0
                for i=1, #parents do
                    if oldstates[parents[i].id] then
                        num = num + 1
                    end
                end
                newstates[id] = num % 2 == 0
            end
        end
    end
    return timeloss
end

--[[controllercache = {}
controllercache.states = {}
controllercache.inters = {}
controllercache.data = {}
controllercache.parents = {}
controllercache.childs = {}]]


--[[ client ]]
function QuickLogicGate.client_onCreate(self )
    if self.cl_mode == nil then
        self.cl_mode = 0
    end
end

function QuickLogicGate.client_onDestroy(self )
    if self.gui then
        self.gui:destroy()
    end
end

function QuickLogicGate.gui_init(self)
    if self.gui == nil then
        self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Interactable_QuickLogicGate.layout")
        self.guimodes = {
            { name = "And", description = "Active if all of the linked triggers are active" },
            { name = "Or", description = "Active if any of the linked triggers are active" },
            { name = "Xor", description = "Active if an odd number of linked triggers are active" },
            { name = "Nand", description = "Active if any of the linked triggers are inactive" },
            { name = "Nor", description = "Active if all of the linked triggers are inactive" },
            { name = "Xnor", description = "Active if an even number of linked triggers are active" }
        }
        local btnNames = {"And", "Or", "Xor", "Nand", "Nor", "Xnor"}
        for _, btnName in pairs(btnNames) do
            self.gui:setButtonCallback(btnName, "gui_buttonCallback")
        end
    end
end

function QuickLogicGate.gui_buttonCallback(self, btnName)
    for i = 1, #self.guimodes do
        local name = self.guimodes[i].name
        self.gui:setButtonState(name, name == btnName)
        if name == btnName then
            self.cl_mode = i - 1
            self.gui:setText("DescriptionText", self.guimodes[i].description)
        end
    end
    self.network:sendToServer("sv_saveMode", self.cl_mode)
end

function QuickLogicGate.client_onRefresh(self )
    self:client_onCreate()
end

function QuickLogicGate.client_onInteract(self, character, state )
    if state then
        self:gui_init()
        local btnNames = {"And", "Or", "Xor", "Nand", "Nor", "Xnor"}
        self:gui_buttonCallback(btnNames[self.cl_mode + 1])
        self.gui:open()
    end
end

function QuickLogicGate.client_onTinker(self, character, state)
    if state then
        self.network:sendToServer("sv_changeSpeed", character:isCrouching())
    end
end

function QuickLogicGate.client_onFixedUpdate(self, deltaTime)
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6 + self.cl_mode)
    else
        self.interactable:setUvFrameIndex(0 + self.cl_mode)
    end
end

function QuickLogicGate.client_onClientDataUpdate(self, data)
    self.cl_mode = data.mode
end


--[[ server ]]
function QuickLogicGate.sv_changeSpeed(self, crouching)
    if crouching then
        if controllerspeed > 1 then
            controllerspeed = controllerspeed / 2
        else
            controllerspeed = 0
        end
    else
        if controllerspeed >= 1 then
            controllerspeed = controllerspeed * 2
        else
            controllerspeed = 1
        end
    end
    controller_saveSpeed()
    if controllerspeed == 0 then
        sm.gui.chatMessage("Speed Factor: Single Step")
    else
        sm.gui.chatMessage("Speed Factor: " .. tostring(controllerspeed) .. "x")
    end
    --print(controllerspeed)
end

function QuickLogicGate.sv_saveMode(self, mode)
    self.data.mode = mode
    self.network:setClientData({mode = self.data.mode})
    self.storage:save({mode = self.data.mode})
end

function QuickLogicGate.server_onCreate(self )
    self.data = {}
    if self.storage:load() ~= nil then
        self.data.mode = self.storage:load().mode
    else
        self.data.mode = 0
    end
    signin(self, "QuickLogicGate", QuickLogicGate.partFunction, true)
    self.network:setClientData({mode = self.data.mode})
    self.storage:save({mode = self.data.mode})
end

function QuickLogicGate.server_onRefresh(self )
    --controllerloaded = false
    --dofile("controller.lua")
    self:server_onCreate()
end

function QuickLogicGate.server_onFixedUpdate(self, deltaTime )
    if controllerlastupdate ~= sm.game.getCurrentTick() then
        local operationno = controller2(controllerspeed)
        --print(operationno)
    end

end

function QuickLogicGate.server_onDestroy(self )
    signin(self, "QuickLogicGate", QuickLogicGate.partFunction, false)
end