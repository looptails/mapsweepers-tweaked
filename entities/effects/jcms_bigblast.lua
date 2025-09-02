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

EFFECT.mat_core = Material "effects/fluttercore_gmod"
EFFECT.mats_blood = {
	Material "decals/blood3",
	Material "decals/blood4",
	Material "decals/blood5", 
	nil -- Blocks the second return of "Material"
}
EFFECT.decal_blood = Material "decals/bloodstain_002"

EFFECT.v_gravity = Vector(0, 0, -720)
EFFECT.v_gravityHeavy = Vector(0, 0, -1440)

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	self.pos = data:GetOrigin()
	self.size = data:GetRadius()
	self.type = data:GetFlags()
	-- 0: Blood explosion
	-- 1: Normal explosion
	
	self.t = 0
	self.tout = data:GetMagnitude()
	
	local sizevec = Vector(self.size+32, self.size+32, self.size+32)
	self:SetRenderBounds(-sizevec, sizevec)
	
	self.angles = { AngleRand(), AngleRand(), AngleRand() }
	self.angleDelta = Angle(128, 32, 4)
	self.angleDelta.r = 0
	
	if self.type == 0 then
		pcall(self.DoBloodBlast, self) -- This sometimes errors about a "NULL Entity" for NO REASON. Sick of it.
	elseif self.type == 1 then
		self:DoNormalBlast()
	end
end

function EFFECT:DoBloodBlast()
	self:EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(1,4)..".wav", 100, math.random(80, 90), 1)

	self.emitter = ParticleEmitter(self.pos)
	if self.emitter then
		local additional = self.size >= 200 and 4 or 0
		for i=1, math.ceil(self.size/8) + 2 + additional do
			local p = self.emitter:Add("effects/fleck_cement"..math.random(1, 2), self.pos)
			if p then
				local vel = VectorRand(-self.size*2, self.size*2)
				vel.z = vel.z + self.size*3
				p:SetVelocity(vel)
				p:SetGravity(self.v_gravity)
				p:SetCollide(true)

				p:SetStartSize(math.Rand(self.size/8, self.size/4))
				p:SetEndSize(0)

				p:SetRoll(math.random()*360)
				p:SetRollDelta(math.random()*10 - 5)

				p:SetDieTime(0.3 + (math.random()^3)*2)
				p:SetColor(64, 24, 24)
			end
		end

		for i=1, math.ceil(self.size/7) + 3 + additional do
			local p = self.emitter:Add("effects/blood_drop", self.pos)
			if p then
				local vel = VectorRand(-self.size*4, self.size*4)
				vel.z = vel.z + self.size*8
				p:SetVelocity(vel)
				p:SetGravity(self.v_gravityHeavy)
				p:SetCollide(true)
	
				p:SetStartSize(math.Rand(1, 3))
				p:SetEndSize(0)
	
				p:SetRoll(math.random()*360)
	
				p:SetDieTime(2.3 + math.random()*3)
				p:SetColor(30, 10, 10)
			end
		end

		for i=1, 6 do
			local p = self.emitter:Add("effects/blood", self.pos)
			if p then
				p:SetVelocity(VectorRand(-64, 64))
				p:SetRoll(math.random()*360)
				p:SetRollDelta(math.random()*2)

				p:SetStartSize(math.Rand(0.8, 1.2)*self.size)
				p:SetEndSize(math.Rand(0.2, 1.4)*self.size)
				p:SetDieTime(self.tout + math.random())
				p:SetColor(32, 12, 12)
			end
		end

		self.emitter:Finish()
	end

	local tr = util.TraceLine {
		start = self.pos,
		endpos = self.pos + VectorRand(-self.size*3, self.size*3),
		mask = MASK_PLAYERSOLID_BRUSHONLY
	}

	if (tr.Hit) and (IsValid(tr.Entity) or tr.Entity == game.GetWorld()) and IsValid(self) then
		local scale = math.Rand(self.size, self.size*1.2) / 24
		util.DecalEx(self.decal_blood, tr.Entity, tr.HitPos, tr.Normal, color_white, scale, scale) -- This part often throws an unfixable "null entity" error even though there's nothing to be null here.
	end
end

function EFFECT:DoNormalBlast()
	self.emitter = ParticleEmitter(self.pos)
	if self.emitter then
		for i=1, 2 do
			local p = self.emitter:Add("effects/muzzleflash" .. math.random(1, 4), self.pos)
			if p then
				p:SetVelocity(VectorRand(-4, 4))
				p:SetAirResistance(150)
				
				p:SetStartAlpha(255)
				p:SetEndAlpha(0)

				p:SetStartSize(self.size * 1.5)
				p:SetEndSize(self.size * 0.3)

				p:SetRoll(math.random()*360)
				p:SetRollDelta(math.random()*5 - 2.5)

				p:SetDieTime(0.15 + i*0.02)
				p:SetColor(255, 255, 255)
			end
		end

		for i=1, math.random(5, 8) do
			local dir = VectorRand()
			dir:Normalize()
			local forceVector = dir * (self.size * 5)

			local length = math.random(5, 9)
			local smokeSize = self.size/4
			for j=1, length do
				local p = self.emitter:Add("particle/smokesprites_000" .. (j%5 + 1), self.pos)
				if p then
					local br = Lerp(j/length, 64, 96)
					p:SetVelocity(forceVector)
					p:SetAirResistance(125 + j*90)

					p:SetStartSize(Lerp(j/length, smokeSize, smokeSize*1.5))
					p:SetEndSize(Lerp(j/length, smokeSize*2, smokeSize*3))

					p:SetRoll(math.random()*360)
					p:SetRollDelta(math.random()*2 - 1)

					p:SetDieTime(Lerp(j/length, 2, 3) + math.random()*0.3)
					p:SetColor(br, br, br)
				end
			end
		end

		for i=1, math.ceil(self.size/16) + 2 do
			local p = self.emitter:Add("effects/fleck_cement"..math.random(1, 2), self.pos)
			if p then
				local vel = VectorRand(-self.size*2, self.size*2)
				vel.z = vel.z + self.size*2
				p:SetVelocity(vel)
				p:SetGravity(self.v_gravity)
				p:SetCollide(true)

				p:SetStartSize(math.Rand(self.size/16, self.size/12))
				p:SetEndSize(0)

				p:SetRoll(math.random()*360)
				p:SetRollDelta(math.random()*10 - 5)

				p:SetDieTime(3 + (math.random()^3)*2)
				p:SetColor(96, 96, 96)
			end
		end
	end
end

function EFFECT:Think()
	if self.t < self.tout then
		self.t = self.t + FrameTime()

		for i, ang in ipairs(self.angles) do
			local delta = self.angleDelta * FrameTime() * (10 - i)
			ang:Add(delta)
		end

		return true
	else
		return false
	end
end

function EFFECT:Render()
	local selfTbl = self:GetTable()

	if selfTbl.type == 0 then
		local matrix = Matrix()

		local n = #selfTbl.mats_blood
		for i, mat in ipairs(selfTbl.mats_blood) do
			local startTime = self.tout / Lerp(i/n, 8, 3)
			local dur = self.tout / 2
			local f = math.Clamp(math.Remap(self.t, startTime, startTime + dur, 0, 1), 0, 1)

			if f > 0 and f < 1 then
				render.SetMaterial(mat)
				matrix:Identity()
				matrix:Translate(self.pos)
				matrix:Rotate(self.angles[i])
				cam.PushModelMatrix(matrix)
					render.DrawSphere(jcms.vectorOrigin, self.size*f + i*16*f, 7, 7)
				cam.PopModelMatrix(matrix)
			end
		end
	end
end