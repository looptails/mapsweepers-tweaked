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

local upVector = Vector(0, 0, 1)
local upVector2 = Vector(0, 0, 2)

EFFECT.mat = Material "effects/spark"
EFFECT.mat_gunship = Material "effects/fluttercore_gmod"
EFFECT.mat_light = Material "sprites/light_glow02_add"
EFFECT.mat_ring = Material "effects/select_ring"
EFFECT.mat_warnbeam = CreateMaterial("jcms_orbitalwarnbeam", "Refract", {
	["$refractamount"] = 0,
	["$bluramount"] = 0,
	["$dudvmap"] = "trails/tube_nrm.vtf",
	["$normalmap"] = "trails/tube_nrm.vtf",
	["$nocull"] = 1,
	["$ignorez"] = 0,

	["Refract_DX80"] = {
		["$fallbackmaterial"] = "null"
	},

	["Refract_DX60"] = {
		["$fallbackmaterial"] = "null"
	}
} )

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	self.start = data:GetStart()
	self.endpos = data:GetOrigin()
	self.type = data:GetFlags()

	self:SetRenderBoundsWS(self.start, self.endpos)

	self.t = 0
	self.tout = 0.5
	self.color = Color(255, 255, 255, 255)

	if self.type == 3 then
		-- Get random position in the sky above.
		sound.Play("npc/strider/fire.wav", self.start, 150, 80, 1, 25)
		self.delay = data:GetMagnitude()
		self.t = -self.delay -- Delay
		
		local randomVisualSkyTrace = util.TraceLine {
			start = self.endpos, endpos = self.endpos + Vector(math.Rand(-8000, 8000), math.Rand(-8000, 8000), 32000)
		}

		if randomVisualSkyTrace.HitSky then
			self.start = randomVisualSkyTrace.HitPos
		else
			local directSkyPos, isClear = jcms.util_GetSky(randomVisualSkyTrace.HitPos)

			if isClear then
				self.start = directSkyPos
			end
		end

	elseif self.type == 5 then
		self.radius = data:GetMagnitude()
		self.tout = 0.25 + math.sqrt(self.radius / 1200)
	end

	self.length = self.start:Distance(self.endpos)
	self.traveled = 0
	self.travelspeed = math.max(10000, self.length / self.tout)
end

function EFFECT:Think()
	local selfTbl = self:GetTable()
	if selfTbl.t < selfTbl.tout then
		local ft = FrameTime()
		selfTbl.t = math.min(selfTbl.tout, selfTbl.t + ft)
		selfTbl.traveled = selfTbl.traveled + selfTbl.travelspeed * ft

		if selfTbl.type == 3 then
			if selfTbl.t >= 0 and not selfTbl.didExplosion then
				local ed = EffectData()
				ed:SetMagnitude(1)
				ed:SetOrigin(selfTbl.endpos)
				ed:SetRadius(450)
				ed:SetNormal(upVector)
				ed:SetFlags(2)
				util.Effect("jcms_blast", ed)
				util.Effect("Explosion", ed)

				sound.Play("Explo.ww2bomb", selfTbl.endpos, 140, 110)
				selfTbl.didExplosion = true
			end
		end

		return true
	else
		return false
	end
end

