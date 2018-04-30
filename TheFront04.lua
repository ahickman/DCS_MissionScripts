--dofile([[C:\Users\AMH\Saved Games\DCS\MissionScripts\mathHelpers.lua]])
--dofile([[C:\Users\AMH\Saved Games\DCS\MissionScripts\Scenario01\Scenario01.lua]])

-- WIKI for common
-- https://mp3cut.net/    Crop OGG (Download tp MP3)
-- https://convertio.co/wav-converter/ (Convert WAV to OGG)
-- Add sound to UKRAINE in order to include in mission
-- https://en.wikipedia.org/wiki/Snare_drum

function CatTables(a,b)
	for _, v in pairs(b) do
		table.insert(a, v)
	end 
	return a
end

function SecondsToClock(seconds)

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



meDebug = false

_state								= {} -- Reset Round Info State
_state.missionComplete 				= false
_state.premissionDuration 			= 3*60
_state.missionDuration    			= 30*60
_state.postmissionDuration 			= 30
--_state.clockNotificationTimes 		= {0, 30} -- TESTING
_state.clockNotificationTimes 		= {0, 300, 600, 900, 1200, 1500, 1800-120, 1800-60, 1800-30, 1800-10} -- 30 minute mission
_state.RedAirplaneSpawnPct 			= 100
_state.BlueAirplaneSpawnPct 		= 100

_state.BLUEgroups 					= {"Alpha 1", "Alpha 2", "Alpha 3", "Alpha 4", "Bravo 1", "Bravo 2", "Bravo 3", "Bravo 4", "Queen 1", "Queen 3", "Queen 3", "Queen 4", "Winston 1", "Winston 2", "Winston 3", "Winston 4"}
_state.REDgroups 					= {"Anton 1", "Anton 2", "Anton 3", "Anton 4", "Berta 1", "Berta 2", "Berta 3", "Berta 4", "Charlotte 1", "Charlotte 2", "Charlotte 3", "Charlotte 4", "Dora 1", "Dora 2", "Dora 3", "Dora 4"}
_state.ALLgroups 					= CatTables(_state.BLUEgroups,_state.REDgroups)

scenarioIds 		= {1,2,3}
scenarioNames		= {"Goodwood", "AxisThrust", "BeachLanding"}

local tmp = trigger.misc.getUserFlag("ScenarioId")
if tmp > 0 then
	env.info("PREVIOUS MISSION WAS: ")
	env.info(scenarioNames[tmp])	
	scenarioIds[tmp]=nil
	scenarioIds = shuffleTable( scenarioIds )
	scenarioId = scenarioIds[1]
else
	env.info("NO PREVIOUS MISSION")	
	scenarioIds = shuffleTable( scenarioIds )
	scenarioId = scenarioIds[1]
end
--scenarioId 			= 3 -- randomize
scenarioName 		= scenarioNames[scenarioId]
trigger.action.setUserFlag("ScenarioId", scenarioId)

-- Container for storing units that score by reaching a zone
zoneBonusPoints 	= {
	[coalition.side.BLUE] 	= {},
	[coalition.side.RED] 	= {},
}

-- Store bonus points awarded for the destruction of particular units (by coalition)
groupBonusPoints 	= {}
	

--for i, gp in pairs(coalition.getGroups(2)) do
--	env.info(Group.getName(gp))
--end

-- clientData includes basic data for non-static aircraft
clientData = {}
set = SET_GROUP:New():FilterCategories( "plane" ):FilterStart() 
set:ForEachGroup(  
	function( g )  		
		if g~=nil then
			clientData[g:GetName()] = {
				["Coalition"] 	    = g:GetCoalition(),
				["KillsPending"]    = {}, -- GroupName
				["KillsConfirmed"]  = {}, -- GroupName
				["PointsPending"]   = 0, 
				["PointsConfirmed"] = 0, 
			}
		end	
	end  
)
for ii = 1,#_state.BLUEgroups do	
	clientData[_state.BLUEgroups[ii]] = {
		["Coalition"] 	    = coalition.side.BLUE,
		["KillsPending"]    = {}, -- GroupName
		["KillsConfirmed"]  = {}, -- GroupName
		["PointsPending"]   = 0, 
		["PointsConfirmed"] = 0, 
	}
end
for ii = 1,#_state.REDgroups do	
	clientData[_state.REDgroups[ii]] = {
		["Coalition"] 	    = coalition.side.RED,
		["KillsPending"]    = {}, -- GroupName
		["KillsConfirmed"]  = {}, -- GroupName
		["PointsPending"]   = 0, 
		["PointsConfirmed"] = 0, 
	}
end

env.info("ARX >> clientGroup:" )
--print_r(clientData)

