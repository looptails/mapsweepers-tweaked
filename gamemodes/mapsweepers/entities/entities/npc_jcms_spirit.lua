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
AddCSLuaFile()

ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Spirit"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsDying")
	self:NetworkVar("Float", 0, "DeathTime")
	self:NetworkVar("Int", 0, "CarriedNPCCount")
end

function ENT:Initialize()
	self:SetModel("models/zombie/fast.mdl")
	self:SetHealth(80)

	if SERVER then
		self:SetMaxHealth(80)
		self:SetHullType(HULL_HUMAN)
		self:SetHullSizeNormal()
		self:SetSolid(SOLID_BBOX)
		self:DrawShadow(false)

		self:SetMaxLookDistance(3000)
		self:SetArrivalDistance(128)
		self:SetMaxYawSpeed(45)

		self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_MOVE_JUMP, CAP_TURN_HEAD, CAP_OPEN_DOORS))
		self:SetMoveType(MOVETYPE_STEP)
		self:SetNavType(NAV_GROUND)
		self:SetNPCClass(CLASS_ZOMBIE)

		self.npcCarryGoal = math.random(3, 5)
		self.wantToCarry = true
	end

	if CLIENT then
		self.trailLength = 16

		self.trailBones = {
			self:LookupBone("ValveBiped.Bip01_L_Calf"),
			self:LookupBone("ValveBiped.Bip01_R_Calf"),
			self:LookupBone("ValveBiped.Bip01_L_Hand"),
			self:LookupBone("ValveBiped.Bip01_R_Hand")
		}

		self.trails = {}
		for i, bid in ipairs(self.trailBones) do 
			self.trails[i] = {}
		end
	end
end

