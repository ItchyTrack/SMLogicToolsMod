BlockMerge = BlockMerge or {}

function BlockMerge.onCreate(self)
    self.BlockMerge = {}
    self.BlockMerge.confirmed = 0
end

local nameTagAdd, nameTagCleanup, nameTagNextTick = baseLib.createNameTagManager()
function BlockMerge.main(self, primaryState, secondaryState, forceBuild)
    local lookAt = baseLib.lookAtConnectDot(self)
    nameTagNextTick(self)
    local BlockMerge = self.BlockMerge

    if lookAt then
        nameTagAdd(self, lookAt.worldPosition, "X")
        local childs = lookAt:getInteractable():getChildren()
        for i = 1, #childs do
            nameTagAdd(self, childs[i]:getShape().worldPosition, "#ff0000O")
        end
        local parents = lookAt:getInteractable():getParents()
        for i = 1, #parents do
            nameTagAdd(self, parents[i]:getShape().worldPosition, "#00ff00O")
        end

        if primaryState == 1 and #parents > 0 and #childs > 0 then
            if BlockMerge.confirmed == 1 then
                BlockMerge.confirmed = 0
                self.network:sendToServer("sv_blockMerge", lookAt)
            else
                BlockMerge.confirmed = 1
            end
        end

        if secondaryState == 1 then
            BlockMerge.confirmed = 0
        end

        if BlockMerge.confirmed == 1 then
            sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Merge Inputs and Outputs? Click again to confirm")
        else
            sm.gui.setInteractionText("", sm.gui.getKeyBinding("Create", true), "Merge Input and Output Connections")
        end

        if lookAt.id ~= BlockMerge.lookAt_id then
            BlockMerge.confirmed = 0
        end
        BlockMerge.lookAt_id = lookAt.id
    else
        BlockMerge.confirmed = 0
    end

    nameTagCleanup(self)
end

function BlockMerge.onUnequip(self)
    local BlockMerge = self.BlockMerge
    BlockMerge.confirmed = 0
    nameTagNextTick(self)
    nameTagCleanup(self)
end

function BlockMerge.sv_blockMerge(self, lookAt)
    local inter = lookAt:getInteractable()
    local childs = inter:getChildren()
    local parents = inter:getParents()

    if #childs == 0 then
        return
    end
    if #parents == 0 then
        return
    end

    for i = 1, #parents do
        local parent = parents[i]

        for j = 1, #childs do
            local child = childs[j]

            parent:connect(child)
        end
    end
    lookAt:destroyPart()
end