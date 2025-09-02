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

EFFECT.mat_glow = Material "sprites/blueglow2"
EFFECT.mat_ring = Material "effects/select_ring"
EFFECT.mat_spark = Material "effects/spark"
EFFECT.mat_shield = Material "models/shiny"
EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local function drawShieldModel(self, ent, sc, color)
	local selfTbl = self:GetTable()

	local scVec = Vector(sc, sc, sc) 
	for i=1, ent:GetBoneCount() do
		ent:ManipulateBoneScale(i, scVec)
	end

	ent:RemoveAllDecals()
	
	local oldMat = ent:GetMaterial()
	render.SetColorModulation(color.r/32, color.g/32, color.b/32)
	render.ModelMaterialOverride(selfTbl.mat_shield)
	render.MaterialOverride(selfTbl.mat_shield)
	render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_ONE, BLENDFUNC_ADD)
		ent:SetupBones()
		ent:DrawModel()
	render.OverrideBlend(false)
	render.MaterialOverride()
	render.ModelMaterialOverride()
	render.SetColorModulation(1, 1, 1)
	
	for i=1, ent:GetBoneCount() do
		ent:ManipulateBoneScale(i, jcms.vectorOne)
	end
end

function EFFECT:Init( data )
	self.t = 0
	if data:GetFlags() == 0 then -- Player damaged with shields on
		self.mode = 0
		self.pos = data:GetOrigin()
		self.normal = data:GetNormal()
		self.scale = data:GetScale()
		self.tout = math.Rand(0.15, 0.25)
	elseif data:GetFlags() == 1 then -- Shield has been broken
		self.mode = 1
		self.ent = data:GetEntity()
		self.tout = math.Rand(0.22, 0.28)
		
		self.sparks = {}
		for i=1, math.random(20, 40) do
			local spark = {}
			spark.start = VectorRand(-16, 16)
			spark.endpos = spark.start + spark.start:GetNormalized()*math.Rand(16, 64)
			spark.width = math.Rand(1, 4)^2
			spark.off = math.random()*0.3
			table.insert(self.sparks, spark)
		end
	elseif data:GetFlags() == 2 then -- Shield has been fully restored
		self.mode = 2
		self.ent = data:GetEntity()
		self.t = -0.2
		self.tout = 1

		if self.ent == LocalPlayer() then
			jcms.hud_shieldRestoredAnim = 0
		end
	end

	self.color1 = jcms.util_ColorFromInteger( data:GetColor() )
	self.color2 = Color( self.color1:Unpack() )
	self.color3 = Color( self.color1:Unpack() )
end

local vec4 = Vector(4,4,4)
function EFFECT:Think()
	local selfTbl = self:GetTable()
	if (selfTbl.t < selfTbl.tout) and (selfTbl.mode) and (not selfTbl.ent or IsValid(selfTbl.ent)) then
		if selfTbl.ent then
			local pos = selfTbl.ent:GetPos()
			self:SetRenderBoundsWS(pos - selfTbl.ent:OBBMins(), pos + selfTbl.ent:OBBMaxs(), vec4)
		end
		selfTbl.t = math.min(selfTbl.tout, selfTbl.t + FrameTime())
		return true
	else
		return false
	end
end

function EFFECT:Render()
	local selfTbl = self:GetTable()

	if selfTbl.mode == 0 then
		local f = selfTbl.t/selfTbl.tout
		
		local col1 = selfTbl.color1
		local col2 = selfTbl.color2
		col2:SetUnpacked( col1:Unpack() )
		col2.a = 64
		local col3 = selfTbl.color3
		col3.r = col1.r * f
		col3.g = col1.g * f
		col3.b = col1.b * f

		render.SetMaterial(selfTbl.mat_glow)
		local size = Lerp(f, 32, 0)*selfTbl.scale
		render.DrawQuadEasy(selfTbl.pos, selfTbl.normal, size/2, size/2, col1, math.random()*360)

		render.DrawSprite(selfTbl.pos, size*2, size, col2)
		render.SetMaterial(selfTbl.mat_ring)
		size = Lerp(math.ease.InQuart(f), 0, 16)*selfTbl.scale
		render.DrawQuadEasy(selfTbl.pos, selfTbl.normal, size, size, col3, math.random()*360)
	elseif selfTbl.mode == 1 then
		if IsValid(selfTbl.ent) then
			local boneId = selfTbl.ent:LookupBone("ValveBiped.Bip01_Spine1")
			local matrix = boneId and selfTbl.ent:GetBoneMatrix(boneId)
			local mypos = matrix and matrix:GetTranslation() or selfTbl.ent:WorldSpaceCenter()
			local color = selfTbl.color1
			
			render.SetMaterial(selfTbl.mat_spark)
			local sparkStart = Vector(mypos)
			local sparkEnd = Vector(mypos)
			for i, spark in ipairs(selfTbl.sparks) do
				local f = math.Clamp((selfTbl.t-spark.off)/(selfTbl.tout-spark.off*2), 0, 1)
				local anim = Lerp(f, -0.5, 0.7)
				local parabolic = 1-f^2
				sparkStart:Add(spark.start)
				sparkEnd:Add(spark.endpos)

				render.DrawBeam(sparkStart, sparkEnd, spark.width*parabolic, anim+0.5, anim^2, color)
				
				sparkEnd:Sub(spark.endpos)
				sparkStart:Sub(spark.start)
			end
			
			local parabolic = selfTbl.t*2/selfTbl.tout
			if parabolic < 1 then
				local sc = Lerp(parabolic, 1, 3)
				drawShieldModel(self, selfTbl.ent, sc, color)
			end
		end
	elseif selfTbl.mode == 2 then
		if selfTbl.t < 0 or not IsValid(selfTbl.ent) then
			return
		end
		
		local rings = 6
		local vUp = jcms.vectorUp
		local radius = selfTbl.ent:BoundingRadius()
		local color = selfTbl.color1
		
		local boneId = selfTbl.ent:LookupBone("ValveBiped.Bip01_Head1")
		local matrix = boneId and selfTbl.ent:GetBoneMatrix(boneId)
		local ringpos = matrix and matrix:GetTranslation() or selfTbl.ent:WorldSpaceCenter()
		ringpos.z = selfTbl.ent:GetPos().z
		
		local baseRingZ = ringpos.z
		for i=1, rings do
			local f = math.ease.InOutQuart(math.Clamp((selfTbl.t - (i*2/rings)/rings) / (selfTbl.tout - 2/rings), 0, 1))
			local parabolic = math.max(0,-4*(f*f)+4*f)
			local size = Lerp(parabolic^0.5, 24, 48)
			render.SetMaterial(selfTbl.mat_ring)
			ringpos.z = baseRingZ + Lerp(f, radius*0.1, radius*1.6)
			render.DrawQuadEasy(ringpos, vUp, size, size, color, 0)
		end
		
		local f = math.ease.InOutQuart(selfTbl.t/selfTbl.tout, 0, 1)
		local parabolic = math.max(0,-4*(f*f)+4*f)^0.3
		local sc = Lerp(parabolic, 1, 1.5)
		drawShieldModel(self, selfTbl.ent, sc, color)
	end
end
