net.log("LOADING SingleMissionFunctions")

local server = {}
local prevExecTime = -1
local timerEndTime = 0
local simulationStartTime = 0

local playerReady = false
local scenarioId  = 0

-- UTILITY FUCTIONS
function server.getFlagValue(_flag)
    local _status,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag(\"".._flag.."\"); ")
    if not _status and _error then
        net.log("error getting flag: ".._error)
        return 0
    else	
        return tonumber(_status)
    end
end

function server.print_field_names(t)    
    local i,v=next(t,nil)
    while i do
		net.log("val = " .. i)
        i,v=next(t,i)
    end    
end

server.smEnabled = function()
    local _aux = server.getFlagValue("SM_ENABLED")
    return _aux == 1
end

function server.onSimulationStart()
	net.log("server.onSimulationStart()")
	simulationStartTime = os.clock()	
	DCS.setPause(false)	
    execLoop = true	
	net.dostring_in('server', "  trigger.action.setUserFlag(\"GAME_STATE\",0) ")
	net.dostring_in('server', "  trigger.action.setUserFlag(\"PLAYER_READY\",0) ")	
	playerRead = false
	timerEndTime = 0
end

function server.onSimulationStop()
	net.log("server.onSimulationStop()")
	--net.dostring_in('server', "  trigger.action.setUserFlag(\"GAME_STATE\",0) ")
	--net.dostring_in('server', "  trigger.action.setUserFlag(\"PLAYER_READY\",0) ")	
	playerRead = false
	timerEndTime = 0
	execLoop = false
end


function server.secondsToClock(seconds)
	local seconds = tonumber(seconds)		
	if seconds <= 0 then
		return "00:00"
	else    
		hours = string.format("%02.f", math.floor(seconds/3600))
		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)))
		secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60))
		return mins..":"..secs
	end
end


function server.onSimulationFrame()
	
	if execLoop and server.smEnabled() and playerReady then 	
		local curExecTime = os.clock()		
					
		if math.abs(curExecTime - prevExecTime) >= 1 then --do every second
			prevExecTime = curExecTime						
			net.log("T="..math.floor(curExecTime-simulationStartTime))
			
			-- 3 Game States:
			-- 0] Nobody has selected a slot, do not start a countdown.
			-- 1] Pre-Mission
			-- 2] Mission (Inactive)
			
			local gameState 	= server.getFlagValue("GAME_STATE")									
			
			if gameState==0 then
				
				timerEndTime = 0
			end
			-- 1] Pre-Mission			
			if gameState==1 then		
				
				if timerEndTime==0 then
					scenarioId = server.getFlagValue("ScenarioId")
					server.getFlagValue("TIMER_DURATION_SECONDS")
					timerEndTime = curExecTime+server.getFlagValue("TIMER_DURATION_SECONDS")
				end
				local tRem = math.floor(timerEndTime-curExecTime)
				if tRem < 0 then
					net.log("trigger.action.setUserFlag(GAME_STATE,0)")
					net.dostring_in('server', "  trigger.action.setUserFlag(\"GAME_STATE\",2) ")					
					net.log("Reset Countdown Timer")					
					net.dostring_in('server', " trigger.action.outText(\"ALL UNITS, Cleared for Take-off\", 2.5, true)")																									
				else
					if scenarioId==0 then
						net.dostring_in('server', " trigger.action.outText(\"Flight Starts in ".. server.secondsToClock(tRem) .."\\nTAXI to runway and HOLD until instructed\", 2.5, true)")																				
					elseif scenarioId==1 then
						net.dostring_in('server', " trigger.action.outTextForCountry(2, \"Take-off in  ".. server.secondsToClock(tRem) .." | TAXI to Runway 09 and WAIT\\nSPECIAL OBJECTIVE:\\nUSAF Bomber Command is concentrating its assault on a narrow swath of the axis FRONT. A force of M4 Sherman tanks will breakout to the EAST. Support its advance toward the FACTORY.  Bonus points will awarded as units secure the FACTORY complex at Bretteville. (See Kneeboard)\\nStandard Objectives Apply\", 2.5, true)")													
						net.dostring_in('server', " trigger.action.outTextForCountry(66,\"Take-off in  ".. server.secondsToClock(tRem) .." | TAXI to Runway 12 and WAIT\\nSPECIAL OBJECTIVE:\\nIncreased allied communications suggest an assault near the front line is imminent. Defend the FACTORY complex at Bretteville. Bonus points will be awarded for the destruction of advancing units. (See Kneeboard)\\nStandard Objectives Apply\", 2.5, true)")																
					elseif scenarioId==2 then
						net.dostring_in('server', " trigger.action.outTextForCountry(2, \"Take-off in  ".. server.secondsToClock(tRem) .." | TAXI to Runway 09 and WAIT\\nSPECIAL OBJECTIVE:\\nA force of panzers broke the front line headed NORTH toward the coast. Intercept the thrust before Les Moulins is captured isolating our allies to the East. Bonus points will be awarded for the destruction of advancing units. (See Kneeboard)\\nStandard Objectives Apply\", 2.5, true)")															
						net.dostring_in('server', " trigger.action.outTextForCountry(66,\"Take-off in  ".. server.secondsToClock(tRem) .." | TAXI to Runway 12 and WAIT\\nSPECIAL OBJECTIVE:\\nPanzers breeched the enemy line and march toward the port town of Les Moulins. Support its advance to the coast by destroying nearby threats. Bonus points will be awarded as Panzers arrive at the city. (See Kneeboard)\\nStandard Objectives Apply\", 2.5, true)")																					
					elseif scenarioId==3 then
						net.dostring_in('server', " trigger.action.outTextForCountry(2, \"Take-off in  ".. server.secondsToClock(tRem) .." | TAXI to Runway 09 and WAIT\\nSPECIAL OBJECTIVE:\\nAllied transports are enroute to GOLD beach. Destroy the naval guns defending the beach. Bonus points will be awarded for ships that reach the deployment site. (See Kneeboard)\\nStandard Objectives Apply\", 2.5, true)")															
						net.dostring_in('server', " trigger.action.outTextForCountry(66,\"Take-off in  ".. server.secondsToClock(tRem) .." | TAXI to Runway 12 and WAIT\\nSPECIAL OBJECTIVE:\\nAllied transports are steaming EAST along the coast.  Defend naval guns and/or sink the transports before they reach the deployment site. (See Kneeboard)\\nStandard Objectives Apply\", 2.5, true)")					
					end					
				end
			end
								
		end
	end
end

-- Set Flag when at least 1+ player has joined slot
server.onPlayerTryChangeSlot = function(playerID, side, slotID)
	net.dostring_in('server', "  trigger.action.setUserFlag(\"PLAYER_READY\",1) ")	
	if server.getFlagValue("GAME_STATE")==0 then
		net.dostring_in('server', "  trigger.action.setUserFlag(\"GAME_STATE\",1) ")	
	end
	playerReady = true
   return true
end

DCS.setUserCallbacks(server)

net.log("server callbacks loaded")


