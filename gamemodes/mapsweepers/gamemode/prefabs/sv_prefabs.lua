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

-- // Prefabs {{{
	jcms.prefabs = {} --Filled by types files

	function jcms.prefab_Check(type, area)
		return jcms.prefabs[ type ].check(area)
	end

	function jcms.prefab_ForceStamp(type, area, bonusData)
		return jcms.prefabs[ type ].stamp(area, bonusData)
	end

	function jcms.prefab_TryStamp(type, area)
		local can, bonusData = jcms.prefab_Check(type, area)

		if can then
			local ent = jcms.prefab_ForceStamp(type, area, bonusData)
			return true, ent
		else
			return false
		end
	end

	function jcms.prefab_GetNaturalTypes()
		local t = {}

		for name, data in pairs(jcms.prefabs) do
			if data.natural then
				table.insert(t, name)
			end
		end

		return t
	end

	function jcms.prefab_GetNaturalTypesWithWeights()
		local t = {}

		for name, data in pairs(jcms.prefabs) do
			if data.natural then
				t[name] = data.weight or 1.0
			end
		end

		return t
	end

	function jcms.prefab_GetWallSpotsFromArea(area, elevation, injectionDistance, subdivisionByUnits, conicDivergence, conicSubdivision)
		local wallspots = {}
		local normals = {}

		local center = area:GetCenter()
		center.z = center.z + elevation

		injectionDistance = injectionDistance or 16
		subdivisionByUnits = subdivisionByUnits or 128
		conicDivergence, conicSubdivision = conicDivergence, conicSubdivision or 2

		local xSpan, ySpan = area:GetSizeX(), area:GetSizeY()
		local xSteps, ySteps = math.max(1, math.floor(xSpan / subdivisionByUnits)), math.max(1, math.floor(ySpan / subdivisionByUnits))

		for x = 1, xSteps do
			for sign = -1, 1, 2 do
				local fromPos = center + Vector(math.Remap(x, 0, xSteps + 1, -xSpan/2, xSpan/2), 0, 0)
				local targetPos = fromPos + Vector(0, sign*(ySpan/2 + injectionDistance), 0)

				local s, pos, normal = jcms.prefab_CheckConicWallSpot(fromPos, targetPos, conicDivergence, conicSubdivision)

				if s then
					table.insert(wallspots, pos)
					table.insert(normals, normal)
				end
			end
		end

		for y = 1, ySteps do
			for sign = -1, 1, 2 do
				local fromPos = center + Vector(0, math.Remap(y, 0, ySteps + 1, -ySpan/2, ySpan/2), 0)
				local targetPos = fromPos + Vector(sign*(xSpan/2 + injectionDistance), 0, 0)

				local s, pos, normal = jcms.prefab_CheckConicWallSpot(fromPos, targetPos, conicDivergence, conicSubdivision)

				if s then
					table.insert(wallspots, pos)
					table.insert(normals, normal)
				end
			end
		end
		
		return wallspots, normals
	end

	function jcms.prefab_CheckConicWallSpot(fromPos, targetPos, divergence, subdivision)
		local tr_Main = util.TraceLine {
			start = fromPos,
			endpos = targetPos
		}

		if not tr_Main.HitWorld then return false end
		local normal = tr_Main.HitNormal
		
		local zThreshold = 0.2 -- walls cant be this tilted
		if normal.z > zThreshold or normal.z < -zThreshold then return false end
		
		local normalAngle = normal:Angle()
		local right, up = normalAngle:Right(), normalAngle:Up()

		local angleThreshold = 1.25
		divergence = divergence or 48
		subdivision = subdivision or 3

		for i = 1, subdivision do
			local dist = divergence / subdivision * i

			for j = 1, 2 do
				local tr_Adj = util.TraceLine {
					start = fromPos,
					endpos = targetPos + (j == 1 and right or up)*dist
				}
				
				if not tr_Adj.HitWorld then return false end
				if not normalAngle:IsEqualTol( tr_Adj.HitNormal:Angle(), angleThreshold ) then return false end
			end
		end

		return true, tr_Main.HitPos, tr_Main.HitNormal
	end

	function jcms.prefab_CheckOverlooking(area)
		--Check function for prefabs meant to overlook large spaces. 

		if ( area:GetSizeX()*area:GetSizeY() ) <= 60000 then
			return false
		end

		if #area:GetVisibleAreas() < jcms.mapgen_GetVisData().avg then
			return false
		end

		local c1, c2, c3, c4 = area:GetCorner(1), area:GetCorner(2), area:GetCorner(3), area:GetCorner(0)
		if math.max(c1.z, c2.z, c3.z, c4.z) - math.min(c1.z, c2.z, c3.z, c4.z) > 34 then
			return false
		end

		local corners = { c1, c2, c3, c4 }
		local sideVisibilities = { 0, 0, 0, 0 }
		local weighed = {}
		local sideVectors = {}

		local tr = {}
		local traceData = {
			mins = Vector(-2, -2, 0),
			maxs = Vector(2, 2, 4),
			mask = MASK_SHOT,
			output = tr
		}

		for side=1, 4 do
			local v = corners[side%4+1] + corners[(side+1)%4+1]
			v:Div(2)
			v.z = v.z + 24

			sideVectors[side] = v
			traceData.start = v

			for i = 1, 3 do
				for j = 1, 6 do
					local ang = Angle((i-1)*10, 90*side + math.Remap(j, 1, 6, -45, 45), 0)
					traceData.endpos = ang:Forward()
					traceData.endpos:Mul(500+i*500)
					traceData.endpos:Add(v)
					util.TraceHull(traceData)
					
					sideVisibilities[side] = sideVisibilities[side] + tr.Fraction
				end
			end

			v.z = v.z - 24 - 10
		end

		do
			local maximum = 0
			for side=1,4 do
				if sideVisibilities[side] > maximum then
					maximum = sideVisibilities[side]
				end
			end

			local threshold = (maximum >= 10) and 9.5 or (maximum >= 5) and 3 or 9999999
			for side=1,4 do
				if sideVisibilities[side] > threshold then
					weighed[side] = sideVisibilities[side] + 1
				end
			end
		end

		local chosen = jcms.util_ChooseByWeight(weighed)
		if chosen then
			return true, { pos = sideVectors[ chosen ], ang = Angle(0, 90*chosen, 0) }
		else
			return false
		end
	end
-- // }}}
