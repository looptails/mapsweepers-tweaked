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
	A single rain particle/streak/drop/etc.

	I recommend against using this serverside. Exact positioning isn't important, so networking
	10 jillion rain particles to clients is a bad idea.
--]]

EFFECT.mat_rain = Material "particle/Particle_Square_Gradient_NoFog"

function EFFECT:Init(data)
	local origin = data:GetOrigin()

	local rainDir = Vector(0,0.15,1):GetNormalized() --todo: Would be better to have an actual angle and/or be based on wind.

	local upTr = util.TraceLine({
		start = origin, 
		endpos = origin + rainDir * 32000
	})
	if not upTr.HitSky then return end --Kill us instantly.
	local downTr = util.TraceLine({
		start = origin,
		endpos = origin - rainDir * 32000
	})

	self.rainStreakStart = origin + rainDir * 2500
	self.rainStreakEnd = downTr.HitPos

	self:SetPos(origin) --I guess this makes the most sense due to PVS culling.
	self.rainColour = Color(255,255,255) --todo: Either make this configurable or remove it.

	self.rainVec = self.rainStreakEnd - self.rainStreakStart
	self.rainDir = rainDir--self.rainVec:GetNormalized()

	self.rainLength = 500

	self.lifeSpan = self.rainVec:Length() / 2000
	self.dieTime = CurTime() + self.lifeSpan
end

function EFFECT:Think()
	return self.dieTime and (CurTime() < self.dieTime)
end

function EFFECT:Render()
	local selfTbl = self:GetTable()
	if not selfTbl.dieTime then return end 

	local scalar = (selfTbl.dieTime - CurTime()) / selfTbl.lifeSpan
	local origin = selfTbl.rainStreakEnd - (selfTbl.rainVec * scalar)
	local distRemaining = selfTbl.rainStreakEnd:Distance(origin)
	local rainLen = math.min(selfTbl.rainLength, distRemaining - 10) --prevent us from going through rooves.

	if distRemaining < selfTbl.rainLength and not selfTbl.hasSplashed then --Splash on death.
		selfTbl.hasSplashed = true
		local ed = EffectData()
		ed:SetOrigin(selfTbl.rainStreakEnd)
		util.Effect("jcms_rainsplash", ed)
	end

	selfTbl.rainColour.a = 255 * (1-scalar) 

	render.SetMaterial(selfTbl.mat_rain)

	render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_DST_ALPHA, BLENDFUNC_REVERSE_SUBTRACT	 )
		render.DrawBeam( origin, origin + (rainLen * selfTbl.rainDir), 20, 0, 1, selfTbl.rainColour)
	render.OverrideBlend( false )
end