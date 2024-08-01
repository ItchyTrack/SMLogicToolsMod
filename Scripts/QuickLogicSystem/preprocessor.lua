

function vanilla_logic_update()
    local controllercache = controllercache
    local interlist = controllercache.inters
    local minterlist = controllercache.minters
    local statelist = controllercache.states


    --Update state for all non-mod interactables, or remove if non-existent
    local tpt_main = tpt_main
    local updatequeue = tpt_main.member_update_queue
    local index_lookup = tpt_main.index_lookup
    local classlookup = controllercache.classname
    local count = tpt_main.count

    local testcounter3 = 0
    local removedidsinter = {}
    for id, inter in pairs(interlist) do
        if minterlist[id] == nil then
            if not sm.exists(inter) then
                table.insert(removedidsinter, id)
            else
                testcounter3 = testcounter3 + 1
                local newstate = inter.active
                if newstate ~= statelist[id] then
                    statelist[id] = newstate
                    local childs = inter:getChildren() --TODO Find way to cache connections of vanilla parts
                    for i = 1, #childs do
                        local child = childs[i].id --TEMP, getChildren returns interactables
                        local index = index_lookup[child]

                        --Queue for update
                        if index then --the child could be vanilla, in which case index_lookup returns nil
                            local class = classlookup[child]
                            local queue = updatequeue[class]
                            queue[#queue+1] = index

                            --Change counttable
                            if newstate == false then
                                count[index] = count[index] - 1
                            else
                                count[index] = count[index] + 1
                            end
                        end

                    end
                end
            end
        end
    end
    for _, id in pairs(removedidsinter) do
        interlist[id] = nil
    end
    --print(testcounter3) --shows how many non-mod interactables got updated
end

local function checkBodyInters(bodyid)
    local controllercache = controllercache
    local bodylist = controllercache.bodylist
    local interlist = controllercache.inters
    local statelist = controllercache.states
    local parentcache = controllercache.parents
    local childcache = controllercache.childs


    local removedids = {}
    --print("a1")

    --check every part of the body for changes
    for id, _ in pairs(bodylist.bodyidtointid[bodyid]) do
        if interlist[id] == nil then
            --deleted
            table.insert(removedids, id)
        else
            --still exists
            local interbody = interlist[id]:getShape().body
            local interbodyid = interbody.id
            if bodylist.bodies[interbodyid] == nil then --unknown body = new body
                --became a new body
                bodylist.bodies[interbodyid] = interbody --add new body
                bodylist.lastUpdate[interbodyid] = 0 --add update counter
                bodylist.bodyidtointid[interbodyid] = {} --add new inter list
                --print("a2")
                if bodylist.bodyidtointid[interbodyid][id] ~= nil then
                    print("ALARM1")
                end
                bodylist.bodyidtointid[interbodyid][id] = true --add to inter list
            else
                --switched to existing body, does that even require any changes except parent/child? probably not right?
                --remove from orig. body (bodyid), add to new body (interbodyid)
                if interbodyid ~= bodyid then --make sure we don't write to the table of the loop
                    table.insert(removedids, id) --remove from orig. body (bodyid)
                    --print("a3")
                    if bodylist.bodyidtointid[interbodyid][id] ~= nil then
                        print("ALARM2")
                    end
                    bodylist.bodyidtointid[interbodyid][id] = true
                end
            end

            --testcounter2 = testcounter2 + 1

            parentcache[id] = {}
            for _, parent in pairs(interlist[id]:getParents()) do
                table.insert(parentcache[id], parent.id)
                interlist[parent.id] = parent
                statelist[parent.id] = parent.active
            end

            --childcache[id] = interlist[id]:getChildren()
            childcache[id] = {}
            for _, child in pairs(interlist[id]:getChildren()) do
                table.insert(childcache[id], child.id)
                interlist[child.id] = child
                statelist[child.id] = child.active
            end

        end
    end

    --List cleanup of removed stuff o-o
    for _, id in pairs(removedids) do
        bodylist.bodyidtointid[bodyid][id] = nil
    end
end

function update_bodies()
    local bodylist = controllercache.bodylist
    local checkBodyInters = checkBodyInters

    --New Mod-Interactables are now added/handled in external_functions.lua

    local testcounter2 = 0

    --Check if all bodies still exist
    local updated = false
    local removedbodyids = {}
    for bodyid, body in pairs(bodylist.bodies) do
        if not sm.exists(body) then
            removedbodyids[#removedbodyids+1] = bodyid
            --Check all inters to see where they went or if they were destroyed too :/
            print("body got destroyed")
            updated = true
            checkBodyInters(bodyid)
        end
    end

    --Remove deleted bodies from the lists
    for i = 1, #removedbodyids do
        local bodyid = removedbodyids[i]
        bodylist.bodies[bodyid] = nil
        bodylist.bodyidtointid[bodyid] = nil
    end

    local currentTick = sm.game.getCurrentTick()
    local lastUpdate = bodylist.lastUpdate
    for bodyid, body in pairs(bodylist.bodies) do
        if body:hasChanged(lastUpdate[bodyid]) then
            bodylist.lastUpdate[bodyid] = currentTick
            --A known body has changed
            --Check all inters to see what they did >:|
            print("body got changed")
            updated = true
            checkBodyInters(bodyid)
        end
    end

    if testcounter2 > 0 then
        print("Refreshed", testcounter2, "parent/child information")
    end

    return updated
end

function generate_main_tpt_tables()
    local globalparentcache = controllercache.parents
    local globalchildcache = controllercache.childs
    local globalmembers = controllermemberlist --holds data for
    local globalstates = controllercache.states
    local globalinters = controllercache.minters
    local globalclassname = controllercache.classname

    local inters = {}
    local counttable = {}
    local parentcount = {}
    local classname_lookup = {}
    local states = {}
    for id, _ in pairs(globalinters) do
        inters[#inters+1] = id

        local parents = globalparentcache[id]
        local count = 0
        for j=1, #parents do
            local parent = parents[j]
            if globalstates[parent] then
                count = count + 1
            end
        end
        counttable[#counttable+1] = count

        parentcount[#parentcount+1] = #parents

        classname_lookup[#classname_lookup+1] = globalclassname[id]

        states[#states+1] = globalstates[id]
    end
    tpt_main.inters = inters
    tpt_main.count = counttable
    tpt_main.parentcount = parentcount
    tpt_main.classname = classname_lookup
    tpt_main.states = states

    local index_lookup = {}
    for i = 1, #inters do
        index_lookup[inters[i]] = i
    end
    tpt_main.index_lookup = index_lookup

    local childs = {}
    for i = 1, #inters do
        local id = inters[i]
        local childids = globalchildcache[id]
        local childindexes = {}
        for j = 1, #childids do
            childindexes[#childindexes+1] = index_lookup[childids[j]]
        end
        childs[i] = childindexes
    end
    tpt_main.childs = childs

    local queue = {}
    local data = {}
    for classname, ids in pairs(globalmembers) do
        local newqueue = {}
        local newdata = {}
        for id, datatable in pairs(ids) do
            newqueue[#newqueue+1] = index_lookup[id]
            newdata[index_lookup[id]] = datatable
        end
        queue[classname] = newqueue
        data[classname] = newdata
    end
    tpt_main.member_update_queue = queue
    tpt_main.data = data


    --Interface System
    --TODO Make the interface controller save the data by index natively
    if globalmembers.IO then
        local helperdata = interface_helperdata
        --local inputvaluestable = helperdata.inputvalues --contains RAM data, don't change
        --local outputvaluestable = helperdata.outputvalues --same with this one ig
        local bitlookup = helperdata.bitlookup
        local colorlookup = helperdata.colorlookup
        local isinput = helperdata.isinput

        local newbitlookup = {}
        local newcolorlookup = {}
        local newisinput = {}

        --interface_interfacetopart
        --interface_parttoclassname --probably not necessary, because special blocks stay as IDs
        --interfacedata? --probably not too important, can stay as IDs
        local interfacetopart = interface_interfacetopart
        local newinterfacetopart = {}

        for i = 1, #inters do
            local id = inters[i]
            local bit = bitlookup[id]
            local color = colorlookup[id]
            local isinputvalue = isinput[id]

            local partofinterface = interfacetopart[id]

            if bit then
                newbitlookup[i] = bit
            end
            if color then
                newcolorlookup[i] = color
            end
            if isinputvalue then
                newisinput[i] = isinputvalue
            end

            if partofinterface then
                newinterfacetopart[i] = partofinterface
            end
        end

        helperdata.bitlookup = newbitlookup
        helperdata.colorlookup = newcolorlookup
        helperdata.isinput = newisinput

        interface_interfacetopart = newinterfacetopart

        local interfacedata = interfacedata
        for classname, datatable in pairs(interfacedata) do
            for id, io in pairs(datatable.iomembers) do
                for color, interlist in pairs(io.input) do
                    local newlist = {}
                    for i = 1, #interlist do
                        newlist[i] = index_lookup[interlist[i]]
                    end
                    interfacedata[classname].iomembers[id].input[color] = newlist
                end
                for color, interlist in pairs(io.output) do
                    local newlist = {}
                    for i = 1, #interlist do
                        newlist[i] = index_lookup[interlist[i]]
                    end
                    interfacedata[classname].iomembers[id].output[color] = newlist
                end
            end
        end


    end


    --[[ from init.lua:
    tpt_main = {}
    tpt_main.members = {} --[class][index] = {indexes}
    tpt_main.inters = {} --[index] = id
    tpt_main.count = {} --[index] = number
    tpt_main.parentcount = {} --[index] = {number}
    tpt_main.childs = {} --[index] = {indexes}
    tpt_main.member_update_queue = {} --[class][index] = {indexes}
    tpt_main.index_lookup = {} --[id] = index
    tpt_main.data = {} --[classname][index] = data
    ]]
end