_state.airbaseMap = {}
_state.airbaseMap = {
	[5000001] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
    [5000002] = {	["Coalition"] 	= coalition.side.BLUE,    ["DisplayName"] = "Saint Pierre du Mont",},
	[5000003] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000004] = {	["Coalition"] 	= coalition.side.RED, 	  ["DisplayName"] = "Lignerolles",},
	[5000005] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000006] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Cretteville",},
	[5000007] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000008] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000009] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000010] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Brucheville",},
	[5000011] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000012] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Meautis",},
	[5000013] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000014] = {	["Coalition"] 	= coalition.side.BLUE,    ["DisplayName"] = "Cricqueville en Bessin",},
	[5000015] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000016] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000017] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000018] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000019] = {	["Coalition"] 	= coalition.side.BLUE,    ["DisplayName"] = "Sainte Laurent sur Mer",},
	[5000020] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000021] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Biniville",},
	[5000022] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000023] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Cardonville",},
	[5000024] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000025] = {	["Coalition"] 	= coalition.side.BLUE,    ["DisplayName"] = "Deux Jumeaux",},
	[5000026] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000027] = {	["Coalition"] 	= coalition.side.BLUE,    ["DisplayName"] = "Chippelle",},
	[5000028] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000029] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Beuzeville",},
	[5000030] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000031] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Azeville",},
	[5000032] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000033] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Picauville",},
	[5000034] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000035] = {	["Coalition"] 	= coalition.side.BLUE,    ["DisplayName"] = "Le Molay",},
	[5000036] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000037] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Longues sur Mer",},
	[5000038] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000039] = {	["Coalition"] 	= coalition.side.RED, 	  ["DisplayName"] = "Carpiquet",},
	[5000040] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000041] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Bazenville",},
	[5000042] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000043] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Sainte Croix sur Mer",},
	[5000044] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000045] = {	["Coalition"] 	= coalition.side.RED, 	  ["DisplayName"] = "Beny sur Mer",},
	[5000046] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000047] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Rucqueville",},
	[5000048] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000049] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "Sommervieu",},
	[5000050] = {	["Coalition"] 	= coalition.side.NEUTRAL, ["DisplayName"] = "N/A",},
	[5000051] = {	["Coalition"] 	= coalition.side.RED,     ["DisplayName"] = "Lantheuil",},
}
--[[ landed at wide airport - got friendly message
print_r(_state.airbaseMap)
_state.airbaseMap[5000002] = coalition.side.BLUE	-- Saint Pierre du Mont
_state.airbaseMap[5000003] = coalition.side.NEUTRAL
_state.airbaseMap[5000004] = coalition.side.NEUTRAL	-- Lignerolles
_state.airbaseMap[5000005] = coalition.side.NEUTRAL
_state.airbaseMap[5000006] = coalition.side.RED 	-- Cretteville
_state.airbaseMap[5000007] = coalition.side.NEUTRAL
_state.airbaseMap[5000008] = coalition.side.NEUTRAL
_state.airbaseMap[5000009] = coalition.side.NEUTRAL
_state.airbaseMap[5000010] = coalition.side.RED 	-- Brucheville
_state.airbaseMap[5000011] = coalition.side.NEUTRAL
_state.airbaseMap[5000012] = coalition.side.RED 	-- Meautis
_state.airbaseMap[5000013] = coalition.side.NEUTRAL
_state.airbaseMap[5000014] = coalition.side.BLUE	-- Cricqueville-en-Bessin
_state.airbaseMap[5000015] = coalition.side.NEUTRAL
_state.airbaseMap[5000016] = coalition.side.NEUTRAL
_state.airbaseMap[5000017] = coalition.side.NEUTRAL
_state.airbaseMap[5000018] = coalition.side.NEUTRAL
_state.airbaseMap[5000019] = coalition.side.BLUE	-- Sainte-Laurent-sur-Mer
_state.airbaseMap[5000020] = coalition.side.NEUTRAL
_state.airbaseMap[5000021] = coalition.side.RED 	-- Biniville
_state.airbaseMap[5000022] = coalition.side.NEUTRAL
_state.airbaseMap[5000023] = coalition.side.BLUE 	-- Cardonville
_state.airbaseMap[5000024] = coalition.side.NEUTRAL
_state.airbaseMap[5000025] = coalition.side.BLUE	-- Deux Jumeaux
_state.airbaseMap[5000026] = coalition.side.NEUTRAL
_state.airbaseMap[5000027] = coalition.side.BLUE	-- Chippelle
_state.airbaseMap[5000028] = coalition.side.NEUTRAL
_state.airbaseMap[5000029] = coalition.side.RED 	-- Beuzeville
_state.airbaseMap[5000030] = coalition.side.NEUTRAL
_state.airbaseMap[5000031] = coalition.side.RED 	-- Azeville
_state.airbaseMap[5000032] = coalition.side.NEUTRAL
_state.airbaseMap[5000033] = coalition.side.RED	 	-- Picauville
_state.airbaseMap[5000034] = coalition.side.NEUTRAL
_state.airbaseMap[5000035] = coalition.side.BLUE	-- Le Molay
_state.airbaseMap[5000036] = coalition.side.NEUTRAL
_state.airbaseMap[5000037] = coalition.side.NEUTRAL -- Longues-sur-Mer
_state.airbaseMap[5000038] = coalition.side.NEUTRAL
_state.airbaseMap[5000039] = coalition.side.NEUTRAL -- Carpiquet
_state.airbaseMap[5000040] = coalition.side.NEUTRAL
_state.airbaseMap[5000041] = coalition.side.NEUTRAL -- Bazenville
_state.airbaseMap[5000042] = coalition.side.NEUTRAL
_state.airbaseMap[5000043] = coalition.side.NEUTRAL -- Sainte-Croix-sur-Mer
_state.airbaseMap[5000044] = coalition.side.NEUTRAL
_state.airbaseMap[5000045] = coalition.side.NEUTRAL -- Beny-sur-Mer
_state.airbaseMap[5000046] = coalition.side.NEUTRAL
_state.airbaseMap[5000047] = coalition.side.NEUTRAL -- Rucqueville
_state.airbaseMap[5000048] = coalition.side.NEUTRAL
_state.airbaseMap[5000049] = coalition.side.NEUTRAL -- Sommervieu
_state.airbaseMap[5000050] = coalition.side.NEUTRAL
_state.airbaseMap[5000051] = coalition.side.NEUTRAL -- Lantheuil
--]]

