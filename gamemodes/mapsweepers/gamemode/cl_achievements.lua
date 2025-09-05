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

-- // List {{{

jcms.achievements = {
  kills_total_1 = {
    name = "kills_total_1",
    type = "kills",
    amount = 1000
  },

  kills_total_2 = {
    name = "kills_total_2",
    type = "kills",
    amount = 5000
  },

  kills_total_3 = {
    name = "kills_total_3",
    type = "kills",
    amount = 15000
  },

  kills_total_4 = {
    name = "kills_total_4",
    type = "kills",
    amount = 30000
  },

  kills_total_5 = {
    name = "kills_total_5",
    type = "kills",
    amount = 50000
  },

  kills_antlion = {
    name = "kills_antlion",
    type = "kills_antlion",
    amount = 10000
  },

  kills_combine = {
    name = "kills_combine",
    type = "kills_combine",
    amount = 10000
  },

  kills_rebels = {
    name = "kills_rebels",
    type = "kills_rebels",
    amount = 10000
  },

  kills_zombies = {
    name = "kills_zombies",
    type = "kills_zombies",
    amount = 10000
  },

  kills_infantry = {
    name = "kills_infantry",
    type = "kills_infantry",
    amount = 5000
  },

  kills_recon = {
    name = "kills_recon",
    type = "kills_recon",
    amount = 5000
  },

  kills_sentinel = {
    name = "kills_sentinel",
    type = "kills_sentinel",
    amount = 5000
  },

  kills_engineer = {
    name = "kills_engineer",
    type = "kills_engineer",
    amount = 5000
  },

  level_1 = {
    name = "level_1",
    type = "level",
    amount = 5
  },

  level_2 = {
    name = "level_2",
    type = "level",
    amount = 15
  },

  level_3 = {
    name = "level_3",
    type = "level",
    amount = 25
  },

  level_4 = {
    name = "level_4",
    type = "level",
    amount = 50
  },

  level_5 = {
    name = "level_5",
    type = "level",
    amount = 100
  },

  missions_1 = {
    name = "missions_1",
    type = "missions",
    amount = 5
  ),

  missions_2 = {
    name = "missions_2",
    type = "missions",
    amount = 25
  ),

  missions_3 = {
    name = "missions_3",
    type = "missions",
    amount = 100
  ),

  missions_4 = {
    name = "missions_4",
    type = "missions",
    amount = 250
  ),

  winstreak_1 = {
    name = "winstreak_1",
    type = "winstreak",
    amount = 3
  },

  winstreak_2 = {
    name = "winstreak_2",
    type = "winstreak",
    amount = 5
  },

  winstreak_3 = {
    name = "winstreak_3",
    type = "winstreak",
    amount = 10
  },

  friendly = {
    name = "friendly",
    type = "kills_friendly",
    amount = 1
  },

  deaths = {
    name = "deaths",
    type = "deaths",
    amount = 100
  },

  orders = {
    name = "orders",
    type = "orders",
    amount = 1000
  },

  hacker = {
    name = "hacker",
    type = "terminals",
    amount = 100
  }
}
-- // }}}

-- // Functions {{{

function jcms.achievements_GetOrder()
  local keys = table.GetKeys(jcms.achievements)
	table.sort(keys)
	return keys
end

-- // }}}
