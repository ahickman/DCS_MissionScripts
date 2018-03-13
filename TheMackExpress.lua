--dofile([[C:\Users\AMH\Saved Games\DCS\MissionScripts\mathHelpers.lua]])
--dofile([[C:\Users\AMH\Saved Games\DCS\MissionScripts\Scenario01\Scenario01.lua]])

_state							= {} -- Reset Round Info State
_state.pointsRED 				= 0
_state.pointsBLUE 				= 0
_state.victor 					= "NONE"
_state.pointsToWin				= 999
_state.waitingToRestart 		= 0
_state.pendingPoints 			= {}
_state.earnedPoints 			= {}	
_state.lastToHit 				= {}
_state.vehicleGroups 			= {}
_state.AI_aircraftGroupsRED 	= {}
_state.AI_aircraftGroupsBLUE 	= {}


local function tableLength(myTable)
	numItems = 0
	for k,v in pairs(myTable) do
		numItems = numItems + 1
	end
	return numItems
end


local function attachEventListenersAircraft(g)	
	if g~=nil then				
		if g:IsAlive() then 								
			local u = g:GetUnit(1)	
			
			--u:HandleEvent( EVENTS.ShootingEnd )							
			--function u:OnEventShootingEnd( EventData )												
			--	MESSAGE:New("SHOOTING!     "..u:GetGroup():GetName(), 1 ):ToAll()
			--end
			
			
			u:HandleEvent( EVENTS.Land )							
			function u:OnEventLand( EventData )	
				print_r(EventData)
				--MESSAGE:New("LANDED!     "..EventData.place.id_, 1 ):ToAll()
				
				-- LIST ALL VALID AIRFIELDS AS CONDITION										
				if (u:GetGroup():GetCoalition()==coalition.side.BLUE and EventData.place.id_==5000035) or (u:GetGroup():GetCoalition()==coalition.side.RED and EventData.place.id_==5000006) then
					if _state.pendingPoints[u:GetGroup():GetName()] ~= nil then
						
						local outcome = u:GetGroup():GetName().." scored ".._state.pendingPoints[u:GetGroup():GetName()].." points for "
						if u:GetGroup():GetCoalition()==coalition.side.BLUE then
							_state.pointsBLUE = _state.pointsBLUE+_state.pendingPoints[u:GetGroup():GetName()]	
							outcome = outcome.."BLUE!"
						else
							_state.pointsRED = _state.pointsRED+_state.pendingPoints[u:GetGroup():GetName()]					
							outcome = outcome.."RED!"
						end
						
						
						if _state.earnedPoints[u:GetGroup():GetName()]==nil then
							_state.earnedPoints[u:GetGroup():GetName()] = _state.pendingPoints[u:GetGroup():GetName()]								
						else
							_state.earnedPoints[u:GetGroup():GetName()] = _state.earnedPoints[u:GetGroup():GetName()]+_state.pendingPoints[u:GetGroup():GetName()]								
						end
						_state.pendingPoints[u:GetGroup():GetName()] = nil										
						
						
						local duration = 10
						if _state.pointsBLUE>_state.pointsToWin then
							_state.victor = "BLUE"
							duration = 600
						elseif
							_state.pointsRED>_state.pointsToWin then
							_state.victor = "BLUE"
							duration = 600
						end
						-- UPDATE SCORE FOR EVERYONE					
						MESSAGE:New(outcome.."\n\nBLUE.....".._state.pointsBLUE.."\nRED.......".._state.pointsRED.."\n\n ", duration ):ToAll()
					end
					
					
				end

				
				
			end			
			u:HandleEvent( EVENTS.Dead ) 
			function u:OnEventDead( EventData )				_state.pendingPoints[u:GetGroup():GetName()] = nil end									
			u:HandleEvent( EVENTS.PilotDead )							
			function u:OnEventPilotDead( EventData )		_state.pendingPoints[u:GetGroup():GetName()] = nil end									
			u:HandleEvent( EVENTS.Crash )							
			function u:OnEventCrash( EventData )			_state.pendingPoints[u:GetGroup():GetName()] = nil end									
			u:HandleEvent( EVENTS.Ejection )							
			function u:OnEventEjection( EventData )			_state.pendingPoints[u:GetGroup():GetName()] = nil end									
			u:HandleEvent( EVENTS.PlayerLeaveUnit )							
			function u:OnEventPlayerLeaveUnit( EventData )	_state.pendingPoints[u:GetGroup():GetName()] = nil end									
		end
	end	
end

function attachEventListenerVehicle(g)		
	if g~=nil then						
		if g:IsAlive() then 								
			local u = g:GetUnit(1)	
			
			u:HandleEvent( EVENTS.Hit )							
			function u:OnEventHit( EventData )					
				local initiator = UNIT:Find(EventData.initiator)
				-- This Prevents Friendly Fire on trucks
				if initiator:GetCoalition()~=u:GetGroup():GetCoalition() then
					_state.lastToHit[u:GetGroup():GetName()] = initiator:GetGroup():GetName()
				end
				-- MESSAGE:New("HIT!     "..initiator:GetGroup():GetName(), 1 ):ToAll()
			end
			
			u:HandleEvent( EVENTS.Dead )							
			function u:OnEventDead( EventData )					
				local initiator = _state.lastToHit[u:GetGroup():GetName()]							
				if _state.pendingPoints[initiator]==nil then				
					_state.pendingPoints[initiator] = 1;
				else
					_state.pendingPoints[initiator] = _state.pendingPoints[initiator]+1;
				end
				-- TODO: SEND MESSAGE TO CLIENT INDICATING NUMBER OF PENDING POINTS
				MESSAGE:New("Vehicle Destroyed!/nRTB to score ".._state.pendingPoints[initiator].." points"):ToGroup(g)
				--print_r(EventData)
				--MESSAGE:New("DEAD1!   ", 20 ):ToAll()							
				--MESSAGE:New("DEAD2!   "..u:GetGroup():GetName(), 20 ):ToAll()	
				--MESSAGE:New("DEAD3!   "..initiator, 20 ):ToAll()	
				--print_r(_state.lastToHit)
				--MESSAGE:New("DEAD!!!!!   "..initiator..":".._state.pendingPoints[initiator], 20 ):ToAll()
			end					
		end
	end	