-- Target Data contains basic information about targets and special rules
typeData = {
	["Blitz_36-6700A"] = {
		["class"]				= "TRUCK",
		["points"]				= 2
	}, 
	["Bedford_MWD"] = {
		["class"]				= "TRUCK",
		["points"]				= 2
	},
	["Willys_MB"] = {
		["class"]				= "TRUCK",
		["points"]				= 2
	},
	["Tiger_I"] = {
		["class"]				= "HEAVY TANK",
		["points"] 				= 16,		
		["weapons.nurs.HVAR"]	= { 10, 33, 66 },
		["weapons.nurs.WGr21"] 	= { 100 },
	},
	["Pz_IV_H"] = {
		["class"]				= "TANK",
		["points"] 				= 10,		
		["GenericGuns"] 		= {10},   -- 1% chance each hit w/ guns / cannons / etc  Try it out
		["weapons.shells.M2_50_aero_AP"] = {10, 25, 33,66,100},	  --P51D
		["weapons.shells.M20_50_aero_APIT"] = {10, 25, 33,66,100},
		["weapons.shells.MG_13x64_APT"] = {10, 25, 33,66,100},  -- FW190D9
		["weapons.shells.MG_13x64_API"] = {10, 25, 33,66,100},
		["weapons.shells.MG_13x64_HEI"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_API"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_MGsch"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_HEI_T"] = {10, 25, 33,66,100},		
		["weapons.nurs.HVAR"]	= { 0, 100 },
		["weapons.nurs.WGr21"] 	= { 100 },
		--["weapons.bombs.AN_M64"]= { 100 }, 
	},
	
	["M4_Sherman"] = {
		["class"]				= "TANK",
		["points"] 				= 16,
		["weapons.nurs.HVAR"]	= { 66, 100 },
		["weapons.nurs.WGr21"]	= { 100 },
	},
	["USS_Samuel_Chase"] = {
		["class"]				= "SHIP",
		["points"] 				= 18,
		--["newLife0"] 			= 1700,
	},
	["flak38"] = {
		["class"]				= "AAA",
		["points"] 				= 1,
	},
	["SK_C_28_naval_gun"] = {
		["class"]				= "FORIFICATION",
		["points"] 				= 14,
	},
	["soldier_mauser98"] = {
		["class"]				= "AIRPLANE",
		["points"] 				= 3,
		["immortal"] 			= 1,
		["GenericGuns"] 		= {10, 25, 33,66,100},
		["weapons.shells.M2_50_aero_AP"] = {10, 25, 33,66,100},	  --P51D
		["weapons.shells.M20_50_aero_APIT"] = {10, 25, 33,66,100},
		["weapons.shells.MG_13x64_APT"] = {10, 25, 33,66,100},  -- FW190D9
		["weapons.shells.MG_13x64_API"] = {10, 25, 33,66,100},
		["weapons.shells.MG_13x64_HEI"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_API"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_MGsch"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_HEI_T"] = {10, 25, 33,66,100},
		["weapons.nurs.HVAR"]	= {0, 100 },
		["weapons.nurs.WGr21"] 	= {0, 100 },
		["weapons.bombs.AN_M64"]= {0, 100}, 
	},
	["soldier_wwii_us"] = {
		["class"]				= "AIRPLANE",
		["points"] 				= 3,
		["immortal"] 			= 1,
		["GenericGuns"] 		= {10, 25, 33,66,100},
		["weapons.shells.M2_50_aero_AP"] = {10, 25, 33,66,100},	  --P51D
		["weapons.shells.M20_50_aero_APIT"] = {10, 25, 33,66,100},
		["weapons.shells.MG_13x64_APT"] = {10, 25, 33,66,100},  -- FW190D9
		["weapons.shells.MG_13x64_API"] = {10, 25, 33,66,100},
		["weapons.shells.MG_13x64_HEI"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_API"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_MGsch"] = {10, 25, 33,66,100},
		["weapons.shells.MG_20x82_HEI_T"] = {10, 25, 33,66,100},
		
		["weapons.nurs.HVAR"]	= {0, 100 },
		["weapons.nurs.WGr21"] 	= {0, 100 },
		["weapons.bombs.AN_M64"]= {0, 100}, 
	}
}
--print_r(typeData)

-- Remove / Destroy Targets (To achieve a random landscape



-- Current hack for parked aircraft.  DCS does not reliably generate hit events when a multiplayer client attacks a parked aircraft.  Instead, use co-located infantry to register hits/ trigger death events
StaticRedAirplanes = {}
for ii=1,100 do
	local searchString = string.format("StaticRedAirplane #%03.f", ii)
	static = STATIC:FindByName(searchString, false)
	if static~=nil then
		StaticRedAirplanes[#StaticRedAirplanes+1]= static
	end	
end
--print_r(StaticRedAirplanes)

StaticBlueAirplanes = {}
for ii=1,100 do
	local searchString = string.format("StaticBlueAirplane #%03.f", ii)
	static = STATIC:FindByName(searchString, false)
	if static~=nil then
		StaticBlueAirplanes[#StaticBlueAirplanes+1]= static
	end	
end

linkedTarget = {}
sgRedAirplanePilot = SPAWN:NewWithAlias( "RedAirplanePilot", "TargetRedAirplaneA" )	
sgRedAirplaneCoPilot = SPAWN:NewWithAlias( "RedAirplaneCoPilot", "TargetRedAirplaneB" )	-- Test putting a second infantry on other side
SCHEDULER:New( nil, 
	function()	
		for ii=1,#StaticRedAirplanes do	
			local staticObject = StaticRedAirplanes[ii]
			--Only spawn a percentage of airplanes:
			local rnd = math.random(100)
			if rnd<_state.RedAirplaneSpawnPct then
				
				--local pilotOffset = POINT_VEC3:New(-1.2,0, 0.8) --x+ is NORTH, z+ is EAST
				--												 x+ is FORWARD, z+ is RIGHT (Body coord)
				local pilotOffset = POINT_VEC3:New(-1.4,0, -1) --x+ is NORTH, z+ is EAST
				pilotOffset = pilotOffset:RotateY(staticObject:GetHeading()*math.pi/180)												
				local pilotPosition = staticObject:GetPointVec3()
				pilotPosition = pilotPosition:Add(pilotOffset)
				g1 = sgRedAirplanePilot:SpawnFromVec3(pilotPosition:GetVec3() )
				
				pilotOffset = POINT_VEC3:New(-1.4,0, 1) --x+ is NORTH, z+ is EAST
				pilotOffset = pilotOffset:RotateY(staticObject:GetHeading()*math.pi/180)												
				pilotPosition = staticObject:GetPointVec3()
				pilotPosition = pilotPosition:Add(pilotOffset)
				g2 = sgRedAirplaneCoPilot:SpawnFromVec3(pilotPosition:GetVec3() )
				linkedTarget[g1:GetName()]=g2:GetName()
				linkedTarget[g2:GetName()]=g1:GetName()			
			else
				staticObject:Destroy()
			end
		end
	end, {}, 1
)

sgBlueAirplanePilot = SPAWN:NewWithAlias( "BlueAirplanePilot", "TargetBlueAirplaneA" )	
sgBlueAirplaneCoPilot = SPAWN:NewWithAlias( "BlueAirplaneCoPilot", "TargetBlueAirplaneB" )	-- Test putting a second infantry on other side
SCHEDULER:New( nil, 
	function()	
		for ii=1,#StaticBlueAirplanes do	
			local staticObject = StaticBlueAirplanes[ii]
			--Only spawn a percentage of airplanes:
			local rnd = math.random(100)
			if rnd<_state.BlueAirplaneSpawnPct then
				
				--local pilotOffset = POINT_VEC3:New(-1.2,0, 0.8) --x+ is NORTH, z+ is EAST
				--												 x+ is FORWARD, z+ is RIGHT (Body coord)
				local pilotOffset = POINT_VEC3:New(-2.4,0, -1) --x+ is NORTH, z+ is EAST
				pilotOffset = pilotOffset:RotateY(staticObject:GetHeading()*math.pi/180)												
				local pilotPosition = staticObject:GetPointVec3()
				pilotPosition = pilotPosition:Add(pilotOffset)
				g1 = sgBlueAirplanePilot:SpawnFromVec3(pilotPosition:GetVec3() )
				
				pilotOffset = POINT_VEC3:New(-2.4,0, 1) --x+ is NORTH, z+ is EAST
				pilotOffset = pilotOffset:RotateY(staticObject:GetHeading()*math.pi/180)												
				pilotPosition = staticObject:GetPointVec3()
				pilotPosition = pilotPosition:Add(pilotOffset)
				g2 = sgBlueAirplaneCoPilot:SpawnFromVec3(pilotPosition:GetVec3() )
				linkedTarget[g1:GetName()]=g2:GetName()
				linkedTarget[g2:GetName()]=g1:GetName()			
			else
				staticObject:Destroy()
			end
		end
	end, {}, 2
)



-- Bigger Units are too robust for WWII, this function allows us to trigger death events at customized hit point levels
local function OverrideLife0(u, EventData)
	env.info("ARX >> OverrideLife0(): { ".. u:GetGroup():GetName().." }" )
	local myType = EventData.TgtTypeName	
	if targetData[u:GetGroup():GetName()].dead == nil  then
		env.info("ARX >>                : LIEF REMAINING = ".. u:GetLife() .. "}" )
		if u:GetLife() < typeData[myType].newLife0 then
			env.info("ARX >>                : DEAD }" )
			targetData[u:GetGroup():GetName()].dead = true
			-- Initiate death sequence with multiple explosions along the length of the ship
			for ii = 1,10 do	
				local sLenMeters 	= 110
				local headingDeg  	= u:GetGroup():GetHeading()
				local onShip 		= math.random(sLenMeters)-sLenMeters/2																								
				local pos 			= POINT_VEC3:New(1, 0, 0 )																			
				pos = pos:RotateY(headingDeg*math.pi/180)												
				pos = pos:MulY(onShip)
				pos = pos:Add(POINT_VEC3:NewFromVec3( u:GetGroup():GetVec3() ))				
				env.info("ARX >>                : Ship Heading=".. headingDeg .."(deg)" )
				local bombScheduler = SCHEDULER:New( nil, 
					function(pos)				
						trigger.action.explosion(pos:GetVec3(), 250)	
						--pos:SmokeRed()
					end, {pos}, 0.5+math.random(8)
				)				
			end
		end
		
	end
end

-- Get Total Points Confirmed for coalition
local function GetPointsConfirmed(c)
	local points = 0
	for clientName,client in pairs(clientData) do			
		if client.Coalition==c then
			points = points+client.PointsConfirmed			
		end
	end			
	return points
end

-- Get Total Points Pending for coaltion
local function GetPointsPending(c)
	local points = 0
	for client,v in pairs(clientData) do
		if client.Coalition==c then
			points = points+client.PointsPending
		end
	end	
	return points
end

local function GetZoneBonusPoints(c)
	local points = 0
	for groupName,pts in pairs(zoneBonusPoints[c]) do					
		points = points+pts		
	end			
	return points
end

-- Convert coalition id to string, RED, BLUE, NEUTRAL
local function CoalitionToString(c)
	if c==coalition.side.RED then
		return "RED"
	elseif c==coalition.side.BLUE then
		return "BLUE"
	else
		return "NEUTRAL"
	end
end

-- Get Pilot name for a group. Pilot name is the pilot's chosen callsign.  AI returns "AI.".
local function GetPilotName(g)
	local playerName = "AI"						
		if g:GetUnit(1)~=nil then
			playerNameT = g:GetUnit(1):GetPlayerName()
			if playerNameT~=nil then						
				if playerNameT~="" then
					playerName = playerNameT		
				end
			end
		end		
	return playerName
end

-- Given a word, add and "a" or "an" as appropriate
local function AddIndefiniteArticle(iStr)	
	if string.sub(iStr, 1, 1)=="A" or string.sub(iStr, 1, 1)=="a" then
		return "an "..iStr
	end
	return "a "..iStr
end

-- Add an "s" based on input value
local function AddPlural(iVal)
	if iVal==1 then
		return ""
	end
	return "s"
end

-- Called after a death event.
-- Increment Pending/Confirmed Kill/point counters
-- Artifically destroy immortal unit types
local function AddKillPending(target, EventData)
	env.info("ARX >> AddKillPending()")
	local attacker = targetData[target:GetGroup():GetName()].lastToHit	                  
	if attacker~=nil then		
		local attacker = GROUP:FindByName(attacker)	
		if attacker~=nil then	
			-- make sure attacker is a client(!)
			if clientData[attacker:GetName()]~=nil then
				targetData[target:GetGroup():GetName()].lastToHit = {}		
				local myType= EventData.IniTypeName
				
				local bp = 0		
				if groupBonusPoints[target:GetGroup():GetName()]~=nil then				
					bp = groupBonusPoints[target:GetGroup():GetName()]
				end
				print_r(bp)
				clientData[attacker:GetName()].KillsPending = CatTables(clientData[attacker:GetName()].KillsPending, {target:GetGroup():GetName()})
				clientData[attacker:GetName()].PointsPending = clientData[attacker:GetName()].PointsPending + typeData[myType].points + bp			
				env.info("ARX >> AddKillPending() : "..attacker:GetName().. " killed "..target:GetGroup():GetName().. " for +" .. typeData[myType].points+bp .." (pending) points.")						
				
				
				-- If immortal, remove unit
				print_r(typeData[myType])
				if typeData[myType].immortal~=nil then
					env.info("ARX >> AddKillPending() : Removing Immortal " ..target:GetGroup():GetName())
					-- If Target has a link, Destroy it first
					if linkedTarget[target:GetGroup():GetName()]~=nil then
						--clear last to hit to prevent double scoring
						local linkName = linkedTarget[target:GetGroup():GetName()]
						local link = GROUP:FindByName(linkName)
						if link~=nil then
							targetData[link:GetName()].lastToHit = {}
							link:Destroy()
						end					
					end
					target:GetGroup():Destroy()
				end
				
				--MESSAGE OUT
				MESSAGE:New(GetPilotName(attacker).." destroyed "..AddIndefiniteArticle(typeData[myType].class).."! RTB to score "..clientData[attacker:GetName()].PointsPending.." point"..AddPlural(clientData[attacker:GetName()].PointsPending), 5):ToCoalition(attacker:GetCoalition())											
			else
				env.info("ARX >> clientData[attacker:GetName()] is nil (Probably Ground unit AI attacker)")
				--env.info("ARX >> attacker =")
				--print_r(attacker:GetName())
				--env.info("ARX >> clientData =")
				--print_r(clientData)
			end
		else
			env.info("ARX >> attackerGroup is nil")
			env.info("ARX >> clientData =")
			print_r(clientData)
		end
	else
		env.info("ARX >> attacker is nil")
		env.info("ARX >> targetName ".. target:GetGroup():GetName())
		env.info("ARX >> targetData ")
		print_r(targetData)
	end
end

-- Define event listeners for target groups
local function AttachEventListenersToTarget(g)		
	if g~=nil then 
		if g:IsAlive() then 				
			env.info("ARX >> AttachEventListenersToTarget() : "..g:GetName())	
			local target = g:GetUnit(1) -- Exactly 1 unit per group
			
			target:HandleEvent( EVENTS.Hit )							
			function target:OnEventHit( EventData )
				env.info("ARX >> AttachEventListenerTarget():OnEventHit() : Target="..target:GetGroup():GetName()..", ".. EventData.TgtTypeName)	
				if _state.missionComplete==false then
					if EventData.initiator~=nil then					
						local initiator = UNIT:Find(EventData.initiator)				
						if initiator~=nil then						
							env.info("ARX >>                                          : Attacker="..initiator:GetGroup():GetName())

							if initiator:GetCoalition()~=target:GetGroup():GetCoalition() then
							    -- might want to add something to prevent AI kill stealing
								if clientData[initiator:GetGroup():GetName()]~=nil then
									targetData[target:GetGroup():GetName()].lastToHit = initiator:GetGroup():GetName()
									env.info("ARX >> Assigned lastToHit = "..target:GetGroup():GetName())
									print_r(targetData[target:GetGroup():GetName()])
								end
							else							
								-- HANDLE FRIENDLY FIRE
								-- Right now they just don't get any credit
								
								env.info("ARX >> Friendly fire?: targetName = "..target:GetGroup():GetName())
							end		

							local myType = EventData.TgtTypeName
							if typeData[myType].newLife0~=nil then
								SCHEDULER:New( nil, 
									function(target, EventData)	
										if _state.missionComplete==false then
											OverrideLife0(target, EventData)
										end
									end, {target, EventData}, 1
								)	
							end
								
							
								
							if EventData.WeaponName==nil then
								env.info("ARX >> EventData.WeaponName is nil! Setting to GenericGuns")
								EventData.WeaponName = "GenericGuns"
							end

							-- Hack to make Server's Pew Pew guns Generic Type		
							if EventData.WeaponName=="weapons.shells.M2_50_aero_AP"	or EventData.WeaponName=="weapons.shells.M20_50_aero_APIT" or EventData.WeaponName=="weapons.shells.MG_13x64_APT" or EventData.WeaponName=="weapons.shells.MG_13x64_API" or EventData.WeaponName=="weapons.shells.MG_13x64_HEI" or EventData.WeaponName=="weapons.shells.MG_20x82_API" or EventData.WeaponName=="weapons.shells.MG_20x82_MGsch" or EventData.WeaponName=="weapons.shells.MG_20x82_HEI_T" then
								EventData.WeaponName = "GenericGuns"
							end
							
							if typeData[myType][EventData.WeaponName]~=nil then
								-- Increment Hits
								if targetData[target:GetGroup():GetName()][EventData.WeaponName]==nil then							
									targetData[target:GetGroup():GetName()][EventData.WeaponName] = {["numHits"] = 0 }						
								end
								targetData[target:GetGroup():GetName()][EventData.WeaponName].numHits = targetData[target:GetGroup():GetName()][EventData.WeaponName].numHits + 1						
								
								--If there is a linked target, consider adding hits together
								local linkedHits = 0;
								if linkedTarget[target:GetGroup():GetName()]~=nil then
									local linkName = linkedTarget[target:GetGroup():GetName()]
									local link = GROUP:FindByName(linkName)
									env.info("HERE1:"..linkName)
									if link~=nil then
										if targetData[link:GetName()][EventData.WeaponName]~=nil then											
											linkedHits = targetData[link:GetName()][EventData.WeaponName].numHits											
											env.info("HERE2:"..linkedHits)
										end
									end													
								end
								--M2 P-51
								
								local numHits = math.min(targetData[target:GetGroup():GetName()][EventData.WeaponName].numHits+linkedHits, #typeData[myType][EventData.WeaponName])
								local killPct = typeData[myType][EventData.WeaponName][numHits]
								local rnd = math.random(100)	
								if rnd <= killPct then
									env.info("ARX >>                                          : Killed ("..targetData[target:GetGroup():GetName()][EventData.WeaponName].numHits+linkedHits.." hit(s))")																
									trigger.action.explosion(target:GetVec3(), 10) -- Possibly make explosion size a typeData field								
									--If immortal, force death processing because events are unreliable.
									if typeData[myType].immortal~=nil then	
										local fakeEvent = { ["IniTypeName"] = myType}
										AddKillPending(target, fakeEvent)
									end
								else
									env.info("ARX >>                                          : Survived ("..targetData[target:GetGroup():GetName()][EventData.WeaponName].numHits+linkedHits.." hit(s))")
								end
							end		
						end
					end
				end
			end
			
			target:HandleEvent( EVENTS.Dead )							
			function target:OnEventDead( EventData )	
				if _state.missionComplete==false then
					AddKillPending(target, EventData)
				end
			end		
			target:HandleEvent( EVENTS.Crash )							
			function target:OnEventCrash( EventData )	
				if _state.missionComplete==false then
					AddKillPending(target, EventData)
				end
			end				
		end
	end	
end	



-- When a client dies/leaves/ejects/etc, clear Pending Kills/Points and remove lastToHit entries
-- Removing lastToHit guards against delayed kills (due to fire) that occur after the player respawns
local function RemovePendingPointsAndLastHit(u)
	if u~=nil then
		local g = u:GetGroup()
		if g~=nil then
			local groupName = g:GetName()			
			clientData[groupName].KillsPending 	= {}					
			clientData[groupName].PointsPending  = 0
			for targetName,v in pairs(targetData) do
				if targetData[targetName].lastToHit~=nil then
					if targetData[targetName].lastToHit == groupName then
						targetData[targetName].lastToHit = {}
					end			
				end
			end							
		end
	end
end

-- Landing Events trigger scoring 
local function AttachEventListenersToClient(g)	
	if g~=nil then				
		if g:IsAlive() then 								
			local u = g:GetUnit(1)				
			--env.info("ARX >> AttachEventListenersToClient() "..u:GetGroup():GetName().."=>"..u:GetPlayerName())
			
			u:HandleEvent( EVENTS.Land )							
			function u:OnEventLand( EventData )	
				if _state.missionComplete==false then
					local group = u:GetGroup()
					local groupName = g:GetName()
					if _state.airbaseMap[EventData.place.id_]["Coalition"]==group:GetCoalition() then
						env.info(">> LANDING: { Group=" .. groupName.." }")
						
						--print_r(clientData)
						local pointsPending = clientData[group:GetName()].PointsPending
						if pointsPending>0 then
						
							clientData[groupName].KillsConfirmed 	= CatTables(clientData[groupName].KillsConfirmed, clientData[groupName].KillsPending)										
							clientData[groupName].PointsConfirmed  	= clientData[groupName].PointsPending + clientData[groupName].PointsConfirmed
							clientData[groupName].KillsPending 	    = {}					
							clientData[groupName].PointsPending 	= 0
							
							-- Send Message to all							
							local pointsBLUE = GetPointsConfirmed(coalition.side.BLUE)+GetZoneBonusPoints(coalition.side.BLUE)
							local pointsRED  = GetPointsConfirmed(coalition.side.RED)+GetZoneBonusPoints(coalition.side.RED)
							local outcome = GetPilotName(group).." scored "..pointsPending.." point"..AddPlural(clientData[groupName].PointsPending).." for "..CoalitionToString(u:GetCoalition())																						
							MESSAGE:New(outcome.."\n\nBLUE Team:\n"..pointsBLUE.." Point"..AddPlural(pointsBLUE).."\n\nRED Team:\n"..pointsRED.." Point"..AddPlural(pointsRED) , 10 ):ToAll()														
							--trigger.action.outSound("audio_IncomingMessage.ogg")																						
						else
							MESSAGE:New("Landed at friendly airfield.  No points to score!"):ToGroup(group)
							print_r(clienData[groupName])
							
						end
					else
						MESSAGE:New("Landed at Neutral/Enemy Airfield!"):ToGroup(group)
					end										
				end							
			end		
													
			u:HandleEvent( EVENTS.Dead ) 
			function u:OnEventDead( EventData )				RemovePendingPointsAndLastHit(u) end									
			u:HandleEvent( EVENTS.PilotDead )							
			function u:OnEventPilotDead( EventData )		RemovePendingPointsAndLastHit(u) end									
			u:HandleEvent( EVENTS.Crash )							
			function u:OnEventCrash( EventData )			RemovePendingPointsAndLastHit(u) end									
			u:HandleEvent( EVENTS.Ejection )							
			function u:OnEventEjection( EventData )			RemovePendingPointsAndLastHit(u) end									
			u:HandleEvent( EVENTS.PlayerLeaveUnit )							
			function u:OnEventPlayerLeaveUnit( EventData )	RemovePendingPointsAndLastHit(u) end	
			
		end
	end	
end

-- Event listeners must be attached to a client group every time it is taken control.  
-- Until I find a better way to do this (catch a global takeoff event) I will do this periodicially every 30 seconds.
local AttachEventListenersToClientScheduler = SCHEDULER:New( nil, 
	function()								
		env.info("ARX >> PilotEventListenerScheduler()")		
		for groupName,v in pairs(clientData) do
			AttachEventListenersToClient(GROUP:FindByName(groupName))
		end				
	end, {}, 0, 30
)

-- MISC flags are used by server script to handle count down timer and mission reload action
trigger.action.setUserFlag("GAME_STATE", 0) --- TEST HERE
trigger.action.setUserFlag("TIMER_DURATION_SECONDS", _state.premissionDuration)	
trigger.action.setUserFlag("SM_ENABLED", 1)
trigger.action.setUserFlag("999", 0)						-- Set to 999 to restart mission

-- Destroy plans that take off early
local function CheckForSabatage()
	env.info("ARX >> SabotageAircraft()")	
	for groupName,v in pairs(clientData) do
		local g = GROUP:FindByName(groupName)
		env.info("ARX >> SabotageAircraft():"..groupName)
		if g~=nil then
			env.info("ARX >> SabotageAircraft():Here")
			if g:InAir() and g:IsAlive() then
				env.info("ARX >> SabotageAircraft()")	
				local pilotName 	= GetPilotName(g)
				local groupName 	= g:GetName()
				-- This is not a robust way to prevent early takeoffs
				env.info("ARX >> SabotageAircraft(): DESTROYING "..groupName..":"..pilotName)
				if pilotName~="AI" then
					env.info("ARX >> SabotageAircraft(): DESTROYING "..groupName..":"..pilotName)	
					MESSAGE:New(pilotName..":".. groupName.." fell victim to sabotage!" , 30 ):ToAll()	
					trigger.action.explosion(g:GetVec3(), 10)
				end
			end
		end
	end		
end

local function DisplayTimeRemaining( )		
	local tRem = round((_state.missionDuration - (timer.getAbsTime( ) - _state.missionStartTime)))	
	MESSAGE:New(SecondsToClock(tRem).." Remaining", 5):ToAll()	
end

-- Start Scenario Events when pre-mission begins(!)
-- The following block is used to spawn scenario specific assets immediately after a player joins.  
--This is useful to script time sensitive events that occur during startup (like AWESOME B17 FLYOVERS)
initScenario = false;
local PreMission = SCHEDULER:New(nil,
	function()		
		if initScenario==false and (trigger.misc.getUserFlag("PLAYER_READY")==1 or meDebug) then
		
			-- Do Anytime Actors
			sg = {}
			set = SET_GROUP:New():FilterPrefixes("TargetBlueTruckConvoy1"):FilterStart() 				
			set:ForEachGroup(  					
				function( g )  			
					env.info("DoTheseGroupsExist?")	
					sg[#sg+1]=SPAWN:New(g:GetName())
				end  
			)
			-- Do the Spawning
			for ii =1,#sg do
				sg[ii]:Spawn()
			end
			
			
			
			--END Anytime Actors
		
		
		
			if scenarioName=="Goodwood" then
				--Spawn Bomber flyover
				env.info("SPAWNING BOMBER SQUADRON")
				SPAWN:New("BomberSquadronGoodwood1"):Spawn()			
				SPAWN:New("BomberSquadronGoodwood2"):Spawn()
				SPAWN:New("BomberSquadronGoodwood3"):Spawn()
				SPAWN:New("BomberSquadronGoodwood4"):Spawn()
				
				-- Spawn Spearhead				
				sg = {}
				set = SET_GROUP:New():FilterPrefixes("TargetBlueM4Goodwood"):FilterStart() 				
				set:ForEachGroup(  					
					function( g )  			
						env.info("DoTheseGroupsExist?")	
						sg[#sg+1]=SPAWN:New(g:GetName())
					end  
				)
				-- Do the Spawning
				for ii =1,#sg do
					sg[ii]:Spawn()
				end
			end
			
			if scenarioName=="AxisThrust" then							
				-- Spawn Spearhead				
				sg = {}
				set = SET_GROUP:New():FilterPrefixes("TargetRedPanzerThrust1"):FilterStart() 				
				set:ForEachGroup(  					
					function( g )  			
						env.info("DoTheseGroupsExist?")	
						sg[#sg+1]=SPAWN:New(g:GetName())
					end  
				)
				-- Do the spawning
				for ii =1,#sg do
					sg[ii]:Spawn()
				end
			end	
			
			if scenarioName=="BeachLanding" then							
				-- Spawn Fleet				
				sg = {}
				set = SET_GROUP:New():FilterPrefixes("TargetBlueShipBeach"):FilterStart() 				
				set:ForEachGroup(  					
					function( g )  			
						env.info("DoTheseGroupsExist?")	
						sg[#sg+1]=SPAWN:New(g:GetName())
					end  
				)				
				-- Do the Spawning
				for ii =1,#sg do
					sg[ii]:Spawn()
				end
			end	
			
			initScenario = true
		end
	end, {}, 0, 1
)


-- Where the magic happens...
missionStarted = false
BeginMission = SCHEDULER:New( nil, 
	function()					
		--The scheduler does not sync well with server time	
		--UNCOMMENT BELOW FOR TESTING
		--env.info("STARTING MISSION (?)")
		if missionStarted==false and ((trigger.misc.getUserFlag("GAME_STATE")==2 and trigger.misc.getUserFlag("PLAYER_READY")==1) or meDebug )then
		--if missionStarted==false then
			env.info("STARTING MISSION!!!")
			missionStarted=true		
			
			-- Server script handles the "START MISSION" message
			
			-- Immediately check for planes who departed early and Make. Them. Pay.
			CheckForSabatage()	
			
			-- This Trigger activates all Anytime Actors (convoys etc)
			trigger.action.setUserFlag("0", 1)
			
			if scenarioName=="Goodwood" then			
				env.info("GOT HERE!@!!")
				trigger.action.setUserFlag("1", 1)
				--Setup Bonus Points (for destroying Units)				
				set = SET_GROUP:New():FilterPrefixes("TargetBlueM4Goodwood"):FilterStart() 
				set:ForEachGroup(  
					function( g ) 
						groupBonusPoints[g:GetName()] = 8
					end  
				)
				env.info("groupBonusPoints")
				print_r(groupBonusPoints)
				-- Destroy Allied tanks in the way:
				local dz11 = ZONE:New("DZ11")
				set = SET_GROUP:New():FilterPrefixes("TargetRedPanzer"):FilterStart() 				
				set:ForEachGroup(  
					function( g )  													
						if g:IsCompletelyInZone(dz11) then													
							trigger.action.explosion(g:GetVec3(), 250)	
						end
					end  
				)
				
				set = SET_GROUP:New():FilterPrefixes("BomberSquadronGoodwood"):FilterStart() 
				set:ForEachGroup(  
					function( g ) 
							g:Destroy()
							--trigger.action.explosion(g:GetVec3(), 250)	
					end  
				)
				
				-- Check For Victory Conditions at T+18 to T+24
				SCHEDULER:New( nil, 
					function()	
						env.info("CHECK VICTORY CONDITIONS")
						local goal11 = ZONE:New("GOAL11")									
						local newPoints = false
						set = SET_GROUP:New():FilterPrefixes("TargetBlueM4Goodwood"):FilterStart() 
						set:ForEachGroup(  
							function( g ) 
								if g:IsCompletelyInZone(goal11) then							
									if zoneBonusPoints[g:GetCoalition()][g:GetName()]==nil then									
										zoneBonusPoints[g:GetCoalition()][g:GetName()] = 16																	
										g:FlareGreen()															
										g:FlareGreen()															
										g:FlareGreen()					
										newPoints = true
										MESSAGE:New("Sherman arrived at Factory! Red +16", 1):ToAll()
									end								
								end							
							end  
						)											
						env.info("ZONE BONUS POINTS")
						print_r(zoneBonusPoints)
						if newPoints then
							local pointsBLUE 	= GetPointsConfirmed(coalition.side.BLUE)+GetZoneBonusPoints(coalition.side.BLUE)
							local pointsRED		= GetPointsConfirmed(coalition.side.RED)+GetZoneBonusPoints(coalition.side.RED)	
							MESSAGE:New("BLUE Team:\n"..pointsBLUE.." Point"..AddPlural(pointsBLUE).."\n\nRED Team:\n"..pointsRED.." Point"..AddPlural(pointsRED), 5):ToAll()		
						end
					end, {}, 18*60, 15, 0, 30*60
				)
			end
			
			if scenarioName=="AxisThrust" then			
				-- Start Tanks Roling
				trigger.action.setUserFlag("2", 1)
				
				--Setup Bonus Points (for destroying Units)				
				set = SET_GROUP:New():FilterPrefixes("TargetRedPanzerThrust1"):FilterStart() 
				set:ForEachGroup(  
					function( g ) 
						groupBonusPoints[g:GetName()] = 8
					end  
				)
				env.info("groupBonusPoints")
				print_r(groupBonusPoints)
				-- Destroy Allied tanks in the way:
				local dz21 = ZONE:New("DZ21")
				set = SET_GROUP:New():FilterPrefixes("TargetBlueM4"):FilterStart() 				
				set:ForEachGroup(  
					function( g )  													
						if g:IsCompletelyInZone(dz21) then													
							trigger.action.explosion(g:GetVec3(), 250)	
						end
					end  
				)
		
				-- Check For Victory Conditions at T+18 to T+24
				SCHEDULER:New( nil, 
					function()	
						env.info("CHECK VICTORY CONDITIONS")
						local goal21 = ZONE:New("GOAL21")									
						local newPoints = false
						set = SET_GROUP:New():FilterPrefixes("TargetRedPanzerThrust1"):FilterStart() 
						set:ForEachGroup(  
							function( g ) 
								if g:IsCompletelyInZone(goal21) then							
									if zoneBonusPoints[g:GetCoalition()][g:GetName()]==nil then									
										zoneBonusPoints[g:GetCoalition()][g:GetName()] = 16																	
										g:FlareGreen()															
										g:FlareGreen()															
										g:FlareGreen()					
										newPoints = true
										MESSAGE:New("Panzer arrived at Les Moulins! Red +16", 1):ToAll()
									end								
								end							
							end  
						)											
						env.info("ZONE BONUS POINTS")
						print_r(zoneBonusPoints)
						if newPoints then
							local pointsBLUE 	= GetPointsConfirmed(coalition.side.BLUE)+GetZoneBonusPoints(coalition.side.BLUE)
							local pointsRED		= GetPointsConfirmed(coalition.side.RED)+GetZoneBonusPoints(coalition.side.RED)	
							MESSAGE:New("BLUE Team:\n"..pointsBLUE.." Point"..AddPlural(pointsBLUE).."\n\nRED Team:\n"..pointsRED.." Point"..AddPlural(pointsRED), 5):ToAll()		
						end
					end, {}, 18*60, 15, 0, 25*60
				)
			end
		
			
			if scenarioName=="BeachLanding" then			
				-- Start Tanks Roling
				trigger.action.setUserFlag("3", 1)
				
				--Setup Bonus Points (for destroying Units)				
				set = SET_GROUP:New():FilterPrefixes("TargetBlueShipBeach"):FilterStart() 
				set:ForEachGroup(  
					function( g ) 
						groupBonusPoints[g:GetName()] = 8
					end  
				)
				env.info("groupBonusPoints")
				print_r(groupBonusPoints)
				
				-- Check For Victory Conditions at T+18 to T+24
				SCHEDULER:New( nil, 
					function()	
						env.info("CHECK VICTORY CONDITIONS")
						local goal31 = ZONE:New("GOAL31")									
						local newPoints = false
						set = SET_GROUP:New():FilterPrefixes("TargetBlueShipBeach"):FilterStart() 
						set:ForEachGroup(  
							function( g ) 
								if g:IsCompletelyInZone(goal31) then							
									if zoneBonusPoints[g:GetCoalition()][g:GetName()]==nil then									
										zoneBonusPoints[g:GetCoalition()][g:GetName()] = 25																	
										g:FlareGreen()															
										g:FlareGreen()															
										g:FlareGreen()					
										newPoints = true
										MESSAGE:New("Transport Arrived at Beach! Blue +25", 1):ToAll()
										-- Also, Explode any remaining Naval Gun::
										local set2 = SET_GROUP:New():FilterPrefixes("TargetRedNavalGunBeach"):FilterStart() 
										set2:ForEachGroup(  
											function( g ) 
												if g~=nil then
													if g:IsAlive() then
														trigger.action.explosion(g:GetVec3(), 250)															
													end
												end
											end										
										)
									end								
								end							
							end  
						)											
						env.info("ZONE BONUS POINTS")
						print_r(zoneBonusPoints)
						if newPoints then
							local pointsBLUE 	= GetPointsConfirmed(coalition.side.BLUE)+GetZoneBonusPoints(coalition.side.BLUE)
							local pointsRED		= GetPointsConfirmed(coalition.side.RED)+GetZoneBonusPoints(coalition.side.RED)	
							MESSAGE:New("BLUE Team:\n"..pointsBLUE.." Point"..AddPlural(pointsBLUE).."\n\nRED Team:\n"..pointsRED.." Point"..AddPlural(pointsRED), 5):ToAll()		
						end
					end, {}, 18*60, 15, 0, 25*60
				)						
			end	
					
			-- At T+5s, Initialize targetData structure (convenience)
			-- AttachEventListeners to all targets
			targetData = {}
			SCHEDULER:New( nil, 
				function()	
					
					set = SET_GROUP:New():FilterPrefixes("Target"):FilterStart() 
					set:ForEachGroup(  
						function( g )  
							--print_r(g:GetUnit(1))
							targetData[g:GetName()] = {}			
						end  
					)
					for groupName,v in pairs(targetData) do
						AttachEventListenersToTarget(GROUP:FindByName(groupName))
					end	
					print_r("ARX >> BeginMission(): targetData")
					print_r(targetData)
				end, {}, 5
			)
			
			
			-- START CLOCK
			_state.missionStartTime = timer.getAbsTime( )
			for kk=1,#_state.clockNotificationTimes do
				SCHEDULER:New( nil, 
					function()						
						DisplayTimeRemaining()				
					end, {}, _state.clockNotificationTimes[kk]
				)
			end
		
			-- SCHEDULE MISSION END time
			local endMission = SCHEDULER:New( nil, 
				function()			
					env.info("ARX >> Mission Complete()")
					_state.missionComplete = true
					--DISPLAY SCORE, INSTRUCTIONS	
									
					local pointsBLUE 	= GetPointsConfirmed(coalition.side.BLUE)+GetZoneBonusPoints(coalition.side.BLUE)
					local pointsRED		= GetPointsConfirmed(coalition.side.RED)+GetZoneBonusPoints(coalition.side.RED)
					local outcome = "Match ends in a DRAW!"
					if pointsBLUE>pointsRED then
						outcome = "BLUE is Victorious!"
					elseif pointsBLUE<pointsRED then
						outcome = "RED is Victorious!"	
					end
					
					--trigger.action.outSound("audio_Drum01.ogg")					
					MESSAGE:New(outcome.."\n\nBLUE Team:\n"..pointsBLUE.." Point"..AddPlural(pointsBLUE).."\n\nRED Team:\n"..pointsRED.." Point"..AddPlural(pointsRED).."\n\nReloading Mission in ".._state.postmissionDuration.." seconds" , _state.postmissionDuration ):ToAll()		
					
				end, {}, _state.missionDuration
			)
			-- SCHEDULE MISSION RELOAD
			local reloadMission = SCHEDULER:New( nil, 
				function()			
					env.info("ARX >> ReloadMission()")
					trigger.action.setUserFlag("999", 999)												
				end, {}, _state.missionDuration + _state.postmissionDuration
			)
			BeginMission:Clear()
			
			
		end
	end, {}, 0, 1
)
