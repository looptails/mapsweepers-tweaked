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

--This file sets up precaching for enemy models to prevent lag-spikes when they spawn.

local precacheModels = {
	"models/AntLion.mdl",
	"models/antlion_guard.mdl",
	"models/jcms/ultracyberguard.mdl"
}

if CLIENT or jcms.HasEpisodes() then
	table.insert(precacheModels, "models/antlion_worker.mdl")
end

table.Add(jcms.precacheModels, precacheModels)