Multitool = class()
dofile("MultitoolLib/baseLib.lua")
dofile("MultitoolLib/logicInfo.lua")
dofile("MultitoolLib/quickGateConverter.lua")
dofile("MultitoolLib/parallelConnectTool.lua")
dofile("MultitoolLib/inlineConnectTool.lua")
dofile("MultitoolLib/2dMatrixConnectTool.lua")
dofile("MultitoolLib/controlMerge.lua")
dofile("MultitoolLib/nToNConnectTool.lua")

dofile("MultitoolLib/gui.lua")

dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )

local renderables = { "$CONTENT_DATA/Objects/Textures/Char_liftremote/char_liftremote.rend" }
local renderablesTp = { "$CONTENT_DATA/Objects/Textures/Char_liftremote/char_liftremote_tp_animlist.rend" }
local renderablesFp = { "$CONTENT_DATA/Objects/Textures/Char_liftremote/char_liftremote_fp_animlist.rend" }

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Multitool.loadAnimations(self)
    self.tpAnimations = createTpAnimations(
		self.tool,
		{
			idle = { "weldtool_idle" },
			pickup = { "weldtool_pickup", { nextAnimation = "idle" } },
			putdown = { "weldtool_putdown" },
            useInto = { "weldtool_use_into" },
            useIdle = { "weldtool_use_idle" },
            useExit = { "weldtool_use_exit" },
            useError = { "weldtool_use_error" }
		}
	)
    local movementAnimations = {
		idle = "weldtool_idle",
		idleRelaxed = "weldtool_relaxed",

		sprint = "weldtool_sprint",
		runFwd = "weldtool_run_fwd",
		runBwd = "weldtool_run_bwd",

		jump = "weldtool_jump",
		jumpUp = "weldtool_jump_up",
		jumpDown = "weldtool_jump_down",

		land = "weldtool_jump_land",
		landFwd = "weldtool_jump_land_fwd",
		landBwd = "weldtool_jump_land_bwd",

		crouchIdle = "weldtool_crouch_idle",
		crouchFwd = "weldtool_crouch_fwd",
		crouchBwd = "weldtool_crouch_bwd"
	}

    for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

    setTpAnimation( self.tpAnimations, "idle", 5.0 )

    if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "weldtool_pickup", { nextAnimation = "idle" } },
				unequip = { "weldtool_putdown" },

				idle = { "weldtool_idle", { looping = true } },

				sprintInto = { "weldtool_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "weldtool_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "weldtool_sprint_idle", { looping = true } }
			}
		)
	end
    self.blendTime = 0.2
end



function Multitool.client_onCreate(self)
	ParallelConnect.onCreate(self)
	InlineConnect.onCreate(self)
	BlockMerge.onCreate(self)
	NtoNConnect.onCreate(self)

    self.tool:setDispersionFraction(0.1)
    self.confirmed = 0
    self.F = false
    self.selectedTool = 1
    LogicInfo.cl_onCreate(self)
end

function Multitool.client_onRefresh(self)
    self:client_onCreate()
end

function Multitool.client_onInteract(self, character, state)
    --print("EEEE")
end

function Multitool.client_onUpdate(self, dt)
    LogicInfo.client_onUpdate(self, dt)

    -- First person animation
	local isSprinting =  self.tool:isSprinting()
	local isCrouching =  self.tool:isCrouching()

    if self.tool:isLocal() then
		if self.equipped then
			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not self.tool:isSprinting() and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end
		end
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

    if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end

    local totalWeight = 0.0
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )

			if animation.time >= animation.info.duration - self.blendTime then
				if name == "pickup" then
					setTpAnimation( self.tpAnimations, "idle", 0.001 )
				elseif animation.nextAnimation ~= "" then
					setTpAnimation( self.tpAnimations, animation.nextAnimation, 0.001 )
				end
			end
		else
			animation.weight = math.max( animation.weight - ( self.tpAnimations.blendSpeed * dt ), 0.0 )
		end

		totalWeight = totalWeight + animation.weight
	end
end

function Multitool.client_onDestroy(self)

end

function Multitool.client_onEquip(self, animate)
    self.confirmed = 0

    if animate then
		sm.audio.play( "PaintTool - Equip", self.tool:getPosition() )
	end
    self.wantEquipped = true

    currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
    self.tool:setTpRenderables( currentRenderablesTp )

    self:loadAnimations()

    if self.tool:isLocal() then
		-- Sets PotatoRifle renderable, change this to change the mesh
		self.tool:setFpRenderables( currentRenderablesFp )
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function Multitool.client_onUnequip(self, animate)
    ParallelConnect.onUnequip(self)
    InlineConnect.onUnequip(self)
	BlockMerge.onUnequip(self)
	NtoNConnect.onUnequip(self)

    self.wantEquipped = false
	self.equipped = false
    if sm.exists( self.tool ) then
		if animate then
			sm.audio.play( "PaintTool - Unequip", self.tool:getPosition() )
		end
		setTpAnimation( self.tpAnimations, "putdown" )
		if self.tool:isLocal() then
			if self.fpAnimations.currentAnimation ~= "unequip" then
				swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
			end
		end
	end
