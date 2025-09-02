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

EFFECT.mat = Material "sprites/physbeama"
EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	local start = data:GetStart()
	local endpos = data:GetOrigin()

	self:SetRenderBoundsWS(start, endpos)
	self.t = 0
	self.tout = 0.25
	
	self.points = { start }
	local n = math.random(4, 10)
	for i=1, n do
		local nv = LerpVector(math.Remap(i+math.random()-0.5,0,n+2,0,1), start, endpos)
		nv.x = nv.x + math.Rand(-10, 10)
		nv.y = nv.y + math.Rand(-10, 10)
		nv.z = nv.z + math.Rand(-10, 10)
		self.points[i+1] = nv
	end
	self.points[n+2] = endpos
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
	
	render.SetMaterial(self.mat)
	
	local n = #self.points
	render.StartBeam(n)
	for i, point in ipairs(self.points) do
		local r = math.random()*256
        render.AddBeam(point, math.Remap(i, 1, n, 64, 0)*ff, math.Remap(i, 1, n, 0, 1), color_white)
	end
	render.EndBeam()
end
