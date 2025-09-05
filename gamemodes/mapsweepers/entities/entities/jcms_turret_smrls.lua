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
ENT.Base = "jcms_turret"
ENT.PrintName = "J Corp SMRLS"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.MissileBlastDamage = 100
ENT.MissileBlastRadius = 250
ENT.Radius = 5400
ENT.RadiusMin = 600

function ENT:Initialize()
	if SERVER then
		local health = 300
		self:SetHealth(health)
		self:SetMaxHealth(health)
		self:SetModel("models/jcms/jcorp_smrls.mdl")
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self.nextAttack = 0
		self.targetingMode = "smrls"

		if jcms.npc_airCheck() then
			self.startNode = jcms.pathfinder.getNearestNodePVS( self:GetTurretShootPos() )
			if not self.startNode then 
				self.startNode = jcms.pathfinder.getNearestNode( self:GetTurretShootPos() )
			end
		end
	end
	
	self:SetTurretMaxClip(48)
	self:SetTurretClip(self:GetTurretMaxClip())
	self:SetTurretTurnSpeed(Vector(32, 32, 0))
	self:SetTurretPitchLock(Vector(16, 80, 0))
	
	self.turretAngle = Angle(0, 0, 0)
	self:SetTurretKind("smrls")
end

function ENT:SetupBoosted() -- For engineer
	self:SetMaxHealth(450)
	self:SetHealth(450)
	self:SetTurretBoosted(true)
end

function ENT:TurretAngleIsSafe()
	local target = self:GetTurretDesiredAngle()
	local angle = self.turretAngle
	return math.abs(math.AngleDifference(angle.y, target.y)) <= 60
end

function ENT:TurretFirerate()
	return 3
end

function ENT:TurretGetAlertTime()
	return 1
end

function ENT:TurretLoseAlertTime()
	return 5
end

function ENT:TurretRadius()
	return self.Radius
end

function ENT:GenTurretSpread()
	return math.Rand(-5, 5), math.Rand(-4, 4)
end

