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

-- // Antlion-Specific Functions {{{
	function jcms.npc_NearThumper(target) --This should be somewhat more performant than FindInSphere in this context - J
		local thumpers = ents.FindByClass("prop_thumper")
		local nPos = target:GetPos()
		for i, v in ipairs(thumpers) do
			if v:GetInternalVariable("m_bEnabled") and v:GetPos():DistToSqr(nPos) < 750^2 then --Radius is actually 1k but they can attack things at the edges.
				return v --Useful for CyberGuards to know which one I guess
			end
		end
		return false
	end

	function jcms.DischargeEffect(pos, duration, radius, intervalMin, intervalMax, beamCountMin, beamCountMax, thickMin, thickMax, lifeMin, lifeMax)
		-- // Defaults {{{
			--Pos is required, everything else is optional
			--Duration as nil or negative means it lasts forever.
			radius = radius or 250
			intervalMin = intervalMin or 0.5
			intervalMax = intervalMax or 2.1
			beamCountMin = beamCountMin or 3
			beamCountMax = beamCountMax or 10
			thickMin = thickMin or 3
			thickMax = thickMax or 5
			lifeMin = lifeMin or 0.1
			lifeMax = lifeMax or 0.15
		-- // }}}
		
		local discharge = ents.Create("point_tesla")

		discharge:SetPos(pos)
		discharge:SetKeyValue("texture", "trails/laser.vmt")
		discharge:SetKeyValue("m_Color", "255 255 255")
		discharge:SetKeyValue("m_flRadius", tostring(radius))
		discharge:SetKeyValue("interval_min", tostring(intervalMin))
		discharge:SetKeyValue("interval_max", tostring(intervalMax))
		discharge:SetKeyValue("beamcount_min", tostring(beamCountMin))
		discharge:SetKeyValue("beamcount_max", tostring(beamCountMax))
		discharge:SetKeyValue("thick_min", tostring(thickMin))
		discharge:SetKeyValue("thick_max", tostring(thickMax))
		discharge:SetKeyValue("lifetime_min", tostring(lifeMin))
		discharge:SetKeyValue("lifetime_max", tostring(lifeMax))

		discharge:Spawn()
		discharge:Activate()

		discharge:Fire("DoSpark", "", 0)
		discharge:Fire("TurnOn", "", 0)

		if duration and not(duration < 0) then 
			timer.Simple(duration, function()
				if IsValid(discharge) then
					discharge:Remove()
				end
			end)
		end

		return discharge --So we can still mess with the discharge entity directly if we really need to.
	end

	function jcms.npc_CyberGuard_Think(npc)
		-- // Buffing allies {{{
			local sched = npc:GetCurrentSchedule()
			if (sched==252 or sched==104 or sched==324 or sched==81) and (npc.jcms_cyberguardLastAtk==nil or (CurTime()-npc.jcms_cyberguardLastAtk)>=15) then
				npc:SetSchedule(SCHED_RANGE_ATTACK1)
				
				timer.Simple(1.0, function()
					if IsValid(npc) and npc:GetSequenceName(npc:GetSequence()) == "fireattack" then
						npc.jcms_cyberguardLastAtk = CurTime()
						
						for i, ent in ipairs(ents.FindInSphere(npc:WorldSpaceCenter(), 800)) do
							if jcms.team_GoodTarget(ent) and jcms.team_SameTeam(ent, npc) and npc ~= ent then
								jcms.npc_AddBulletShield(ent, 4)
							end
						end
					end
				end)
			end
		-- // }}}

		-- // Disabling thumpers {{{
			local nearThumper = jcms.npc_NearThumper(npc)
			if nearThumper then
				nearThumper:SetSaveValue("m_bEnabled", false)

				nearThumper:EmitSound("coast.thumper_shutdown")
				npc:EmitSound("d3_citadel.weapon_zapper_charge_node")
				local soundPatch = CreateSound(nearThumper ,"NPC_AttackHelicopter.CrashingAlarm1")
				soundPatch:PlayEx(0.75, 90)

				local ed = EffectData()
				ed:SetStart(npc:WorldSpaceCenter())
				ed:SetOrigin(nearThumper:WorldSpaceCenter())
				util.Effect("jcms_tesla", ed)

				for i=1, 5, 1 do
					jcms.DischargeEffect(nearThumper:GetPos() + Vector(0, 0, 100) + VectorRand(-1, 1):GetNormalized() * 65, 30)
				end

				timer.Simple(30, function()
					if IsValid(soundPatch) then
						soundPatch:Stop()
					end
					
					if IsValid(nearThumper) then
						nearThumper:SetSaveValue("m_bEnabled", true)
					end
				end)
			end
		-- // }}}
	end

	function jcms.npc_AntlionFodder_Think(npc)
		if npc:GetInternalVariable("startburrowed") and npc.jcms_shouldUnburrow then 
			npc:Fire("Unburrow")
		end

		local enemy = npc:GetEnemy()
		if not IsValid(enemy) or not jcms.npc_NearThumper(enemy) then return end

		npc:SetSaveValue("vLastKnownLocation", enemy:GetPos())
		npc:IgnoreEnemyUntil(enemy, CurTime() + 10)
		npc:SetSchedule(SCHED_TAKE_COVER_FROM_ORIGIN)
	end

	function jcms.npc_AntlionBeamAttack(npc, targetPos, range, fromAngle, toAngle, duration)
		local beam = ents.Create("jcms_beam")
		beam:SetPos(npc:WorldSpaceCenter())
		beam:SetBeamAttacker(npc)
		beam:Spawn()
		beam.Damage = 20
		beam.friendlyFireCutoff = 100 --Don't hurt guards/other high-HP targets. Fodder's fine though.
		beam:SetBeamLength(range)

		npc:EmitSound("ambient/energy/weld"..math.random(1,2)..".wav", 140, 105, 1)

		beam:FireBeamSweep(targetPos, fromAngle, toAngle, duration)
		
		return beam
	end

	--todo: Maybe playbackrate scaling could be used to scale up the threat of fodder lategame?
