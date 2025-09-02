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
local class = {}
class.orderIndex = 1
jcms.class_Add("recon", class, true)

-- Kestrel Armor
class.mdl = "models/player/urban.mdl"
class.footstepSfx = "NPC_MetroPolice.RunFootstep"

class.health = 75
class.shield = 30
class.shieldRegen = 7.5 -- Armor/suit power restoration, per second
class.shieldDelay = 2.75 -- This many seconds must've passed since unit last got hurt to start restoring

class.damage = 1 -- This unit deals 1.0x damage
class.hurtMul = 1 -- This unit takes 1.0x damage
class.hurtReduce = 1 -- Subtracted from damage taken
class.speedMul = 1.25 -- Speed multiplier
class.walkSpeed = 160
class.runSpeed = 350
class.jumpPower = 280 -- Self-explanatory
class.shareObjectiveMarkers = true

class.noFallDamage = true
class.sprintHack = true --Allow us to shoot while sprinting

class.matOverrides = { 
	["models/cstrike/ct_urban"] = "models/jcms/player/recon",
	["models/cstrike/ct_urban_glass"] = "jcms/jglow"
}

function class.SetupMove(ply, mv, cmd)
	if ply:Alive() and not ply:OnGround() and ply:WaterLevel()<3 and not IsValid(ply:GetNWEntity("jcms_vehicle")) then
		if ply.jcms_CanJump and mv:KeyPressed(IN_JUMP) then
			ply.jcms_CanJump = false

			local vel = ply:GetVelocity()
			vel:Mul( 0.12 )

			local lim = mv:GetMaxSpeed()
			local ang = mv:GetAngles()
			local jump = Vector(0, 0, 0)
			local fwd = math.Clamp(mv:GetForwardSpeed(), -lim, lim)
			local right = math.Clamp(mv:GetSideSpeed(), -lim, lim)
			jump:Add( ang:Forward() * fwd )
			jump:Add( ang:Right() * right )
			jump:Normalize()
			jump:Mul(ply:GetJumpPower())
			jump.z = ply:GetJumpPower() + 25

			vel:Add( jump )
			mv:SetVelocity(vel)

			-- Damage
			local tr = util.TraceEntity({ 
				start = ply:GetPos(), 
				endpos = ply:GetPos() + Vector(0, 0, -220), 
				filter = ply
			}, ply)

			sound.Play("weapons/grenade_launcher1.wav", ply:GetPos(), 70, 88, 1)

			if tr.Hit then
				local pos = tr.HitPos

				if SERVER then
					timer.Simple(0, function()
						local ed = EffectData()
						ed:SetOrigin(pos)
						util.Effect("HelicopterMegaBomb", ed)
					end)
					sound.Play("ambient/explosions/explode_9.wav", ply:GetPos(), 95, 105, 1)
				end

				local dmg = DamageInfo()
				dmg:SetDamagePosition(ply:GetPos())
				dmg:SetReportedPosition(ply:GetPos())
				dmg:SetDamageType( DMG_CRUSH )
				dmg:SetInflictor(ply)
				dmg:SetAttacker(ply)

				for i, target in ipairs( ents.FindInSphere(pos, 128) ) do
					if not jcms.team_SameTeam(ply, target) and target.TakeDamageInfo then
						dmg:SetDamage( 25 )
						target:TakeDamageInfo(dmg)
					end
				end
				if tr.Entity then
					if not jcms.team_SameTeam(ply, tr.Entity) and tr.Entity.TakeDamageInfo then --An extra 25 dmg if we are on top of it.
						dmg:SetDamage(25)
						tr.Entity:TakeDamageInfo(dmg)
					end
				end
			end
		end
	else
		ply.jcms_CanJump = true
	end
end

if CLIENT then
	class.stats = {
		offensive = "0",
		resistance = "-2",
		mobility = "2"
	}

	function class.CalcView(ply, origin, angles, fov)
		if jcms.cvar_motionsickness:GetBool() then return end

		local plyTbl = ply:GetTable()
		local cTime = CurTime()

		plyTbl.lastCalcView = plyTbl.lastCalcView or cTime
		plyTbl.lastFov = plyTbl.lastFov or fov

		-- todo: It'd be nice to add some over-correction to fast changes, so that quick stops/starts feel a bit more impactful.
		local factor = math.Clamp( (ply:GetVelocity():Length() - class.walkSpeed) / 2000, 0, 1)
		local desiredFov = fov * (2 + factor) / 2

		--Limit how much we change over time
		local dt = cTime - plyTbl.lastCalcView
		local finalFov = Lerp( dt * 10, plyTbl.lastFov, desiredFov )

		plyTbl.lastCalcView = cTime
		plyTbl.lastFov = finalFov
	
		return finalFov
	end

	class.highlightEnts = {
		["item_battery"] = true,
		["item_healthkit"] = true,
		["item_healthvial"] = true,
		["item_healthcharger"] = true,
		["item_suitcharger"] = true,
		["jcms_shop"] = true,
		["item_item_crate"] = true
	}

	local emt = FindMetaTable("Entity") --Optimisation
	local function drawModels(entities, eyePos)
		local maxDist, minDist = 5000, 0

		for i, ent in ipairs(entities) do 
			if IsValid(ent) and class.highlightEnts[emt.GetClass(ent)] then
				local dist = emt.GetPos(ent):DistToSqr(eyePos)
				
				if dist < maxDist^2 and dist > minDist^2 then
					emt.DrawModel(ent)
				end
			end
		end
	end

	function class.PreDrawOpaqueRenderables(ply)
		local eyePos = EyePos()
	
		render.SetStencilEnable(true)
		render.ClearStencil()
		render.SetStencilTestMask(255)
		render.SetStencilWriteMask(255)
		
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_REPLACE)
		render.SetStencilReferenceValue(1)
		
		cam.Start3D()
			render.OverrideBlend(true, BLEND_ZERO, BLEND_ONE, BLENDFUNC_ADD)
			drawModels(ents.FindByClass("item_*"), eyePos) --Way better than ents.iterator for optimisation. even if this is a little jank.
			drawModels(ents.FindByClass("jcms_shop"), eyePos)

			render.OverrideBlend(false)
		cam.End3D()
		
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilReferenceValue(1)
		cam.Start2D()
			local r, g, b = jcms.color_bright:Unpack()
			local scrW, scrH = ScrW(), ScrH()
			render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD)
			surface.SetDrawColor(r, g, b, 200)
			jcms.hud_DrawNoiseRect(0, 0, scrW, scrH, 24)

			render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
			surface.SetDrawColor(r, g, b, 255)
			jcms.hud_DrawNoiseRect(0, 0, scrW, scrH, 24)
		cam.End2D()
		render.OverrideBlend(false)
		
		render.SetStencilEnable( false )
		render.ClearStencil()

	end
end