end	
	
--Score Scheduler	

local victoryScheduler = SCHEDULER:New( nil, 
	function()		
		if _state.waitingToRestart==0 then
			if _state.victor == "BLUE" then		
				MESSAGE:New("BLUE IS VICTORIOUS! Mission Restarting . . . \n\n", 600 ):ToAll()		
			elseif _state.victor == "RED" then			
				MESSAGE:New("RED IS VICTORIOUS! Mission Restarting . . . \n\n", 600 ):ToAll()		
			end
			if _state.victor~="NONE" then
				_state.waitingToRestart=1
				-- schedule Mission Reload
				local restartScheduler = SCHEDULER:New( nil, 
					function()		
						MESSAGE:New("RESTARTING")
					end, {}, 30
				)

			end		
		end
	end, {}, 0, 10
)


local scoreScheduler = SCHEDULER:New( nil, 
	function()							
		if _state.victor=="NONE" then
			MESSAGE:New("\n\nBLUE.....".._state.pointsBLUE.."\nRED.......".._state.pointsRED.."\n ", 10 ):ToAll()		
		end
	end, {}, 0, 120
)
	
	
function spawnTrucks( spawnGroup, zoneDest, number )
	local truckSpawner = SCHEDULER:New( nil, 
		function(spawnGroup, zoneDest, number)							
			local g			= spawnGroup:Spawn()			
			attachEventListenerVehicle(g)	
			_state.vehicleGroups[g:GetName()]= zoneDest:GetName()			
			--MESSAGE:New("SPAWN "..number, 2 ):ToAll()						
		end, {spawnGroup, zoneDest, number}, 0, 6, 0, 6*(number-1)
	)
end

attachEventListenersAircraft(GROUP:FindByName("testP51"))

zoneRD = {}
zoneRD[1]		= ZONE:New("RD1")
zoneRD[2]		= ZONE:New("RD2")
zoneRD[3]		= ZONE:New("RD3")
zoneRD[4]		= ZONE:New("RD4")

--Red Truck SpawnGroups
sgRT = {}
sgRT[1]		= SPAWN:New( "RT1" ):InitLimit( 150,150 )	
sgRT[2]		= SPAWN:New( "RT2" ):InitLimit( 150,150 )	
sgRT[3]		= SPAWN:New( "RT3" ):InitLimit( 150,150 )	
sgRT[4]		= SPAWN:New( "RT4" ):InitLimit( 150,150 )	

zoneBD = {}
zoneBD[1]		= ZONE:New("BD1")
zoneBD[2]		= ZONE:New("BD2")
zoneBD[3]		= ZONE:New("BD3")
zoneBD[4]		= ZONE:New("BD4")

--Blue Truck SpawnGroups
sgBT = {}
sgBT[1]		= SPAWN:New( "BT1" ):InitLimit( 150,150 )	
sgBT[2]		= SPAWN:New( "BT2" ):InitLimit( 150,150 )	
sgBT[3]		= SPAWN:New( "BT3" ):InitLimit( 150,150 )	
sgBT[4]		= SPAWN:New( "BT4" ):InitLimit( 150,150 )	


--Spawn 1, 10 truck convoy every, 10 minutes
spawnIntervalSec 		= 600 	-- % Attempt spawn every minute 60
spawnIntervalRandSec 	= 0 	-- % Add a little slop 20
spawnPercentChance 		= 100 	-- % chance to spawn every interval 10
convoyLengthMin			= 3 	
convoyLengthMax 		= 4	

