-- controller.lua for quick logic by HerrVincling, 05.06.2022
dofile("init.lua")
loadController()
dofile("external_functions.lua")
dofile("internal_functions.lua")
dofile("balanced_circuits.lua")
dofile("tpt_system.lua")
dofile("preprocessor.lua")

dofile("$CONTENT_DATA/Scripts/interface_controller.lua")

function controller2(tickspeed) --Executes every game tick (self = Autotool)
    if tickspeed == 0 then
        --print("sim halted")
        return {}
    end

    controllerlastupdate = sm.game.getCurrentTick()

    local clock0 = os.clock()
    local clock1, clock2, clock3, clock4 = clock0, clock0, clock0, clock0

    --[[ Global Databases
    All Parts
    - States (by ID)
    - Interactables (by ID)

    Q-Logic Parts
    - Data "controllermemberlist" (by class, by ID)
    - Function [per class]
    - Mod-only Interactables (by ID)
    - Classname (by ID)
    ]]

    local datalist = controllermemberlist
    local functionlist = controllerfunctionlist
    local interlist = controllercache.inters
    local statelist = controllercache.states

    local parentcache = controllercache.parents
    local childcache = controllercache.childs


    --database.lua
    --0.001s
    local bodyupdate = update_bodies() --check for changed bodies and update global tables

    --clear vanilla cache when a body updates (not perfect but good enough)

    if bodyupdate then
        if datalist.IO then
            --TODO scpu errors expeciall in this bad boy right here \/
            interface_controller(datalist.IO, parentcache, childcache, statelist)
        end
        --balanced_circuit_optimization(childcache, parentcache) TODO balanced circuits, will be new input for table generation
        generate_main_tpt_tables() --generate optimized lists for main tpt simulation
    end

    vanilla_logic_update() --update states of vanilla parts

    --Indexed arrays (copies) instead of tables
    --print(tpt_main.count)
    --print(tpt_main.member_update_queue)
    tpt_simulation(tickspeed, tpt_main.member_update_queue, functionlist, tpt_main.data, tpt_main.parentcount, tpt_main.count, tpt_main.states, tpt_main.childs, tpt_main.classname)

    --print(tpt_main.states)
    --0.0 - 0.001s
    clock1 = os.clock()
    changed_ids = setNewInGameLogicStates(tpt_main.states, statelist, interlist) --internal Function
    clock2 = os.clock()

    --print(interlist)

    --self_Autotool.network:sendToClients("cl_updateTextures", {})--{states = tpt_main.states, index_lookup = tpt_main.index_lookup})

    local testvar = clock2-clock1
    local testvar2 = os.clock()-clock0
    --print(testvar)
    --print(testvar, "\t", testvar2-testvar)--, "\t", tptontime, "\t", testvar-tptontime)
    --print(timeloss)
    --print(testcounter / testvar)
    return changed_ids --, testcounter
end