end

Multitool.tools = {
    "Logic Converter",
    "Advanced Tool Functions",
    "Parallel Connect Tool",
    "Series Connect Tool",
    "Block Merge",
	"N to N Connect Tool (Beta)",
}

function Multitool.client_onEquippedUpdate(self, primaryState, secondaryState, forceBuild)
	if self.selectedTool == 6 then
		NtoNConnect.main(self, primaryState, secondaryState, forceBuild)
	else
		NtoNConnect.onUnequip(self)
	end

	if self.selectedTool == 5 then
		BlockMerge.main(self, primaryState, secondaryState, forceBuild)
	else
		BlockMerge.onUnequip(self)
	end

    if self.selectedTool == 4 then
        InlineConnect.main(self, primaryState, secondaryState, forceBuild)
    else
        InlineConnect.onUnequip(self)
    end

    if self.selectedTool == 3 then
        ParallelConnect.main(self, primaryState, secondaryState, forceBuild)
    else
        ParallelConnect.onUnequip(self)
    end

    if self.selectedTool == 2 then
        if forceBuild and not self.F then
            --print("F")
            if math.random(0, 10000 ) == 69 then
                sm.gui.chatMessage(sm.localPlayer.getPlayer():getName() .. " paid respect")
            end
            if LogicInfo.gui:isActive() then
                LogicInfo.gui:close()
            else
                LogicInfo.gui:open()
            end
        end
        sm.gui.setInteractionText("", sm.gui.getKeyBinding("ForceBuild", true), "Open Settings")
    end
    self.F = forceBuild

    if self.selectedTool == 1 then
        if self.tool:isLocal() and sm.localPlayer.getPlayer():getCharacter() then
            local success, raycastResult = sm.localPlayer.getRaycast( 7.5 )
            Converter.cl_aim(self, primaryState, secondaryState, raycastResult )
        end
    end
    --sm.gui.displayAlertText("Tool: " .. Multitool.tools[self.selectedTool] .. " (" .. self.selectedTool .. "/" .. #Multitool.tools .. ")", 1)
    sm.gui.setInteractionText("", sm.gui.getKeyBinding("NextCreateRotation", true), "Switch Tool ", "<p textShadow='false' bg='gui_keybinds_bg' color='#ffffff' spacing='4'>" .. Multitool.tools[self.selectedTool] .. " (" .. self.selectedTool .. "/" .. #Multitool.tools .. ")</p>")--"Switch tool")
    return false, true --blocks secondary -> doesn't remove parts/blocks
end

function Multitool.client_onToggle(self)
    if sm.localPlayer.getPlayer():getCharacter():isCrouching() then
        self.selectedTool = self.selectedTool - 1
        if self.selectedTool <= 0 then
            self.selectedTool = #Multitool.tools
        end
    else
        self.selectedTool = self.selectedTool + 1
        if self.selectedTool > #Multitool.tools then
            self.selectedTool = 1
        end
    end
    return true
end

function Multitool.client_onFixedUpdate(self, deltaTime)
    LogicInfo.client_onFixedUpdate(self, deltaTime)
end

-- Advanced Tool Functions --
function Multitool.cl_LogicInfo_onButtonPress(self, btnName)
    LogicInfo.onButtonPress(self, btnName)
end

function Multitool.cl_LogicInfo_onTabPress(self, tabName)
    LogicInfo.onTabChange(self, tabName)
end

function Multitool.sv_pierceColor(self, data)
    LogicInfo.sv_pierceColor(self, data)
end
-- Advanced Tool Functions --

-- Quick Gate Converter --
function Multitool.sv_convertBody(self, data)
    Converter.sv_convertBody(self, data)
end
-- Quick Gate Converter --

-- Parallel Connect Tool --
function Multitool.sv_connectLines(self, data)
    ParallelConnect.sv_connectLines(self, data)
end
-- Parallel Connect Tool --

-- Inline Connect Tool --
function Multitool.sv_connectInlineLines(self, data)
    InlineConnect.sv_connectLines(self, data)
end
-- Inline Connect Tool --

-- N to N Connect Tool --
function Multitool.sv_connectNtoNLines(self, data)
	NtoNConnect.sv_connectLines(self, data)
end
-- N to N Connect Tool --

-- Block Merge --
function Multitool.sv_blockMerge(self, data)
	BlockMerge.sv_blockMerge(self, data)
end
-- Block Merge --

function Multitool.client_onFixedUpdate(self, deltaTime)
    LogicInfo.client_onFixedUpdate(self, deltaTime)
end