-- // }}}

jcms.npc_types.antlion_worker = {
	portalSpawnWeight = 0.25,
	faction = "antlion",
	
	danger = jcms.NPC_DANGER_FODDER,
	suppressSwarmPortalEffect = true,
	cost = 0.9,
	swarmWeight = 0.34,

	class = "npc_antlion",
	bounty = 50,
	
	episodes = true,

	preSpawn = function(npc)
		if not npc.jcms_fromPortal then
			npc:SetKeyValue("startburrowed", "1")
		end

		if jcms.HasEpisodes() then
			npc:SetKeyValue("spawnflags", bit.bor(npc:GetKeyValues().spawnflags, 262144))
		end
	end,

	postSpawn = function(npc)
		npc:SetSkin( math.random(0, npc:SkinCount() ))

		if not jcms.HasEpisodes() then
			npc:SetMaxHealth(60)
			npc:SetHealth(60)
		end
	end,

	timerMin = 0.2,
	timerMax = 5.6,
	timedEvent = function(npc)
		if not npc.jcms_fromPortal then
			npc:Fire "Unburrow"
			npc.jcms_shouldUnburrow = true

			timer.Simple(60, function() --fall-back
				if IsValid(npc) and npc:GetInternalVariable("startburrowed") then 
					npc:Remove()
				end
			end)
		end
	end,
	
	think = function(npc, state)
		if npc:GetInternalVariable("startburrowed") and npc.jcms_shouldUnburrow then 
			npc:Fire("Unburrow")
		end

		if npc:GetCurrentSchedule() == SCHED_COMBAT_FACE then
			npc:SetSchedule(SCHED_CHASE_ENEMY)
		end
	end
}

