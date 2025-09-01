-- Dedicated Server Expansion for Map Sweepers by Octantis Addons (MerekiDor & JonahSoldier)
if not(engine.ActiveGamemode() == "mapsweepers") then return end 
include("jcms_serverext/shared.lua")
AddCSLuaFile("autorun/client/cl_jcms_serverext_init.lua")

-- // Utils {{{
	function jcms.ServerExtension_GetPlyFromStr( str )
		for i, ply in player.Iterator() do 
			if ply:Name() == str then 
				return ply
			end
		end
	end
-- // }}}


-- // VoteKick {{{
	jcms.playerKickVotes = {} --Total
	jcms.playerKickVoters = {} --Dict w/subtable dicts of people who voted for a player.

	function jcms.ServerExtension_GetVoteKickThreshold()
		return math.ceil(player.GetCount() * jcms.cvar_votekickThreshold:GetFloat())
	end

	function jcms.ServerExtension_CheckShouldKick(ply)
		--Null entity clean-up
		for voter, _ in pairs(jcms.playerKickVoters[ply]) do
			if not IsValid(voter) then 
				jcms.playerKickVoters[ply][voter] = nil
				jcms.playerKickVotes[ply] = jcms.playerKickVotes[ply] - 1
			end
		end

		if jcms.playerKickVotes[ply] >= jcms.ServerExtension_GetVoteKickThreshold() then 
			--No longer want this data.
			jcms.playerKickVoters[ply] = nil
			jcms.playerKickVotes[ply] = nil

			--Ban the fucker
			local duration = jcms.cvar_votekickTime:GetInt()
			ply:Ban(duration, false )
			ply:Kick( "Vote-kicked. You will be able to return in " .. tostring(duration) .. " minutes" )

			return true -- kicked
		end

		return false --We didn't kick the player
	end

	hook.Add( "PlayerSay", "jcms_serverExtension_votekick", function( ply, text )
		if not string.StartsWith(string.lower(text), "!votekick") then return end
		if not jcms.cvar_votekick_enabled:GetBool() then return end

		--Is there a 2nd argument?
		local exploded = string.Explode(" ", text)
		if not exploded[2] then 
			ply:ChatPrint("Incorrect format. Use: !votekick playerName")
			return ""
		end

		--Get the player entity from the 2nd argument's name
		local targetStr = exploded[2]
		local targetPly = jcms.ServerExtension_GetPlyFromStr( targetStr )

		if not IsValid(targetPly) then 
			ply:ChatPrint("Please enter a valid name (You can use tab to cycle options)")
			return ""
		end
		
		--Make sure initial values are set
		jcms.playerKickVoters[targetPly] = jcms.playerKickVoters[targetPly] or {}
		jcms.playerKickVotes[targetPly] = jcms.playerKickVotes[targetPly] or 0

		if jcms.playerKickVoters[targetPly][ply] then --Can't vote for the same person twice
			ply:ChatPrint("You have already voted to kick this person.")
			return ""
		end

		--Track our vote
		jcms.playerKickVoters[targetPly][ply] = true
		jcms.playerKickVotes[targetPly] = jcms.playerKickVotes[targetPly] + 1

		--Printing a message to let everyone know
		local required = jcms.ServerExtension_GetVoteKickThreshold()
		local fracString = "[" .. tostring(jcms.playerKickVotes[targetPly]) .. "/" .. tostring(required) .. "]"

		PrintMessage(HUD_PRINTTALK, ply:Name() .." voted to kick " .. targetStr .. " " .. fracString )

		--Kick the guy (if there are enough votes)
		jcms.ServerExtension_CheckShouldKick(targetPly)
		return ""
	end)
-- // }}}

