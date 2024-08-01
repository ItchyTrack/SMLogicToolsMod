Autotool = class()

dofile("QuickLogicSystem/controller.lua")
dofile("MultitoolLib/baseLib.lua")

-- [SERVER]
function Autotool.server_onCreate(self)
    self_Autotool = self
    tool_Autotool = self.tool
end

function Autotool.server_onRefresh(self)
    self:server_onCreate()
end

function Autotool.server_onFixedUpdate(self, deltaTime)
	if controllerlastupdate ~= sm.game.getCurrentTick() then
        local clock0 = os.clock()
        self.sv_changed_ids = controller2(controllerspeed)
        --print(os.clock() - clock0)
        self:sv_updateTextures()
    end

    if controllerspeed == 0 then
        self.network:setClientData({show_changed_qgates = true})
    else
        self.network:setClientData({show_changed_qgates = false})
        self.network:sendToClients("cl_highlightGates", {})
    end
end

function Autotool.sv_updateTextures(self, _)
    --print("sv_updateTextures")
    self.network:sendToClients("cl_updateTextures", self.sv_changed_ids)
end

function Autotool.sv_makeStep(self)
    --print("sv_makeStep")
    controllerspeed = 0
    local changed_ids = controller2(1)
    self.sv_changed_ids = changed_ids
    if #self.sv_changed_ids > 0 then
        sm.event.sendToTool(self.tool, "sv_updateTextures", {})
    end

    update_queue_ids = {}
    local qgate_update_queue = tpt_main.member_update_queue["QuickLogicGate"] or {}
    for i = 1, #qgate_update_queue, 1 do
        index = qgate_update_queue[i]
        id = tpt_main.inters[index]
        --print(id)
        update_queue_ids[#update_queue_ids+1] = id
    end

    --print(changed_ids, update_queue_ids)

    local id_values = {}
    for i = 1, #update_queue_ids, 1 do
        id = update_queue_ids[i]
        if id_values[id] == nil then
            id_values[id] = 0
        end
        id_values[id] = id_values[id] + 1
    end
    for i = 1, #changed_ids, 1 do
        id = changed_ids[i]
        if id_values[id] == nil then
            id_values[id] = 0
        end
        id_values[id] = id_values[id] + 2
    end

    local ids_queue = {}
    local ids_queue_and_changed = {}
    local ids_changed = {}

    for id, value in pairs(id_values) do
        if value == 1 then
            ids_queue[#ids_queue+1] = id
        elseif value == 2 then
            ids_changed[#ids_changed+1] = id
        elseif value == 3 then
            ids_queue_and_changed[#ids_queue_and_changed+1] = id
        else
            print(id, value, "not possible!")
        end
    end

    self.network:sendToClients("cl_highlightGates", {ids_changed=ids_changed,ids_queue=ids_queue,ids_queue_and_changed=ids_queue_and_changed})
end



-- [CLIENT]
local nameTagAdd, nameTagCleanup, nameTagNextTick = baseLib.createNameTagManager()
selfs_QuickLogicGate = selfs_QuickLogicGate or {}

function Autotool.client_onCreate(self)
    self.cl_last_texture_update = sm.game.getCurrentTick()
    self.cl_show_changed_qgates = false
end

function Autotool.client_onClientDataUpdate(self, data, _)
    self.cl_show_changed_qgates = data.show_changed_qgates
end

function Autotool.cl_updateTextures(self, changed_ids)
    for i = 1, #changed_ids, 1 do
        local id = changed_ids[i]
        local self_Gate = selfs_QuickLogicGate[id]
        local active = self_Gate.interactable.active
        --print(id, active)
        if active ~= self_Gate.active then
            if active then
                self_Gate.interactable:setUvFrameIndex(6 + self_Gate.cl_mode)
            else
                self_Gate.interactable:setUvFrameIndex(0 + self_Gate.cl_mode)
            end
        end
        self_Gate.active = active
    end
    self.cl_last_texture_update = sm.game.getCurrentTick()
end

function Autotool.cl_highlightGates(self, data)
    nameTagNextTick(self)
    if self.cl_show_changed_qgates == false then
        nameTagCleanup(self)
        return
    end

    for i = 1, #data.ids_changed, 1 do
        local id = data.ids_changed[i]
        local self_Gate = selfs_QuickLogicGate[id]
        if self_Gate then
            nameTagAdd(self, self_Gate.shape:getWorldPosition(), "#ffff00O")
        end
    end

    for i = 1, #data.ids_queue, 1 do
        local id = data.ids_queue[i]
        local self_Gate = selfs_QuickLogicGate[id]
        if self_Gate then
            nameTagAdd(self, self_Gate.shape:getWorldPosition(), "#00ff00O")
        end
    end

    for i = 1, #data.ids_queue_and_changed, 1 do
        local id = data.ids_queue_and_changed[i]
        local self_Gate = selfs_QuickLogicGate[id]
        if self_Gate then
            nameTagAdd(self, self_Gate.shape:getWorldPosition(), "#ffff00(#00ff00O#ffff00)")
        end
    end


    nameTagCleanup(self)
end
