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
ENT.PrintName = "Orbital Beam"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.DPS = 90
ENT.DPS_DIRECT = 120

jcms.deathray_npcMinDamageThresholds = {
	["npc_strider"] = 100,
	["npc_combinegunship"] = 75,
	["npc_helicopter"] = 150
}

jcms.deathray_dmgMultipliers = {
	["npc_helicopter"] = 4.5,
	["npc_jcms_zombiespawner"] = 3
}

if SERVER then
	sound.Add( {
		name = "jcms_deathray_blast",
		channel = CHAN_STATIC,
		volume = 1.0,
		level = 140,
		pitch = 90,
		sound = {
			"ambient/levels/citadel/weapon_disintegrate3.wav",
			"ambient/levels/citadel/weapon_disintegrate4.wav"
		}
	} )
end

function ENT:Initialize()
	if CLIENT then
		self.soundBeam = CreateSound(self, "ambient/levels/citadel/zapper_loop1.wav")
		self.soundBeam:ChangePitch(130, 0)
		self.soundBeam:SetSoundLevel(200)

		self.BeamColor = Color(255, 0, 0)

		self.pixVis = {}
		for i=1, 10 do 
			self.pixVis[i] = util.GetPixelVisibleHandle()
		end
	end

	self:DrawShadow(false)
end

if SERVER then
	function ENT:Think()
		local selfTbl = self:GetTable() 
		local iv = 1/20
		selfTbl:SetBeamTime(selfTbl:GetBeamTime() + iv)
		
		local beamTime, prepTime, lifeTime = selfTbl:GetBeamTime(), selfTbl:GetBeamPrepTime(), selfTbl:GetBeamLifeTime()
		if beamTime >= prepTime and beamTime <= lifeTime + prepTime then
			local tr = self:GetBeamTrace()
			local rad = selfTbl:GetBeamRadius()
			local targets = ents.FindAlongRay(tr.StartPos, tr.HitPos, Vector(-rad/2, -rad/2, -4), Vector(rad/2, rad/2, 4))
			table.RemoveByValue(targets, self)
			local parent = self:GetParent()
			if IsValid(parent) then 
				table.RemoveByValue(targets, parent)
			end

			local dmg = DamageInfo()
			dmg:SetDamage(selfTbl.DPS * iv)
			
			if IsValid(selfTbl.jcms_owner) then
				dmg:SetAttacker(selfTbl.jcms_owner)
			else
				dmg:SetAttacker(self)
			end
			
			dmg:SetInflictor(self)
			dmg:SetReportedPosition(self:GetPos())
			dmg:SetDamageForce(Vector(0, 0, 0))
			dmg:SetDamageType( bit.bor(DMG_BLAST, DMG_DISSOLVE, DMG_DIRECT, DMG_AIRBOAT) )
			
			util.BlastDamageInfo(dmg, tr.HitPos + vector_up, rad * 4)

			local basedmg = selfTbl.DPS_DIRECT
			for i, target in ipairs(targets) do
				if jcms.team_GoodTarget(target) then
					local targetclass = target:GetClass()
					local threshold = jcms.deathray_npcMinDamageThresholds[ targetclass ] or 15
					dmg:SetDamagePosition(target:WorldSpaceCenter())
					
					if threshold > 1 then
						local multiplier = jcms.deathray_dmgMultipliers[ targetclass ] or 1
						target.jcms_beamSumDmg = (target.jcms_beamSumDmg or 0) + dmg:GetDamage()*multiplier
						
						if target.jcms_beamSumDmg >= threshold then
							target.jcms_beamSumDmg = target.jcms_beamSumDmg - threshold
							dmg:SetDamage(threshold)
							target:DispatchTraceAttack(dmg, tr)
							dmg:SetDamage(basedmg)
							
							local ed = EffectData()
							ed:SetMagnitude(0.5)
							ed:SetOrigin(target:EyePos())
							ed:SetRadius(threshold / 10 + 72)
							ed:SetNormal(target:GetAngles():Up())
							ed:SetFlags(2)
							util.Effect("jcms_blast", ed)
							
							target:EmitSound("jcms_deathray_blast")
							target:Ignite(math.ceil(threshold/5))
						end
					else
						target:DispatchTraceAttack(dmg, tr)
					end
				end
			end
		elseif beamTime >= lifeTime + prepTime then
			self:Remove()
		end
		
		self:NextThink(CurTime() + iv)
		return true 
	end
end

