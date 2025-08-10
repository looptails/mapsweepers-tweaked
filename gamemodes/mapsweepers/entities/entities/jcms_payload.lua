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

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Payload"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()
	if SERVER then
		self.UpOffset = 8
		self:SetModel("models/jcms/jcorp_payload.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:MakePhysicsObjectAShadow(false, false)
		self:GetPhysicsObject():Wake()
		self:SetMoveType(MOVETYPE_NOCLIP)
		self:SetMoveType(MOVETYPE_PUSH)
		self:SetPos( self:GetPos() + Vector(0, 0, self.UpOffset) )
		self:AddCallback("PhysicsCollide", self.PhysicsCollide)
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "NetworkedSpeedMul")
end

if SERVER then
	ENT.MaxSpeed = 10
	ENT.BoostMul = 3.2
	ENT.PushRadius = 600
	ENT.BoostTime = 0

	function ENT:Think()
		if IsValid(self.targetNode) then
			if not IsValid(self.oldNode) then
				self.oldNode = self.targetNode
			end
			
			self:DoMove()
			self:NextThink(CurTime())

			local speedMul = self:GetSpeedFromPlayers() / self.MaxSpeed
			if self:GetNetworkedSpeedMul() ~= speedMul then
				self:SetNetworkedSpeedMul(speedMul)
			end
			
			return true
		else
			self:NextThink(CurTime() + 0.1)
			return true
		end
	end

	function ENT:PhysicsCollide(cData, physObj)
		if cData.Speed > 1000 then
			local externalStress = physObj:GetStress()
			if externalStress >= 40000 then
				local blocker = cData.HitEntity
				if IsValid(blocker) then
					blocker:Dissolve(1)
				end
			end
		end
	end
	
	function ENT:DoMove()
		local speed = self:GetSpeedFromPlayers()
		
		if speed > 0 then
			local node = self.targetNode
			local pos = self:GetPos()
			pos.z = pos.z - self.UpOffset
			local target = node:GetTrackPosition()
			local diff = target - pos
			local len = diff:Length()
			diff:Div(len)
			diff:Mul(speed)
			
			self:SetSaveValue("m_flMoveDoneTime", self:GetInternalVariable("ltime") + 1)
			self:SetLocalVelocity(diff)

			if IsValid(self:GetPhysicsObject()) and self:GetPhysicsObject():IsAsleep() then
				self:GetPhysicsObject():Wake()
			end
			
			if len < 8 then
				local nextNode = node:GetNextNode()
				self.oldNode = node
				if IsValid(nextNode) and node:GetIsEnabled() then
					self.targetNode = nextNode
				else
					self.targetNode = node
				end
			end
		end
	end

	function ENT:GetPushingPlayers()
		local ct = CurTime()
		if not self.lastCalcPushedTime or (ct - self.lastCalcPushedTime) > 0.02 then
			self.lastCalcPushedTime = ct

			local pushing = {}
			local sweepers = team.GetPlayers(1)
			local rad2 = self.PushRadius^2
			local mypos = self:WorldSpaceCenter()
			
			for i, ply in ipairs(sweepers) do
				if not (ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE) then continue end
				if ply:WorldSpaceCenter():DistToSqr(mypos) <= rad2 then
					table.insert(pushing, ply)
				end
			end

			self.lastPushing = pushing
			return pushing
		else
			return self.lastPushing
		end
	end
	
	function ENT:GetPushingPlayerCount()
		return #self:GetPushingPlayers()
	end
	
	function ENT:GetSpeedFromPlayers(count)
		if jcms.director then
			local pushing = self:GetPushingPlayerCount()
			local living = math.max(1, jcms.director.livingPlayers)
			local mul = math.sqrt(pushing / living)
			return ((CurTime() <= self.BoostTime) and self.BoostMul or 1) * self.MaxSpeed * mul
		else
			return 0
		end
	end
	
	hook.Add("MapSweepersDeathNPC", "jcms_PayloadKill", function(ply_or_npc, attacker, inflictor, isPlayerNPC)
		if jcms.director and jcms.director.missionData and IsValid(jcms.director.missionData.payload) and IsValid(attacker) and attacker ~= ply_or_npc then
			local payload = jcms.director.missionData.payload
			
			local mypos = payload:WorldSpaceCenter()
			local distPly = attacker:WorldSpaceCenter():DistToSqr(mypos)
			local distNPC = ply_or_npc:WorldSpaceCenter():DistToSqr(mypos)
			if math.min(distPly, distNPC) <= payload.PushRadius*payload.PushRadius then
				local ct = CurTime()
				payload.BoostTime = math.max(ct, payload.BoostTime or ct) + (ply_or_npc.jcms_bounty or 0) * 0.008
			end
		end
	end)

	function ENT:OnTakeDamage(dmgInfo)
		local attacker = dmgInfo:GetAttacker()
		if attacker:IsPlayer() and jcms.util_IsStunstick( dmgInfo:GetInflictor() ) then
			self.BoostTime = math.max(CurTime() + 0.1, self.BoostTime + 0.01)
		end
	end
end

if CLIENT then
	function ENT:OnRemove()
		if self.soundMove then
			self.soundMove:Stop()
		end
		
		if self.soundBoost then
			self.soundBoost:Stop()
		end
	end

	function ENT:Think()
		if not self.soundMove then
			self.soundMove = CreateSound(self, "ambient/levels/citadel/extract_loop1.wav")
			self.soundMove:PlayEx(1, 90)
		end
		
		if not self.soundBoost then
			self.soundBoost = CreateSound(self, "ambient/energy/electric_loop.wav")
			self.soundBoost:PlayEx(1, 90)
		end

		if self.soundMove then
			local speedMul = self:GetNetworkedSpeedMul()

			if speedMul > 0 then
				self.soundMove:ChangePitch(Lerp(speedMul, 75, 115), 0.1)
				self.soundMove:ChangeVolume(1, 0.1)
			else
				self.soundMove:ChangePitch(0, 0.1)
				self.soundMove:ChangeVolume(0, 0.1)
			end
			
			if speedMul > 1 then
				self.soundBoost:ChangePitch(150, 0.1)
				self.soundBoost:ChangeVolume(1, 0.1)
			else
				self.soundBoost:ChangePitch(50, 0.1)
				self.soundBoost:ChangeVolume(0, 0.1)
			end
		end
	end
end