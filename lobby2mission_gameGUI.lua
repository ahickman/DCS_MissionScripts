net.log("LOADING Lobby2Mission")

local server = {}
local prevExecTime = -1
local pauseEndTime = 0
local matchStartTime = 0
local teamLockTime = 0

--_forceToSpectators = {}
_forceToSpectatorsPlayerID 	= {}
_forceToSpectatorsSide 		= {}
_forceToSpectatorsSlot 		= {}
_forceToSpectatorsTime 		= {}

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

server.auxEnabled = function()
    local _aux = server.getFlagValue("AUX_ENABLED")
    return _aux == 1
end

function server.onSimulationStart()
    execLoop = true
    DCS.setPause(false)		
end

function server.onSimulationStop()
    execLoop = false
end

function server.onSimulationFrame()
	if execLoop and server.auxEnabled() then 
		local curExecTime = os.clock()		
					
		if math.abs(curExecTime - prevExecTime) >= 1 then --do every second
			prevExecTime = curExecTime						
			net.log("T="..curExecTime)
			local gameState = server.getFlagValue("GAME_STATE")
			-- IDLE / Match Complete
			if gameState==1 then				
				-- All Pilots
				net.dostring_in('server', " trigger.action.outText(\"INITIATE match using the F10 Radio Menu\\n(".. 1 .." pilots queued)\", 2.5, true)")									
			end

			 -- Countdown to Team Lock
			if gameState==2 then
				-- All Pilots
				local tRem = math.floor(teamLockTime-curExecTime)
				net.dostring_in('server', " trigger.action.outText(\"MATCH Starts in ".. tRem .."\\nAfter timer expires, pilots are moved to mission slots (AUTOMATIC)\", 2.5, true)")												
			end

			 -- Countdown to Match Start (paused)
			if gameState==3 then
				-- All Pilots (not in cockpit)
				local tRem = math.floor(matchStartTime-curExecTime)
				if tRem<0 then
					tRem = 0
				end
				net.dostring_in('server', " trigger.action.outText(\"LAUNCH in ".. tRem .."\\nEnter cockpit before LAUNCH:\\nOPEN 'Select Role' but *do not* select a new role\\nCLICK 'Briefing'\\nCLICK 'Fly'\", 2.5, true)")									
				--Pilots who are in cockpit
				--net.dostring_in('server', " trigger.action.outText(\"> Match Starts in ".. 1 .."\\n> *READY*\", 1.5, true)")									
			end

			-- Match In Progress
			if gameState==4 then
				--FORMATION SLOTS ONLY			
				local tRem = math.floor(curExecTime - matchStartTime)
				local mm = math.floor(tRem/60)
				local ss = tRem-60*mm
				net.dostring_in('server', " trigger.action.outText(\"MATCH IN PROGRESS: +"..string.format("%02d", mm)..":"..string.format("%02d", ss).."\\nPractice intstructions (etc)\", 2.5, true)")									
			end
			
			-- Forces Killed players to spectators after a delay
			for i,playerID in ipairs(_forceToSpectatorsPlayerID) do 													
				local side 		= _forceToSpectatorsSide[playerID]
				local slot 		= _forceToSpectatorsSlot[playerID]
				local tMove 	= _forceToSpectatorsTime[playerID]
				net.log("forceToSpectators="..playerID.. "." ..side..","..slot..","..tMove)
				local playerDetails = net.get_player_info(playerID)				
				if playerDetails ~=nil and playerDetails.side == side and playerDetails.slot == slot and curExecTime >= tMove then		
					net.force_player_slot(playerID, 0, '')
				end
			end
		end					

		-- Handle Remote Pauses
		-- TODO - Customize Countdown Text

		local pauseDuration = server.getFlagValue("PAUSE")
		if pauseDuration>0 then
			pauseEndTime = curExecTime + pauseDuration
			net.dostring_in('server', "  trigger.action.setUserFlag(\"PAUSE\",0) ")
		end

		if (pauseEndTime>=curExecTime) then										
			DCS.setPause(true)	
			local tRem = math.floor(pauseEndTime-curExecTime)
			--net.dostring_in('server', " trigger.action.outText(\""..tRem.." seconds to mission start\\n\\nHQ: Instructions to spawn: Open 'Select Role', Click 'Briefing', Click 'Fly'\", 0.5, true)")
			_forceToSpectatorsPlayerID 	= {}
			_forceToSpectatorsSide 		= {}
			_forceToSpectatorsSlot 		= {}
			_forceToSpectatorsTime 		= {}
		else
			DCS.setPause(false)
			pauseEndTime = 0			
		end
		
		local startLockTeamTimer = server.getFlagValue("START_LOCK_TEAM_TIMER")		
		if startLockTeamTimer==1 then		
			-- Initialize times for current round			
			local timeToLockTeams 		= server.getFlagValue("TIME_TO_LOCK_TEAMS")
			local timeToEnterCockpit 	= server.getFlagValue("TIME_TO_ENTER_COCKPIT")		
			teamLockTime 				= curExecTime+timeToLockTeams 
			matchStartTime 				= curExecTime+timeToLockTeams +timeToEnterCockpit 			
			net.dostring_in('server', "  trigger.action.setUserFlag(\"START_LOCK_TEAM_TIMER\",0) ")
		end

		local moveBlueToMission = server.getFlagValue("MOVE_BLUE_TO_MISSION")		
		if moveBlueToMission>0 then				    		
			-- force move from pool to mission slots
			local _playerList = net.get_player_list()	
			for i,v in ipairs(_playerList) do 										
				local side   = net.get_player_info(v, "side")
				local slotID = net.get_player_info(v, "slot")				
				--net.log("side:"..side.."  slotID:"..slotID)
				if slot~='' and side==2 then
					local groupName = server.slot2Group(side, slotID)				
					local groupPrefix = 0

					if     string.find(groupName,"Alpha 1")   	then groupPrefix = 01
					elseif string.find(groupName,"Alpha 1")   	then groupPrefix = 02
					elseif string.find(groupName,"Alpha 1")   	then groupPrefix = 03
					elseif string.find(groupName,"Alpha 1")   	then groupPrefix = 04
					elseif string.find(groupName,"Bravo 1")   	then groupPrefix = 05
					elseif string.find(groupName,"Bravo 2")   	then groupPrefix = 06
					elseif string.find(groupName,"Bravo 3")   	then groupPrefix = 07
					elseif string.find(groupName,"Bravo 4")   	then groupPrefix = 08
					elseif string.find(groupName,"Charlie 1") 	then groupPrefix = 09
					elseif string.find(groupName,"Charlie 2") 	then groupPrefix = 10
					elseif string.find(groupName,"Charlie 3") 	then groupPrefix = 11
					elseif string.find(groupName,"Charlie 4") 	then groupPrefix = 12
					elseif string.find(groupName,"Delta 1")   	then groupPrefix = 13
					elseif string.find(groupName,"Delta 2")   	then groupPrefix = 14
					elseif string.find(groupName,"Delta 3")   	then groupPrefix = 15
					elseif string.find(groupName,"Delta 4")   	then groupPrefix = 16
					elseif string.find(groupName,"Anton 1")   	then groupPrefix = 01
					elseif string.find(groupName,"Anton 1")   	then groupPrefix = 02
					elseif string.find(groupName,"Anton 1")   	then groupPrefix = 03
					elseif string.find(groupName,"Anton 1")   	then groupPrefix = 04
					elseif string.find(groupName,"Berta 1")   	then groupPrefix = 05
					elseif string.find(groupName,"Berta 2")   	then groupPrefix = 06
					elseif string.find(groupName,"Berta 3")   	then groupPrefix = 07
					elseif string.find(groupName,"Berta 4")   	then groupPrefix = 08
					elseif string.find(groupName,"Charlotte 1") then groupPrefix = 09
					elseif string.find(groupName,"Charlotte 2") then groupPrefix = 10
					elseif string.find(groupName,"Charlotte 3") then groupPrefix = 11
					elseif string.find(groupName,"Charlotte 4") then groupPrefix = 12
					elseif string.find(groupName,"Dora 1")   	then groupPrefix = 13
					elseif string.find(groupName,"Dora 2")   	then groupPrefix = 14
					elseif string.find(groupName,"Dora 3")   	then groupPrefix = 15
					elseif string.find(groupName,"Dora 4")   	then groupPrefix = 16					
					end

					--local groupPrefix = string.sub(groupName, 1,2)
					local missionGroupName = "z"..moveBlueToMission..groupPrefix					
					local newSlotId = server.group2Slot(side, missionGroupName)

					if newSlotId~=nil then
						net.force_player_slot(v, side, newSlotId)							
					else
						net.force_player_slot(v, 0, '')							
					end
				end
			end
			net.dostring_in('server', "  trigger.action.setUserFlag(\"MOVE_BLUE_TO_MISSION\",0) ")
		end

		local moveRedToMission = server.getFlagValue("MOVE_RED_TO_MISSION")		
		if moveRedToMission>0 then
		    --matchStartTime = curExecTime
			-- force move from pool to mission slots
			local _playerList = net.get_player_list()
			for i,v in ipairs(_playerList) do 										
				local side   = net.get_player_info(v, "side")
				local slotID = net.get_player_info(v, "slot")				
				--net.log("side:"..side.."  slotID:"..slotID)
				if slot~='' and side==1 then
					local groupName = server.slot2Group(side, slotID)				
					local groupPrefix = string.sub(groupName, 1,2)
					local missionGroupName = "z"..moveRedToMission..groupPrefix					
					local newSlotId = server.group2Slot(side, missionGroupName)
					if newSlotId~=nil then
						net.force_player_slot(v, side, newSlotId)							
					else
						net.force_player_slot(v, 0, '')							
					end
				end
			end
			net.dostring_in('server', "  trigger.action.setUserFlag(\"MOVE_RED_TO_MISSION\",0) ")
		end

		local moveAllToSpectators = server.getFlagValue("MOVE_ALL_TO_SPECTATORS")		

		if moveAllToSpectators>0 then	
			_forceToSpectatorsPlayerID 	= {}
			_forceToSpectatorsSide 		= {}
			_forceToSpectatorsSlot 		= {}
			_forceToSpectatorsTime 		= {}
		
			local _playerList = net.get_player_list()
			for i,v in ipairs(_playerList) do 																		
				net.force_player_slot(v, 0, '')																
			end
			net.dostring_in('server', "  trigger.action.setUserFlag(\"MOVE_ALL_TO_SPECTATORS\",0) ")
		end

		local moveMissionToSpectators = server.getFlagValue("MOVE_MISSION_TO_SPECTATORS")		
		if moveMissionToSpectators>0 then	
			_forceToSpectatorsPlayerID 	= {}
			_forceToSpectatorsSide 		= {}
			_forceToSpectatorsSlot 		= {}
			_forceToSpectatorsTime 		= {}
		
			local _playerList = net.get_player_list()
			for i,v in ipairs(_playerList) do 
				-- If in a mission slot move to spectators
				local side = net.get_player_info(v, 'side')
				local slot = net.get_player_info(v, 'slot')
				local gn = server.slot2Group(side, slot)
				if gn~=nil then
					if string.sub(gn,1,1)=="z" then
						net.force_player_slot(v, 0, '')	
					end
				end																	
			end
			net.dostring_in('server', "  trigger.action.setUserFlag(\"MOVE_MISSION_TO_SPECTATORS\",0) ")
		end		
	end