-- Spawns Convoys Periodically
local convoySpawner = SCHEDULER:New( nil, 
	function(sgRT, zoneRD, sgBT, zoneBD, convoyLengthMin, convoyLengthMax)				
		--MESSAGE:New("SpawnConvoy", 20 ):ToAll()		

		local randomInt = math.random(100)
		if randomInt<=spawnPercentChance then			
			local spawnInt1 = math.random(1,#sgRT)			
			local convoyLength = math.random(convoyLengthMin,convoyLengthMax)			
			spawnTrucks( sgRT[spawnInt1], zoneRD[spawnInt1], convoyLength )
		end
		randomInt = math.random(100)
		if randomInt<=spawnPercentChance then			
			local spawnInt1 = math.random(1,#sgBT)			
			local convoyLength = math.random(convoyLengthMin,convoyLengthMax)
			spawnTrucks( sgBT[spawnInt1], zoneBD[spawnInt1], convoyLength )
		end			
	end, {sgRT, zoneRD, sgBT, zoneBD, convoyLengthMin, convoyLengthMax}, 0, spawnIntervalSec, spawnIntervalRandSec
)

	

local removeVehiclesAtDestination = SCHEDULER:New( nil, 
	function()		
		
		for groupName,zoneName in pairs(_state.vehicleGroups) do
		
			local g = GROUP:FindByName(groupName)
			if g==nil then					
				_state.vehicleGroups[groupName]=nil
			else		
				if g:IsAlive() then
					local zone = ZONE:New(zoneName)
					--MESSAGE:New("ZONE  = "..zone:GetVec2().x..":"..zone:GetVec2().y, 2 ):ToAll()					
					--MESSAGE:New("GROUP = "..g:GetUnit(1):GetVec2().x..":"..g:GetUnit(1):GetVec2().y, 2 ):ToAll()						
					if zone:IsPointVec2InZone(POINT_VEC2:NewFromVec2(g:GetVec2() )) then					
						--MESSAGE:New("DESTROY = "..g:GetName(), 100 ):ToAll()		
						g:Destroy()
						_state.vehicleGroups[groupName]=nil
					end
				else
					_state.vehicleGroups[groupName]=nil
				end
			end 
		
		end
		--MESSAGE:New("Remove Vehicle Checker", 2 ):ToAll()		

		attachEventListenersAircraft(GROUP:FindByName("Alpha 1"))
		attachEventListenersAircraft(GROUP:FindByName("Alpha 2"))
		attachEventListenersAircraft(GROUP:FindByName("Alpha 3"))
		attachEventListenersAircraft(GROUP:FindByName("Alpha 4"))
		attachEventListenersAircraft(GROUP:FindByName("Bravo 1"))
		attachEventListenersAircraft(GROUP:FindByName("Bravo 2"))
		attachEventListenersAircraft(GROUP:FindByName("Bravo 3"))
		attachEventListenersAircraft(GROUP:FindByName("Bravo 4"))
		attachEventListenersAircraft(GROUP:FindByName("Queen 1"))
		attachEventListenersAircraft(GROUP:FindByName("Queen 2"))
		attachEventListenersAircraft(GROUP:FindByName("Queen 3"))
		attachEventListenersAircraft(GROUP:FindByName("Queen 4"))
		attachEventListenersAircraft(GROUP:FindByName("Winston 1"))
		attachEventListenersAircraft(GROUP:FindByName("Winston 2"))
		attachEventListenersAircraft(GROUP:FindByName("Winston 3"))
		attachEventListenersAircraft(GROUP:FindByName("Winston 4"))

		attachEventListenersAircraft(GROUP:FindByName("Anton 1"))
		attachEventListenersAircraft(GROUP:FindByName("Anton 2"))
		attachEventListenersAircraft(GROUP:FindByName("Anton 3"))
		attachEventListenersAircraft(GROUP:FindByName("Anton 4"))
		attachEventListenersAircraft(GROUP:FindByName("Berta 1"))
		attachEventListenersAircraft(GROUP:FindByName("Berta 2"))
		attachEventListenersAircraft(GROUP:FindByName("Berta 3"))
		attachEventListenersAircraft(GROUP:FindByName("Berta 4"))
		attachEventListenersAircraft(GROUP:FindByName("Charlotte 1"))
		attachEventListenersAircraft(GROUP:FindByName("Charlotte 2"))
		attachEventListenersAircraft(GROUP:FindByName("Charlotte 3"))
		attachEventListenersAircraft(GROUP:FindByName("Charlotte 4"))
		attachEventListenersAircraft(GROUP:FindByName("Dora 1"))
		attachEventListenersAircraft(GROUP:FindByName("Dora 2"))
		attachEventListenersAircraft(GROUP:FindByName("Dora 3"))
		attachEventListenersAircraft(GROUP:FindByName("Dora 4"))
		
	end, {}, 5,5
)

--g = SPAWN:New("Blue2"):Spawn()
--print_r(g:GetTaskMission())

-- THIS WORKS!
sgRed2 = SPAWN:New( "Red2" )
	:InitLimit( 100,100 )
	:OnSpawnGroup(
		function( SpawnGroup )					
			--MESSAGE:New("FIRED!", 100 ):ToAll()						
			local tt = {}
			tt[1] = "Air"
			EngageTargetTask ={ 
			  id = 'EngageTargets', 
			  params = { 
				maxDist = 4000,
				maxDistEnabled = true,
				targetTypes = tt,
				priority = 100 
			  } 
			}
			--print_r(EngageTargetTask)
			ComboTaskEmpty = { 
			   id = 'ComboTask', 
			   params = { 
				 tasks = {        
				 } 
			   } 
			 }
			SwitchWaypointCommand = { 
			   id = 'SwitchWaypoint', 
			   params = { 
				 fromWaypointIndex = 8,  
				 goToWaypointIndex = 3, 
			   } 
			}
			SwitchWaypointTask = {
			 id = 'WrappedAction', 
			   params = { 
				 action = SwitchWaypointCommand 
			   }
			}					 				
			
			ComboTaskSwitchWaypoint = { 
			   id = 'ComboTask', 
			   params = { 
				 tasks = {    
				   [1] = SwitchWaypointTask,      
				 } 
			   } 
			}
			
			randomInt = math.random(3,#_ptsR+1)	
			RandomWaypointCommand = { 
			   id = 'SwitchWaypoint', 
			   params = { 
				 fromWaypointIndex = 2,  
				 goToWaypointIndex = randomInt, 
			   } 
			}
				RandomWaypointTask = {
			 id = 'WrappedAction', 
			   params = { 
				 action = RandomWaypointCommand 
			   }
			}					 				
			
			ComboTaskRandomWaypoint = { 
			   id = 'ComboTask', 
			   params = { 
				 tasks = {    
				   [1] = RandomWaypointTask,      
				 } 
			   } 
			}
				
			local Mission = {}
			Mission.id = 'Mission'
			Mission.params = {}
			Mission.params.route  = {}
			Mission.params.route.points = {}
			Mission.params.route.points[1] = {}
			Mission.params.route.points[1].type   		= "TakeOff"
			Mission.params.route.points[1].airdromeId  = 3
			Mission.params.route.points[1].action   	= "From Runway"
			Mission.params.route.points[1].y   		= -77791.164063
			Mission.params.route.points[1].x   		= -18675.582031 
			Mission.params.route.points[1].alt   		= 29
			Mission.params.route.points[1].alt_type  	= "BARO"
			Mission.params.route.points[1].speed  	 	= 138.88888
			Mission.params.route.points[1].speed_locked = true
			Mission.params.route.points[1].ETA  		= 0
			Mission.params.route.points[1].ETA_locked 	= true
			Mission.params.route.points[1].name  		= "PT1"
			Mission.params.route.points[1].task   		= EngageTargetTask 
					
			for ii = 1, #_ptsR do
				Mission.params.route.points[ii+1] = {}
				Mission.params.route.points[ii+1].type   		= "Turning Point"
				Mission.params.route.points[ii+1].airdromeId  	= 3
				Mission.params.route.points[ii+1].action   		= "Turning Point"
				Mission.params.route.points[ii+1].y   			= _ptsR[ii].y
				Mission.params.route.points[ii+1].x   			= _ptsR[ii].x
				Mission.params.route.points[ii+1].alt   		= _ptsR[ii].alt
				Mission.params.route.points[ii+1].alt_type  	= "BARO"
				Mission.params.route.points[ii+1].speed  	 	= 138.8888888888
				Mission.params.route.points[ii+1].speed_locked 	= true
				Mission.params.route.points[ii+1].ETA  			= 0
				Mission.params.route.points[ii+1].ETA_locked 	= false
				Mission.params.route.points[ii+1].name  		= "PT2"
				Mission.params.route.points[ii+1].task   		= EngageTargetTask
			
			end
			Mission.params.route.points[2].task   									= ComboTaskRandomWaypoint
			Mission.params.route.points[#Mission.params.route.points].task   		= ComboTaskSwitchWaypoint				
		
			SpawnGroup:SetTask(Mission)
			--MESSAGE:New("THERE!", 100 ):ToAll()	
		end)
			

local redDefenseScheduler = SCHEDULER:New( nil, 
	function(spawnGroup)	
		-- Remove Dead / Landed Patrols:		
		for groupName,meh in pairs(_state.AI_aircraftGroupsRED) do
			local g = GROUP:FindByName(groupName)				
			if g==nil then
				g:Destroy()				
				_state.AI_aircraftGroupsRED[g:GetName()] = nil
			else
				local vel = g:GetMaxVelocity()
				if vel==nil then 
					vel = 0
				end
				if vel<1 then
					g:Destroy()				
					_state.AI_aircraftGroupsRED[g:GetName()] = nil
				end
			end			
		end
	
		--Lets Say we choose to spawn an AI Group to patrol front line

		if tableLength(_state.AI_aircraftGroupsRED) < 2 then		
			altitude = 2000
			local wp0_r = ZONE:New("WP0_R"):GetRandomVec2()
			local wp1_r = ZONE:New("WP1_R"):GetRandomVec2()
			local wp2_r = ZONE:New("WP2_R"):GetRandomVec2()
			local wp3_r = ZONE:New("WP3_R"):GetRandomVec2()
			
			_ptsR = {}
			_ptsR[1] = {}
			_ptsR[1].x 	= wp0_r.x
			_ptsR[1].y 	= wp0_r.y
			_ptsR[1].alt = altitude		
			
			_ptsR[2] = {}
			_ptsR[2].x 	= wp1_r.x
			_ptsR[2].y 	= wp1_r.y - 1000
			_ptsR[2].alt = altitude
			
			_ptsR[3] = {}
			_ptsR[3].x 	= wp1_r.x
			_ptsR[3].y 	= wp1_r.y + 1000
			_ptsR[3].alt = altitude
			
			_ptsR[4] = {}
			_ptsR[4].x 	= wp2_r.x
			_ptsR[4].y 	= wp2_r.y
			_ptsR[4].alt = altitude
			
			_ptsR[5] = {}
			_ptsR[5].x 	= wp3_r.x 
			_ptsR[5].y 	= wp3_r.y + 1000
			_ptsR[5].alt = altitude 
			
			_ptsR[6] = {}
			_ptsR[6].x 	= wp3_r.x
			_ptsR[6].y 	= wp3_r.y - 1000
			_ptsR[6].alt = altitude
			
			_ptsR[7] = {}
			_ptsR[7].x 	= wp2_r.x
			_ptsR[7].y 	= wp2_r.y
			_ptsR[7].alt = altitude
						
			g = spawnGroup:Spawn()
			--_state.AI_aircraftGroupsRED[#_state.AI_aircraftGroupsRED+1] = g:GetName()					
			_state.AI_aircraftGroupsRED[g:GetName()] = "Alive"
			--MESSAGE:New("TEST!@# = "..g:GetName()..":".. tableLength(_state.AI_aircraftGroupsRED), 100 ):ToAll()	
			--print_r(_state.AI_aircraftGroupsRED)
		end
		
	end, {sgRed2}, 1, 300
)	



-- ADJUST DISTANCES TO MAKE MORE DEFENSIVE BUSINESS
sgBlue2 = SPAWN:New( "Blue2" )
	:InitLimit( 100,100 )
	:OnSpawnGroup(
		function( SpawnGroup )					
			--MESSAGE:New("FIRED!", 100 ):ToAll()						
			local tt = {}
			tt[1] = "Air"
			EngageTargetTask ={ 
			  id = 'EngageTargets', 
			  params = { 
				maxDist = 4000,
				maxDistEnabled = true,
				targetTypes = tt,
				priority = 100 
			  } 
			}
			--print_r(EngageTargetTask)
			ComboTaskEmpty = { 
			   id = 'ComboTask', 
			   params = { 
				 tasks = {        
				 } 
			   } 
			 }
			SwitchWaypointCommand = { 
			   id = 'SwitchWaypoint', 
			   params = { 
				 fromWaypointIndex = 8,  
				 goToWaypointIndex = 3, 
			   } 
			}
			SwitchWaypointTask = {
			 id = 'WrappedAction', 
			   params = { 
				 action = SwitchWaypointCommand 
			   }
			}					 				
			
			ComboTaskSwitchWaypoint = { 
			   id = 'ComboTask', 
			   params = { 
				 tasks = {    
				   [1] = SwitchWaypointTask,      
				 } 
			   } 
			}
			
			randomInt = math.random(3,#_ptsB+1)	
			RandomWaypointCommand = { 
			   id = 'SwitchWaypoint', 
			   params = { 
				 fromWaypointIndex = 2,  
				 goToWaypointIndex = randomInt, 
			   } 
			}
				RandomWaypointTask = {
			 id = 'WrappedAction', 
			   params = { 
				 action = RandomWaypointCommand 
			   }
			}					 				
			
			ComboTaskRandomWaypoint = { 
			   id = 'ComboTask', 
			   params = { 
				 tasks = {    
				   [1] = RandomWaypointTask,      
				 } 
			   } 
			}
				
			local Mission = {}
			Mission.id = 'Mission'
			Mission.params = {}
			Mission.params.route  = {}
			Mission.params.route.points = {}
			Mission.params.route.points[1] = {}
			Mission.params.route.points[1].type   		= "TakeOff"
			Mission.params.route.points[1].airdromeId  = 17
			Mission.params.route.points[1].action   	= "From Runway"
			Mission.params.route.points[1].y   		= -41988.894540288
			Mission.params.route.points[1].x   		= -26506.125038148 
			Mission.params.route.points[1].alt   		= 32
			Mission.params.route.points[1].alt_type  	= "BARO"
			Mission.params.route.points[1].speed  	 	= 138.88888
			Mission.params.route.points[1].speed_locked = true
			Mission.params.route.points[1].ETA  		= 0
			Mission.params.route.points[1].ETA_locked 	= true
			Mission.params.route.points[1].name  		= "PT1"
			Mission.params.route.points[1].task   		= EngageTargetTask 
					
			for ii = 1, #_ptsB do
				Mission.params.route.points[ii+1] = {}
				Mission.params.route.points[ii+1].type   		= "Turning Point"
				Mission.params.route.points[ii+1].airdromeId  	= 17
				Mission.params.route.points[ii+1].action   		= "Turning Point"
				Mission.params.route.points[ii+1].y   			= _ptsB[ii].y
				Mission.params.route.points[ii+1].x   			= _ptsB[ii].x
				Mission.params.route.points[ii+1].alt   		= _ptsB[ii].alt
				Mission.params.route.points[ii+1].alt_type  	= "BARO"
				Mission.params.route.points[ii+1].speed  	 	= 138.8888888888
				Mission.params.route.points[ii+1].speed_locked 	= true
				Mission.params.route.points[ii+1].ETA  			= 0
				Mission.params.route.points[ii+1].ETA_locked 	= false
				Mission.params.route.points[ii+1].name  		= "PT2"
				Mission.params.route.points[ii+1].task   		= EngageTargetTask
			
			end
			Mission.params.route.points[2].task   									= ComboTaskRandomWaypoint
			Mission.params.route.points[#Mission.params.route.points].task   		= ComboTaskSwitchWaypoint				
		
			SpawnGroup:SetTask(Mission)
			--MESSAGE:New("THERE!", 100 ):ToAll()	
		end)
			

local blueDefenseScheduler = SCHEDULER:New( nil, 
	function(spawnGroup)	
		-- Remove Dead / Landed Patrols:		
		for groupName,meh in pairs(_state.AI_aircraftGroupsBLUE) do
			local g = GROUP:FindByName(groupName)			
			if g==nil then
				g:Destroy()				
				_state.AI_aircraftGroupsBLUE[g:GetName()] = nil
			else
				local vel = g:GetMaxVelocity()
				if vel==nil then 
					vel = 0
				end
				if vel<1 then
					g:Destroy()				
					_state.AI_aircraftGroupsRED[g:GetName()] = nil
				end
			end		
		end
	
		--Lets Say we choose to spawn an AI Group to patrol front line

		if tableLength(_state.AI_aircraftGroupsBLUE) < 2 then		
			altitude = 2000
			local wp0_b = ZONE:New("WP0_B"):GetRandomVec2()
			local wp1_b = ZONE:New("WP1_B"):GetRandomVec2()
			local wp2_b = ZONE:New("WP2_B"):GetRandomVec2()
			local wp3_b = ZONE:New("WP3_B"):GetRandomVec2()
			
			_ptsB = {}
			_ptsB[1] = {}
			_ptsB[1].x 	= wp0_b.x
			_ptsB[1].y 	= wp0_b.y
			_ptsB[1].alt = altitude		
			
			_ptsB[2] = {}
			_ptsB[2].x 	= wp1_b.x
			_ptsB[2].y 	= wp1_b.y - 1000
			_ptsB[2].alt = altitude
			
			_ptsB[3] = {}
			_ptsB[3].x 	= wp1_b.x
			_ptsB[3].y 	= wp1_b.y + 1000
			_ptsB[3].alt = altitude
			
			_ptsB[4] = {}
			_ptsB[4].x 	= wp2_b.x
			_ptsB[4].y 	= wp2_b.y
			_ptsB[4].alt = altitude
			
			_ptsB[5] = {}
			_ptsB[5].x 	= wp3_b.x 
			_ptsB[5].y 	= wp3_b.y + 1000
			_ptsB[5].alt = altitude 
			
			_ptsB[6] = {}
			_ptsB[6].x 	= wp3_b.x
			_ptsB[6].y 	= wp3_b.y - 1000
			_ptsB[6].alt = altitude
			
			_ptsB[7] = {}
			_ptsB[7].x 	= wp2_b.x
			_ptsB[7].y 	= wp2_b.y
			_ptsB[7].alt = altitude
						
			g = spawnGroup:Spawn()
			--_state.AI_aircraftGroupsRED[#_state.AI_aircraftGroupsRED+1] = g:GetName()					
			_state.AI_aircraftGroupsBLUE[g:GetName()] = "Alive"
			--MESSAGE:New("TEST!@# = "..g:GetName()..":".. tableLength(_state.AI_aircraftGroupsRED), 100 ):ToAll()	
			--print_r(_state.AI_aircraftGroupsRED)
		end
		
	end, {sgBlue2}, 1, 300
)	
--[[	
	
local myScheduler = SCHEDULER:New( nil, 
	function()	
		MESSAGE:New("FIRED!", 100 ):ToAll()	


		EngageTargetTask ={ 
		  id = 'EngageTargets', 
		  params = { 
			maxDist = 2000,
			targetTypes = "Planes", 
			priority = 100 
		  } 
		}

		SwitchWaypointCommand = { 
		   id = 'SwitchWaypoint', 
		   params = { 
			 fromWaypointIndex = 3,  
			 goToWaypointIndex = 2, 
		   } 
		 }

		SwitchWaypointTask = {
		 id = 'WrappedAction', 
		   params = { 
			 action = SwitchWaypointCommand 
		   }
		 }
		 
		 
		ComboTaskEmpty = { 
		   id = 'ComboTask', 
		   params = { 
			 tasks = {        
			 } 
		   } 
		 }

		ComboTask = { 
		   id = 'ComboTask', 
		   params = { 
			 tasks = {    
			   [1] = SwitchWaypointTask,      
			 } 
		   } 
		 }

			local Mission = {}
			Mission.id = 'Mission'
			Mission.params = {}
			Mission.params.route  = {}
			Mission.params.route.points = {}
			Mission.params.route.points[1] = {}
			Mission.params.route.points[1].type   		= "TakeOff"
			Mission.params.route.points[1].airdromeId  = 3
			Mission.params.route.points[1].action   	= "From Runway"
			Mission.params.route.points[1].y   		= -77791.164063
			Mission.params.route.points[1].x   		= -18675.582031 
			Mission.params.route.points[1].alt   		= 29
			Mission.params.route.points[1].alt_type  	= "BARO"
			Mission.params.route.points[1].speed  	 	= 138.88888
			Mission.params.route.points[1].speed_locked = true
			Mission.params.route.points[1].ETA  		= 0
			Mission.params.route.points[1].ETA_locked 	= true
			Mission.params.route.points[1].name  		= "PT1"
			Mission.params.route.points[1].task   		= EngageTargetTask 

			Mission.params.route.points[2] = {}
			Mission.params.route.points[2].type   		= "Turning Point"
			Mission.params.route.points[2].airdromeId  = 3
			Mission.params.route.points[2].action   	= "Turning Point"
			Mission.params.route.points[2].y   		= -80364.0657
			Mission.params.route.points[2].x   		= -11865.93
		
			Mission.params.route.points[2].alt_type  	= "BARO"
			Mission.params.route.points[2].speed  	 	= 138.8888888888
			Mission.params.route.points[2].speed_locked = true
			Mission.params.route.points[2].ETA  		= 0
			Mission.params.route.points[2].ETA_locked 	= false
			Mission.params.route.points[2].name  		= "PT2"
			Mission.params.route.points[2].task   		= ComboTaskEmpty

			Mission.params.route.points[3] = {}
			Mission.params.route.points[3].type   		= "Turning Point"
			Mission.params.route.points[3].airdromeId  = 3
			Mission.params.route.points[3].action   	= "Turning Point"
			Mission.params.route.points[3].y   		= -72186.497142855
			Mission.params.route.points[3].x   		= -9100.8597142878
			Mission.params.route.points[3].alt_type  	= "BARO"
			Mission.params.route.points[3].speed  	 	= 138.8888888888
			Mission.params.route.points[3].speed_locked = true
			Mission.params.route.points[3].ETA  		= 0
			Mission.params.route.points[3].ETA_locked 	= false
			Mission.params.route.points[3].name  		= "PT3"
			Mission.params.route.points[3].task   		= ComboTask

			--local g2 = GROUP:FindByName("Plane2")
			--g2:SetTask(Mission)
			MESSAGE:New("THERE!", 100 ):ToAll()	
			
		end, {}, 555
)










local Mission = {}
					Mission.id = 'Mission'
					Mission.params = {}
					Mission.params.route  = {}
					Mission.params.route.points = {}
					Mission.params.route.points[1] = {}
					Mission.params.route.points[1].type   		= "TakeOff"
					Mission.params.route.points[1].airdromeId  = 3
					Mission.params.route.points[1].action   	= "From Runway"
					Mission.params.route.points[1].y   		= -77791.164063
					Mission.params.route.points[1].x   		= -18675.582031 
					Mission.params.route.points[1].alt   		= 29
					Mission.params.route.points[1].alt_type  	= "BARO"
					Mission.params.route.points[1].speed  	 	= 138.88888
					Mission.params.route.points[1].speed_locked = true
					Mission.params.route.points[1].ETA  		= 0
					Mission.params.route.points[1].ETA_locked 	= true
					Mission.params.route.points[1].name  		= "PT1"
					Mission.params.route.points[1].task   		= EngageTargetTask 
																
					-- WP0
					Mission.params.route.points[2] = {}
					Mission.params.route.points[2].type   		= "Turning Point"
					Mission.params.route.points[2].airdromeId  = 3
					Mission.params.route.points[2].action   	= "Turning Point"
					Mission.params.route.points[2].y   		= -80364.0657
					Mission.params.route.points[2].x   		= -11865.93
					Mission.params.route.points[2].alt   		= 1000
					Mission.params.route.points[2].alt_type  	= "BARO"
					Mission.params.route.points[2].speed  	 	= 138.8888888888
					Mission.params.route.points[2].speed_locked = true
					Mission.params.route.points[2].ETA  		= 0
					Mission.params.route.points[2].ETA_locked 	= false
					Mission.params.route.points[2].name  		= "PT2"
					Mission.params.route.points[2].task   		= ComboTaskEmpty
					
					-- WP1-3
					Mission.params.route.points[3] = {}
					Mission.params.route.points[3].type   		= "Turning Point"
					Mission.params.route.points[3].airdromeId  = 3
					Mission.params.route.points[3].action   	= "Turning Point"
					Mission.params.route.points[3].y   		= -72186.497142855
					Mission.params.route.points[3].x   		= -9100.8597142878
					Mission.params.route.points[3].alt_type  	= "BARO"
					Mission.params.route.points[3].speed  	 	= 138.8888888888
					Mission.params.route.points[3].speed_locked = true
					Mission.params.route.points[3].ETA  		= 0
					Mission.params.route.points[3].ETA_locked 	= false
					Mission.params.route.points[3].name  		= "PT3"
					Mission.params.route.points[3].task   		= ComboTask
				
					SpawnGroup:SetTask(Mission)
					MESSAGE:New("THERE!", 100 ):ToAll()	








]]--
	
--[[ 




route  = {}
route.points = {}
route.points[1] = {}
route.points[1].type   		= "TakeOff"
route.points[1].airdromeId  = 3
route.points[1].action   	= "From Runway"
route.points[1].y   		= -77791.164063
route.points[1].x   		= -18675.582031 
route.points[1].alt   		= 29
route.points[1].alt_type  	= "BARO"
route.points[1].speed  	 	= 138.88888
route.points[1].speed_locked = true
route.points[1].ETA  		= 0
route.points[1].ETA_locked 	= true
route.points[1].name  		= "PT1"
route.points[1].task   		= EngageTargetTask 

route.points[2] = {}
route.points[2].type   		= "Turning Point"
route.points[2].airdromeId  = 3
route.points[2].action   	= "Turning Point"
route.points[2].y   		= -80364.0657
route.points[2].x   		= -11865.93
route.points[2].alt_type  	= "BARO"
route.points[2].speed  	 	= 138.8888888888
route.points[2].speed_locked = true
route.points[2].ETA  		= 0
route.points[2].ETA_locked 	= false
route.points[2].name  		= "PT2"
route.points[2].task   		= ComboTaskEmpty

route.points[3] = {}
route.points[3].type   		= "Turning Point"
route.points[3].airdromeId  = 3
route.points[3].action   	= "Turning Point"
route.points[3].y   		= -72186.497142855
route.points[3].x   		= -9100.8597142878
route.points[3].alt_type  	= "BARO"
route.points[3].speed  	 	= 138.8888888888
route.points[3].speed_locked = true
route.points[3].ETA  		= 0
route.points[3].ETA_locked 	= false
route.points[3].name  		= "PT3"
route.points[3].task   		= ComboTask


print_r(route)

local g2 = GROUP:FindByName("Plane2")
g2:SetTask(Mission)
--]]

--[[
--AI CAP
GroupPolygonR = GROUP:FindByName( "Patrol Zone R" )
GroupPolygonB = GROUP:FindByName( "Patrol Zone B" )

PatrolZoneR = ZONE_POLYGON:New( "Patrol Zone R", GroupPolygonR )
PatrolZoneB = ZONE_POLYGON:New( "Patrol Zone B", GroupPolygonB )

PatrolZoneR:SmokeZone(SMOKECOLOR.Red, 20)
PatrolZoneB:SmokeZone(SMOKECOLOR.Blue, 20)

EngageRange = 1000

sgRF = {}
sgRF[1] = SPAWN:New( "RF1" ):InitLimit(1,2):InitRepeatOnLanding()
sgRF[2] = SPAWN:New( "RF2" ):InitLimit(1,2):InitRepeatOnLanding()
sgRF[3] = SPAWN:New( "RF3" ):InitLimit(1,2):InitRepeatOnLanding()

sgBF = {}
sgBF[1] = SPAWN:New( "BF1" ):InitLimit(1,2):InitRepeatOnLanding()
sgBF[2] = SPAWN:New( "BF2" ):InitLimit(1,2):InitRepeatOnLanding()
sgBF[3] = SPAWN:New( "BF3" ):InitLimit(1,2):InitRepeatOnLanding()



--_state.AI_aircraftGroupsRED 	= {"RF1", "RF2", "RF3"}
--_state.AI_aircraftGroupsBLUE 	= {"BF1", "BF2", "BF3"}

local aiManager = SCHEDULER:New( nil, 
	function(sgRF, sgBF, PatrolZoneR, PatrolZoneB)				
		MESSAGE:New("SpawnFighterDefense", 20 ):ToAll()		
		for ii=1,#sgRF do
			g = GROUP:FindByName(_state.AI_aircraftGroupsRED[ii])
			local spawnRed = false
			if g==nil then							
				spawnRed = true	
			elseif g:GetUnit(1)==nil	then			
				spawnRed = true
			elseif g:InAir()==false and g:GetFuel()<0.95 then 
				MESSAGE:New("FUEL REMAINING = "..g:GetFuel(), 20):ToAll()
				--g:Destroy()
				spawnRed = true			
			end
			if g~=nil then
				MESSAGE:New("LIFE REMAINING (R)= "..g:GetUnit(1):GetLife(), 20):ToAll()
			end
			if spawnRed then			
				local randomInt = math.random(100)
				if randomInt<=100 then
					MESSAGE:New("HERE (R) ", 20):ToAll()
					CapGroup = sgRF[ii]:Spawn()
					AICapZone = AI_CAP_ZONE:New( PatrolZoneR, 500, 1000, 500, 600 )
					AICapZone:SetControllable( CapGroup )
					AICapZone:SetEngageRange( 5000 ) 
					AICapZone:__Start( 1 )
					_state.AI_aircraftGroupsRED[ii] = CapGroup:GetName()	
				end
			end			
		end
		for ii=1,#sgBF do
			g = GROUP:FindByName(_state.AI_aircraftGroupsBLUE[ii])
			local spawnBlue = false
			if g==nil then							
				spawnBlue = true	
			elseif g:GetUnit(1)==nil	then			
				spawnBlue = true				
			elseif g:InAir()==false and g:GetFuel()<0.65 then 
				MESSAGE:New("FUEL REMAINING (B) = "..g:GetFuel(), 20):ToAll()
				--g:Destroy()
				spawnBlue = true			
			end
			if g~=nil then
				MESSAGE:New("LIFE REMAINING (B)= "..g:GetUnit(1):GetLife(), 20):ToAll()
			end
			if spawnBlue then			
				local randomInt = math.random(100)
				if randomInt<=100 then
					MESSAGE:New("HERE (B) ", 20):ToAll()
					CapGroup = sgBF[ii]:Spawn()
					AICapZone = AI_CAP_ZONE:New( PatrolZoneB, 500, 1000, 500, 600 )
					AICapZone:SetControllable( CapGroup )
					AICapZone:SetEngageRange( 5000 ) 
					AICapZone:__Start( 1 )
					_state.AI_aircraftGroupsBLUE[ii] = CapGroup:GetName()	
				end
			end
			
		end
		
	end, {sgRF, sgBF, PatrolZoneR, PatrolZoneB}, 0, 30
)




CapSpawn = SPAWN:New( "RF1" ):InitLimit(1,2):InitRepeatOnLanding()
CapGroup = CapSpawn:Spawn()
AICapZone = AI_CAP_ZONE:New( PatrolZoneR, 500, 1000, 500, 600 )
AICapZone:SetControllable( CapGroup )
AICapZone:SetEngageRange( EngageRange ) 
AICapZone:__Start( 1 )

CapSpawn = SPAWN:New( "RF2" ):InitLimit(1,2):InitRepeatOnLanding()
CapGroup = CapSpawn:Spawn()
AICapZone = AI_CAP_ZONE:New( PatrolZoneR, 500, 1000, 500, 600 )
AICapZone:SetControllable( CapGroup )
AICapZone:SetEngageRange( EngageRange ) 
AICapZone:__Start( 1 )

CapSpawn = SPAWN:New( "RF3" ):InitLimit(1,2):InitRepeatOnLanding()
CapGroup = CapSpawn:Spawn()
AICapZone = AI_CAP_ZONE:New( PatrolZoneR, 500, 1000, 500, 600 )
AICapZone:SetControllable( CapGroup )
AICapZone:SetEngageRange( EngageRange ) 
AICapZone:__Start( 1 )


CapSpawn = SPAWN:New( "BF1" ):InitLimit(1,2):InitRepeatOnLanding()
CapGroup = CapSpawn:Spawn()
AICapZone = AI_CAP_ZONE:New( PatrolZoneB, 500, 1000, 500, 600 )
AICapZone:SetControllable( CapGroup )
AICapZone:SetEngageRange( EngageRange ) 
AICapZone:__Start( 1 )

CapSpawn = SPAWN:New( "BF2" ):InitLimit(1,2):InitRepeatOnLanding()
CapGroup = CapSpawn:Spawn()
AICapZone = AI_CAP_ZONE:New( PatrolZoneB, 500, 1000, 500, 600 )
AICapZone:SetControllable( CapGroup )
AICapZone:SetEngageRange( EngageRange ) 
AICapZone:__Start( 1 )

CapSpawn = SPAWN:New( "BF3" ):InitLimit(1,2):InitRepeatOnLanding()
CapGroup = CapSpawn:Spawn()
AICapZone = AI_CAP_ZONE:New( PatrolZoneB, 500, 1000, 500, 600 )
AICapZone:SetControllable( CapGroup )
AICapZone:SetEngageRange( EngageRange ) 
AICapZone:__Start( 1 )
]]--
