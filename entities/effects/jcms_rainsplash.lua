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

--[[
	The splash at the end of a raindrop.

	(Small circular shape that expands and fades out at the origin)

	I recommend only using this clientside (if you use it *at all*. I only made it for the other rain effect).

	I may remove this effect, as it's more perf for something that isn't very noticeable
--]]

EFFECT.mat_splash = Material "effects/splashwake3"

function EFFECT:Init(data)
	local origin = data:GetOrigin()
	self:SetPos(origin)
	
	self.colour = Color(75,0,0) --todo: Pass-in

	self.lifeSpan = 0.75
	self.dieTime = CurTime() + self.lifeSpan

	self.scale = math.Rand(30, 45)
end

function EFFECT:Think()
	return CurTime() < self.dieTime
end

function EFFECT:Render()
	local scalar = (self.dieTime - CurTime()) / self.lifeSpan

	self.colour.a = 255 * scalar^(1/3)

	render.SetMaterial(self.mat_splash)
	local scale = self.scale * (1-scalar)

	render.DrawQuadEasy(self:GetPos(), jcms.vectorUp, scale, scale, self.colour, 0)
end