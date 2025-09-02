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

EFFECT.mat = Material "effects/spark"
EFFECT.mat_light = Material "sprites/light_glow02_add"
EFFECT.mat_fire = Material "effects/fire_cloud1.vtf"
EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	self.start = data:GetStart()
	self.endpos = data:GetOrigin()
	self.isIncendiary = data:GetFlags() == 1

	self:SetRenderBoundsWS(self.start, self.endpos)

	self.t = 0
	self.tout = 0.1 + math.random()*0.4
	self.color = Color(255, 255, 255, 255)
end

function EFFECT:Think()
	local selfTbl = self:GetTable()
	if selfTbl.t < selfTbl.tout then
		selfTbl.t = math.min(selfTbl.tout, selfTbl.t + FrameTime())
		return true
	else
		return false
	end
end

function EFFECT:Render()
	local selfTbl = self:GetTable()

	local f = selfTbl.t / selfTbl.tout
	local ff = math.ease.InCirc(1 - f)
	
	selfTbl.color:SetUnpacked(255, 200*ff, 200*ff, 256*ff)
	
	render.SetMaterial(selfTbl.mat)
	render.DrawBeam(selfTbl.start, selfTbl.endpos, (selfTbl.isIncendiary and 32 or 16)*ff, 0.1, 0.5, selfTbl.color)
	render.SetMaterial(selfTbl.mat_light)
	render.DrawSprite(selfTbl.endpos, 64 * ff, 48 * ff, selfTbl.color)
	
	if selfTbl.isIncendiary then
		selfTbl.color:SetUnpacked(255, 255, 255, 255)
		render.SetMaterial(selfTbl.mat_fire)
		render.DrawBeam(selfTbl.start, selfTbl.endpos, Lerp(f, 16, 32), 0, ff, selfTbl.color)
		render.DrawSprite(selfTbl.endpos, 127 * ff, 120 * ff, selfTbl.color)
	end
end