end










-- Fetch groupName given a side+slotID
function server.group2Slot(_side, _groupName)
	local _slotList={}
	if _side==1 then
		_slotList = DCS.getAvailableSlots("red")
	elseif _side==2 then
		_slotList = DCS.getAvailableSlots("blue")
	end

	local i, v = next(_slotList, nil)
	while i do				
		if _slotList[i].groupName == _groupName then			
			return _slotList[i].unitId			
		end				
		i, v = next(_slotList, i)
	end		
	return nil
end

-- Fetch groupName given a side+slotID
function server.slot2Group(_side, _slotID)
	local _slotList={}
	if _side==1 then
		_slotList = DCS.getAvailableSlots("red")
	elseif _side==2 then
		_slotList = DCS.getAvailableSlots("blue")
	end
	local i, v = next(_slotList, nil)
	while i do				
		if _slotList[i].unitId == _slotID then			
			return _slotList[i].groupName			
		end				
		i, v = next(_slotList, i)
	end		
	return nil
end

-- Check slot names against flags to determine block status
server.onPlayerTryChangeSlot = function(playerID, side, slotID)
    if  DCS.isServer() and DCS.isMultiplayer() and server.auxEnabled() then
        if  (side ~=0 and  slotID ~='' and slotID ~= nil)  then			
			local _slotList = {}
			if side==1 then
				_slotList = DCS.getAvailableSlots("red")
			else
				_slotList = DCS.getAvailableSlots("blue")
			end
			local i, v = next(_slotList, nil)
			while i do			
				if _slotList[i].unitId == slotID then
					local _val = server.getFlagValue(_slotList[i].groupName)			
					return _val==1
				end				
				i, v = next(_slotList, i)
			end
        end
    end
    return false