jcms.npc_types.antlion_drone = {
	portalSpawnWeight = 1.0,
	faction = "antlion",
	
	danger = jcms.NPC_DANGER_FODDER,
	cost = 0.3,
	swarmWeight = 1,

	class = "npc_antlion",
	suppressSwarmPortalEffect = true,
	bounty = 15,

	preSpawn = function(npc)
		if not npc.jcms_fromPortal then
			npc:SetKeyValue("startburrowed", "1")
		end
	end,

	think = function(npc)
		jcms.npc_AntlionFodder_Think(npc)
	end,

	postSpawn = function(npc)
		npc:SetSkin( math.random(0, npc:SkinCount() ))
		npc.jcms_dmgMult = 3
	end,

	timerMin = 0.1,
	timerMax = 3.2,
	timedEvent = function(npc)
		if not npc.jcms_fromPortal then
			npc:Fire "Unburrow"
			npc.jcms_shouldUnburrow = true
			
			timer.Simple(60, function() --fall-back
				if IsValid(npc) and npc:GetInternalVariable("startburrowed") then 
					npc:Remove()
				end
			end)
		end
	end
}

jcms.npc_types.antlion_waster = {
	portalSpawnWeight = 1.33,
	faction = "antlion",

	danger = jcms.NPC_DANGER_FODDER,
	suppressSwarmPortalEffect = true,
	cost = 0.15,
	swarmWeight = 1.2,
	
	class = "npc_antlion",
	bounty = 5,

	preSpawn = function(npc)
		if not npc.jcms_fromPortal then
			npc:SetKeyValue("startburrowed", "1")
		end
	end,

	think = function(npc)
		jcms.npc_AntlionFodder_Think(npc)
	end,

	postSpawn = function(npc)
		npc:SetSkin( math.random(0, npc:SkinCount() ))
		npc:SetModelScale(0.63)
		npc:SetColor( Color(168, 125, 59) )
		npc:SetMaxHealth( npc:Health() / 2 )
		npc:SetHealth( npc:GetMaxHealth() )

		local timerName = "jcms_anltion_fastThink_" .. tostring(npc:EntIndex())
		timer.Create(timerName, 0.05, 0, function() 
			if not IsValid(npc) then 
				timer.Remove(timerName)
				return 
			end

			local sched = npc:GetCurrentSchedule()

			if sched == 126 or sched == 125 or sched == 41 then
				npc:SetPlaybackRate(1.5)
			end
		end)

		npc.jcms_dmgMult = 2
	end,
	
	takeDamage = function(npc, dmg)
		dmg:SetDamageType(DMG_ALWAYSGIB)
	end,

	timerMin = 0.1,
	timerMax = 1.2,
	timedEvent = function(npc)
		if not npc.jcms_fromPortal then
			npc:Fire "Unburrow"
			npc.jcms_shouldUnburrow = true
			
			timer.Simple(60, function() --fall-back
				if IsValid(npc) and npc:GetInternalVariable("startburrowed") then 
					npc:Remove()
				end
			end)
		end
	end,
}

jcms.npc_types.antlion_guard = {
	faction = "antlion",
	
	class = "npc_antlionguard",
	suppressSwarmPortalEffect = true,
	bounty = 350,
	
	danger = jcms.NPC_DANGER_BOSS,
	cost = 6,
	swarmWeight = 1,
	swarmLimit = 3,
	portalScale = 4,
	
	preSpawn = function(npc)
		if not npc.jcms_fromPortal then
			npc:SetKeyValue("startburrowed", "1")
		end
	end,

	postSpawn = function(npc)
		--todo: Guards seem to like getting stuck in doorways/trying to nav to people they can't reach.
		--It would be better if we detected that and made them hide or patrol instead.
		--Will need to apply to all guards (default, cyber, ultracyber)
		jcms.npc_GetRowdy(npc)
		
		local hp = math.ceil(npc:GetMaxHealth()*1.5)
		npc:SetMaxHealth(hp)
		npc:SetHealth(hp)
		
		npc:SetNWString("jcms_boss", "antlion_guard")
	end,

	takeDamage = function(npc, dmg)
		timer.Simple(0, function()
			if IsValid(npc) then
				npc:SetNWFloat("HealthFraction", npc:Health() / npc:GetMaxHealth())
			end
		end)
	end,

	timerMin = 0.1,
	timerMax = 1.2,
	timedEvent = function(npc) --Not replicated for cyberguards because they're teleported in by mafia.
		if not npc.jcms_fromPortal then
			npc:Fire "Unburrow"
			npc.jcms_shouldUnburrow = true

			timer.Simple(60, function() --fall-back
				if IsValid(npc) and npc:GetInternalVariable("startburrowed") then 
					npc:Remove()
				end
			end)
		end
	end,

	think = function(npc) 
		if npc:GetInternalVariable("startburrowed") and npc.jcms_shouldUnburrow then 
			npc:Fire("Unburrow")
		end
	end,
	
	check = function(director)
		return jcms.npc_capCheck("npc_antlionguard", 12)
	end
}

