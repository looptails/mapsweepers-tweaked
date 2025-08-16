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

-- Hell {{{

	jcms.missions.hell = {
		faction = "antlion",
		
		phrasesOverride = {
			["ambient/explosions/exp1.wav"] = 1,
			["ambient/explosions/exp2.wav"] = 1,
			["ambient/explosions/exp3.wav"] = 1,
			["ambient/explosions/exp4.wav"] = 1
		},
		
		generate = function(data, missionData)
			jcms.mapgen_PlaceNaturals( jcms.mapgen_AdjustCountForMapSize(20) )
		end,
		
		getObjectives = function(missionData)
			local time = jcms.director_GetMissionTime() or 0
			
			if time < 60 then
				return {
					{ type = "prep", progress = 60 - math.floor(time), style = 1, completed = true },
				}
			else
				local diffMult = jcms.runprogress_GetDifficulty() ^ (2/3)
				local progress = math.floor( (time - 60) / (60*7.5 * diffMult) * 100 )

				if progress < 100 then
					return {
						{ type = "j", progress = 0, total = 0 },
						
						{ 
							type = "surv", 
							progress = math.min(100, progress),
							total = 100,
							percent = true,
							completed = progress >= 100
						}
					}
				else
					missionData.evacuating = true
				
					if not IsValid(missionData.evacEnt) then
						missionData.evacEnt = jcms.mission_DropEvac(jcms.mission_PickEvacLocation(), 5)
					end
					
					return jcms.mission_GenerateEvacObjective()
				end
			end
		end,
		
		npcTypeQueueCheck = function(director, swarmCost, dangerCap, npcType, npcData, basePassesCheck)
			return (npcData.danger <= dangerCap) and (not npcData.check or npcData.check(director))
		end,
		
		swarmCalcCost = function(director, baseCost)
			local missionData = director.missionData
			
			if missionData.evacuating then
				return baseCost
			else
				local time = jcms.director_GetMissionTime()
				
				if time >= 60 then
					return baseCost + 4 + 4*math.floor( (time-60)/60 )
				else
					return 0
				end
			end
		end,

		swarmCalcDanger = function(d, swarmCost) 
			return d.swarmDanger + 1
		end,

		swarmCalcBossCount = function(d, swarmCost)
			return 1
		end,

		think = function(director)
			director.totalWar = true
			
			if not director.swarmNext or director.swarmNext < 60 then
				director.swarmNext = 60
			else
				local missionTime = jcms.director_GetMissionTime()
				if missionTime >= 70 then
					director.swarmNext = math.min( director.swarmNext, missionTime + #director.npcs*2 )
				end
			end
			
			for i, npc in ipairs(director.npcs) do
				if math.random() < 0.25 then
					jcms.npc_GetRowdy(npc)
				end
			end
		end
	}

-- }}}
