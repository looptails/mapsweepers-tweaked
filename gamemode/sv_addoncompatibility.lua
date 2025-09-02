--[[
	Map Sweepers - Co-op NPC Shooter Gamemode for Garry's Mod by "Octantis Addons" (consisting of MerekiDor & JonahSoldier)
    Copyright (C) 2025  MerekiDor

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

	See the full GNU GPL v3 in the LICENSE file.
	Contact E-Mail: merekidorian@gmail.com
--]]
-- These are various compatibility patches & measures for third-party addons. All for your experience.

-- The following code adds compatibility with various 3rd-party addons (with Steam Workshop links attached) to Map Sweepers.
hook.Add("InitPostEntity", "jcms_addonCompatibility", function()
	
	-- // Nombat {{{
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=270169947
	if NOMBAT then
		-- Combat music starts playing if there's enough enemies going after the players.
		
		hook.Remove("Think", "nombat.find.hostiles.Think")
		hook.Add("Think", "jcms_NombatFindHostiles", function()
			if jcms.director then
				NOMBAT.InCombat = #jcms.director.npcs >= 25 and jcms.director.npcs_inCombat >= 10
			else
				NOMBAT.InCombat = false
			end
			
			if NOMBAT.InCombat then
				-- Apparently this is the way Nombat sends info from server to client. I mean, it works and requires no net messages..?
				for i, ply in pairs( player.GetHumans() ) do
					if ply.ConCommand then
						ply:ConCommand("nombat.client.has.hostiles")
					end
				end
			end
		end)
	
	end
	-- // }}}

	-- // DOOM Dynamic Music System {{{
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=3371358666
	if MUSIC_SYSTEM and type(DOOM_CalculateHostiles) == "function" then
		-- I hijack the intensity logic so that this addon works with Map Sweepers better.

		local INTENSITY_NONE = 0
		local INTENSITY_LIGHT = 1
		local INTENSITY_HEAVY = 2

		local intensity_tallies = {
			[INTENSITY_NONE] = 0,
			[INTENSITY_LIGHT] = 4,
			[INTENSITY_HEAVY] = 16
		}

		jcms.doomdms_lastValues = {} -- key: player, value: intensity

		function jcms.doomdms_musicIntensityLogic()
			for ply, intensity in pairs( jcms.doomdms_lastValues ) do
				if not IsValid(ply) then
					jcms.doomdms_lastValues[ ply ] = nil
				end
			end
			
			local d = jcms.director

			if d and not d.gameover then
				local combatIntensity = INTENSITY_NONE

				if (d.swarmBossCount or 0) > 0 or ( d.npcs_alarm >= 0.75 and d.npcs_inCombat >= 20 ) or ( d.npcs_inCombat >= 36 ) then
					combatIntensity = INTENSITY_HEAVY
				elseif (d.npcs_inCombat >= 1) then
					combatIntensity = INTENSITY_LIGHT
				end

				if d.missionData and d.missionData.evacuating then
					combatIntensity = math.min(combatIntensity + 1, INTENSITY_HEAVY)
				end

				for i, ply in ipairs( player.GetAll() ) do

					local intensity = INTENSITY_NONE
					
					if ( ply:GetObserverMode() == OBS_MODE_NONE and ply:Alive() ) then
						-- In-game.
						intensity = combatIntensity
					elseif ply:GetObserverMode() == OBS_MODE_CHASE then
						-- Spectating.
						intensity = math.min(combatIntensity, INTENSITY_LIGHT)
					end

					if jcms.doomdms_lastValues[ ply ] ~= intensity then
						jcms.doomdms_lastValues[ ply ] = intensity
						
						net.Start("DOOM_CalculateHostiles")
							net.WriteInt(intensity_tallies[intensity] or 0, 32)
							net.WriteInt(1, 32)
						net.Send(ply)
					end

				end
			else
				for ply, intensity in pairs( jcms.doomdms_lastValues ) do
					if not IsValid(ply) then
						jcms.doomdms_lastValues[ ply ] = nil
						net.Start("DOOM_CalculateHostiles")
							net.WriteInt(0, 32)
							net.WriteInt(1, 32)
						net.Send(ply)
					end
				end
			end
		end

		timer.Simple(1, function()
			
			hook.Add("Think", "DOOM_CalculateHostiles", jcms.doomdms_musicIntensityLogic)
			jcms.printf("DOOM Dynamic Music System found. Hijacked for better compatibility. Nice taste!")

		end)
	end
	-- // }}}

	-- // VJ Base (handling player-npc relations) {{{
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=131759821
	if VJ then
		local sweeperClass = "CLASS_JCORP_MAPSWEEPER"
		local factionsToVJClasses = {
			["antlion"] = "CLASS_ANTLION",
			["combine"] = "CLASS_COMBINE",
			["rebel"] = "CLASS_PLAYER_ALLY",
			["zombie"] = "CLASS_ZOMBIE",

			-- Just in case
			["hecu"] = "CLASS_UNITED_STATES",
			["xen"] = "CLASS_XEN"
		}

		jcms.vjbase_hackablesTracker = jcms.vjbase_hackablesTracker or {}
		timer.Create("jcms_vjTrackHackables", 0.33, 0, function()
			for i = #jcms.vjbase_hackablesTracker, 1, -1 do
				local ent = jcms.vjbase_hackablesTracker[ i ]

				if not ( IsValid(ent) and ent.GetHackedByRebels ) then
					table.remove(jcms.vjbase_hackablesTracker, i)
				elseif type(ent.VJ_NPC_Class) == "table" then
					ent.VJ_NPC_Class[1] = ent:GetHackedByRebels() and factionsToVJClasses.rebel or sweeperClass 
				end
			end
		end)

		hook.Add("MapSweepersClassApplied", "jcms_VJClassRelations", function(ply, className, classData)
			if classData.jcorp then
				ply.VJ_NPC_Class = { sweeperClass }
			elseif factionsToVJClasses[ classData.faction ] then
				ply.VJ_NPC_Class = { factionsToVJClasses[ classData.faction ] }
			else
				ply.VJ_NPC_Class = nil
			end
		end)

		hook.Add("OnEntityCreated", "jcms_VJNPCClassAssigner", function(ent)
			if IsValid(ent) and ent:IsNPC() then
				timer.Simple(0.01, function()
					if IsValid(ent) then
						local class = ent:GetClass()

						if jcms.team_jCorpClasses[ class ] then
							ent.VJ_NPC_Class = { sweeperClass }
						elseif ent.jcms_faction and factionsToVJClasses[ ent.jcms_faction ] then
							ent.VJ_NPC_Class = { factionsToVJClasses[ ent.jcms_faction ] }
						end

						if type(ent.GetHackedByRebels) == "function" then
							table.insert(jcms.vjbase_hackablesTracker, ent)
						end
						
					end
				end)
			end
		end)
	end
	-- // }}}

	-- // Rycch's Custom NPCs (mostly combine) {{{
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=3455201353
	do
		-- Turret Soldier
		if scripted_ents.GetStored("npc_vj_c_overwatch_soldier_turret") then
			jcms.npc_types.combine_rycch_turretsoldier = {
				portalSpawnWeight = 0.01,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_STRONG,
				cost = 2,
				swarmWeight = 0.15,
			
				class = "npc_vj_c_overwatch_soldier_turret",
				bounty = 80,
			
				proficiency = WEAPON_PROFICIENCY_GOOD
			}
		end

		-- Flame Trooper
		if scripted_ents.GetStored("npc_vj_c_overwatch_flametrooper") then
			jcms.npc_types.combine_rycch_flametrooper = {
				portalSpawnWeight = 0.01,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_STRONG,
				cost = 1,
				swarmWeight = 0.1,
			
				class = "npc_vj_c_overwatch_flametrooper",
				bounty = 60,
			
				proficiency = WEAPON_PROFICIENCY_PERFECT
			}
		end

		-- CP Sniper
		if scripted_ents.GetStored("npc_vj_c_civil_protection_sniper") then
			jcms.npc_types.combine_rycch_cpsniper = {
				portalSpawnWeight = 0.05,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_STRONG,
				cost = 1.5,
				swarmWeight = 0.1,
			
				class = "npc_vj_c_civil_protection_sniper",
				bounty = 75,
			
				proficiency = WEAPON_PROFICIENCY_PERFECT
			}
		end

		-- CP Heavy
		if scripted_ents.GetStored("npc_vj_c_civil_protection_heavy") then
			jcms.npc_types.combine_rycch_cpheavy = {
				portalSpawnWeight = 0.04,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_STRONG,
				cost = 1.85,
				swarmWeight = 0.4,
			
				class = "npc_vj_c_civil_protection_heavy",
				bounty = 135,
			
				proficiency = WEAPON_PROFICIENCY_VERY_GOOD
			}
		end

		-- CP Riot Shield
		if scripted_ents.GetStored("npc_vj_c_civil_protection_riot") then
			jcms.npc_types.combine_rycch_cpriot = {
				portalSpawnWeight = 0.1,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_FODDER,
				cost = 1,
				swarmWeight = 0.1,
			
				class = "npc_vj_c_civil_protection_riot",
				bounty = 60,
			
				proficiency = WEAPON_PROFICIENCY_GOOD
			}
		end

		-- CP Shield Dropper
		if scripted_ents.GetStored("npc_vj_c_civil_protection_dropshield") then
			jcms.npc_types.combine_rycch_cpdropshield = {
				portalSpawnWeight = 0.02,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_STRONG,
				cost = 1.5,
				swarmWeight = 0.05,
			
				class = "npc_vj_c_civil_protection_dropshield",
				bounty = 100,
			
				proficiency = WEAPON_PROFICIENCY_VERY_GOOD
			}
		end

		-- Dark Energy RPG
		if scripted_ents.GetStored("npc_vj_c_overwatch_anti-armor") then
			jcms.npc_types.combine_rycch_antiarmor = {
				portalSpawnWeight = 0.002,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_STRONG,
				cost = 2.1,
				swarmWeight = 0.03,
			
				class = "npc_vj_c_overwatch_anti-armor",
				bounty = 100,
			
				proficiency = WEAPON_PROFICIENCY_PERFECT
			}
		end
		
		-- Melee Assassin
		if scripted_ents.GetStored("npc_vj_c_overwatch_assassin_melee") then
			jcms.npc_types.combine_rycch_meleeassassin = {
				portalSpawnWeight = 0.05,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_FODDER,
				cost = 1.1,
				swarmWeight = 0.1,
			
				class = "npc_vj_c_overwatch_assassin_melee",
				bounty = 40,
			
				proficiency = WEAPON_PROFICIENCY_GOOD
			}
		end

		-- Jump Trooper
		if scripted_ents.GetStored("npc_vj_c_overwatch_jumptrooper") then
			jcms.npc_types.combine_rycch_jumptrooper = {
				portalSpawnWeight = 0.2,
				faction = "combine",
				
				danger = jcms.NPC_DANGER_FODDER,
				cost = 1.3,
				swarmWeight = 0.4,
			
				class = "npc_vj_c_overwatch_jumptrooper",
				bounty = 75,
			
				proficiency = WEAPON_PROFICIENCY_VERY_GOOD
			}
		end
	end
	-- // }}}
	

	-- // Grappling Hook {{{
	-- https://steamcommunity.com/sharedfiles/filedetails/?id=3371358666
	if scripted_ents.GetStored("ent_thefinals_grapplehook") then
		--Re-route their net-receive so we can make players falldamage immune.
		local oldF = net.Receivers["vmanip_tfgrap_start"]

		net.Receive("vmanip_tfgrap_start", function(len, ply) 
			oldF(len, ply)
			ply.noFallDamage = true
			timer.Simple(0.25, function() --First one isn't super reliable.
				if not IsValid(ply) then return end
				ply.noFallDamage = true
			end)
		end)
		hook.Add("PlayerSpawn", "jcms_TFGrap_SetCol", function(ply, transition)
			local isGrey = ply:GetNWString("jcms_class", "infantry") == "recon"

			local col = (isGrey and Color(100,100,100)) or jcms.util_ColorFromInteger(jcms.util_colorIntegerJCorp)
			ply:SetWeaponColor(Vector(col.r/255, col.g/255, col.b/255))
		end)
	end
	
	-- // }}}
end)
