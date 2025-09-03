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

jcms.bestiary = {}

-- // Antlion {{{

	jcms.bestiary.antlion_cyberguard = {
		faction = "antlion", bounty = 300, health = 450,
		mdl = "models/antlion_guard.mdl", mats = { "models/jcms/cyberguard" }, camlookvector = Vector(0, 0, 50)
	}

	jcms.bestiary.antlion_drone = {
		faction = "antlion", bounty = 15, health = 25,
		mdl = "models/antlion.mdl", camfov = 28
	}

	jcms.bestiary.antlion_guard = {
		faction = "antlion", bounty = 350, health = 675,
		mdl = "models/antlion_guard.mdl", camlookvector = Vector(0, 0, 50)
	}

	jcms.bestiary.antlion_reaper = {
		faction = "antlion", bounty = 75, health = 200,
		mdl = "models/antlion.mdl", mats = { "metal2" }, color = Color(195, 150, 38)
	}

	jcms.bestiary.antlion_ultracyberguard = {
		faction = "antlion", bounty = 600, health = 563,
		mdl = "models/jcms/ultracyberguard.mdl", camlookvector = Vector(0, 0, 50)
	}

	jcms.bestiary.antlion_waster = {
		faction = "antlion", bounty = 5, health = 15,
		mdl = "models/antlion.mdl", scale = 0.63, color = Color(168, 125, 59), camfov = 28
	}

	jcms.bestiary.antlion_worker = {
		faction = "antlion", bounty = 50, health = 60,
		mdl = "models/antlion_worker.mdl"
	}

-- // }}}

-- // Combine {{{

	jcms.bestiary.combine_cybergunship = {
		faction = "combine", bounty = 700, health = 4500,
		mdl = "models/gunship.mdl", mats = { "", "models/jcms/cybergunship/body" }, scale = 0.3
	}

	jcms.bestiary.combine_elite = {
		faction = "combine", bounty = 95, health = 80,
		mdl = "models/combine_super_soldier.mdl", camfov = 25
	}

	jcms.bestiary.combine_gunship = {
		faction = "combine", bounty = 450, health = 4500,
		mdl = "models/gunship.mdl", scale = 0.3
	}

	jcms.bestiary.combine_hunter = {
		faction = "combine", bounty = 125, health = 210,
		mdl = "models/hunter.mdl"
	}

	jcms.bestiary.combine_metrocop = {
		faction = "combine", bounty = 40, health = 40,
		mdl = "models/police.mdl", camfov = 25
	}

	jcms.bestiary.combine_scanner = {
		faction = "combine", bounty = 15, health = 25,
		mdl = "models/combine_scanner.mdl", camfov = 20
	}

	jcms.bestiary.combine_sniper = {
		faction = "combine", bounty = 75, health = 38,
		mdl = "models/combine_soldier_prisonguard.mdl", skin = 1, camfov = 25
	}

	jcms.bestiary.combine_soldier = {
		faction = "combine", bounty = 70, health = 50,
		mdl = "models/combine_soldier.mdl", camfov = 25
	}

	jcms.bestiary.combine_suppressor = {
		faction = "combine", bounty = 130, health = 90,
		mdl = "models/combine_soldier_prisonguard.mdl", skin = 2, camfov = 25
	}

-- // }}}

-- // Rebels {{{

	jcms.bestiary.rebel_alyx = {
		faction = "rebel", bounty = 75, health = 45,
		mdl = "models/alyx.mdl", camfov = 25, seq = 3
	}

	jcms.bestiary.rebel_dog = {
		faction = "rebel", bounty = 135, health = 240,
		mdl = "models/dog.mdl"
	}

	jcms.bestiary.rebel_fighter = {
		faction = "rebel", bounty = 25, health = 45,
		mdl = "models/humans/group03/male_07.mdl", seq = 1, camfov = 25
	}

	jcms.bestiary.rebel_helicopter = {
		faction = "rebel", bounty = 400, health = 1764,
		mdl = "models/combine_helicopter.mdl", scale = 0.3
	}

	jcms.bestiary.rebel_medic = {
		faction = "rebel", bounty = 35, health = 40,
		mdl = "models/humans/group03m/female_07.mdl", seq = 3, camfov = 25
	}

	jcms.bestiary.rebel_megacopter = {
		faction = "rebel", bounty = 600, health = 2268,
		mdl = "models/combine_helicopter.mdl", mats = { "models/jcms/ultracopter/body", "models/jcms/ultracopter/glass" }, scale = 0.3
	}

	jcms.bestiary.rebel_odessa = {
		faction = "rebel", bounty = 50, health = 25,
		mdl = "models/odessa.mdl", seq = 7, camfov = 25
	}

	jcms.bestiary.rebel_rgg = {
		faction = "rebel", bounty = 25, health = 4,
		mdl = "models/humans/group02/male_05.mdl", mats = { "models/shiny", "models/shiny", "models/shiny", "models/shiny", "models/shiny" }, seq = 14, camfov = 25, color = Color(195, 0, 255)
	}

	jcms.bestiary.rebel_vanguard = {
		faction = "rebel", bounty = 45, health = 65,
		mdl = "models/humans/group03/male_05.mdl", seq = 1, camfov = 25, color = Color(90, 69, 110)
	}

	jcms.bestiary.rebel_vortigaunt = {
		faction = "rebel", bounty = 90, health = 100,
		mdl = "models/vortigaunt.mdl", camfov = 25
	}