end

server.onGameEvent = function(eventName,playerID,arg2,arg3,arg4) -- This means if a slot is disabled while the player is flying, they'll be removed	
    if DCS.isServer() and DCS.isMultiplayer() and not DCS.getPause() then
        if DCS.getModelTime() > 1 and  server.auxEnabled() then  -- must check this to prevent a possible CTD by using a_do_script before the game is ready to use a_do_script. -- Source GRIMES :)			
            if eventName == "self_kill"
                    or eventName == "crash"
                    or eventName == "eject"
                    or eventName ==  "pilot_death" then
                -- is player still in a valid slot
                local _playerDetails = net.get_player_info(playerID)			

                if _playerDetails ~=nil and _playerDetails.side ~= 0 and _playerDetails.slot ~= "" and _playerDetails.slot ~= nil then
                    local _unitRole = DCS.getUnitType(_playerDetails.slot)					
                    if _unitRole ~= nil and
                            (_unitRole == "forward_observer"
                                    or _unitRole == "instructor"
                                    or _unitRole == "artillery_commander"
                                    or _unitRole == "observer")
                    then
                        return true
                    end

					local gn = server.slot2Group(_playerDetails.side, _playerDetails.slot)
					if gn~=nil then
						local _allow = server.getFlagValue(gn)==1									
						if not _allow then
							net.log("BOOOOM....wtf? "..playerID)
							--If this slot is blocked (mission slot), forceToSpectator after an X second delay.
							if server.getFlagValue(gn)==0 then
								_forceToSpectatorsPlayerID[playerID] 	= playerID
								_forceToSpectatorsSide[playerID] 		= _playerDetails.side
								_forceToSpectatorsSlot[playerID] 		= _playerDetails.slot
								_forceToSpectatorsTime[playerID] 		= os.clock() + 20

								net.log("IN=>forceToSpectators="..playerID..",".._forceToSpectatorsSide[playerID]..",".._forceToSpectatorsSlot[playerID]..",".._forceToSpectatorsTime[playerID])
								--local idx = #_forceToSpectators 
 								--_forceToSpectators[idx].playerID 	= playerID
								--_forceToSpectators[idx].side 		= _playerDetails.side
								--_forceToSpectators[idx].slot		= _playerDetails.slot
								--_forceToSpectators[idx].time 		= os.clock()+5 --force move after XX seconds
								--net.force_player_slot(playerID, 0, '')
							end
							--net.force_player_slot(playerID, 0, '')
						end
					end
                end
            end
        end
    end
end


DCS.setUserCallbacks(server)
net.log("server callbacks loaded")