jcms.npc_types.antlion_cyberguard = {
	faction = "antlion",
	
	class = "npc_antlionguard",
	bounty = 300,
	
	danger = jcms.NPC_DANGER_BOSS,
	cost = 5,
	swarmWeight = 0.8,
	swarmLimit = 2,
	portalScale = 3,

	preSpawn = function(npc)
		npc:SetMaterial("models/jcms/cyberguard")
	end,

	postSpawn = function(npc)
		jcms.npc_GetRowdy(npc)
		
		local hp = math.ceil( npc:GetMaxHealth())
		npc:SetMaxHealth(hp)
		npc:SetHealth(hp)
		
		npc:SetNWString("jcms_boss", "antlion_cyberguard")
	end,

	think = function(npc, state)
		jcms.npc_CyberGuard_Think(npc)
	end,
	
	scaleDamage = function(npc, hitGroup, dmgInfo)
		local inflictor = dmgInfo:GetInflictor()
		if not IsValid(inflictor) then return end 

		local attkVec = npc:GetPos() - inflictor:GetPos()
		attkVec.z = 0
		
		local attkNorm = attkVec:GetNormalized()
		local npcAng = npc:GetAngles():Forward()

		npc:EmitSound("Computer.BulletImpact")

		local effectdata = EffectData()
		effectdata:SetEntity(npc)
		effectdata:SetOrigin(dmgInfo:GetDamagePosition() - attkNorm)
		effectdata:SetStart(dmgInfo:GetDamagePosition() + attkNorm )
		effectdata:SetSurfaceProp(29)
		effectdata:SetDamageType(dmgInfo:GetDamageType())
		
		util.Effect("impact", effectdata)
		
		local dmg = dmgInfo:GetDamage()
		if dmg > 0.3 then
			dmgInfo:SetDamage( math.max(dmg - 4, 0.3) )
		end
		
		timer.Simple(0, function()
			if IsValid(npc) then
				npc:SetNWFloat("HealthFraction", npc:Health() / npc:GetMaxHealth())
			end
		end)
	end,
	
	check = function(director)
		return jcms.npc_capCheck("npc_antlionguard", 12)
	end
}

