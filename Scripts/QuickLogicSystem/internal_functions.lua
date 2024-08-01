function setNewInGameLogicStates(tptstates, statelist, interlist)
    local changed2 = false
    local id_lookup = tpt_main.inters
    local classlookup = tpt_main.classname
    local tptdata = tpt_main.data
    local changed_ids = {}
    for i = 1, #tptstates do
        local id = id_lookup[i]
        local state = tptstates[i]
        if statelist[id] ~= state then
            local inter = interlist[id]
            changed2 = true
            inter.active = state
            if state then
                inter.power = 1
            else
                inter.power = 0
            end
            statelist[id] = state

            if classlookup[i] == "QuickLogicGate" then
                changed_ids[#changed_ids+1] = id
            end
        end
    end

    --prevents that body:hadChanged() triggers next tick, just, a 20Hz would make any real changes invisible because every tick would be blocked
    if changed2 then
        for bodyid, body in pairs(controllercache.bodylist.bodies) do
            controllercache.bodylist.lastUpdate[bodyid] = sm.game.getCurrentTick()
        end
    end

    return changed_ids
end
