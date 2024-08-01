
function loadController() --runs on controller.lua file update
    controllerlastupdate = sm.game.getCurrentTick()

    controllerspeed = 1
    --controllerspeed = sm.storage.load("controller") or 1

    function controller_saveSpeed()
        --sm.storage.save("controller", controllerspeed)
    end


    --controller() is now globally accessible, any lonely timer or logic gate can run it

    if controllerloaded ~= true then
        print("Initializing Quick Logic Controller v3")
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

        --Non System Data - Application Specific
        tpt_main = {}
        --tpt_main.members = {} --[class][index] = {indexes}
        tpt_main.inters = {} --[index] = id
        tpt_main.count = {} --[index] = number
        tpt_main.parentcount = {} --[index] = {number}
        tpt_main.childs = {} --[index] = {indexes}
        tpt_main.member_update_queue = {} --[class][index] = {indexes}
        tpt_main.index_lookup = {} --[id] = index
        tpt_main.data = {} --[classname][index] = data
        tpt_main.states = {} --[index] = state
        tpt_main.classname = {}

        --tpt_main.main_functions = {} --Array with functions
        --tpt_main.part_to_function = {} --Array with indexes to main_functions
    end
    controllerloaded = true
end
