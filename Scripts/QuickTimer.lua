-- QuickTimer.lua by HerrVincling, 05.06.2022

QuickTimer = class( nil )
QuickTimer.maxChildCount = -1
QuickTimer.maxParentCount = 1
QuickTimer.connectionInput = sm.interactable.connectionType.logic
QuickTimer.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
QuickTimer.colorNormal = sm.color.new(0x00662Bff) --3D995C --3E8057
QuickTimer.colorHighlight = sm.color.new(0x0B7D31ff)

--GenericClass.poseWeightCount = 1
dofile("controller.lua")

QuickTimer.partFunction = function(ids, datalist, parentcache, childcache, oldstates, newstates, newmemberids)
    for index=1, #ids do
        local id = ids[index]
        local parent = parentcache[id][1] --only has one parent lol
        local parentstate = false
        if parent then
            parentstate = oldstates[parent.id]
        end

        local data = datalist[id]
        if data.time == 0 then
            newstates[id] = parentstate
        else
            newstates[id] = data.delayTable[data.pointer]
            data.delayTable[data.pointer] = parentstate
            data.pointer = data.pointer + 1
            if data.pointer > data.time then
                data.pointer = 1
            end
        end
        newmemberids[id] = true
    end

    return 0
end


--[[ client ]]
function QuickTimer.client_onCreate(self )
    self.guidata = {}
    self.guidata.seconds = 0
    self.guidata.ticks = 0
end

function QuickTimer.client_onDestroy(self )
    if self.gui then
        self.gui:destroy()
    end
end

function QuickTimer.gui_init(self)
    if self.gui == nil then
        self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Interactable_QuickTimer.layout")
        self.gui:createVerticalSlider("TickSlider", 41, 0, "gui_tickSlider")
        self.gui:createVerticalSlider("SecondSlider", 60, 0, "gui_secondSlider")
        self.gui:setSliderPosition("TickSlider", self.guidata.ticks)
        self.gui:setSliderPosition("SecondSlider", self.guidata.seconds)
        self:gui_update()
    end
end

function QuickTimer.gui_tickSlider(self, pos)
    self.guidata.ticks = pos
    self:gui_update()
    self.network:sendToServer("sv_saveTime", { ticks = self.guidata.ticks, seconds = self.guidata.seconds })
end

function QuickTimer.gui_secondSlider(self, pos)
    self.guidata.seconds = pos
    self:gui_update()
    self.network:sendToServer("sv_saveTime", { ticks = self.guidata.ticks, seconds = self.guidata.seconds })
end

function QuickTimer.gui_update(self)
    local seconds = self.guidata.seconds
    local ticks = self.guidata.ticks / 40
    if self.guidata.ticks == 40 then
        seconds = seconds + 1
        ticks = 0
    end
    ticks = ticks * 1000
    local totalticks = self.guidata.seconds * 40 + self.guidata.ticks
    self.gui:setText("SecondsText", string.format("%02d", seconds))
    self.gui:setText("MillisecondsText", string.format("%03d", ticks))
    self.gui:setText("TicksText", tostring(totalticks) .. " TICKS")
end

function QuickTimer.client_onRefresh(self )
    self:client_onCreate()
end

function QuickTimer.client_onInteract(self, character, state )
    if state then
        self:gui_init()
        self:gui_update()
        self.gui:open()
    end
end

function QuickTimer.client_onTinker(self, character, state)
    if state then
        self.network:sendToServer("sv_changeSpeed", character:isCrouching())
    end
end

function QuickTimer.client_onFixedUpdate(self, deltaTime)
end

function QuickTimer.client_onClientDataUpdate(self, data)
    self.guidata.seconds = data.seconds
    self.guidata.ticks = data.ticks

    if self.gui then
        self.gui:setSliderPosition("TickSlider", self.guidata.ticks)
        self.gui:setSliderPosition("SecondSlider", self.guidata.seconds)
    end
end


--[[ server ]]
function QuickTimer.sv_changeSpeed(self, crouching)
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
end

function QuickTimer.sv_saveTime(self, data)
    self.ticks = data.ticks
    self.seconds = data.seconds
    self.data.time = data.seconds * 40 + data.ticks
    self.data.delayTable = {}
    self.data.pointer = 1
    signin(self, "QuickTimer", QuickTimer.partFunction, true)
    self.network:setClientData({ticks = self.ticks, seconds = self.seconds})
    self.storage:save({ticks = self.ticks, seconds = self.seconds})
end

function QuickTimer.server_onCreate(self )
    self.data = {}
    if self.storage:load() ~= nil then
        local data = self.storage:load()
        self.ticks = data.ticks
        self.seconds = data.seconds
        self.data.time = self.ticks + self.seconds * 40
    else
        self.ticks = 0
        self.seconds = 0
        self.data.time = 0
    end
    self.data.delayTable = {}
    self.data.pointer = 1
    signin(self, "QuickTimer", QuickTimer.partFunction, true)
    self.network:setClientData({ticks = self.ticks, seconds = self.seconds})
    self.storage:save({ticks = self.ticks, seconds = self.seconds})
end

function QuickTimer.server_onRefresh(self )
    --signin(self, "QuickTimer", QuickTimer.partFunction, true)
    self:server_onCreate()
end

function QuickTimer.server_onFixedUpdate(self, deltaTime )
    if controllerlastupdate ~= sm.game.getCurrentTick() then
        local operationno = controller2(controllerspeed)
        --print(operationno)
    end
end

function QuickTimer.server_onDestroy(self )
    signin(self, "QuickTimer", QuickTimer.partFunction, false)
end