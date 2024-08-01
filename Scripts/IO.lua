-- IO.lua by HerrVincling, 05.06.2022

IO = class( nil )
IO.maxChildCount = -1
IO.maxParentCount = -1
IO.connectionInput = sm.interactable.connectionType.logic
IO.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
IO.colorNormal = sm.color.new(0x85CC3Dff) --5CE6B8
IO.colorHighlight = sm.color.new(0x9EE359ff)
--GenericClass.poseWeightCount = 1
dofile("controller.lua")
dofile("interface_controller.lua")

IO.partFunction = function(ids, datalist, parentcache, childcache, oldstates, newstates, newmemberids)
    if interface_lastUpdate ~= controllerlastupdate then
        --parentcache is altered so the interface blocks only have non-interface blocks as parents
        interface_controller(ids, parentcache, childcache)
    end

    local memberlist = {}
    for i = 1, #ids do
        local id = ids[i]
        local part = interface_interfacetopart[id]
        if part then
            local classname = interface_parttoclassname[part]
            if memberlist[classname] == nil then
                memberlist[classname] = {}
            end
            memberlist[classname][interface_interfacetopart[id]] = true
        end
        --newmemberids[ids[i]] = true
    end
    --update all changed special blocks
    for classname, members in pairs(memberlist) do
        local data = interfacedata[classname]
        for id, _ in pairs(members) do
            local io = data.iomembers[id]
            local inputvalues = {}
            --find states of input interfaces
            --actually I need to find their new state, they don't have an old one C_C
            for color, idlist in pairs(io.input) do
                local value = 0
                for i = 1, #idlist do
                    local parents = parentcache[idlist[i]]
                    --print(parents)
                    local state = false
                    for j = 1, #parents do

                        if oldstates[parents[j].id] then
                            --state = true
                            state = true
                            value = value + 2 ^ (i - 1)
                            break
                        end
                    end
                    if interface_parttoclassname[idlist[i]] then
                        print("HELP")
                    end
                    newstates[idlist[i]] = state -- ---------------------------------------------------
                end
                inputvalues[color] = value
            end
            local newvalues = data.partFunction(data.members[id], inputvalues)
            --write states of output interfaces
            for color, newvalue in pairs(newvalues) do
                local outputids = io.output[color]
                --print(#outputids)
                for i = 1, #outputids do
                    if bit.band(newvalue, 2 ^ (i - 1)) > 0 then
                        newstates[outputids[i]] = true
                    else
                        newstates[outputids[i]] = false
                    end
                end
                --newstates[id0] = state
            end
        end
    end
    return 0
end

--[[ client ]]
function IO.client_onCreate(self )
end

function IO.client_onRefresh(self )
 self:client_onCreate()
end

function IO.client_onFixedUpdate(self, deltaTime)
    if self.interactable.active then
        self.interactable:setUvFrameIndex(6 + self.mode)
    else
        self.interactable:setUvFrameIndex(0 + self.mode)
    end
end

function IO.client_onTinker(self, character, state)
    if state then
        self.network:sendToServer("sv_changeSpeed", character:isCrouching())
    end
end

--[[ server ]]
function IO.sv_changeSpeed(self, crouching)
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

function IO.server_onCreate(self )
    if self.storage:load() ~= nil then

    else

    end
    self.mode = 1
    self.data = {}
    signin(self, "IO", IO.partFunction, true)
end

function IO.server_onRefresh(self )
    self:server_onCreate()
end

function IO.server_onFixedUpdate(self, deltaTime )
    if controllerlastupdate ~= sm.game.getCurrentTick() then
        local operationno = controller2(controllerspeed)
    end
end

function IO.server_onDestroy(self )
    signin(self, "IO", IO.partFunction, false)
end

