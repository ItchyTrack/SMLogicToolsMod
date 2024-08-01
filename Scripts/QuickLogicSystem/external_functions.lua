local function addNewInteractable(inter)
    local id = inter.id
    local bodylist = controllercache.bodylist
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

function signin(instance, classname, partfunction, login)
    if controllermemberlist[classname] == nil then
        controllermemberlist[classname] = {}
        controllercache.states[classname] = {}
    end
    if login then
        controllerfunctionlist[classname] = partfunction --temporary, should be only once

        controllermemberlist[classname][instance.interactable.id] = instance.data --has to be a table (because of it's "pointer" properties)
        controllercache.states[instance.interactable.id] = instance.interactable.active --used to be split up per class, which the bodyupdate "fixed" for probably a very long time O_O
        controllercache.inters[instance.interactable.id] = instance.interactable
        controllercache.minters[instance.interactable.id] = instance.interactable
        --controllernewinterlist[instance.interactable.id] = instance.interactable
        addNewInteractable(instance.interactable)
        controllercache.classname[instance.interactable.id] = classname
    else
        controllermemberlist[classname][instance.interactable.id] = nil
        controllercache.inters[instance.interactable.id] = nil
        controllercache.minters[instance.interactable.id] = nil
        controllercache.classname[instance.interactable.id] = nil
    end
end

--Deprecated
function getData(classname, id)
    return controllermemberlist[classname][id]
end

--Deprecated
function setData(classname, id, data)
    controllermemberlist[classname][id] = data
end

function addToQueue(instance, classname)
    id = instance.interactable.id
    index = tpt_main.index_lookup[id]
    if index == nil then
        print("no index")
        return
    end
    for i = 1, #tpt_main.member_update_queue[classname] do
        if tpt_main.member_update_queue[classname][i] == index then
            print("already in queue")
            return
        end
    end
    tpt_main.member_update_queue[classname][#tpt_main.member_update_queue+1] = index
    print("added to queue")
end
