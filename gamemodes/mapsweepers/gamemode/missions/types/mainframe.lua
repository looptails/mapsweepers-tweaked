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

-- Mainframe {{{
	function jcms.mapgen_MainframeGenerateTrack(missionObjects, sectorDistances, areaSectors, totalSectors, mainframeArea, chosenSector, nodeCount) 
		local zoneDict = jcms.mapgen_ZoneDict()
		local mainframeZone = zoneDict[mainframeArea] or jcms.mapdata.largestZone
		
		local prevArea = (IsValid(mainframeArea) and mainframeArea) or jcms.mapgen_UseRandomArea()
		local mapCentre = (IsValid(mainframeArea) and mainframeArea:GetCenter()) or Vector(0,0,0)
		
		local sectorDistance = sectorDistances[chosenSector] 

		--local tracks = {}
		local prevTerminal 
		local terminals = {} 

		-- Path gen attempt #1 {{{
			for i=1, nodeCount, 1 do 
				local distToNode = (sectorDistance / nodeCount) * i
				local nodeAngleYaw = (360 / totalSectors) * chosenSector
				local nodeAngle = Angle(0, nodeAngleYaw, 0)
				
				local nodePos = mapCentre + nodeAngle:Forward() * distToNode --A random position in the sector, getting further and further out.

				local areaWeights = {}
				-- // Calculating weights {{{
					local validAreas = jcms.mapdata.validAreas 
					for i, area in ipairs(validAreas) do 							-- =Sector weights =
						if areaSectors[area] == chosenSector then 					--The sector we're in
							areaWeights[area] = 1
						elseif math.abs(areaSectors[area] - chosenSector) == 1 then	--Low chance for adjacent sectors.
							areaWeights[area] = 0.00000001
						else 														--Every other sector
							areaWeights[area] = 0
						end
					end

					for i, area in ipairs(validAreas) do 							-- =Only in our zone=
						if not(zoneDict[area] == mainframeZone) then 
							areaWeights[area] = 0
						end
					end

					for i, area in ipairs(validAreas) do 							-- =Node-position-weights=
						local fac = 1 / area:GetCenter():DistToSqr(nodePos)
						areaWeights[area] = areaWeights[area] * fac
					end

					for i, area in ipairs(validAreas) do 							-- =Distancing from other objects=
						local closestDist = 3000 --Doesn't matter after 3k
						for i, mEnt in ipairs(missionObjects) do 
							local dist = mEnt:GetPos():Distance(area:GetCenter())
							closestDist = (closestDist > dist and dist) or closestDist
						end

						areaWeights[area] = areaWeights[area] * closestDist/3000
					end

					local tr_data = { 
						--start = centre + Vector(0,0,height),
						mins = Vector(1, 1, 15), 
						maxs = Vector(1, 1, 15), 
						mask = MASK_PLAYERSOLID_BRUSHONLY
					}
					for i, area in ipairs(validAreas) do 							-- =Stop us spawning in an unhackable spot=
						tr_data.start = area:GetCenter() + Vector(0,0,20)
						
						for i, tr in ipairs(jcms.mapgen_WallTraces(8, 35, tr_data)) do 
							if tr.Fraction < 1 then  
								areaWeights[area] = nil
							end
						end
					end
				-- // }}}

				local targetArea 
				local path -- Actual vectors (payload-style) path.
				
				for attempt=1, 5 do 
					targetArea = jcms.util_ChooseByWeight(areaWeights)
					local navSuccess, pathAreas = jcms.mapgen_Navigate(prevArea, targetArea)

					if navSuccess then
						local expandedPathAreas = jcms.mapgen_ExpandedAreaList(pathAreas)
						local connections, chunks = jcms.mapgen_VectorGrid(expandedPathAreas, 90 - attempt*2, 170)
						local costs = jcms.mapgen_VectorGridCosts_WallProximity(connections, chunks, 256, 15000, true)
						
						-- We can only navigate though points in 'connections' table.
						-- We must navigate from a center of a CNavArea to a center of another one.
						-- Therefore we look for the closest-matching vector in the 'connections' table.
						local from, to = pathAreas[1]:GetCenter(), pathAreas[#pathAreas]:GetCenter()
						local closestA, closestDist2A
						local closestB, closestDist2B

						for chunkId, chunk in pairs(chunks) do
							for i, pt in ipairs(chunk) do
								local dist2A, dist2B = pt:DistToSqr(from), pt:DistToSqr(to)
								
								if (not closestA) or (dist2A < closestDist2A) then
									closestA, closestDist2A = pt, dist2A
								end

								if (not closestB) or (dist2B < closestDist2B) then
									closestB, closestDist2B = pt, dist2B
								end
							end
						end

						from, to = closestA, closestB -- We found closest-matching vectors.
						path = jcms.pathfinder.navigateVectorGrid(connections, costs, from, to)

						jcms.mapgen_Wait( 0.15 + (i/nodeCount) * 0.85 )

						if not path then continue end

						jcms.mapgen_OptimiseVectorPath( path )
						break
					end
				end

				if targetArea and path then
					prevArea = targetArea
					
					local terminal = ents.Create("jcms_terminal")
					terminal:SetPos(targetArea:GetCenter())
					terminal:Spawn()

					table.insert(missionObjects, terminal)
					table.insert(terminals, terminal)
					
					local purpleFrac = math.min(((i-1) * 0.3), 1)
					local purpleVector = LerpVector(purpleFrac, Vector(162/255, 81/255, 1), Vector(20/255,11/255,114/255) )
					local lastNodeEnt = NULL
					local nodes = {}
					for j, point in ipairs(path) do
						local nodeEnt = ents.Create("jcms_node")
						nodeEnt:SetPos(point) 
						nodeEnt:Spawn()

						if j == #path then
							nodeEnt:SetIsPowerful(true)
							nodeEnt:SetPos(terminal:GetPos() + Vector(0, 0, 32))
							local goodFacing, facingAngle = jcms.mapgen_PickBestFacingDirection(nodeEnt:GetPos(), 150, { terminal, nodeEnt }, MASK_PLAYERSOLID_BRUSHONLY)
							terminal:SetAngles(facingAngle)
						end

						nodeEnt:SetEnergyColour(purpleVector)
						if IsValid(lastNodeEnt) then
							lastNodeEnt:ConnectNode(nodeEnt)
						end
						
						table.insert(nodes, nodeEnt)
						lastNodeEnt = nodeEnt
					end

					terminal.track = nodes
					terminal.dependents = {}
					terminal.prevTerminal = prevTerminal

					if IsValid(prevTerminal) then 
						table.insert(prevTerminal.dependents, terminal)
					end
					prevTerminal = terminal
					--tracks[terminal] = nodes
				end

				jcms.mapgen_Wait( 0.15 + (i/nodeCount) * 0.85 )
			end
		-- }}}

		-- Path gen attempt #2 (Payload-style, less fancy but more reliable) {{{
		if #terminals == 0 then
			jcms.printf("A mainframe track failed to generate using old algo, using new one")

			do
				local areaSectorsList = {}
				for area, sectorId in pairs(areaSectors) do
					if sectorId == chosenSector then
						table.insert(areaSectorsList, area)
					end
				end
				
				local track
				for attempt=1, 3 do
					track = jcms.mapgen_GenLongPath(areaSectorsList, 256, 15000, mapCentre)

					jcms.mapgen_Wait(0.15)
					if not track then continue end
					jcms.util_ReverseTable(track)

					targetArea = navmesh.GetNearestNavArea(track[#track], true)

					jcms.mapgen_OptimiseVectorPath( track )
					break
				end

				if track then
					local hackNodes = {}
					if #track > 7 then
						local hackNodesCount = nodeCount
						local everySteps = math.Round( #track / (hackNodesCount + 1) )
						local baseStep = math.random(1, math.ceil(everySteps/2))
						
						for i = 1, hackNodesCount do
							if hackNodesCount == i then
								hackNodes[ #track ] = true
							else
								hackNodes[ baseStep + everySteps * i ] = true
							end
						end
					elseif #track >= 5 then
						local presets = {
							[5] = { 3, 5 },
							[6] = { math.random(3, 4), 6 },
							[7] = math.random() < 0.5 and { 4, 7 } or { 5, 7 }
						}

						for i, index in ipairs(presets[ #track ]) do
							hackNodes[index] = true
						end
					else
						hackNodes[#track] = true
					end

					local lastNodeEnt = NULL
					local prevTerminal
					local nodes = {}
					local hackNodesSoFar = {}
					for j=0, #track do
						local purpleFrac = math.Clamp(j/#track+0.3, 0, 1)
						local purpleVector = LerpVector(purpleFrac, Vector(162/255, 81/255, 1), Vector(20/255,11/255,114/255) )
						local point = j==0 and mapCentre or track[j]
						local nodeEnt = ents.Create("jcms_node")
						nodeEnt:SetPos(point) 
						nodeEnt:Spawn()
						table.insert(hackNodesSoFar, nodeEnt)

						nodeEnt:SetEnergyColour(purpleVector)
						if IsValid(lastNodeEnt) then
							lastNodeEnt:ConnectNode(nodeEnt)
						end
						
						table.insert(nodes, nodeEnt)

						if hackNodes[j] then
							local terminal = ents.Create("jcms_terminal")
							local nodeVec = nodeEnt:GetPos()
							terminal:SetPos(nodeVec)
							terminal:Spawn()

							local goodFacing, facingAngle = jcms.mapgen_PickBestFacingDirection(nodeVec, 150, { terminal, nodeEnt }, MASK_PLAYERSOLID_BRUSHONLY)
							nodeVec.z = nodeVec.z + 32
							if IsValid(lastNodeEnt) then
								lastNodeEnt:SetIsPowerful(true)
							else
								nodeEnt:SetIsPowerful(true)
							end
							nodeEnt:SetPos(nodeVec)
							terminal:SetAngles(facingAngle)

							table.insert(missionObjects, terminal)
							table.insert(terminals, terminal)

							terminal.track = hackNodesSoFar
							terminal.dependents = {}
							terminal.prevTerminal = prevTerminal

							if IsValid(prevTerminal) then 
								table.insert(prevTerminal.dependents, terminal)
							end

							prevTerminal = terminal
							hackNodesSoFar = { nodeEnt }
						end

						lastNodeEnt = nodeEnt
					end
				end
			end
		end
		-- }}}

		-- Path gen attempt #3 (This map sucks) {{{
		if #terminals == 0 then
			jcms.printf("A mainframe track failed to generate using even the new algorithm, using a VERY BAD one")
			local pos = mainframeArea:GetCenter()
			
			local node1 = ents.Create("jcms_node")
			node1:SetPos(pos) 
			node1:Spawn()
			node1:SetEnergyColour(Vector(0, 1, 0))

			local terminal = ents.Create("jcms_terminal")

			local zoneList = jcms.mapgen_ZoneList()[ mainframeZone ]
			local randomArea = zoneList[ math.random(1, #zoneList) ]
			if randomArea then
				pos = jcms.mapgen_AreaPointAwayFromEdges(randomArea, 150)
				local goodFacing, facingAngle = jcms.mapgen_PickBestFacingDirection(pos, 150, { terminal, node1 }, MASK_PLAYERSOLID_BRUSHONLY)
				terminal:SetAngles(facingAngle)
				terminal:SetPos(pos)
			else
				local ang = math.random()*math.pi*2
				local cos, sin = math.cos(ang), math.sin(ang)
				local mag = 128
				pos:Add(Vector(cos*mag, sin*mag, -4))
				terminal:SetAngles(Angle(0, ang/math.pi*180, 0))
				terminal:SetPos(pos)
			end
			
			nodeVec = Vector(pos.x, pos.y, pos.z + 32)
			local node2 = ents.Create("jcms_node")
			node2:SetIsPowerful(true)
			node2:SetPos(nodeVec)
			node2:Spawn()
			node2:SetEnergyColour(Vector(1, 0, 1))
			node2:ConnectNode(node1)

			terminal:Spawn()
			table.insert(missionObjects, terminal)
			table.insert(terminals, terminal)

			terminal.track = { node1, node2 }
			terminal.dependents = {}
		end
		-- }}}

		return terminals
	end


	jcms.missions.mainframe = {
		faction = "rebel",

		generate = function(data, missionData)
			local missionObjects = {}
			missionData.mainframe = NULL
			missionData.terminal_tracks = {} --Subtables containing a list of terminals in a track. Includes branches.

			-- // Placing the Mainframe {{{
				local zoneDict = jcms.mapgen_ZoneDict()
				local midWeights = jcms.mapgen_CentreWeights()
				for area, weight in pairs(midWeights) do 
					if not(zoneDict[area] == jcms.mapdata.largestZone) or not jcms.mapgen_ValidArea(area) then 
						midWeights[area] = nil
					else
						local centre = area:GetCenter() 
						local tr = util.TraceLine({
							start = centre,
							endpos = centre + Vector(0,0,32000)
						})

						local dist = 32000 * tr.Fraction
						if dist < 200 then 
							midWeights[area] = midWeights[area] * 0.0000001
						elseif not tr.HitSky then 
							midWeights[area] = midWeights[area] * 0.001
						end

						local height = math.min(dist, 300)/2

						local tr_data = { 
							start = centre + Vector(0,0,height),
							mins = Vector(-24, -24, -8), 
							maxs = Vector(24, 24, 8), 
							mask = MASK_PLAYERSOLID_BRUSHONLY
						}

						for i, tr in ipairs(jcms.mapgen_WallTraces(8, 350, tr_data)) do 
							midWeights[area] = midWeights[area] * math.sqrt(tr.Fraction)
						end

						if area:GetSizeX() < 50 or area:GetSizeY() < 50 then 
							midWeights[area] = midWeights[area] * 0.0000001
						end
					end
				end
				mainframeArea = jcms.util_ChooseByWeight(midWeights)

				if IsValid(mainframeArea) then
					local worked, mainframe = jcms.prefab_TryStamp("rgg_mainframe", mainframeArea)
					table.insert(missionObjects, mainframe)
					missionData.mainframe = mainframe
				else
					PrintMessage( HUD_PRINTTALK, "[Map Sweepers] Failed to place mainframe, map is probably too small.")
				end
			-- // }}}

			jcms.mapgen_Wait( 0.075 )

			local sectorDebugAreaCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
			-- // Sectors {{{
				local xMin, yMin, xMax, yMax = jcms.mapgen_GetNavmeshSpan(unrestricted)
				--local mapCentre = Vector((xMin+xMax)/2, (yMin+yMax)/2, 0)
				local mapCentre = (IsValid(mainframeArea) and  mainframeArea:GetCenter()) or Vector(0,0,0)

				local sectorSplits = 6

				local validAreas = jcms.mapdata.validAreas 
				local areaSectors = {}
				local sectorDistances = {}
				for i=1, sectorSplits, 1 do sectorDistances[i] = 0 end --Initialise sector distances

				for i, area in ipairs(validAreas) do 
					--Direction to center
					local centre = area:GetCenter() 
					centre.z = 0
					local dirVec = centre - mapCentre -- AB = B-A

					
					--Sector
					local ang = dirVec:Angle()
					--local sector = math.ceil( math.floor(ang.y / sectorSplits )  % (sectorSplits-1)) + 1
					local sector = math.Round( ang.y / (360 / (sectorSplits-1)) ) + 1

					sectorDebugAreaCounts[sector] = sectorDebugAreaCounts[sector] + 1
					areaSectors[area] = sector 

					--Distance 
					local dist = dirVec:Length()
					if sectorDistances[sector] < dist then 
						sectorDistances[sector] = dist
					end
				end
			-- // }}} 

			local sectorWeights = table.Copy(sectorDistances)
			for sector, weight in pairs(sectorWeights) do 
				sectorWeights[sector] = math.sqrt(weight)
			end

			jcms.mapgen_Wait( 0.15 )

			missionData.completedTracks = {}
			-- // Track Generation {{{
				local trackCount = 3 

				local terminalMaxCount = math.ceil(4 * jcms.runprogress_GetDifficulty(), 0)
				local terminalsLeft = terminalMaxCount

				local maxTerminalsPer = math.ceil(terminalMaxCount/trackCount) + 1
				local minTerminalsPer = math.max(1, math.floor(terminalMaxCount / (trackCount * 2)))

				for i=1, trackCount, 1 do
					--local chosenSector = table.remove(unusedSectors, math.random(#unusedSectors))
					local chosenSector = jcms.util_ChooseByWeight(sectorWeights)
					sectorWeights[chosenSector] = 0.000000001

					local chosenCount = math.random(minTerminalsPer, maxTerminalsPer)
					chosenCount = math.min(chosenCount, terminalsLeft) --Ensure we don't over-place (>max terminals).

					--Ensure no tracks are empty
					local remainingRequired = (trackCount - i) * minTerminalsPer
					local maximum = math.max( terminalsLeft - remainingRequired, 0 )
					chosenCount = math.min(chosenCount, maximum)

					--Ensure we don't under-place (<max terminals)
					local remainingPossible = (trackCount - i) * maxTerminalsPer
					local requirement = math.max(terminalsLeft - remainingPossible, 0)
					chosenCount = math.max(chosenCount, requirement)

					terminalsLeft = terminalsLeft - chosenCount


					local terminals = jcms.mapgen_MainframeGenerateTrack(missionObjects, sectorDistances, areaSectors, sectorSplits, mainframeArea, chosenSector, chosenCount) 
					table.insert(missionData.terminal_tracks, terminals)
					table.insert(missionData.completedTracks, false )
					for j, terminal in ipairs(terminals) do --This is a bit messy
						terminal.trackId = i
						
						terminal:InitAsTerminal("models/jcms/rgg_node.mdl", "mainframe_terminal")
					end
				end
			-- // }}}

			jcms.mapgen_PlaceNaturals( jcms.mapgen_AdjustCountForMapSize(12) )
			jcms.mapgen_PlaceEncounters()
		end,
		
		tagEntities = function(director, missionData, tags)
			if IsValid(missionData.mainframe) then --Track-paths can be easily used to find terminals, so only mark mainframe.
				tags[missionData.mainframe] = { name = "#jcms.mainframe_tag", moving = false, active = true }
			end

			for i, track in ipairs(missionData.terminal_tracks) do 
				for j, terminal in ipairs(track) do 
					tags[terminal] = { name = "#jcms.mainframe_terminal", moving = false, active = (not terminal.isComplete) and terminal.isUnlocked }
				end
			end
		end,

		getObjectives = function(missionData)
			local total = 0
			local totalComplete = 0
			local broken = false
			for i, track in ipairs(missionData.terminal_tracks) do 
				local trackComplete = 0 
				local trackTotal = 0
				for i, terminal in ipairs(track) do 
					if IsValid(terminal) then
						trackComplete = trackComplete + ((terminal.isComplete and 1) or 0)
						trackTotal = trackTotal + 1
					else
						broken = true --Hopefully these don't get garbage collected too quickly
					end
				end

				if trackComplete == trackTotal and not missionData.completedTracks[i] then 
					missionData.completedTracks[i] = true

					local completedTrackEffects = jcms.missions.mainframe.completedTrackEffects
					if completedTrackEffects[i] then
						completedTrackEffects[i](missionData)
					end 
				end

				totalComplete = totalComplete + trackComplete
				total = total + trackTotal
			end

			
			if totalComplete < total or broken then 
				local objectives = {} 

				for i, track in ipairs(missionData.terminal_tracks) do 
					local trackTotal = #track
					local trackTotalComplete = 0
					for i, terminal in ipairs(track) do 
						trackTotalComplete = trackTotalComplete + ((terminal.isComplete and 1) or 0)
					end

					table.insert(objectives, { type = "mainframeterminals" .. tostring(i), completed = (trackTotalComplete == trackTotal), progress = trackTotalComplete, total = trackTotal })
				end

				return objectives
			else
				missionData.evacuating = true 

				if not IsValid(missionData.evacEnt) then
					missionData.evacEnt = jcms.mission_DropEvac(jcms.mission_PickEvacLocation(), 45)
				end
				
				return jcms.mission_GenerateEvacObjective()
			end
		end,

		completedTrackEffects = {
			[1] = function(missionData) --Announce zombies
				local completion = 0
				for i=1, 3 do
					completion = completion + (missionData.completedTracks[i] and 1/3 or 0)
				end

				jcms.net_SendTip("all", true, "#jcms.mainframe_completion1", completion)
			end,

			[2] = function(missionData) --Flip shield charger
				local completion = 0
				for i=1, 3 do
					completion = completion + (missionData.completedTracks[i] and 1/3 or 0)
				end

				jcms.net_SendTip("all", true, "#jcms.mainframe_completion2", completion)
				missionData.mainframe:SetShieldJCorp(true)
			end,
			[3] = function(missionData) --Death-ray bombardment
				local completion = 0
				for i=1, 3 do
					completion = completion + (missionData.completedTracks[i] and 1/3 or 0)
				end

				jcms.net_SendTip("all", true, "#jcms.mainframe_completion3", completion)
				missionData.mainframe.bombardmentActive = true
			end,
		},

		swarmCalcCost = function(director, swarmCost)
			swarmCost = swarmCost + 2 --Faster start for hacking-based missions.

			local missionData = director.missionData
			if not missionData.completedTracks then return swarmCost end 

			for i, completed in ipairs(missionData.completedTracks) do 
				if completed then
					swarmCost = swarmCost * 1.1
				end
			end

			if not missionData.completedTracks[1] then return swarmCost end
			return swarmCost / 0.75
		end,

		swarmCalcCooldown = function(director, baseCooldown, swarmCost)
			local missionData = director.missionData
			if not missionData.completedTracks or not missionData.completedTracks[1] then return baseCooldown end 

			return baseCooldown / 2
		end,

		npcTypeQueueCheck = function(director, swarmCost, dangerCap, npcType, npcData, basePassesCheck)
			if (not npcData.check or npcData.check(director)) then
				if (npcData.danger <= dangerCap) then
					local missionData = director.missionData
					local zombieRatio = 0.25
					
					if missionData.completedTracks then
						if npcData.faction == "any" then
							return true
						else
							if (math.random() < zombieRatio) and missionData.completedTracks[1] then
								return npcData.faction == "zombie" and not(npcData.class == "npc_jcms_spirit" or npcData.class == "npc_jcms_boomer") --todo: BANDAID FIX, ALYX DOESN'T LIKE THE CUSTOM ONES.
							else
								return npcData.faction == "rebel"
							end
						end
					end
					
					return false
				else
					return false
				end
			else
			end
		end,

		--[[
		finalizeQueue = function(queue, d, totalCost, dangerCap, validTypes)
			local missionData = d.missionData
			if not(missionData.completedTracks and missionData.completedTracks[1]) then return end

			--Probably not the most efficient possible solution.
			local zombies = {}
			local rebels = {}
			for i, spawnType in ipairs(queue) do
				local data = jcms.npc_types[ spawnType ]

				if data.faction == "zombie" then
					table.insert(zombies, spawnType)
				else
					table.insert(rebels, spawnType)
				end
			end

			table.Add(zombies, rebels)
			table.CopyFromTo(zombies, queue)
		end
		--]]
	}
-- }}}