if CLIENT then
	ENT.MatBeamInner = CreateMaterial("jcms_orbitalbeam_nofog", "Sprite", {
		["$basetexture"] = "sprites/physbeam_active_white",
		["$spriteorientation"] = "parallel_upright",
		["$spriteorigin"] = "[ 0.50 0.50 ]",
		["$spriterendermode"] = 5,
		["$nofog"] = 1
	})
	--ENT.MatBeamInner = Material("sprites/physbeama")
	ENT.MatBeamOuter = Material("trails/plasma")
	ENT.MatBeamLight = Material("effects/lamp_beam.vmt")
	ENT.MatGlow = Material("particle/Particle_Glow_04")

	function ENT:CalcWidthMultiplier(t, dur)
		local inout = math.min(dur, 0.5)
		return math.ease.InBack(math.max(0,math.min(1,t/0.5,(-t+dur)/0.5)))
	end

	function ENT:DrawTranslucent()
		local selfTbl = self:GetTable()
		local beamTime, prepTime, lifeTime = selfTbl:GetBeamTime(), selfTbl:GetBeamPrepTime(), selfTbl:GetBeamLifeTime()
		
		if selfTbl.GetBeamIsBlue() then
			selfTbl.BeamColor.r = 32
			selfTbl.BeamColor.g = 128
			selfTbl.BeamColor.b = 255
		else
			selfTbl.BeamColor.r = 255
			selfTbl.BeamColor.g = 0
			selfTbl.BeamColor.b = 0
		end

		if beamTime <= prepTime then
			local tr = self.tr or selfTbl.GetBeamTrace(self)
			local beamStartPos = tr.StartPos
			if self:GetBeamIsSky() then
				beamStartPos = Vector(beamStartPos.x, beamStartPos.y, 256000)
			end

			local f = (beamTime / prepTime)^2
			render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
				local beamColor = selfTbl.BeamColor
				render.SetMaterial(selfTbl.MatBeamInner)
				render.DrawBeam(beamStartPos, tr.HitPos, math.Rand(6, 8)*f, 0, 1, beamColor)
				render.SetMaterial(selfTbl.MatBeamLight)
				render.DrawBeam(beamStartPos, tr.HitPos, 32*f^2, 0, 1, beamColor)
			render.OverrideBlend(false)
		elseif beamTime <= lifeTime + prepTime then
			local wm = self:CalcWidthMultiplier(beamTime - prepTime, lifeTime)
			local rad = selfTbl.GetBeamRadius()
			render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
			
			local tr = selfTbl.tr or selfTbl.GetBeamTrace(self)
			local beamStartPos = tr.StartPos
			if self:GetBeamIsSky() then
				beamStartPos = Vector(beamStartPos.x, beamStartPos.y, 256000)
			end

			local scroll = -beamTime
			local lenfactor = tr.HitPos:Distance(beamStartPos)/(rad*8)

			local beamColor = selfTbl.BeamColor
			local beamColorBrighter = Color(selfTbl.BeamColor:Unpack())
			beamColorBrighter:SetUnpacked((beamColorBrighter.r + 255)/2, (beamColorBrighter.g + 255)/2, (beamColorBrighter.b + 255)/2)
			
			render.SetMaterial(selfTbl.MatBeamOuter)
			render.DrawBeam(beamStartPos, tr.HitPos, math.Rand(5, 10)*rad*wm, scroll*lenfactor, (scroll+1)*lenfactor, beamColor)
			render.SetMaterial(selfTbl.MatBeamInner)
			render.DrawBeam(beamStartPos, tr.HitPos, math.Rand(3, 8)*rad*wm, scroll*lenfactor, (scroll+1)*lenfactor, beamColorBrighter)
			render.SetMaterial(selfTbl.MatGlow)
			
			tr.HitPos:Add(tr.HitNormal)
			render.DrawQuadEasy(tr.HitPos, tr.HitNormal, math.Rand(8, 13)*rad*wm, math.random(3, 4)*rad*wm, beamColorBrighter, 360*math.random())
			render.DrawQuadEasy(tr.HitPos, tr.HitNormal, math.random(9, 14)*rad*wm, math.random(2, 4)*rad*wm, beamColorBrighter, 360*math.random())
			render.DrawQuadEasy(tr.HitPos, tr.HitNormal, math.random(6, 14)*rad*wm, math.random(6, 14)*rad*wm, beamColor, wm*360)
			render.DrawQuadEasy(beamStartPos, tr.Normal, math.random(6, 14)*rad*wm, math.random(6, 14)*rad*wm, beamColorBrighter, wm*360)

			render.SetMaterial(selfTbl.MatBeamLight)
			render.DrawBeam(beamStartPos, tr.HitPos, math.Rand(15, 18)*rad*wm, 0, 1, beamColor)
			render.OverrideBlend(false)
		end
	end

	function ENT:Think()
		local selfTbl = self:GetTable()

		local tr = selfTbl.GetBeamTrace(self) --Gets our trace and also updates it for the draw func.

		local ft = FrameTime()
		selfTbl:SetBeamTime(selfTbl:GetBeamTime() + ft)
		self:SetPos(self:GetPos() + selfTbl:GetBeamVelocity()*ft)
		self:SetRenderBoundsWS(tr.StartPos, tr.HitPos)
		
		local beamTime, prepTime, lifeTime = selfTbl:GetBeamTime(), selfTbl:GetBeamPrepTime(), selfTbl:GetBeamLifeTime()
		local wm = self:CalcWidthMultiplier(beamTime - prepTime, lifeTime)
		
		local intensity = math.sqrt(math.max(0, wm * math.max(0, 1 - EyePos():Distance(tr.HitPos)/6000)))

		local visibility = 0 
		for i, pv in ipairs(selfTbl.pixVis) do 
			local travelVec = tr.HitPos - tr.StartPos
			local dist = travelVec:Length()

			local pos = tr.StartPos + travelVec * (i/10)
			local rad = dist * 0.15 --10 + 5% to make it a better approximation of a cylinder.
			visibility = math.max(visibility, util.PixelVisible( pos, rad, pv ))
		end

		visibility = math.min(1, visibility*2.25) --half of the sphere is going to be underground, ignore that.
		intensity = intensity * 0.925 + (intensity * visibility * 0.075) --If we can't see the beam, make the screen-effects less intense.

		local red = jcms.hud_blindingRedLight or 0
		if selfTbl:GetBeamIsBlue() then
			jcms.hud_blindingRedLight = math.min(red, (red - intensity)/2)
		else
			jcms.hud_blindingRedLight = math.max(red, (red + intensity)/2)
		end

		util.ScreenShake(tr.HitPos, 9*intensity^10, 50, 0.1, 50*wm, true)

		if beamTime <= prepTime then
			if beamTime > prepTime - 0.5 and not selfTbl.sndPlayedPre then
				local _, lineVec = util.DistanceToLine(tr.StartPos, tr.HitPos, EyePos())
				EmitSound("ambient/levels/citadel/portal_beam_shoot6.wav", lineVec, 0, CHAN_AUTO, 1, 200, 0, 100, 0)
				selfTbl.sndPlayedPre = true
			end
		elseif beamTime > prepTime and beamTime <= lifeTime + prepTime then
			if not selfTbl.sndPlayed then
				self:EmitSound("beams/beamstart5.wav", 105, 88)
				selfTbl.sndPlayed = true
				
				selfTbl.soundBeam:Play()
				selfTbl.soundBeam:ChangePitch(100, 2)
			end
			
			if not selfTbl.sndEnded and beamTime >= lifeTime + prepTime - 0.5 then
				selfTbl.soundBeam:ChangePitch(10, 0.5)
				selfTbl.sndEnded = true

				local _, lineVec = util.DistanceToLine(tr.StartPos, tr.HitPos, EyePos())
				EmitSound("ambient/levels/citadel/portal_beam_shoot3.wav", lineVec, 0, CHAN_AUTO, 1, 200, 0, 130, 0)
				self:EmitSound("ambient/levels/citadel/portal_beam_shoot3.wav", 105, 130)
			end
		end
		
		self:SetNextClientThink(CurTime() + 1/66) --Consistent think rate / don't think faster than the server can.
		return true 
	end

	function ENT:OnRemove()
		if self.soundBeam then
			self.soundBeam:Stop()
		end
	end
end

function ENT:GetBeamTrace()
	local pos = self:GetPos()
	local endpos = Vector(pos.x, pos.y, pos.z - 32000)

	local tr = util.TraceLine {
		start = pos, endpos = endpos, mask = MASK_VISIBLE, filter = self.filter
	}

	self.tr = tr --For avoiding duplicate work in Draw calls
	return tr
end

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "BeamTime")
	self:NetworkVar("Float", 1, "BeamRadius")
	self:NetworkVar("Vector", 0, "BeamVelocity")
	self:NetworkVar("Float", 2, "BeamLifeTime")
	self:NetworkVar("Float", 3, "BeamPrepTime")
	self:NetworkVar("Bool", 0, "BeamIsBlue")
	self:NetworkVar("Bool", 1, "BeamIsSky")

	if SERVER then
		self:SetBeamRadius(32)
		self:SetBeamLifeTime(15)
		self:SetBeamPrepTime(2)
	end
end
