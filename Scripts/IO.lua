-- IO.lua by HerrVincling, 05.06.2022

IO = class( nil )
IO.maxChildCount = -1
IO.maxParentCount = -1
IO.connectionInput = sm.interactable.connectionType.logic
IO.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
IO.colorNormal = sm.color.new(0x85CC3Dff) --5CE6B8
IO.colorHighlight = sm.color.new(0x9EE359ff)
--GenericClass.poseWeightCount = 1
dofile("QuickLogicSystem/controller.lua")
dofile("interface_controller.lua")

IO.partFunction = function(ids, datalist, parentcount, counttable, newstates, newmemberids, oldstates)
    local interface_interfacetopart = interface_interfacetopart
    local interface_parttoclassname = interface_parttoclassname
    local interfacedata = interfacedata

    local helperdata = interface_helperdata
    local memberlist = helperdata.memberlist

    local inputvaluestable = helperdata.inputvalues
    --local outputvaluestable = helperdata.outputvalues --unused so far
    local bitlookup = helperdata.bitlookup
    local colorlookup = helperdata.colorlookup
    local isinput = helperdata.isinput
    local bxor = bit.bxor
    local band = bit.band


    --Find out which special blocks need to be updated
    for i = 1, #ids do
        local id = ids[i] --now mainindex
        if isinput[id] then
            local state = counttable[id] > 0
            if state ~= oldstates[id] then
                local part = interface_interfacetopart[id]
                if part then
                    local classname = interface_parttoclassname[part]
                    --local partid = interface_interfacetopart[id] --this line seems awfully redundant
                    memberlist[classname][part] = true

                    local inputvalues = inputvaluestable[part]
                    local inputno = bitlookup[id]
                    local inputcolor = colorlookup[id]

                    if (band(inputvalues[inputcolor], 2 ^ inputno) > 0) ~= state then
                        inputvalues[inputcolor] = bxor(inputvalues[inputcolor], 2 ^ inputno)
                    end

                    newstates[id] = state --state only changes if correctly hooked up to a special block -> indicator for correct setup
                end
            end
        end
    end

    --print(inputvaluestable)
    
    --update all changed special blocks
    for classname, members in pairs(memberlist) do
        local data = interfacedata[classname]
        for id, _ in pairs(members) do
            local io = data.iomembers[id]

            local inputvalues = inputvaluestable[id]
            --find states of input interfaces
            --actually I need to find their new state, they don't have an old one C_C

            local newvalues = data.partFunction(data.members[id], inputvalues)

            --write states of output interfaces
            for color, newvalue in pairs(newvalues) do
                local outputids = io.output[color]
                for i = 1, #outputids do
                    if band(newvalue, 2 ^ (i - 1)) > 0 then
                        newstates[outputids[i]] = true
                    else
                        newstates[outputids[i]] = false
                    end
                end
            end

            --Remove from list to clear for next cycle
            memberlist[classname][id] = nil
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

function IO.server_onDestroy(self )
    signin(self, "IO", IO.partFunction, false)
end

