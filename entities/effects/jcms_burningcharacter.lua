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

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

EFFECT.mat_glow = Material "sprites/light_glow02_add"

PrecacheParticleSystem("fire_medium_03")

function EFFECT:Init( data )
	self.ent = data:GetEntity()
	self.entIndex = self.ent:EntIndex() --optimisation
	self.col = Color(0,0,0)
	local dur = data:GetScale() -- scale used for duration
	if not IsValid(self.ent) then return end 

	if dur == 0 then 
		self.infinite = true
		self.endTime = 0
	else
		self.endTime = CurTime() + dur
		self.infinite = false
	end

	local ang = self.ent:GetAngles()
	local offs = data:GetStart() or jcms.vectorOrigin  --start is offset
	offs = offs.x * ang:Forward() + offs.y * ang:Right() + offs.z * ang:Up()

	self:SetPos(self.ent:WorldSpaceCenter() + offs)
	self:SetParent(self.ent)

	local mins, maxs = self.ent:OBBMins(), self.ent:OBBMaxs()
	local bounds = maxs - mins

	local lx = math.max(bounds.x, bounds.y, bounds.z) --Largest extent
	self.glowScale = lx

	self.firePart1 = CreateParticleSystem( self, "fire_medium_03", PATTACH_ABSORIGIN_FOLLOW)
end

function EFFECT:Think()
	local selfTbl = self:GetTable()
	if not IsValid(self:GetParent()) and IsValid(selfTbl.ent) then 
		self:SetPos(selfTbl.ent:WorldSpaceCenter())
		self:SetParent(selfTbl.ent)
	end
	return IsValid(selfTbl.ent) and (selfTbl.infinite or selfTbl.endTime > CurTime()) and (selfTbl.ent.Health and selfTbl.ent:Health() >= 0)
end

function EFFECT:Render()
	local selfTbl = self:GetTable()
	if not IsValid(selfTbl.ent) then return end 

	local selfPos = self:GetPos()
	
	local dist = jcms.EyePos_lowAccuracy:DistToSqr(selfPos)
	local mult2 = math.Clamp(math.Remap(dist, 1250*1250, 300^2, 1, 0), 0.75, 1)	--Alpha/Brightness

	local r, g, b = math.random(250, 255) * mult2, math.random(100, 150)*mult2, 32*mult2
	selfTbl.col:SetUnpacked(r, g, b)
	--local col = Color(math.random(250, 255) * mult2, math.random(100, 150)*mult2, 32*mult2)

	render.SetMaterial(selfTbl.mat_glow)
	local gs = selfTbl.glowScale
	--render.DrawSprite(selfPos + VectorRand(-gs/15,gs/15), gs*4, gs*4, col)
	render.DrawSprite(selfPos + VectorRand(-gs/15,gs/15), gs*4, gs*4, selfTbl.col)

	local dlight = DynamicLight( selfTbl.entIndex )
	dlight.pos = selfPos + VectorRand(-gs/3,gs/3)
	--local r, g, b = col:Unpack()
	dlight.r = r
	dlight.g = g
	dlight.b = b
	dlight.brightness = 4
	dlight.decay = 3000
	dlight.size = 2 * gs
	dlight.dietime = CurTime() + 0.1
end