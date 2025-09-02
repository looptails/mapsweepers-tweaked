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

EFFECT.mat = Material "sprites/physbeama.vmt"
EFFECT.mat_beam = Material "effects/lamp_beam.vmt"
EFFECT.mat_ring = Material "effects/select_ring"
EFFECT.mat_light = Material "effects/blueflare1.vmt"
EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local vUp = Vector(0, 0, 1) -- vector_up is broken on client with some addons, it seems? this is safer anyway

function EFFECT:Init(data)
	self.pos = data:GetOrigin()
	self.isRed = data:GetFlags() == 1
	
	local tr = util.TraceLine {
		start = self.pos,
		endpos = self.pos + Vector(0, 0, 16000),
		mask = MASK_NPCWORLDSTATIC,
		filter = self
	}
	
	self.posUp = tr.HitPos
	self:SetRenderBoundsWS(self.pos, self.posUp)

	self.t = 0
	self.tout = 4
	self.color1 = Color(255, 255, 255, 255)
	self.color2 = Color(255, 255, 255, 255)
end

function EFFECT:Think()
	if self.t < self.tout then
		self.t = math.min(self.tout, self.t + FrameTime())
		return true
	else
		return false
	end
end

function EFFECT:Render()
	local f = self.t / self.tout
	local ff = math.ease.InCirc(1 - f)
	
	if self.isRed then
		self.color1.r = 255
		self.color1.g = 200*ff
		self.color1.b = 200*ff
		self.color1.a = 255*ff
		
		self.color2.r = 255
		self.color2.g = 50*ff
		self.color2.b = 50*ff
		self.color2.a = 100*ff
	else
		self.color1.r = 180*ff
		self.color1.g = 200*ff
		self.color1.b = 255
		self.color1.a = 255*ff
		
		self.color2.r = 50*ff
		self.color2.g = 95*ff
		self.color2.b = 220
		self.color2.a = 100*ff
	end
	
	render.SetMaterial(self.mat)
	render.DrawBeam(self.pos, self.posUp, Lerp(ff, 48, 64), ff, ff+1, self.color2)
	
	render.SetMaterial(self.mat_beam)
	render.DrawBeam(self.pos, self.pos + Vector(0, 0, Lerp(ff, 256, 64)), Lerp(ff, 128, 170), 0, 1, self.color1)
	render.DrawBeam(self.pos, self.posUp, Lerp(ff, 48, 64), ff, ff+1, self.color1)

	local ringpos = Vector(self.pos)
	local oldAlpha = self.color1.a
	render.SetMaterial(self.mat_ring)
	for i = 0, 15 do
		local size = Lerp(ff, math.Remap(i, 0, 15, 128, 256), math.Remap(i, 0, 15, 0, 64)) - f*i^2
		self.color1.a = math.Remap(i, 0, 15, 300*ff, 0)
		render.DrawQuadEasy(ringpos, vUp, size, size, self.color1, 0)
		ringpos.z = ringpos.z + i*Lerp(1-f, 4+ff*2, ff)
	end
	
	render.SetMaterial(self.mat_light)
	local size = Lerp(ff, 0, 400)
	render.DrawQuadEasy(self.pos, vUp, size, size, self.color1, 0)
	
	render.EnableClipping(true)
		render.PushCustomClipPlane(self.pos, self.pos:Dot(vUp))
		local fromp = self.pos + vUp*32
		local tov = (EyePos()-fromp):GetNormalized()
		tov.z = 0
		render.DrawQuadEasy(fromp, tov, size, size*2, self.color1, 0)
		render.PopCustomClipPlane()
	render.EnableClipping(false)
end