if SERVER then
	ENT.GiveShieldAmount = 25
	ENT.GiveShieldRegen = 7
	ENT.GiveShieldRegenDelay = 3
	ENT.DeployDistance = 1000
	ENT.GrabDistance = 666
	ENT.GiveShieldDistance = 666
	ENT.MinGrabDist = 1500

	ENT.GrabWhitelist = { --Grabbing anything faster than us is a waste, grabbing anything that can't/shouldn't move is bad.
		["npc_zombie"] = true,
		["npc_poisonzombie"] = true,
		["npc_zombine"] = true,
		["npc_jcms_boomer"] = true
		--Would include sprit, but that actually reduces the rate at which zombies get to you on average
	}

	function ENT:IsGoodGrabTarget(target)
		--and target:IsNPC() --Removed because we use a whitelist now.
		return IsValid(target) and self.GrabWhitelist[target:GetClass()] and target ~= self and (target:Health() > 0) and (not IsValid(target:GetParent())) and (not target.jcms_danger or target.jcms_danger < jcms.NPC_DANGER_BOSS) and (target:GetMoveType() > MOVETYPE_NONE) and jcms.team_SameTeam(self, target)
	end
	
	function ENT:IsGoodGrabTarget_optimised(selfTbl, target)
		local targetTbl = target:GetTable()
		return IsValid(target) and selfTbl.GrabWhitelist[target:GetClass()] and (target:Health() > 0) and (not IsValid(target:GetParent())) and (not targetTbl.jcms_danger or targetTbl.jcms_danger < jcms.NPC_DANGER_BOSS) and jcms.team_SameTeam(self, target)
	end

	function ENT:OnTakeDamage(dmg)
		if self:GetIsDying() then return 0 end

		local melee = bit.band(dmg:GetDamageType(), bit.bor(DMG_SLASH, DMG_CLUB)) > 0
		
		if melee then
			dmg:ScaleDamage(2.2)
		elseif (dmg:GetDamage() < 25) then
			dmg:ScaleDamage(0.2)
		end

		self:SetHealth( self:Health() - dmg:GetDamage() )

		if self:Health() <= 0 then
			self:Death(dmg:GetAttacker(), dmg:GetInflictor())

			local v = dmg:GetDamageForce()
			local len = v:Length()
			v:Div(len)
			v:Mul(120)
			self:SetVelocity(v)
		else
			local v = self:GetMoveVelocity()
			v.z = v.z + 2
			v:Mul(2.5)
			self:SetVelocity(v)
		end

		return 0
	end

	function ENT:SelectSchedule()
		local selfTbl = self:GetTable()
		if selfTbl:GetIsDying() then return end

		local enemy = self:GetEnemy()
		if IsValid(enemy) then
			local enemyPos = enemy:GetPos()
			local selfPos = self:GetPos()
			
			if enemyPos:DistToSqr(selfPos) < (selfTbl.DeployDistance/2)^2 then 
				self:SetSchedule(SCHED_RUN_FROM_ENEMY)
				return
			end

			local canMove = not selfTbl.nextMove or CurTime() > selfTbl.nextMove
			local npcs = ents.FindByClass("npc_*")

			local bestDist2, furthest = selfTbl.MinGrabDist^2
			for i, npc in ipairs(npcs) do
				if not selfTbl.IsGoodGrabTarget_optimised(self, selfTbl, npc) or self:IsUnreachable( npc ) then continue end

				local dist2 = npc:GetPos():DistToSqr(enemyPos)
				if dist2 > bestDist2 then
					furthest, bestDist2 = npc, dist2
				end
			end

			if selfTbl.wantToCarry then
				if IsValid(furthest) then
					if self:GetPathTimeToGoal() == 0 then --This happens if the target's unreachable
						self:RememberUnreachable(furthest, 60)
					end
					if canMove or furthest:GetPos():DistToSqr( self:GetGoalPos() ) >= (selfTbl.GrabDistance/2)^2 then
						self:NavSetGoalPos( furthest:GetPos() )
						self:StartEngineTask(48, 0)
						--debugoverlay.Line(selfPos, self:GetGoalPos(), 0.2, Color(0, 255, 129))
						--debugoverlay.Line(furthest:GetPos(), self:GetGoalPos(), 0.2, Color(0, 255, 0))
						selfTbl.nextMove = CurTime() + 5
					end
				else
					selfTbl.wantToCarry = false
				end
			else
				if IsValid(furthest) and self:GetCarriedNPCCount() <= 0 then
					selfTbl.wantToCarry = true
				elseif self:GetCarriedNPCCount() > 0 and self:GetCurrentSchedule() ~= SCHED_CHASE_ENEMY then
					self:SetSchedule(SCHED_CHASE_ENEMY)
				elseif self:GetCurrentSchedule() ~= SCHED_PATROL_RUN then
					self:ClearSchedule()
					self:SetSchedule(SCHED_PATROL_RUN)
				end
			end
		else
			selfTbl.wantToCarry = true
			self:SetSchedule(SCHED_PATROL_RUN)
		end
	end

	function ENT:Death(attacker, inflictor)
		self:DeployNPCs()

		local valids = {}
		for i, npc in ipairs( ents.FindInSphere(self:WorldSpaceCenter(), self.GiveShieldDistance) ) do
			if IsValid(npc) and npc:Health() > 0 and jcms.team_SameTeam(self, npc) then
				table.insert(valids, npc)
			end
		end

		table.Shuffle(valids)
		for i=1, math.min(#valids, 5) do
			local npc = valids[i]

			if npc:IsPlayer() then
				npc:SetMaxArmor( npc:GetMaxArmor() + self.GiveShieldAmount )
				npc:SetArmor( npc:GetMaxArmor() )
			elseif not npc:GetClass() == "npc_jcms_spirit" then --Difficult/impossible to see shields on other spirits, so I'd rather just not.
				jcms.npc_SetupSweeperShields(npc, npc:GetNWInt("jcms_sweeperShield_max", 0) + self.GiveShieldAmount, self.GiveShieldRegen, self.GiveShieldRegenDelay, jcms.factions_GetColorInteger("zombie"))
				npc:SetPlaybackRate(2)
			end

			local ed = EffectData()
			ed:SetFlags(2)
			ed:SetEntity(npc)
			ed:SetOrigin(self:WorldSpaceCenter())
			util.Effect("jcms_chargebeam", ed)
		end

		self:SetSolid(SOLID_NONE)
		self:SetMoveType(MOVETYPE_FLY)
		self:SetIsDying(true)
		self:SetDeathTime(CurTime())
		
		local ed = EffectData()
		ed:SetMagnitude(1.5)
		ed:SetOrigin(self:WorldSpaceCenter())
		ed:SetRadius(78)
		ed:SetNormal(self:GetAngles():Up())
		ed:SetFlags(2)
		util.Effect("jcms_blast", ed)

		self:EmitSound("npc/advisor/advisor_scream.wav", 100, 170, 1)
		hook.Call("OnNPCKilled", GAMEMODE, self, attacker, inflictor)
	end

	function ENT:Think()
		if self:GetIsDying() then
			if CurTime() > self:GetDeathTime() + 3 then
				self:Remove()
			end
		else
			if self.wantToCarry and self:GetCarriedNPCCount() > 0 and IsValid( self:GetEnemy() ) and self:GetEnemy():GetPos():DistToSqr( self:GetPos() ) < self.GrabDistance^2 then
				self.wantToCarry = false
			end

			if not self.carryCooldown or CurTime() > self.carryCooldown then
				if self.wantToCarry then
					for i, npc in ipairs( ents.FindInSphere(self:WorldSpaceCenter(), self.GrabDistance) ) do
						if self:IsGoodGrabTarget(npc) and self:Visible(npc) and (not IsValid(npc:GetEnemy()) or npc:GetEnemy():GetPos():DistToSqr(npc:GetPos()) > self.MinGrabDist^2) then
							self:CarryNPC(npc)
							self.carryCooldown = CurTime() + 0.25
							break
						end
					end

					if self:GetCarriedNPCCount() >= self.npcCarryGoal then
						self.wantToCarry = false
						self.carryCooldown = CurTime() + 1
					end
				elseif self:GetCarriedNPCCount() > 0 then
					local enemy = self:GetEnemy()

					if IsValid(enemy) then
						local viscon = self:Visible(enemy) and (CurTime()-self:GetEnemyLastTimeSeen(enemy)) < 1

						--[[
							todo: If it's impossible to navigate to a target we probably want to change our rules.
							Spirits used to provide a way for zombies to continue attacking targets on short buildings.
							We want that back eventually.
						--]]

						if viscon and enemy:GetPos():DistToSqr(self:GetPos()) < self.DeployDistance^2 then
							self:DeployNPCs(enemy:GetPos())

							self:ClearSchedule()
							self:SetSchedule(SCHED_RUN_FROM_ENEMY)
							self.carryCooldown = CurTime() + 5
							self.wantToCarry = true
						end
					end
				end
			end
		end
	end

	function ENT:HandleAnimEvent(event, eventTime, cycle, type, options)
		if (event == 105 or event == 106) then
			if not self:GetIsDying() then
				self:EmitSound("player/footsteps/snow"..math.random(1, 6)..".wav", 100, 200, 0.7)
			end

			return true
		end
	end

	function ENT:CarryNPC(npc)
		local ed = EffectData()
		ed:SetFlags(2)
		ed:SetEntity(self)
		ed:SetOrigin(npc:WorldSpaceCenter())
		util.Effect("jcms_chargebeam", ed)
		npc:SetParent(self)
		npc:SetPos(self:GetPos())
		npc:SetNoDraw(true)
		self:SetCarriedNPCCount( self:GetCarriedNPCCount() + 1 )
		self:EmitSound("npc/advisor/advisor_blast1.wav", 100, 100, 1)
		self:AddGestureSequence(17)
	end

	function ENT:DeployNPCs(pos)
		local toDeploy = {}

		for i, ent in ipairs( self:GetChildren() ) do
			if IsValid(ent) and ent:IsNPC() and ent:Health() > 0 then
				table.insert(toDeploy, ent)
			end
		end

		local mostVectors

		if isvector(pos) then
			for i=1, 4 do
				local vectors, fully = jcms.director_PackSquadVectors(LerpVector( math.Remap(i, 1, 4, 0.5, 0.2), self:WorldSpaceCenter(), pos ), #toDeploy, math.random(75, 125))

				if fully or (not mostVectors) or (#vectors > #mostVectors) then
					mostVectors = vectors

					if fully then
						break
					end
				end
			end
		else
			local vectors, fully = jcms.director_PackSquadVectors(self:WorldSpaceCenter(), #toDeploy, math.random(150, 200))
			mostVectors = vectors
		end

		if not mostVectors or #mostVectors == 0 then
			return -- Oops
		end

		local upVec = Vector(0,0,10)
		local deployed = 0
		for i, v in ipairs(mostVectors) do
			deployed = deployed + 1

			local ent = toDeploy[i]
			ent:SetParent()
			ent:SetPos(v + upVec)
			--ent:DropToFloor()
			ent:SetNoDraw(false)

			local foe = self:GetEnemy()
			if IsValid(foe) then
				local foePos = foe:GetPos()
				ent:SetEnemy(foe)
				ent:UpdateEnemyMemory(foe, foePos)
				
				ent:NavSetGoalPos(ent:GetPos()) --Reset our target point

				foePos:Sub(v)
				local faceAngle = foePos:Angle()
				faceAngle.p = 0
				faceAngle.r = 0

				ent:SetAngles(faceAngle)
			else
				jcms.npc_GetRowdy(ent)
			end

			local filter = RecipientFilter()
			filter:AddPVS(self:WorldSpaceCenter())
			filter:AddPVS(ent:WorldSpaceCenter())

			local ed = EffectData()
			ed:SetFlags(2)
			ed:SetEntity(self)
			ed:SetOrigin(ent:WorldSpaceCenter())
			util.Effect("jcms_chargebeam", ed, true, filter)
		end

		self:AddGestureSequence(16)
		self:EmitSound("npc/advisor/advisor_blast6.wav", 100, 100, 1)
		local remaining = #toDeploy - deployed
		self:SetCarriedNPCCount(remaining)
		if remaining == 0 then 
			self.npcCarryGoal = math.random(3, 6)
		end
	end
end

if CLIENT then
	ENT.mat = Material "effects/strider_muzzle"
	ENT.mat_trail = Material "trails/plasma"

	function ENT:Think()
		local selfTbl = self:GetTable()

		if FrameTime() > 0 then
			local mypos = self:WorldSpaceCenter()

			local elapsed = CurTime() - selfTbl:GetDeathTime()
			local deathfrac = dying and math.ease.InCubic(( math.max(0, 1 - elapsed/1.5) )) or 1

			local myX, myY, myZ = mypos:Unpack() 
			for i, bid in ipairs(selfTbl.trailBones) do
				local tt = selfTbl.trails[i]

				local bonePos = self:GetBonePosition(bid)
				local bx, by, bz = bonePos:Unpack() 
				bonePos:SetUnpacked( Lerp(1-deathfrac, bx, myX), Lerp(1-deathfrac, by, myY), Lerp(1-deathfrac, bz, myZ))

				table.insert(tt, 1, bonePos)
				if tt[selfTbl.trailLength] then
					tt[selfTbl.trailLength] = nil
				end
			end
		end

		self:SetNextClientThink(CurTime() + 1/selfTbl.trailLength)
		return true
	end

	function ENT:DrawTranslucent(flags)
		if render.GetRenderTarget() then return end

		local mypos = self:WorldSpaceCenter()
		local eyePos = EyePos()
		local distToEyes = eyePos:DistToSqr(mypos)

		self:RemoveAllDecals()

		local selfTbl = self:GetTable()

		local time = CurTime()
		local dying = selfTbl:GetIsDying()
		local elapsed = time - selfTbl:GetDeathTime()
		local deathfrac = dying and math.ease.InCubic(( math.max(0, 1 - elapsed/1.5) )) or 1
		local blastfrac = dying and math.max(0, 1 - elapsed*5) or 0

		render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

			if jcms.performanceEstimate > 30 then 
				render.SetMaterial(selfTbl.mat_trail)
				for i, trailVectors in ipairs(selfTbl.trails) do
					local n = #trailVectors
					render.StartBeam(n)
					for j, v in ipairs(trailVectors) do
						local f = (j-1)/(n-1)
						render.AddBeam(v, 7*deathfrac*(1-f), f*4, Color(255*(1-f), 0, 0))
					end
					render.EndBeam()
				end
			end

			if not dying then
				local colormod = (math.sin(time*4 + self:EntIndex())*0.5 + 700)
				render.SetColorModulation(colormod, 1, 1)
					self:DrawModel()
				render.SetColorModulation(1, 1, 1)
			end

			if distToEyes < 3250 ^2 then
				surface.SetMaterial(selfTbl.mat)
				surface.SetAlphaMultiplier(1)
				surface.SetDrawColor(255*deathfrac, 0, 0, 255*deathfrac)
				local a = (mypos - eyePos):Angle()
				a:RotateAroundAxis(a:Right(), 90)
				for i=1, 4 do
					cam.Start3D2D(mypos, a, 1 + blastfrac*i)
						local ti = (time+i/4) % 1
						local size = (72 - ti*32)*deathfrac
						surface.DrawTexturedRectRotated(0, 0, size, size, ti/4*i*360)
					cam.End3D2D()
				end
			end

			if distToEyes < 2000^2 then 
				local orbcount = selfTbl.GetCarriedNPCCount(self)
				local angShift = math.pi*2/orbcount
				
				for i=1, orbcount do
					local a = (i + time%1)*angShift
					local orbV = mypos + Vector(math.cos(a)*32, math.sin(a)*32, -8)
					local size = 64 * deathfrac + blastfrac*4
					render.DrawSprite(orbV, size, size, jcms.factions.zombie.color)
				end
			end
		render.OverrideBlend( false )

	end
end
