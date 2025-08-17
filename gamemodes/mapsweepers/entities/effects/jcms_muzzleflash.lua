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

EFFECT.mat_light = Material "sprites/light_glow02_add"
EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local mats = {
	Material "effects/fire_cloud1.vmt",
	Material "effects/fluttercore_gmod.vmt",
	Material "effects/combinemuzzle2.vmt",
	Material "effects/fluttercore_gmod.vmt"
}

local colors = {
	{ 255, 100, 100 },
	{ 255, 0, 0 },
	{ 220, 235, 255 },
	{ 180, 230, 255 }
}

local offsets = {
	{ 12, 4 },
	{ 14, 4 },
	{ 4, 3 }
}

function EFFECT:Init(data)
	self.t = 0
	self.tout = math.random()*0.02 + 0.04
	self.flashsize = math.random()*0.5 + 0.5
	
	local turret = data:GetEntity()
	if IsValid(turret) then
		self.scale = data:GetScale()
		self.matId = data:GetFlags()
		
		if turret:GetClass() == "jcms_tank" then
			self.tank = turret
			self.forward = 0
			self.offset = data:GetStart()
			self.normal = data:GetNormal()
			self.color = Color(unpack(colors[self.matId]))
			
			local pos = turret:GetPos()
			local mins, maxs = turret:GetRenderBounds()
			mins:Add(pos)
			maxs:Add(pos)
			self:SetRenderBoundsWS(mins, maxs)
		elseif turret:GetClass() == "jcms_emplacement" then
			self.tank = turret
			self.forward = 14
			self.offset = data:GetStart()

			local v, a = turret:GetBonePosition(1)
			a = a or Angle(0, 0, 0)
			self.normal = a:Right()
			self.normal:Mul(-1)
			self.color = Color(unpack(colors[self.matId]))
			
			local pos = turret:GetPos()
			local mins, maxs = turret:GetRenderBounds()
			mins:Add(pos)
			maxs:Add(pos)
			self:SetRenderBoundsWS(mins, maxs)
		else
			self.turret = turret
			local tkind = self.turret.GetTurretKind and self.turret:GetTurretKind() or "smg"
			self.forward = jcms.turret_offsets[ tkind ] or jcms.turret_offsets.smg or 0
			self.up = jcms.turret_offsets_up[ tkind ] or 0
			
			local boneId = 2
			if boneId then
				local matrix = turret:GetBoneMatrix(boneId)
				if matrix then
					self.offset = matrix:GetTranslation()
					self.normal = -matrix:GetAngles():Right()
					self.offset:Add(-matrix:GetAngles():Up()*(4+self.up))
				else
					self.offset = turret:WorldSpaceCenter()
					self.normal = turret:GetAngles():Forward()
				end
			else
				self.offset = turret:WorldSpaceCenter()
				self.normal = turret:GetAngles():Forward()
			end
			self.color = Color(unpack(colors[self.matId]))
			
			local pos = self.turret:GetPos()
			local mins, maxs = self.turret:GetRenderBounds()
			mins:Add(pos)
			maxs:Add(pos)
			self:SetRenderBoundsWS(mins, maxs)
		end
	end
end

function EFFECT:Think()
	if ( IsValid(self.turret) or IsValid(self.tank) ) and self.t < self.tout then
		self.t = math.min(self.tout, self.t + FrameTime())
		return true
	else
		return false
	end
end

function EFFECT:Render()
	if IsValid(self.turret) or IsValid(self.tank) then
		local v = self.offset
		local n = self.normal
		local s = self.scale
		render.SetMaterial(mats[self.matId] or mats[1])
		
		local frac = self.t / self.tout
		local off = offsets[self.matId] or offsets[1]
		
		for i = 1, 4 do
			local size = Lerp(frac, 32, 15) / (i + 0.5)
			local off = Lerp(frac, off[1], off[2]) * math.sqrt(i-1) + 4 + self.forward
			
			if self.matId == 4 then
				render.DrawSprite(v + off*s*n, size*s, size*s*0.7, Color(100, 100, 255))
			elseif self.matId == 2 then
				render.DrawSprite(v + off*s*n, size*s, size*s*0.7, Color(255, 32, 32))
			else
				render.DrawSprite(v + off*s*n, size*s, size*s*0.6)
			end
		end
		
		frac = 1-frac
		render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_ONE, BLENDFUNC_ADD )
			render.SetMaterial(self.mat_light)
			self.color.r = self.color.r * 0.7
			self.color.g = self.color.g * 0.7
			self.color.b = self.color.b * 0.7
			self.color.a = 255 * frac
			render.DrawSprite(v + 1.2*n*s*self.forward, 64 * s * self.flashsize, 48 * s * self.flashsize, self.color)
		render.OverrideBlend( false )
	end
end