jcms.npc_types.antlion_ultracyberguard = {
	faction = "antlion",
	
	class = "npc_antlionguard",
	bounty = 600,
	
	danger = jcms.NPC_DANGER_RAREBOSS,
	cost = 10,
	swarmWeight = 1,
	swarmLimit = 1,
	portalScale = 5,

	postSpawn = function(npc)
		jcms.npc_GetRowdy(npc)
		
		local hp = math.ceil( npc:GetMaxHealth() * 1.25 )
		npc:SetMaxHealth(hp)
		npc:SetHealth(hp)
		npc:SetModel("models/jcms/ultracyberguard.mdl")

		npc.jcms_dmgMult = 0.75
		npc.jcms_uCyberguard_nextBeam = CurTime() -- + 10
		npc.jcms_uCyberguard_stage2 = false

		npc:SetNWString("jcms_boss", "antlion_ultracyberguard")
	end,

	think = function(npc, state)
		jcms.npc_CyberGuard_Think(npc) --Base think for cyberguard behaviours

		-- // Buffing bosses {{{
			for i, ent in ipairs(ents.FindInSphere(npc:WorldSpaceCenter(), 800)) do
				if not(ent == npc) and ent:GetMaxHealth() > 250 and ent:GetNWInt("jcms_sweeperShield_max", -1) == -1 and jcms.team_GoodTarget(ent) and jcms.team_SameTeam(ent, npc) then
					local ed = EffectData()
					ed:SetStart(npc:WorldSpaceCenter())
					ed:SetOrigin(ent:WorldSpaceCenter())
					util.Effect("jcms_tesla", ed)

					-- todo: Better sound effects
					ent:EmitSound("d3_citadel.weapon_zapper_charge_node")
					
					jcms.npc_SetupSweeperShields(ent, 100, 10, 10, jcms.factions_GetColorInteger("antlion"))
				end
			end
		-- // }}}

		-- // Laser Beams {{{
			local enemy = npc:GetEnemy() 
			if IsValid(enemy) and npc.jcms_uCyberguard_nextBeam < CurTime() then 
				local ePos = npc:Visible(enemy) and enemy:WorldSpaceCenter() + enemy:GetVelocity()*0.5 or npc:GetEnemyLastSeenPos(enemy)

				local fromAngle = math.random()<0.5 and math.Rand(0, 0.15) or math.Rand(0.5, 0.8)
				local toAngle = (math.random()<0.5 and 1 or -1) * 32

				for i=1, (npc.jcms_uCyberguard_stage2 and 2) or 1, 1 do 
					toAngle = (i == 1 and toAngle) or -1 * toAngle

					local beam = jcms.npc_AntlionBeamAttack(npc, ePos, 2000, fromAngle, toAngle, 4)
					beam:SetPos(npc:GetBonePosition(2))
					beam:AddEffects( EF_FOLLOWBONE )
					beam:SetParent(npc, 1)
				end

				npc.jcms_uCyberguard_nextBeam = CurTime() + ((npc.jcms_uCyberguard_stage2 and 3) or 5)
			end
		-- // }}}
	end,

	takeDamage = function(npc, dmgInfo) 
		if not npc.jcms_uCyberguard_stage2 and npc:Health() - dmgInfo:GetDamage() < npc:GetMaxHealth()/2 then 
			--PLACEHOLDER
			local ed = EffectData()
			ed:SetEntity(npc)
			ed:SetFlags(1)
			ed:SetColor(jcms.factions_GetColorInteger("antlion"))
			util.Effect("jcms_shieldeffect", ed)

			npc:EmitSound("npc/antlion_guard/antlion_guard_shellcrack" .. tostring(math.random(1,2)) .. ".wav")
			npc.jcms_uCyberguard_stage2 = true 
		end
	end,

	scaleDamage = function(npc, hitGroup, dmgInfo)
		local inflictor = dmgInfo:GetInflictor()
		local attkVec = IsValid(inflictor) and (npc:GetPos() - inflictor:GetPos()) or Vector(0, 0, 1)
		attkVec.z = 0
		
		local attkNorm = attkVec:GetNormalized()
		local npcAng = npc:GetAngles():Forward()

		npc:EmitSound("Computer.BulletImpact")

		local effectdata = EffectData()
		effectdata:SetEntity(npc)
		effectdata:SetOrigin(dmgInfo:GetDamagePosition() - attkNorm)
		effectdata:SetStart(dmgInfo:GetDamagePosition() + attkNorm )
		effectdata:SetSurfaceProp(29)
		effectdata:SetDamageType(dmgInfo:GetDamageType())
		
		util.Effect("impact", effectdata)
		
		local dmg = dmgInfo:GetDamage()
		if dmg > 0.3 then
			dmgInfo:SetDamage( math.max(dmg - 4, 0.3) )
		end
		
		timer.Simple(0, function()
			if IsValid(npc) then
				npc:SetNWFloat("HealthFraction", npc:Health() / npc:GetMaxHealth())
			end
		end)
	end
}

jcms.npc_types.antlion_reaper = {
	portalSpawnWeight = 0.1,
	faction = "antlion",
	
	danger = jcms.NPC_DANGER_STRONG,
	cost = 1.75,
	swarmWeight = 0.3,
	portalScale = 1.5,

	class = "npc_jcms_reaper",
	bounty = 75,

	postSpawn = function(npc)
		npc:SetMaxLookDistance(3000)
		
		npc.jcms_maxScaledDmg = 65
	end
}