function EFFECT:Render()
	local selfTbl = self:GetTable()
	local eyeDist = jcms.EyePos_lowAccuracy:DistToSqr(selfTbl.endpos)
	local f = selfTbl.t / selfTbl.tout
	local ff = math.ease.InQuart(1 - f)
	
	local width = 24
	if selfTbl.type == 0 then
		-- Blue bolt
		selfTbl.color.r = 64*ff
		selfTbl.color.g = 255*ff
		selfTbl.color.b = 255*(1-f)
		selfTbl.color.a = 256*ff
		width = 32
	elseif selfTbl.type == 4 then
		-- Cybergunship Explosive Pulse
		selfTbl.color.r = 255*(1-f)
		selfTbl.color.g = 200*ff
		selfTbl.color.b = 255*(1-f)
		selfTbl.color.a = 256*ff
		width = 48

		local bulletLength = selfTbl.length / 512
		local tx1 = math.Remap(selfTbl.traveled, 0, selfTbl.length, -bulletLength, 1)
		local tx2 = tx1 + bulletLength
		
		render.SetMaterial(selfTbl.mat)
		render.DrawBeam(selfTbl.endpos, selfTbl.start, width/2, tx1, tx2, color_white)

		if not selfTbl.sparkpos then
			local norm = selfTbl.endpos - selfTbl.start
			norm:Normalize()
			norm:Rotate( AngleRand(-32, 32) )
			norm:Mul( math.random(64, 364) )
			norm:Add(selfTbl.start)
			selfTbl.sparkpos = norm
		end

		render.DrawBeam(selfTbl.sparkpos, selfTbl.start, width/2, tx1, tx2, color_white)
	elseif selfTbl.type == 3 then
		-- Shelling railgun

		if f < 0 then
			local invf = -selfTbl.t / selfTbl.delay
			selfTbl.color.r = math.min(255, invf*255*2)
			selfTbl.color.g = math.min(255, invf*invf*140*2)
			selfTbl.color.b = math.min(255, invf*160*2)
			selfTbl.color.a = invf*255
			width = 32*invf
		else
			selfTbl.color.r = 255*(1-f)
			selfTbl.color.g = 140*ff
			selfTbl.color.b = 190*ff
			selfTbl.color.a = 256*ff
			width = 500
		end
	else
		-- Gatling bolt (type=1 normal, type=2 explosive, type=5 explosive ammo (upgrade station))
		selfTbl.color.r = 255*(1-f)
		selfTbl.color.g = 255*ff
		selfTbl.color.b = 230*ff
		selfTbl.color.a = 256*ff
		if selfTbl.type == 2 then
			width = 48
		elseif selfTbl.type == 5 then
			width = math.sqrt(self.radius) + 1
		end

		local bulletLength = selfTbl.length / 512
		local tx1 = math.Remap(selfTbl.traveled, 0, selfTbl.length, -bulletLength, 1)
		local tx2 = tx1 + bulletLength
		
		render.SetMaterial(selfTbl.mat)
		
		if selfTbl.type == 5 then
			render.StartBeam(2)
				render.AddBeam(selfTbl.endpos, width, 0, selfTbl.color)
				render.AddBeam(selfTbl.start, width/4, 1, selfTbl.color)
			render.EndBeam()
		else
			render.DrawBeam(selfTbl.endpos, selfTbl.start, width/2, tx1, tx2, color_white)
		end
	end
	
	local ff2 = 1 - math.Clamp(selfTbl.t/0.15, 0, 1)
	render.SetMaterial(selfTbl.type == 4 and selfTbl.mat_gunship or selfTbl.mat)

	-- Beam {{{
		if selfTbl.type == 3 then
			-- Shelling railgun
			if not selfTbl.posFarInTheSky then
				selfTbl.posFarInTheSky = LerpVector(-50, selfTbl.start, selfTbl.endpos)
			end

			if f < 0 then
				local invf = 1 - (-selfTbl.t / selfTbl.delay)
				local parabolic = math.max(0,-4*(invf*invf)+4*invf)
				
				selfTbl.mat_warnbeam:SetFloat("$refractamount", parabolic*0.03 )
				selfTbl.mat_warnbeam:Recompute()
				render.SetMaterial(selfTbl.mat_warnbeam)

				render.DrawBeam(selfTbl.posFarInTheSky, selfTbl.endpos, width*parabolic + 8, 0, invf, selfTbl.color)
				render.SetMaterial(selfTbl.mat)
				render.DrawBeam(selfTbl.posFarInTheSky, selfTbl.endpos, width * (1 + invf), 1-invf, invf, selfTbl.color)
			else
				render.DrawBeam(selfTbl.posFarInTheSky, selfTbl.endpos, width/2*ff, 0, 0.8, selfTbl.color)
				render.DrawBeam(selfTbl.posFarInTheSky, selfTbl.endpos, width*ff, ff2-1, ff2+1, selfTbl.color)
			end
		else
			render.DrawBeam(selfTbl.start, selfTbl.endpos, width/2*ff, 0, 0.8, selfTbl.color)
			render.DrawBeam(selfTbl.start, selfTbl.endpos, width*ff, ff2-1, ff2+1, selfTbl.color)
		end
	-- }}}
	
	if selfTbl.type == 0 then
		if eyeDist < 2000^2 then
			render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
				render.SetMaterial(selfTbl.mat_light)
				render.DrawSprite(selfTbl.endpos, 128*(1-f), 64*ff, selfTbl.color)
			render.OverrideBlend( false )
		end
	elseif selfTbl.type == 3 then
		-- Shelling railgun
		if f < 0 and eyeDist < 2000^2 then
			local qs = math.ease.InCirc(-selfTbl.t / selfTbl.delay) * 400
			render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
				selfTbl.color.a = (1 + selfTbl.t / selfTbl.delay) * 255
				render.SetMaterial(selfTbl.mat_ring)
				render.DrawQuadEasy(selfTbl.endpos + upVector2, upVector, qs, qs, selfTbl.color, 0)
			render.OverrideBlend( false )
		end
	elseif selfTbl.type == 2 or selfTbl.type == 4 or selfTbl.type == 5 then
		-- Blast
		local size = self.radius or 128

		if size >= 220 and not selfTbl.doneBigExplosion then
			local ed = EffectData()
			ed:SetMagnitude(0.6)
			ed:SetOrigin(selfTbl.endpos)
			ed:SetRadius(self.radius)
			ed:SetNormal(jcms.vectorUp)
			ed:SetFlags(1)
			util.Effect("jcms_blast", ed)
			selfTbl.doneBigExplosion = true
		end

		render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
			if not self.blastNormal then
				self.blastNormal = VectorRand()
			end

			local vnorm = self.blastNormal * Lerp(ff, size/4, size/2)

			for i=1, 6 do
				local v2 = VectorRand(-size/i*ff, size/i*ff)
				v2:Add(selfTbl.endpos)
				render.DrawQuad(selfTbl.endpos-vnorm, v2-vnorm, selfTbl.endpos+vnorm, v2+vnorm, selfTbl.color)
			end
			
			if selfTbl.type ~= 5 then
				render.SetMaterial(selfTbl.mat_light)
				render.DrawSprite(selfTbl.endpos, size*ff, size*ff, selfTbl.color)
			end
		render.OverrideBlend( false )
	end
end