-- // }}}

-- // Zombies {{{

	jcms.bestiary.zombie_boomer = {
		faction = "zombie", bounty = 25, health = 37,
		mdl = "models/player/zombie_soldier.mdl", seq = 5, color = Color(200, 255, 200), camfov = 25
	}

	jcms.bestiary.zombie_charple = {
		faction = "zombie", bounty = 20, health = 25,
		mdl = "models/zombie/fast.mdl", mats = { "models/charple/charple3_sheet" }, camfov = 25
	}

	jcms.bestiary.zombie_combine = {
		faction = "zombie", bounty = 40, health = 100,
		mdl = "models/zombie/zombie_soldier.mdl"
	}

	jcms.bestiary.zombie_explodingcrab = {
		faction = "zombie", bounty = 2, health = 10,
		mdl = "models/headcrab.mdl", mats = { "models/jcms/explosiveheadcrab/body" }, camfov = 15
	}

	jcms.bestiary.zombie_fast = {
		faction = "zombie", bounty = 28, health = 63,
		mdl = "models/zombie/fast.mdl", bodygroups = { [1] = 1 }, camfov = 25
	}

	jcms.bestiary.zombie_husk = {
		faction = "zombie", bounty = 13, health = 75,
		mdl = "models/zombie/classic.mdl", bodygroups = { [1] = 1 }, camfov = 25
	}

	jcms.bestiary.zombie_minitank = {
		faction = "zombie", bounty = 45, health = 432,
		mdl = "models/zombie/poison.mdl", bodygroups = { [1] = 1 }, camfov = 25
	}

	jcms.bestiary.zombie_poison = {
		faction = "zombie", bounty = 35, health = 263,
		mdl = "models/zombie/poison.mdl", bodygroups = { 1, 1, 1, 1 }, camfov = 25
	}

	local polypMatrix = Matrix()
	polypMatrix:Rotate( Angle(0, 0, 180) )
	jcms.bestiary.zombie_polyp = {
		faction = "zombie", bounty = 50, health = 200,
		mdl = "models/barnacle.mdl", seq = "chew_humanoid", camfov = 20, matrix = polypMatrix, camlookvector = Vector(0, 0, 18),
	}

	jcms.bestiary.zombie_spawner = {
		faction = "zombie", bounty = 250, health = 675,
		mdl = "models/jcms/zombiespawner.mdl", scale = 0.5,
	}

	jcms.bestiary.zombie_spirit = {
		faction = "zombie", bounty = 60, health = 80,
		mdl = "models/zombie/fast.mdl", camfov = 25,
		preDrawModel = function(ent)
			render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
			render.SetColorModulation(15, 1, 1)
		end,
		postDrawModel = function(ent)
			render.SetColorModulation(1, 1, 1)
			render.OverrideBlend( false )
		end
	}

-- // }}}

-- // Turrets {{{

	jcms.bestiary.turret_smg = {
		faction = "turret", bounty = 0, health = 150,
		mdl = "models/jcms/jcorp_turret.mdl", bodygroups = { [1] = 1 }, camfov = 25
	}

	jcms.bestiary.turret_bolter = {
		faction = "turret", bounty = 0, health = 150,
		mdl = "models/jcms/jcorp_turret.mdl", bodygroups = { [1] = 2 }, camfov = 25
	}

	jcms.bestiary.turret_shotgun = {
		faction = "turret", bounty = 0, health = 150,
		mdl = "models/jcms/jcorp_turret.mdl", bodygroups = { [1] = 4 }, camfov = 25
	}

	jcms.bestiary.turret_gatling = {
		faction = "turret", bounty = 0, health = 150,
		mdl = "models/jcms/jcorp_turret.mdl", bodygroups = { [1] = 3 }, camfov = 25
	}

	jcms.bestiary.turret_rocket = {
		faction = "turret", bounty = 0, health = 300,
		mdl = "models/jcms/jcorp_smrls.mdl", camfov = 25
	}

-- // }}}

-- // Sweepers {{{

	jcms.bestiary.sweeper_recon = {
		faction = "sweeper", bounty = 0, health = 75,
		mdl = "models/player/urban.mdl", camfov = 25
	}

	jcms.bestiary.sweeper_infantry = {
		faction = "sweeper", bounty = 0, health = 100,
		mdl = "models/player/riot.mdl", camfov = 25
	}

	jcms.bestiary.sweeper_sentinel = {
		faction = "sweeper", bounty = 0, health = 75,
		mdl = "models/player/gasmask.mdl", camfov = 25
	}

	jcms.bestiary.sweeper_engineer = {
		faction = "sweeper", bounty = 0, health = 75,
		mdl = "models/player/swat.mdl", camfov = 25
	}

-- // }}}