-- // Evac Command {{{

	jcms.evacVotes = 0 --Total
	jcms.evacVoters = {} --Dict of people who voted

	function jcms.ServerExtension_GetEvacThreshold()
		return math.ceil(player.GetCount() * jcms.cvar_voteEndRoundThreshold:GetFloat())
	end
	
	function jcms.ServerExtension_NukePosition(pos)
		local world = game.GetWorld()
		util.BlastDamage(world, world, pos, 1500, 100)
					
		local ed = EffectData()
		ed:SetOrigin(pos)
		ed:SetFlags(6)
		util.Effect("jcms_blast", ed)
		
		ed:SetScale(500)
		ed:SetMagnitude(1.1)
		ed:SetFlags(1)
		util.Effect("jcms_blast", ed)
		
		util.ScreenShake(pos, 50, 50, 10, 6000, true)
		local filter = RecipientFilter()
		filter:AddAllPlayers()
		EmitSound("ambient/explosions/explode_6.wav", pos, CHAN_AUTO, 1, 140, 0, 110, 0, 0, filter)
		EmitSound("ambient/explosions/explode_2.wav", pos, CHAN_AUTO, 1, 100, 0, 140, 0, 0, filter)
		
		local radSphere = ents.Create("jcms_radsphere")
		radSphere:SetPos(pos)
		radSphere:Spawn()
	end
	
	jcms.evacSuddenDeath_startTime = 0
	jcms.evacSuddenDeath_nextThink = 0
	local function evacSuddenDeathThink()
		if not jcms.director then 
			hook.Remove("Think", "jcms_serverExtension_evacSuddenDeath")
		end
		
	
		local cTime = CurTime()
		if jcms.evacSuddenDeath_nextThink > cTime then return end

		local timeNuking = cTime - jcms.evacSuddenDeath_startTime

		local pos
		if timeNuking < 1.5 * 60 then
			local origins = {}
			local swps = team.GetPlayers(1)
			for i, swp in ipairs(swps) do 
				table.insert(origins, swp:WorldSpaceCenter())
			end
			
			local frac = 1 - timeNuking / (60 * 1.5) --Scale to 0 over 1.5 mins
			local areas = jcms.director_GetAreasAwayFrom(jcms.mapdata.validAreas, origins, 1500 * frac, 3500 * frac)
			
			local weightedAreas = {}
			for i, area in ipairs(areas) do
				weightedAreas[area] = area:GetSizeX() * area:GetSizeY()
			end

			local chosenArea = jcms.util_ChooseByWeight(weightedAreas) or jcms.mapgen_UseRandomArea() --fallback to random if no valid areas.
			pos = chosenArea:GetCenter() + Vector(0,0,50)
		else
			--If they're somehow still alive >1.5 min just nuke the bastards directly.
			local swps = team.GetPlayers(1)
			local swp = swps[math.random(#swps)]
			if IsValid(swp) then
				pos = swp:WorldSpaceCenter()
			end
		end
		
		if pos then
			jcms.ServerExtension_NukePosition(pos)
		end
		
		jcms.evacSuddenDeath_nextThink = cTime + 10
	end

	function jcms.ServerExtension_CheckShouldEvac()
		if jcms.serverExtension_suddenDeath then return false end

		--Null entity clean-up
		for voter, _ in pairs(jcms.evacVoters) do
			if not IsValid(voter) then 
				jcms.evacVoters[voter] = nil
				jcms.evacVotes = evacVotes - 1
			end
		end
		
		if not(jcms.evacVotes >= jcms.ServerExtension_GetEvacThreshold()) then return false end 
		
		local d = jcms.director
		if not d then return false end 

		local nukeTime = 3
		
		--Force evacuate.
		if not d.missionData.evacuating then
			d.missionData.evacuating = true
			d.missionData.evacEnt = jcms.mission_DropEvac(jcms.mission_PickEvacLocation())
			--Fuck you if you're evacuating from infestation I guess lol 
			--(it has custom placement logic which isn't replicated here, so it'll be more likely to spawn irradiated)
			
			jcms.serverExtension_forcedEvac = true
			PrintMessage(HUD_PRINTTALK, string.format("[Map Sweepers] Evac called. Cleanse-nuking of the map will commence in %d minutes", nukeTime) )
		else
			PrintMessage(HUD_PRINTTALK, string.format("[Map Sweepers] Cleanse-nuking of the map will commence in %d minutes", nukeTime) )
		end
		
		timer.Simple(60 * (nukeTime-1), function()
			if not jcms.director then return end
			PrintMessage(HUD_PRINTTALK, "[Map Sweepers] Cleanse-nuking of the map will commence in 1 minute" )
		end)

		timer.Simple(60 * nukeTime, function() --3 mins
			if not jcms.director then return end
			jcms.evacSuddenDeath_startTime = CurTime()
			PrintMessage(HUD_PRINTTALK, "[Map Sweepers] Initiating cleanse-nuking of the map" )

			hook.Add("Think", "jcms_serverExtension_evacSuddenDeath",evacSuddenDeathThink)
		end)
		
		jcms.evacVotes = 0
		jcms.evacVoters = {}
		jcms.serverExtension_suddenDeath = true
		
		return true
	end

	hook.Add( "PlayerSay", "jcms_serverExtension_evacvote", function( ply, text )
		if not string.StartsWith(string.lower(text), "!evac") then return end
		if not jcms.cvar_voteEvac_enabled:GetBool() then return end 

		--Don't let us vote twice
		if jcms.evacVoters[ply] then
			ply:ChatPrint("You've already voted.")
			return ""
		end

		--tracking our vote
		jcms.evacVotes = jcms.evacVotes + 1
		jcms.evacVoters[ply] = true

		--Let everyone know we voted
		local required = jcms.ServerExtension_GetEvacThreshold()
		local fracString = "[" .. tostring(jcms.evacVotes) .. "/" .. tostring(required) .. "]"

		PrintMessage(HUD_PRINTTALK, ply:Name() .." voted to evacuate early " .. fracString )

		--Check if we should summon evac.
		jcms.ServerExtension_CheckShouldEvac()
		return ""
	end)

-- // }}}