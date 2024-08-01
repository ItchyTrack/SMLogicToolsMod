
function tpt_simulation(tickspeed, update_queue, functionlist, datalist, parentcount, counttable, oldstates, childcache, classlookup)
    local clock0 = os.clock()
    local clock1, clock2, clock3, clock4 = clock0, clock0, clock0, clock0
    clock1 = os.clock()
    local tptontime = 0
    local changed1
    local timeloss = 0
    local testcounter = 0

    --print(update_queue)

    local newstates = {}
    local newmemberids = {}
    for tick = 1, tickspeed, 1 do
        --print(update_queue)
        changed1 = false

        clock3 = os.clock()
        --print(oldmemberlist)
        for classname, indexes in pairs(update_queue) do
            testcounter = testcounter + #indexes
            timeloss = timeloss + functionlist[classname](indexes, datalist[classname], parentcount, counttable, newstates, newmemberids, oldstates)

            for i=1, #indexes do
                update_queue[classname][i] = nil
            end
        end

        --print(newstates)

        clock4 = os.clock()
        tptontime = tptontime + (clock4-clock3)

        for index, state in pairs(newstates) do
            if state ~= oldstates[index] then
                changed1 = true
                local children = childcache[index]
                for i = 1, #children do
                    local childid = children[i]
                    if counttable[childid] then
                        if state then
                            counttable[childid] = counttable[childid] + 1
                        else
                            counttable[childid] = counttable[childid] - 1
                        end
                    end

                    --oldmemberlist[class][#oldmemberlist[class]+1] = childid  -- FLAW: Can end up with multiples (array should be table instead)
                    newmemberids[childid] = true
                end
            end
            oldstates[index] = state
            newstates[index] = nil
        end

        for id, _ in pairs(newmemberids) do
            local class = classlookup[id]
            --print(id)
            if class then
                changed1 = true --any new members mean that it should run another tpt
                update_queue[class][#update_queue[class]+1] = id
            end
            newmemberids[id] = nil
        end

        if not changed1 then --timers prevent this, so any internal signals will propagate
            --print("stopped after", tick, "ticks")
            break --Optimization
        end
    end
    clock2 = os.clock()
end