if SERVER then
	function ENT:TurretVisible(target)
		if self:TestPVS(target) then
			if isentity(target) then
				target = target:WorldSpaceCenter()
			end
			
			local t = CurTime()
			for i, smokeScreen in ipairs(jcms.smokeScreens) do
				if (t < smokeScreen.expires) and (target:DistToSqr(smokeScreen.pos) < smokeScreen.rad^2) then
					return false
				end
			end
			
			return target:DistToSqr( self:WorldSpaceCenter() ) >= self.RadiusMin*self.RadiusMin
		else
			return false
		end
	end
	
	ENT.NextSlowThink = 0
	ENT.CurrentTarget = NULL

	function ENT:TurretSlowThink()
		local selfTbl = self:GetTable()
		if selfTbl.NextSlowThink > CurTime() then return end 

		local origin, radius = selfTbl.GetTurretShootPos(self), selfTbl.TurretRadius(self)

		local targets = selfTbl.GetTargetsAround(self, origin, radius)
		local targetingFunction = jcms.turret_targetingModes[ selfTbl.targetingMode ] or jcms.turret_targetingModes.closest
		local best, npcPos = targetingFunction(self, targets, origin, radius)

		selfTbl.CurrentTarget = best

		selfTbl.NextSlowThink = CurTime() + 1/2 --2 updates per second, instead of 20 
	end
	
	function ENT:TurretThink(delta)
		local selfTbl = self:GetTable()
		selfTbl.TurretSlowThink(self)
		local best = selfTbl.CurrentTarget

		if IsValid(best) then
			local origin = selfTbl.GetTurretShootPos(self)
			local npcPos = jcms.turret_GetTargetPos(self, best, origin)

			local realAngle = self:GetAngles()
			
			local diff = npcPos - origin
			local dist = diff:Length()
			
			local targetAngle = diff:Angle()
			local halfpoint = 500
			targetAngle.p = 20 - 70 * (1 - halfpoint / (dist + halfpoint))
			targetAngle:Sub(realAngle)
			if not selfTbl:GetTurretDesiredAngle():IsEqualTol(targetAngle, 1) then
				selfTbl:SetTurretDesiredAngle(targetAngle)
			end
			
			self:TurretAngleUpdate(delta)
			return best, selfTbl.TurretAngleIsSafe(self)
		end
	end

	function ENT:Think()
		local dt = 0.05
		local selfTbl = self:GetTable()
		local target, canShoot = selfTbl.TurretThink(self, dt)
		local alert = selfTbl:GetTurretAlert()
		
		local selfDestruct = self:Health() <= 0 or selfTbl:GetTurretClip() <= 0
		
		if selfDestruct then
			if not selfTbl.kamikazeSound then
				self:EmitSound("npc/roller/mine/rmine_predetonate.wav")
				selfTbl.kamikazeSound = true
				self:Ignite(16)
				
				timer.Simple(5, function()
					if IsValid(self) then
						util.BlastDamage(self, IsValid(selfTbl.jcms_owner) and selfTbl.jcms_owner or self, self:WorldSpaceCenter(), 300, self:GetHackedByRebels() and 40 or 80)
						
						local ed = EffectData()
						ed:SetOrigin(self:WorldSpaceCenter())
						ed:SetNormal(vector_up)
						util.Effect("Explosion", ed)
						
						ed:SetRadius(200)
						ed:SetNormal(vector_up)
						ed:SetMagnitude(1.13)
						ed:SetFlags(1)
						util.Effect("jcms_blast", ed)
						
						self:Remove()
					end
				end)
			end
		else
			if selfTbl.currentTarget ~= target and IsValid(target) then
				self:EmitSound("npc/scanner/scanner_siren1.wav", 80, 100)
				selfTbl.currentTarget = target
			end
			
			if target and alert < 1 then
				selfTbl:SetTurretAlert( math.min(alert + dt/selfTbl.TurretGetAlertTime(self), 1) )
			elseif not target and alert > 0 then
				selfTbl:SetTurretAlert( math.max(alert - dt/selfTbl.TurretLoseAlertTime(self), 0) )
			end
			
			alert = selfTbl:GetTurretAlert()

			if alert >= 1 and canShoot then
				if (not selfTbl.nextAttack or selfTbl.nextAttack <= CurTime()) then
					selfTbl.Shoot(self)
					selfTbl.nextAttack = CurTime() + selfTbl.TurretFirerate(self)
				end
			end
		end
		
		self:NextThink(CurTime() + dt)
		return true
	end
	
	function ENT:Use(ply)
		
	end
	
	function ENT:Shoot()
		if self:GetTurretClip() > 0 then
			local myangle = self:GetAngles()
			local up, right, fwd = myangle:Up(), myangle:Right(), myangle:Forward()
			local mypos = self:GetTurretShootPos()
			
			local dir = self:TurretAngle() + myangle
			local spreadX, spreadY = self:GenTurretSpread()
			dir:SetUnpacked(dir.p + spreadY, dir.y + spreadX, dir.r)
			dir = dir:Forward()
			
			local missile = ents.Create("jcms_micromissile")
			missile:SetPos(mypos)
			missile:SetAngles(myangle)
			missile:SetOwner(self)
			missile.Damage = self.MissileBlastDamage
			missile.Radius = self.MissileBlastRadius
			missile.Proximity = self.MissileBlastRadius/4
			missile.jcms_owner = self.jcms_owner
			missile.Target = self.currentTarget
			missile.Damping = 0.76
			missile.Speed = 1500
			missile.ActivationTime = CurTime() + 0.5
			local col = self:GetHackedByRebels() and jcms.factions_GetColor("rebel") or Color(255, 0, 0)
			missile:SetBlinkColor( Vector(col.r/255, col.g/255, col.b/255) )
			missile:Spawn()

			missile.jcms_isPlayerMissile = not self:GetHackedByRebels()

			if IsValid(self.currentTarget) then
				self.currentTarget.jcms_lastTargetedBySMRLS = CurTime()

				if not self:TurretVisibleTrace(self.currentTarget) then
					--Start node is precalculated / stored because missile turrets don't move. Saves some performance.
					if self.startNode then --Lua error prevention. Some maps don't have an airgraph at all.
						missile.Path = jcms.pathfinder.navigate(self.startNode, self.currentTarget:WorldSpaceCenter())
					end
					missile.Damping = 0.89
				end
			end
			
			missile:GetPhysicsObject():SetVelocity(dir*300)
			
			local effectdata = EffectData()
			effectdata:SetEntity(self)
			effectdata:SetScale(5)
			effectdata:SetFlags(1)
			util.Effect("jcms_muzzleflash", effectdata)
			
			self:SetTurretClip( self:GetTurretClip() - 1 )
			self:EmitSound("PropAPC.FireRocket")
		end
	end
end

if CLIENT then
	jcms.turret_offsets.smrls = 4
	jcms.turret_offsets_up.smrls = -4
	
	function ENT:Think()
		local myang = self:GetAngles()
		local ang = self:TurretAngle()
		self:ManipulateBoneAngles(1, Angle(ang.y,0,0))
		self:ManipulateBoneAngles(2, Angle(0,0,-ang.p))
		
		local hfrac = self:GetTurretHealthFraction()^5
		if FrameTime() > 0 and math.random() < (hfrac<=0 and 0.75 or (1 - hfrac)*0.25)*0.2 then
			local ed = EffectData()
			ed:SetOrigin(self:WorldSpaceCenter() + VectorRand(-16, 16))
			ed:SetMagnitude(1-hfrac)
			ed:SetScale(1-hfrac)
			ed:SetRadius(4-hfrac)
			ed:SetNormal(VectorRand())
			util.Effect("Sparks", ed)
		end
		
		self:TurretAngleUpdate(FrameTime())
	end
	
	function ENT:Draw(flags)
		self:DrawModel()
	end
end
