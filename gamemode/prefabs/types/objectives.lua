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

local prefabs = jcms.prefabs

-- // Thumpers {{{
	prefabs.thumper = {
		check = function(area)
			local sx, sy = area:GetSizeX(), area:GetSizeY()
			if sx < 150 or sy < 150 then return false end
			
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
	}

	prefabs.thumpersabotage = {
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
	}
-- // }}}


-- // Other {{{
	prefabs.flashpoint = {
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
	}

	prefabs.zombiebeacon = {
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
	}

	prefabs.rgg_mainframe = {
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
-- // }}}