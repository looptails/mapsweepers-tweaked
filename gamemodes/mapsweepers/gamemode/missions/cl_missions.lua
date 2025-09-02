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

-- See sv_missions.lua if you want to make an addon that adds a custom mission type.

-- // Missions {{{

	-- Mission tags: 'hacking', 'infighting', 'timer', 'extraorders', 'rarebosses', 'killsrequired', 'naturalhazard'

	jcms.missions = {
		thumperreactivation = {
			faction = "antlion",
			tags = { "hacking" }
		},

		thumpersabotage = {
			faction = "combine",
			tags = { "infighting", "extraorders" }
		},

		mainframe = {
			faction = "rebel",
			tags = { "hacking", "infighting" }
		},
		
		infestation = {
			faction = "zombie",
			tags = { "naturalhazard", "extraorders" }
		},
		
		hell = {
			faction = "everyone",
			tags = { "rarebosses", "infighting" }
		},

		violenceflashpoints = {
			faction = "any",
			tags = { "rarebosses", "killsrequired" }
		},

		payload = {
			faction = "any",
			tags = { "hacking" }
		}
	}

-- // }}}

-- // Other {{{

	function jcms.mission_GetTypesByFaction(faction)
		local t = {}

		for misType, data in pairs(jcms.missions) do
			if data.faction == faction then
				table.insert(t, misType)
			end
		end

		table.sort(t)
		return t
	end

	function jcms.mission_GetOrder(split)
		local sorted = {}
		local missionsGeneric = {}

		for name, missionData in pairs(jcms.missions) do
			if missionData.faction == "any" then
				table.insert(missionsGeneric, name)
			else
				table.insert(sorted, name)
			end
		end

		table.sort(sorted, function(first, last)
			local data1, data2 = jcms.missions[ first ], jcms.missions[ last ]
			if data1.faction == data2.faction then
				return first < last
			else
				return data1.faction < data2.faction
			end
		end)

		table.sort(missionsGeneric)

		if split then
			return sorted, missionsGeneric
		else
			for i, name in ipairs(missionsGeneric) do
				missionsGeneric[i] = nil
				sorted[#sorted + 1] = name 
			end

			return sorted
		end
	end

-- // }}}
