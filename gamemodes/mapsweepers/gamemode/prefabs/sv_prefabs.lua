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

-- // Prefabs {{{

	jcms.prefabs = {
		wall_charger = {
			natural = true,
			weight = 0.45,

			check = function(area)
				local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 48, 32)
				
				if #wallspots > 0 then
					local rng = math.random(#wallspots)
					return true, { pos = wallspots[rng], normal = normals[rng] }
				else
					return false
				end
			end,

			stamp = function(area, data)
				local ent = ents.Create("item_healthcharger")
				if not IsValid(ent) then return end

				ent:SetPos(data.pos)
				ent:SetAngles(data.normal:Angle())
				ent:Spawn()
				return ent
			end
		},

		shop = {
			natural = true,
			weight = 9999999,
			limit = function()
				return (jcms.runprogress_GetDifficulty() <= 0.9 and 2) or 1 
			end,
			limitMulBySize = true,
			onlyMainZone = true,

			check = function(area)
				if not jcms.mapgen_ValidArea(area) then return false end

				local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 48, 128)
				
				if #wallspots > 0 then
					local rng = math.random(#wallspots)
					return true, { pos = wallspots[rng], normal = normals[rng] }
				else
					return false
				end
			end,

			stamp = function(area, data)
				local ent = ents.Create("jcms_shop")
				if not IsValid(ent) then return end

				data.pos = data.pos + data.normal * 14
				ent:SetPos(data.pos)
				ent:DropToFloor()
				ent:SetAngles(data.normal:Angle())
				ent:Spawn()
				return ent
			end
		},

		cash_cache = {
			natural = true,
			weight = 0.27,

			check = function(area)
				local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 48, 32)
				
				if #wallspots > 0 then
					local rng = math.random(#wallspots)
					return true, { pos = wallspots[rng], normal = normals[rng] }
				else
					return false
				end
			end,

			stamp = function(area, data)
				local ent = ents.Create("jcms_terminal")
				if not IsValid(ent) then return end

				ent:SetPos(data.pos)
				ent:SetAngles(data.normal:Angle())
				
				-- Ported over from previous 'jcms_cache' entity.
				local correctedAngle = ent:GetAngles()
				correctedAngle:RotateAroundAxis( correctedAngle:Up(), 180 )
				correctedAngle:RotateAroundAxis( correctedAngle:Right(), 90 )
				ent:SetAngles( correctedAngle )

				ent:Spawn()
				ent:SetColor(Color(255, 64, 64))
				ent:InitAsTerminal("models/props_combine/combine_emitter01.mdl", "cash_cache")
				return ent
			end
		},

		gambling = {
			natural = true,
			weight = 0.012,

			check = function(area)
				local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 48, 32)
				
				if #wallspots > 0 then
					local rng = math.random(#wallspots)
					return true, { pos = wallspots[rng], normal = normals[rng] }
				else
					return false
				end
			end,

			stamp = function(area, data)
				local ent = ents.Create("jcms_terminal")
				if not IsValid(ent) then return end

				ent:SetPos(data.pos + data.normal * 7)
				local correctedAngle = data.normal:Angle()
				correctedAngle:RotateAroundAxis( correctedAngle:Up(), -90 )
				correctedAngle:RotateAroundAxis( correctedAngle:Forward(), -4 )
				ent:SetAngles( correctedAngle )

				ent:Spawn()
				ent:SetColor(Color(121, 64, 255))
				ent:InitAsTerminal("models/props_c17/cashregister01a.mdl", "gambling")
				ent.jcms_hackType = nil
				return ent
			end
		},

		upgrade_station = {
			natural = true,
			weight = 0.14,

			check = function(area)
				local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 48, 32)

				if #wallspots > 0 then
					local rng = math.random(#wallspots)
					return true, { pos = wallspots[rng], normal = normals[rng] }
				else
					return false
				end
			end,

			stamp = function(area, data)
				local ent = ents.Create("jcms_terminal")
				if not IsValid(ent) then return end

				ent:SetPos(data.pos)
				ent:SetAngles(data.normal:Angle())

				ent:Spawn()
				ent:InitAsTerminal("models/props_combine/combine_intwallunit.mdl", "upgrade_station")
				ent.jcms_hackType = nil
				return ent
			end
		},

		respawn_chamber = {
			natural = true,
			weight = 0.1,

			check = function(area)
				local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 24, 32)

				if #wallspots > 0 then
					local rng = math.random(#wallspots)
					return true, { pos = wallspots[rng], normal = normals[rng] }
				else
					return false
				end
			end,

			stamp = function(area, data)
				local ent = ents.Create("jcms_terminal")
				if not IsValid(ent) then return end

				ent:SetPos(data.pos + data.normal * 32)
				ent:DropToFloor()
				ent:SetAngles(data.normal:Angle())

				ent:SetColor( Color(222, 104, 238) )

				ent.respawnBeaconUsedUp = false
				ent.initializedAsRespawnBeacon = false

				AccessorFunc(ent, "jcms_respawnBeaconBusy", "RespawnBusy", FORCE_BOOL)
				
				function ent:DoPreRespawnEffect(ply, duration)
					jcms.DischargeEffect(self:WorldSpaceCenter(), duration)
					self:SetSequence("close")
					self:EmitSound("doors/doormove2.wav")
				end

				function ent:DoPostRespawnEffect(ply)
					local ed = EffectData()
					ed:SetColor(jcms.util_colorIntegerJCorp)
					ed:SetFlags(0)
					ed:SetEntity(ply)
					util.Effect("jcms_spawneffect", ed)
					jcms.net_SendRespawnEffect(ply)
					self.respawnBeaconUsedUp = true
					self:SetNWString("jcms_terminal_modeData", "0")
				end

				function ent:GetRespawnPosAng(ply)
					local ang = self:GetAngles()
					return self:GetPos() + ang:Up() * 9.175108 + ang:Forward() * 10
				end

				ent:Spawn()
				ent:InitAsTerminal("models/props_lab/hev_case.mdl", "respawn_chamber")
				return ent
			end
		},

		gunlocker = {
			natural = true,
			weight = 0.09,

			check = function(area)
				local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 60, 32)
				
				if #wallspots > 0 then
					local rng = math.random(#wallspots)
					return true, { pos = wallspots[rng], normal = normals[rng] }
				else
					return false
				end
			end,

			stamp = function(area, data)
				local ent = ents.Create("jcms_terminal")
				if not IsValid(ent) then return end

				ent:Spawn()
				ent:SetColor(Color(87, 83, 34))
				ent:InitAsTerminal("models/props/de_nuke/nuclearcontrolbox.mdl", "gunlocker")
				ent:SetPos(data.pos)
				ent:SetAngles(data.normal:Angle())

				return ent
			end
		},
		
		barricades = {
			natural = true,
			weight = 0.12,

			check = function(area)
				return area:IsFlat() and ( area:GetSizeX()*area:GetSizeY() ) > 60000
			end,

			stamp = function(area, data)
				local squareVariant = math.random() < 0.37
				
				if squareVariant then
					local squish = math.Rand(0.25, 0.5)
					local inverseVariant = math.random() < 0.15
					for i=1,4 do
						if math.random() < 0.25 then continue end
						local v = LerpVector(squish, area:GetCorner(i-1), area:GetCenter())
						
						for j=1,2 do
							local prop = ents.Create("jcms_breakable")
							local ang = Angle(0, (j==1 and 90 or 0) + (inverseVariant and (i*90) or (i*90+180)), 0)
							prop:SetPos(v + ang:Right()*64)
							prop:SetAngles(ang)
							prop:SetModel("models/props_phx/construct/concrete_barrier0"..(math.random() < 0.33 and 0 or 1)..".mdl")
							prop:SetMaxHealth(300)
							prop:SetHealth(300)
							prop:Spawn()
						end
						
						if math.random() < 0.3 then
							-- Extra
							local extrapos = LerpVector(math.Rand(0.05, 0.15), v, area:GetCenter()) + Vector(math.random(-32, 32), math.random(-32, 32), 0)
							local extraangle = Angle(0, math.random(1, 4)*90 + math.random(-15, 15), 0)
							if math.random() < 0.35 then
								local prop = ents.Create("item_item_crate")
								prop:SetPos(extrapos)
								prop:SetAngles(extraangle)
								prop:SetKeyValue("ItemClass", "item_dynamic_resupply")
								prop:SetKeyValue("ItemCount", math.random()<0.1 and 2 or 1)
								prop:Spawn()
							else
								local prop = ents.Create("prop_physics")
								prop:SetPos(extrapos)
								prop:SetAngles(extraangle)
								prop:SetModel(math.random()<0.7 and "models/props_c17/oildrum001.mdl" or "models/props_c17/oildrum001_explosive.mdl")
								prop:Spawn()
							end
						end
					end
				else
					local v = area:GetRandomPoint()
					local prop = ents.Create("jcms_breakable")
					prop:SetPos(v)
					prop:SetAngles(Angle(0, math.random(1, 4)*90, 0))
					prop:SetModel("models/props_phx/construct/concrete_barrier0"..(math.random() < 0.33 and 0 or 1)..".mdl")
					prop:SetMaxHealth(350)
					prop:SetHealth(350)
					prop:Spawn()
				end
			end
		},
		
		oil = {
			natural = true,
			weight = 0.23,

			check = function(area)
				return area:IsFlat() and ( area:GetSizeX()*area:GetSizeY() ) > 60000
			end,

			stamp = function(area, data)
				local v = area:GetCenter() + area:GetRandomPoint()
				v:Mul(0.5)
				
				local prop = ents.Create("prop_physics")
				prop:SetPos(v)
				prop:SetAngles(Angle(0, math.random()*360, 0))
				prop:SetModel(math.random()<0.1 and "models/props_junk/propane_tank001a.mdl" or (math.random()<0.3 and "models/props_c17/oildrum001.mdl") or "models/props_c17/oildrum001_explosive.mdl")
				prop:Spawn()
				
				if math.random() < 1.3 then
					local prop = ents.Create("prop_physics")
					local a = math.random()*math.pi*2
					local away = math.random(31, 42)
					local cos, sin = math.cos(a)*away, math.sin(a)*away
					prop:SetPos(v + Vector(cos, sin, 0))
					prop:SetAngles(Angle(0, math.random()*360, 0))
					prop:SetModel(math.random()<0.1 and "models/props_junk/gascan001a.mdl" or (math.random()<0.4 and "models/props_c17/oildrum001.mdl") or "models/props_c17/oildrum001_explosive.mdl")
					prop:Spawn()
					
					if math.random() < 1 then
						local prop = ents.Create("prop_physics")
						local a = a + math.Rand(0.4, 0.6)*math.pi
						local away = math.random(30, 36)
						local cos, sin = math.cos(a)*away, math.sin(a)*away
						prop:SetPos(v + Vector(cos, sin, 16))
						prop:SetAngles(Angle(math.random()*360, math.random()*360, 90))
						prop:SetModel(math.random()<0.25 and "models/props_junk/gascan001a.mdl" or (math.random()<0.5 and "models/props_c17/oildrum001.mdl") or "models/props_c17/oildrum001_explosive.mdl")
						prop:Spawn()
					end
				end
			end
		},

		supplies = {
			natural = true,
			weight = 1.5,

			check = function(area)
				return #area:GetVisibleAreas() <= jcms.mapgen_GetVisData().avg
			end,

			stamp = function(area, data)
				local v = area:GetCenter() + area:GetRandomPoint()
				v:Mul(0.5)

				local a = Angle( math.Rand(-5, 5), math.random() * 360, math.Rand(-5, 5) )
				local prop = ents.Create("item_item_crate")
				prop:SetPos(v)
				prop:SetAngles(a)
				prop:SetKeyValue("ItemClass", "jcms_dynamicsupply")
				prop:SetKeyValue("ItemCount", math.random() < 0.25 and 4 or 3)
				prop:Spawn()
			end
		},

		ammocrate = {
			natural = true,
			weight = 0.08,

			check = function(area)
				if not jcms.mapgen_ValidArea(area) then return false end
				local c1, c2, c3, c4 = area:GetCorner(1), area:GetCorner(2), area:GetCorner(3), area:GetCorner(0)
				if math.max(c1.z, c2.z, c3.z, c4.z) - math.min(c1.z, c2.z, c3.z, c4.z) > 34 then
					return false
				end

				local wallspots, normals = jcms.prefab_GetWallSpotsFromArea(area, 48, 128)
				
				if #wallspots > 0 then
					local rng = math.random(#wallspots)
					return true, { pos = wallspots[rng], normal = normals[rng] }
				else
					return false
				end
			end,

			stamp = function(area, data)
				local ent = ents.Create("jcms_ammo_crate")
				if not IsValid(ent) then return end

				data.pos = data.pos + data.normal * 24
				data.pos.z = data.pos.z - 32
				ent:Spawn()
				ent:SetPos(data.pos)
				ent:SetAngles(data.normal:Angle())
				return ent
			end
		},

		npc_portal = {
			natural = true,
			weight = 0.3,
			
			onlyMainZone = true,

			check = function(area)
				return ( area:GetSizeX()*area:GetSizeY() ) > 400
			end,

			stamp = function(area, data)
				local ent = ents.Create("jcms_npcportal")
				if not IsValid(ent) then return end

				if not jcms.director or math.random() < 0.006 then
					local factionNames = jcms.factions_GetOrder()
					ent:SetSpawnerType(factionNames[ math.random(1, #factionNames) ])
				else
					ent:SetSpawnerType(jcms.director.faction)
				end

				local v = jcms.mapgen_AreaPointAwayFromEdges(area, 64)
				v.z = v.z + 24
				ent:SetPos(v)
				ent:Spawn()
				return ent
			end
		},

		thumper = {
			check = function(area)
				local center = jcms.mapgen_AreaPointAwayFromEdges(area, 200)
				local tr = util.TraceHull { start = center, endpos = center + Vector(0, 0, 100), mins = Vector(-24, -24, 0), maxs = Vector(24, 24, 64) }
				
				if not tr.Hit then
					return true, center
				else
					return false
				end
			end,

			stamp = function(area, center)
				local thumper = ents.Create("prop_thumper")
				if not IsValid(thumper) then return end
				local terminal = ents.Create("jcms_terminal")
				thumper:SetPos(center)
				thumper:SetAngles( Angle(0, math.random(1, 4)*90, 0) )
				local thumperPos, thumperAngles = thumper:GetPos(), thumper:GetAngles()
				thumper:Fire("Disable")
				terminal:SetPos(thumperPos + thumperAngles:Right()*72)

				thumper:Spawn()
				terminal:InitAsTerminal("models/props_combine/breenconsole.mdl", "thumper_controls", function(ent, cmd, data, ply)
					thumper:Fire("Enable")
					thumper.jcms_thumperEnabled = true
					return true, "1"
				end)
				terminal:SetAngles( thumperAngles )
				terminal:Spawn()
				terminal:SetNWEntity("jcms_link", thumper)

				return thumper
			end
		},

		flashpoint = {
			check = function(area)
				local centre = jcms.mapgen_AreaPointAwayFromEdges(area, 150)

				local checkLength = 100
				local checkAngle = Angle(0, 0, 30)
				local hullMins = Vector(-32, -32, 2)
				local hullMaxs = Vector(32, 32, 16)

				local traceResult = {}
				local traceData = {
					start = centre + Vector(0,0,5),
					mask = MASK_PLAYERSOLID_BRUSHONLY,
					output = traceResult,
					mins = hullMins,
					maxs = hullMaxs
				}
				
				local sidewaysVector = Vector(checkLength, 0, 0)
				for j=1, 12 do
					sidewaysVector:Rotate(checkAngle)
					traceData.endpos = traceData.start + sidewaysVector
					util.TraceLine(traceData)

					if traceResult.Fraction < 1 or traceResult.StartSolid then
						return false
					end
				end

				traceData.endpos = centre + Vector(0, 0, 256 - hullMaxs.z)
				util.TraceHull(traceData)
				if traceResult.Fraction < 1 or traceResult.StartSolid then
					return false
				end

				return true, area:GetCenter()
			end,

			stamp = function(area, center)
				local flashpoint = ents.Create("jcms_flashpoint")
				flashpoint:SetPos(center)
				flashpoint:Spawn()

				return flashpoint
			end
		},

		thumpersabotage = {
			check = function(area)
				local center = jcms.mapgen_AreaPointAwayFromEdges(area, 128)
				local tr = util.TraceHull { start = center, endpos = center + Vector(0, 0, 100), mins = Vector(-24, -24, 0), maxs = Vector(24, 24, 64) }
				
				if not tr.Hit then
					return true, center
				else
					return false
				end
			end,

			stamp = function(area, center)
				local thumper = ents.Create("prop_thumper")
				if not IsValid(thumper) then return end
				thumper:SetPos(center)
				thumper:SetAngles( Angle(0, math.random(1, 4)*90, 0) )
				local thumperPos, thumperAngles = thumper:GetPos(), thumper:GetAngles()
				thumper:Fire("Enable")
				thumper:Spawn()

				thumper:SetSaveValue("m_takedamage", 1)
				thumper:SetMaxHealth(750)
				thumper:SetHealth(750)
				thumper.jcms_PostTakeDamage = function(self, dmg)
					local finalDmg = dmg:GetDamage()

					local inflictor = dmg:GetInflictor() 
					local attacker = dmg:GetAttacker()

					if (IsValid(inflictor) and inflictor:IsPlayer() and jcms.team_NPC(inflictor))
					or (IsValid(attacker) and attacker:IsPlayer() and jcms.team_NPC(attacker)) then
						finalDmg = 0
						return 0
					end

					if bit.band(dmg:GetDamageType(), bit.bor(DMG_SHOCK, DMG_BLAST, DMG_BLAST_SURFACE, DMG_ACID))==0 then
						finalDmg = finalDmg * 0.2
					end
					
					if bit.band(dmg:GetDamageType(), DMG_BULLET, DMG_BUCKSHOT) then
						finalDmg = math.max(1, (finalDmg - 5) * 0.5)
					end

					if not(bit.band(dmg:GetDamageType(), bit.bor(DMG_BLAST, DMG_BLAST_SURFACE))==0) then --Less damage falloff for explosives.
						local dmgPos = dmg:GetDamagePosition()
						local entPos = self:WorldSpaceCenter()
						local dist = entPos:Distance(dmgPos)

						finalDmg = finalDmg * (1 + dist/75)
					end
					
					if not self.jcms_ThumperTookDmgBefore and finalDmg > 100 then
						self:EmitSound("npc/attack_helicopter/aheli_damaged_alarm1.wav", 100, 90, 1)
						self.jcms_ThumperTookDmgBefore = true
						
						local ed2 = EffectData()
						ed2:SetMagnitude(0.85)
						ed2:SetOrigin(self:WorldSpaceCenter() + VectorRand(-32, 32))
						ed2:SetRadius(math.random(64, 128))
						ed2:SetNormal(self:GetAngles():Up())
						ed2:SetFlags(1)
						util.Effect("jcms_blast", ed2)
						
						ed2:SetOrigin(self:WorldSpaceCenter() + VectorRand(-64, 64))
						util.Effect("Explosion", ed2)
					end
					
					local ed = EffectData()
					ed:SetOrigin(dmg:GetDamagePosition())
					local force = dmg:GetDamageForce()
					force:Normalize()
					force:Mul(-1)
					ed:SetScale(math.Clamp(math.sqrt(dmg:GetDamage()/25), 0.01, 1))
					ed:SetMagnitude(math.Clamp(math.sqrt(dmg:GetDamage()/10), 0.1, 10))
					ed:SetRadius(16)
					
					ed:SetNormal(force)
					util.Effect("Sparks", ed)

					finalDmg = math.Clamp(finalDmg, 0, 400)
					finalDmg = finalDmg / #team.GetPlayers(1)

					self:SetHealth( math.Clamp(self:Health() - finalDmg, 0, self:GetMaxHealth()) )
					
					self:SetNWFloat("HealthFraction", self:Health() / self:GetMaxHealth())

					if self:Health() < self:GetMaxHealth() * 0.85 then
						local interval = Lerp(thumper:Health()/thumper:GetMaxHealth(), 0.05, 2)

						local ed = EffectData()
						ed:SetEntity(thumper)
						ed:SetMagnitude(interval * 512) --Interval / 512
						ed:SetScale(0) --duration
						util.Effect("jcms_teslahitboxes_dur", ed) 
					end

					if self:Health() <= 0 then
						local maxtime = math.Rand(2, 3)
						
						self.jcms_PostTakeDamage = nil
						self:Fire("Disable")

						if IsValid(attacker) and attacker:IsPlayer() and jcms.team_JCorp_player(attacker) then
							jcms.net_NotifyGeneric(attacker, jcms.NOTIFY_DESTROYED, "#jcms.thumper")
						end
						
						for i=1, math.random(3, 4) do
							timer.Simple(maxtime/i, function()
								if IsValid(self) then
									local ed2 = EffectData()
									ed2:SetMagnitude(i==1 and 2.3 or 0.85+i/8)
									ed2:SetOrigin(self:WorldSpaceCenter() + VectorRand(-32, 32))
									ed2:SetRadius(i==1 and 220 or math.random(64, 128))
									ed2:SetNormal(self:GetAngles():Up())
									ed2:SetFlags(i==1 and 3 or 1)
									util.Effect("jcms_blast", ed2)
									
									ed2:SetOrigin(self:WorldSpaceCenter() + VectorRand(-64, 64))
									util.Effect("Explosion", ed2)
								end
							end)
							
							timer.Simple(maxtime, function()
								if IsValid(self) then
									self:SetPos(self:GetPos() + Vector(math.Rand(-4, 4), math.Rand(-4, 4), math.Rand(-5, -2)))
									self:SetAngles(self:GetAngles() + AngleRand(-8, 8))
									self:Ignite(math.Rand(24, 60))
								end
							end)
						end
					end
				end

				return thumper
			end
		},

		zombiebeacon = {
			check = function(area)
				local center = jcms.mapgen_AreaPointAwayFromEdges(area, 300)
				local tr = util.TraceHull { start = center, endpos = center + Vector(0, 0, 100), mins = Vector(-24, -24, 0), maxs = Vector(24, 24, 64) }
				
				if not tr.Hit then
					return true, center
				else
					return false
				end
			end,

			stamp = function(area, center)
				local beacon = ents.Create("jcms_zombiebeacon")
				if not IsValid(beacon) then return end

				local tr = util.TraceLine({
					start = center + Vector(0,0,10),
					endpos = center - Vector(0,0,10),
					mask = MASK_SOLID_BRUSHONLY
				})
				local ang = tr.HitNormal:Angle()
				ang.pitch = ang.pitch - 270
				ang:RotateAroundAxis( tr.HitNormal, math.random(1, 4)*90 )

				beacon:SetAngles(ang)
				beacon:SetPos(center + tr.HitNormal * -math.random(4, 8))

				beacon:Spawn()
				return beacon
			end
		},

		rgg_mainframe = {
			check = function(area)
				return true, area:GetCenter()
			end,

			stamp = function(area, center)
				local mainframe = ents.Create("jcms_mainframe")
				if not IsValid(mainframe) then return end

				mainframe:SetPos(center) 
				mainframe:Spawn()

				return mainframe
			end
		}
	}

	function jcms.prefab_Check(type, area)
		return jcms.prefabs[ type ].check(area)
	end

	function jcms.prefab_ForceStamp(type, area, bonusData)
		return jcms.prefabs[ type ].stamp(area, bonusData)
	end

	function jcms.prefab_TryStamp(type, area)
		local can, bonusData = jcms.prefab_Check(type, area)

		if can then
			local ent = jcms.prefab_ForceStamp(type, area, bonusData)
			return true, ent
		else
			return false
		end
	end

	function jcms.prefab_GetNaturalTypes()
		local t = {}

		for name, data in pairs(jcms.prefabs) do
			if data.natural then
				table.insert(t, name)
			end
		end

		return t
	end

	function jcms.prefab_GetNaturalTypesWithWeights()
		local t = {}

		for name, data in pairs(jcms.prefabs) do
			if data.natural then
				t[name] = data.weight or 1.0
			end
		end

		return t
	end

	function jcms.prefab_GetWallSpotsFromArea(area, elevation, injectionDistance, subdivisionByUnits, conicDivergence, conicSubdivision)
		local wallspots = {}
		local normals = {}

		local center = area:GetCenter()
		center.z = center.z + elevation

		injectionDistance = injectionDistance or 16
		subdivisionByUnits = subdivisionByUnits or 128
		conicDivergence, conicSubdivision = conicDivergence, conicSubdivision or 2

		local xSpan, ySpan = area:GetSizeX(), area:GetSizeY()
		local xSteps, ySteps = math.max(1, math.floor(xSpan / subdivisionByUnits)), math.max(1, math.floor(ySpan / subdivisionByUnits))

		for x = 1, xSteps do
			for sign = -1, 1, 2 do
				local fromPos = center + Vector(math.Remap(x, 0, xSteps + 1, -xSpan/2, xSpan/2), 0, 0)
				local targetPos = fromPos + Vector(0, sign*(ySpan/2 + injectionDistance), 0)

				local s, pos, normal = jcms.prefab_CheckConicWallSpot(fromPos, targetPos, conicDivergence, conicSubdivision)

				if s then
					table.insert(wallspots, pos)
					table.insert(normals, normal)
				end
			end
		end

		for y = 1, ySteps do
			for sign = -1, 1, 2 do
				local fromPos = center + Vector(0, math.Remap(y, 0, ySteps + 1, -ySpan/2, ySpan/2), 0)
				local targetPos = fromPos + Vector(sign*(xSpan/2 + injectionDistance), 0, 0)

				local s, pos, normal = jcms.prefab_CheckConicWallSpot(fromPos, targetPos, conicDivergence, conicSubdivision)

				if s then
					table.insert(wallspots, pos)
					table.insert(normals, normal)
				end
			end
		end
		
		return wallspots, normals
	end

	function jcms.prefab_CheckConicWallSpot(fromPos, targetPos, divergence, subdivision)
		local tr_Main = util.TraceLine {
			start = fromPos,
			endpos = targetPos
		}

		if not tr_Main.HitWorld then return false end
		local normal = tr_Main.HitNormal
		
		local zThreshold = 0.2 -- walls cant be this tilted
		if normal.z > zThreshold or normal.z < -zThreshold then return false end
		
		local normalAngle = normal:Angle()
		local right, up = normalAngle:Right(), normalAngle:Up()

		local angleThreshold = 1.25
		divergence = divergence or 48
		subdivision = subdivision or 3

		for i = 1, subdivision do
			local dist = divergence / subdivision * i

			for j = 1, 2 do
				local tr_Adj = util.TraceLine {
					start = fromPos,
					endpos = targetPos + (j == 1 and right or up)*dist
				}
				
				if not tr_Adj.HitWorld then return false end
				if not normalAngle:IsEqualTol( tr_Adj.HitNormal:Angle(), angleThreshold ) then return false end
			end
		end

		return true, tr_Main.HitPos, tr_Main.HitNormal
	end

-- // }}}
