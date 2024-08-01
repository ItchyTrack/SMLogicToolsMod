-- controller.lua for quick logic by HerrVincling, 05.06.2022

--if controllerloaded == true then return end
controllerloaded = true
controllerlastupdate = sm.game.getCurrentTick()

controllerspeed = 1
--controllerspeed = sm.storage.load("controller") or 1

function controller_saveSpeed()
    --sm.storage.save("controller", controllerspeed)
end

--controller() is now globally accessible, any lonely timer or logic gate can run it

print("Loading Quick Logic Controller v3")
controllermemberlist = {}
controllerfunctionlist = {}
controllernewinterlist = {}

-- "semi-static" = Static until the player changes stuff, "dynamic" Changes all the time in the simulation, "static" = valid information until part is deleted/destroyed
controllercache = {}
controllercache.states = {} --dynamic
controllercache.inters = {} --static, but shared with non-mod parts
controllercache.minters = {} --static, holds mod parts exclusively
controllercache.data = {} --dynamic [UNUSED]
controllercache.parents = {} --semi-static
controllercache.childs = {} --semi-static
controllercache.classname = {} --static, mod-part-exclusive, holds classname of every id
--controllercache.bodyupdates = {} --semi-static
controllercache.bodylist = {}
controllercache.bodylist.bodies = {} --semi-static
controllercache.bodylist.intidtobodyid = {} --semi-static
controllercache.bodylist.bodyidtointid = {} --semi-static
controllercache.bodylist.lastUpdate = {} --semi-static

function signin(instance, classname, partfunction, login)
    if controllermemberlist[classname] == nil then
        controllermemberlist[classname] = {}
        controllercache.states[classname] = {}
    end
    if login then
        controllerfunctionlist[classname] = partfunction --temporary, should be only once

        controllermemberlist[classname][instance.interactable.id] = instance.data
        controllercache.states[classname][instance.interactable.id] = instance.interactable.active
        controllercache.inters[instance.interactable.id] = instance.interactable
        controllercache.minters[instance.interactable.id] = instance.interactable
        controllernewinterlist[instance.interactable.id] = instance.interactable
        controllercache.classname[instance.interactable.id] = classname
    else
        controllermemberlist[classname][instance.interactable.id] = nil
        controllercache.inters[instance.interactable.id] = nil
        controllercache.minters[instance.interactable.id] = nil
        controllercache.classname[instance.interactable.id] = nil
    end
end

function getData(classname, id)
    return controllermemberlist[classname][id]
end

function setData(classname, id, data)
    controllermemberlist[classname][id] = data
end

