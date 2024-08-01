-- interface_controller.lua by HerrVincling, 05.06.2022

interfacedata = interfacedata or {} --otherwise it'll wipe on refresh of the script duhh ._.
interface_parttoclassname = interface_parttoclassname or {} --otherwise it'll wipe on refresh of the script duhh ._.

interface_interfacetopart = {}

function interface_signin(instance, classname, partFunction, colors, login)
    --print("RAM SIGNED IN?")
    if interfacedata[classname] == nil then
        interfacedata[classname] = {}
        interfacedata[classname].members = {}
        interfacedata[classname].inters = {}
        interfacedata[classname].iomembers = {}
    end
    local id = instance.interactable.id
    if login then
        interfacedata[classname].partFunction = partFunction
        interfacedata[classname].iocolors = colors

        interfacedata[classname].members[id] = instance
        interfacedata[classname].inters[id] = instance.interactable
        --print("added")
        interface_parttoclassname[id] = classname
    else
        interfacedata[classname].members[id] = nil
        interfacedata[classname].inters[id] = nil
        interface_parttoclassname[id] = nil
    end
end
interface_lastUpdate = sm.game.getCurrentTick()
function interface_controller(datalist, parentcache, childcache, oldstates)
    interface_lastUpdate = controllerlastupdate
    --parentcache holds ~~interactable arrays~~ id arrays now   --both now hold
    --childcache holds id arrays
    local interfacetopart = {}--interface_interfacetopart
    for classname, data in pairs(interfacedata) do
        local colorlist = data.iocolors
        local interlist = data.inters
        for id, inter in pairs(interlist) do
            local io = findio(inter, colorlist, interlist)
            interfacedata[classname].iomembers[id] = io
            for type, colors in pairs(io) do
                for color, idlist in pairs(colors) do
                    for i = 1, #idlist do
                        if interfacetopart[idlist[i]] ~= nil then
                            sm.gui.chatMessage("#D02525[Interface System] Error: Special block sharing an interface")
                        else
                            interfacetopart[idlist[i]] = id
                        end
                    end
                end
            end
        end
    end
    --print(interfacetopart)
    interface_interfacetopart = interfacetopart


    interface_helperdata = {}
    interface_helperdata.memberlist = {}
    local memberlist = interface_helperdata.memberlist

    interface_helperdata.bitlookup = {}
    interface_helperdata.colorlookup = {}
    interface_helperdata.isinput = {}
    for classname, tables in pairs(interfacedata) do
        memberlist[classname] = {}

        interface_helperdata.inputvalues = {}
        interface_helperdata.outputvalues = {}
        for id, _ in pairs(tables.members) do
            interface_helperdata.inputvalues[id] = {}
            for color, idlist in pairs(interfacedata[classname].iomembers[id].input) do
                local inputvalue = 0
                for i = 1, #idlist do
                    local state = oldstates[idlist[i]]
                    if state then
                        inputvalue = inputvalue + 2 ^ (i - 1)
                    end

                    interface_helperdata.bitlookup[idlist[i]] = i - 1
                    interface_helperdata.colorlookup[idlist[i]] = color
                    interface_helperdata.isinput[idlist[i]] = true
                end
                interface_helperdata.inputvalues[id][color] = inputvalue
            end
            interface_helperdata.outputvalues[id] = {}
            for color, idlist in pairs(interfacedata[classname].iomembers[id].output) do
                local outputvalue = 0
                for i = 1, #idlist do
                    local state = oldstates[idlist[i]]
                    if state then
                        outputvalue = outputvalue + 2 ^ (i - 1)
                    end

                    interface_helperdata.bitlookup[idlist[i]] = i - 1
                    interface_helperdata.colorlookup[idlist[i]] = color
                    interface_helperdata.isinput[idlist[i]] = false
                end
                interface_helperdata.outputvalues[id][color] = outputvalue
            end
        end
    end


    --Alter caches
    local idexists = {}
    for id, _ in pairs(datalist) do
        idexists[id] = true
    end
    for id, _ in pairs(datalist) do
        local parents = parentcache[id]
        for j = #parents, 1, -1 do
            if idexists[parents[j]] then
                --print("REMOVED")
                table.remove(parents, j)
            end
        end
        local childs = childcache[id]
        for j = #childs, 1, -1 do
            if idexists[childs[j]] then
                --print("C REMOVED")
                table.remove(childs, j)
            end
        end
    end
end

--returns a table like {output = {color1 = {id1, idn}, colorn = {id1, idn}}, input = {color1 = {id1, idn}, colorn = {id1, idn}}}
function findio(inter, colors, interlist)
    --parentcache holds ~~interactable arrays~~ id arrays now
    --childcache holds id arrays
    local iouuid = sm.uuid.new("23f93461-dfb5-47c5-b7a8-d3508e56b013")
    local ioresult = {}
    ioresult.output = {}
    ioresult.input = {}
    for _, color in pairs(colors.output) do
        local knownlist = {}
        local currentinter = inter
        ioresult.output[color:getHexStr()] = {}
        for i = 1, 31 do
            local childs = currentinter:getChildren()
            local iochilds = {}
            for j = 1, #childs do
                if childs[j]:getShape():getShapeUuid() == iouuid and childs[j]:getShape():getColor() == color then
                    table.insert(iochilds, childs[j])
                end
            end
            if #iochilds == 1 then
                if knownlist[iochilds[1].id] == nil then
                    --new interface block
                    knownlist[iochilds[1].id] = iochilds[1]
                    table.insert(ioresult.output[color:getHexStr()], iochilds[1].id)
                    currentinter = iochilds[1]
                else
                    --old interface block (loop)
                    sm.gui.chatMessage("#D02525[Interface System] Error: IO Output loops")
                    break
                end
            else
                if #iochilds > 1 then
                    sm.gui.chatMessage("#D02525[Interface System] Error: IO Output branches")
                    break
                end
                -- 0 childs
                break
            end
        end
    end
    for _, color in pairs(colors.input) do
        local knownlist = {}
        local currentinter = inter
        ioresult.input[color:getHexStr()] = {}
        for i = 1, 31 do
            local parents = currentinter:getParents()
            local ioparents = {}
            for j = 1, #parents do
                if parents[j]:getShape():getShapeUuid() == iouuid and parents[j]:getShape():getColor() == color then
                    table.insert(ioparents, parents[j])
                end
            end
            if #ioparents == 1 then
                if knownlist[ioparents[1].id] == nil then
                    --new interface block
                    knownlist[ioparents[1].id] = ioparents[1]
                    table.insert(ioresult.input[color:getHexStr()], ioparents[1].id)
                    currentinter = ioparents[1]
                else
                    --old interface block (loop)
                    sm.gui.chatMessage("#D02525[Interface System] Error: IO Input loops")
                    break
                end
            else
                if #ioparents > 1 then
                    sm.gui.chatMessage("#D02525[Interface System] Error: IO Input branches")
                    break
                end
                -- 0 childs
                break
            end
        end
    end
    return ioresult
end