function controller2(tickspeed)
    local clock0 = os.clock()
    local clock1, clock2, clock3, clock4 = clock0, clock0, clock0, clock0


    controllerlastupdate = sm.game.getCurrentTick()

    --if true then return end

    local datalist = controllermemberlist
    local functionlist = controllerfunctionlist
    local interlist = controllercache.inters
    local bodylist = controllercache.bodylist

    local parentcache = controllercache.parents
    local childcache = controllercache.childs

    local statelist = controllercache.states
    local minterlist = controllercache.minters

    local classlookup = controllercache.classname

    --Update state for all non-mod interactables, or remove if non-existent
    local testcounter3 = 0
    local removedidsinter = {}
    for id, inter in pairs(interlist) do
        if minterlist[id] == nil then
            if not sm.exists(inter) then
                table.insert(removedidsinter, id)
            else
                testcounter3 = testcounter3 + 1
                statelist[id] = inter.active
            end
        end
    end
    for _, id in pairs(removedidsinter) do
        interlist[id] = nil
    end

    --print(testcounter3) --shows how many non-mod interactables got updated

    local newinterlist = controllernewinterlist
    --Check for new bodies of new inters
    for id, inter in pairs(newinterlist) do
        --New body or new inter
        local body = inter:getShape().body
        local bodyid = body.id
        if bodylist.bodies[bodyid] == nil then
            --New body!! (can't be a moved one cuz it's no preexisting inter)
            bodylist.bodies[bodyid] = body
            bodylist.lastUpdate[bodyid] = 0
        end
        if bodylist.bodyidtointid[bodyid] == nil then
            bodylist.bodyidtointid[bodyid] = {}
        end
        if bodylist.bodyidtointid[bodyid][id] ~= nil then
            --print("Warning0")
        end
        bodylist.bodyidtointid[bodyid][id] = true
    end
    controllernewinterlist = {} --clear list, new inters got processed
    --print("1")

    local testcounter2 = 0

    local function checkBodyInters(bodyid)
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

                    --[[for newbodyid, body in pairs(bodylist.bodies) do
                        --Check if inter is in bodylist somewhere

                        if newbodyid ~= bodyid then
                            if interbodyid == newbodyid then
                                bodylist.bodyidtointid[bodyid][id] = nil --remove from old body
                                bodylist.bodyidtointid[newbodyid][id] = interlist[id] --add to new body
                            end
                        end
                    end]]
                end

                --refresh parent- & child-cache
                --print("parents/childs")
                testcounter2 = testcounter2 + 1
                --[[parentcache[id] = {}
                for _, parent in pairs(interlist[id]:getParents()) do
                    parentcache[id][parent.id] = parent
                    interlist[parent.id] = parent
                    statelist[parent.id] = parent.active
                end]]

                parentcache[id] = interlist[id]:getParents()
                for _, parent in pairs(parentcache[id]) do
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
        --print("a4")

        --List cleanup of removed stuff o-o
        --print()
        --print(bodylist.bodyidtointid[bodyid])
        for _, id in pairs(removedids) do
            bodylist.bodyidtointid[bodyid][id] = nil
        end
        --print(bodylist.bodyidtointid[bodyid])
        --print("removed:", removedids)
        --print("a5")
    end

    --print("2")
    --Check if all bodies still exist
    local removedbodyids = {}
    for bodyid, body in pairs(bodylist.bodies) do
        if not sm.exists(body) then
            table.insert(removedbodyids, bodyid)
            --Check all inters to see where they went or if they were destroyed too :/
            print("body got destroyed")
            checkBodyInters(bodyid)
        end
    end
    --Remove deleted bodies from the lists
    for _, bodyid in pairs(removedbodyids) do
        bodylist.bodies[bodyid] = nil
        bodylist.bodyidtointid[bodyid] = nil
    end

    --print("5")
    for bodyid, body in pairs(bodylist.bodies) do
        if body:hasChanged(bodylist.lastUpdate[bodyid]) then
            bodylist.lastUpdate[bodyid] = sm.game.getCurrentTick()
            --A known body has changed
            --Check all inters to see what they did >:|
            print("body got changed")
            checkBodyInters(bodyid)
        end
    end

    if testcounter2 > 0 then
        print("Refreshed", testcounter2, "parent/child information")
    end

    controllercache.parents = parentcache
    controllercache.childs = childcache
    controllercache.bodylist = bodylist
    controllercache.inters = interlist


    -- [ Here comes the actual TPT-system (tick per tick)  ]
    -- [ Everything above should only refresh occasionally ]
    -- [ Everything below refreshes every tick, optimize!  ]

    --if true then return end --45fps---------------------------------------------------------------------------------45
    --Copy big member table
    local oldmemberlist = {}
    --local datalist = {}
    for a,b in pairs(datalist) do
        local list1 = {}
        --datalist[a] = {}
        for c,_ in pairs(b) do
            list1[#list1+1] = c
            --datalist[a] = memberlist[a][c].data
            --oldmemberlist[a][c] = memberlist[a][c]
        end
        oldmemberlist[a] = list1
    end
    --Copy state tables
    local oldstates = {}
    for id, state in pairs(statelist) do
        oldstates[id] = state
        --newstates[id] = state
    end

    local testcounter = 0
    local newstates = {}
    local tptontime = 0
    local changed1
    local timeloss = 0

    local newmemberids = {}
    clock1 = os.clock()
    for tick = 1, tickspeed, 1 do
        changed1 = false
        for a, _ in pairs(newstates) do
            newstates[a] = nil
        end

        for a, _ in pairs(newmemberids) do
            newmemberids[a] = nil
        end

        clock3 = os.clock()
        for classname, ids in pairs(oldmemberlist) do
            timeloss = timeloss + functionlist[classname](ids, datalist[classname], parentcache, childcache, oldstates, newstates, newmemberids)
        end

        --[[for a, b in pairs(newstates) do
            testcounter = testcounter + 1
        end]]

        clock4 = os.clock()
        tptontime = tptontime + (clock4-clock3)

        for classname, ids in pairs(oldmemberlist) do
            for i=1, #ids do
                oldmemberlist[classname][i] = nil
            end
        end

        for id, state in pairs(newstates) do
            if state ~= oldstates[id] then
                changed1 = true
                for _, childid in pairs(childcache[id]) do
                    newmemberids[childid] = true
                end
            end
        end

        for id, _ in pairs(newmemberids) do
            local class = classlookup[id]
            --this trips when a q-part has vanilla/non-familiar parts as childs, fix:
            if class then --if the class is known, it's familiar
                changed1 = true --any new members mean that it should run another tpt
                oldmemberlist[class][#oldmemberlist[class]+1] = id
            --else
                --print("unfamiliar", id)
            end
        end

        for id, state in pairs(newstates) do
            oldstates[id] = state
        end
        if not changed1 then --timers prevent this, so any internal signals will propagate
            --print("stopped after", tick, "ticks")
            break --Optimization
        end
    end
    clock2 = os.clock()

    --if true then return end --25fps---------------------------------------------------------------------------------25

    --Set new states for all interactables whose state changed
    local changed2 = false
    for id, state in pairs(oldstates) do
        if statelist[id] ~= state then
            changed2 = true
            interlist[id].active = state
            if state then
                interlist[id].power = 1
            else
                interlist[id].power = 0
            end
        end
    end

    controllercache.states = oldstates

    --if true then return end --25fps---------------------------------------------------------------------------------25

    --prevents that body:hadChanged() triggers next tick, just, a 20Hz would make any real changes invisible because every tick would be blocked
    if changed2 then
        for bodyid, body in pairs(controllercache.bodylist.bodies) do
            controllercache.bodylist.lastUpdate[bodyid] = sm.game.getCurrentTick()
        end
    end

    local testvar = clock2-clock1
    local testvar2 = os.clock()-clock0
    --print(testvar2-testvar, "\t", testvar, "\t", tptontime, "\t", testvar-tptontime)
    --print(timeloss)
    --print(testcounter)
    return testcounter
end
