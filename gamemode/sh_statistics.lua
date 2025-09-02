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

if CLIENT then -- My personal statistics
	jcms.statistics = jcms.statistics or {}

	jcms.statistics.playedTutorial = file.Exists("mapsweepers/client/tutorial_complete.dat", "DATA")
	jcms.statistics.mylevel = jcms.statistics.mylevel or 1
	jcms.statistics.myexp = jcms.statistics.myexp or 0
	jcms.statistics.mylevel_premission = jcms.statistics.mylevel
	jcms.statistics.myexp_premission = jcms.statistics.myexp
	jcms.statistics.myplaytime = jcms.statistics.myplaytime or {}
	jcms.statistics.mykills = jcms.statistics.mykills or {}
	jcms.statistics.mymissions_started = jcms.statistics.mymissions_started or {}
	jcms.statistics.mymissions_completed = jcms.statistics.mymissions_completed or {}
	jcms.statistics.myother = jcms.statistics.myother or {}

	function jcms.statistics_GetEXPForNextLevel(level)
		if level < 2 then
			return 0
		else
			return 10000 + (level-2) * 1100
		end
	end

	function jcms.statistics_GetLevelAndEXP()
		return jcms.statistics_GetLevel(), jcms.statistics_GetEXP()
	end

	function jcms.statistics_GetLevel()
		return jcms.statistics.mylevel
	end

	function jcms.statistics_GetEXP()
		return jcms.statistics.myexp
	end

	function jcms.statistics_GetPlaytime(asClass)
		local sum = 0
		for class, time in pairs(jcms.statistics.myplaytime) do
			if (asClass == nil) or (class == asClass) then
				sum = sum + time
			end
		end
		return sum
	end

	function jcms.statistics_GetKillCount(ofFaction, asClass)
		local total = 0

		for class, factionKills in pairs(jcms.statistics.mykills) do
			if ( (asClass == nil) or (class == asClass) ) then

				for faction, kills in pairs(factionKills) do
					if ( (ofFaction == nil) or (faction == ofFaction) ) then
						total = total + kills
					end
				end

			end
		end

		return total
	end

	function jcms.statistics_GetMissionCount(misType, asClass, completedOnly)
		local tab = completedOnly and jcms.statistics.mymissions_completed or jcms.statistics.mymissions_started
		local total = 0

		for class, missionsCounts in pairs(tab) do
			if ( (asClass == nil) or (class == asClass) ) then

				for mission, count in pairs(missionsCounts) do
					if (misType == nil) or (mission == misType or mission:gsub(":%w+$", "") == misType) then
						total = total + count
					end
				end

			end
		end

		return total
	end

	function jcms.statistics_GetOther(name, asClass)
		local sum = 0
		for class, counts in pairs(jcms.statistics.myother) do
			if (asClass == nil) or (class == asClass) then
				sum = sum + (tonumber(counts[name]) or 0)
			end
		end

		return sum
	end

	function jcms.statistics_AddLevel(amount)
		jcms.statistics.mylevel = jcms.statistics.mylevel + (tonumber(amount) or 0)
	end

	function jcms.statistics_AddEXP(amount)
		jcms.statistics.myexp = jcms.statistics.myexp + (tonumber(amount) or 0)
	end

	function jcms.statistics_AddPlaytime(asClass, seconds)
		asClass = asClass or "infantry"
		jcms.statistics.myplaytime[ asClass ] = (jcms.statistics.myplaytime[ asClass ] or 0) + (tonumber(seconds) or 1)
	end

	function jcms.statistics_AddKillCount(ofFaction, asClass, amount)
		ofFaction = ofFaction or "???"
		asClass = asClass or "infantry"
		amount = math.ceil(tonumber(amount) or 1)
		
		if not jcms.statistics.mykills[ asClass ] then
			jcms.statistics.mykills[ asClass ] = {}
		end

		local classFactionKills = jcms.statistics.mykills[ asClass ]
		classFactionKills[ ofFaction ] = (classFactionKills[ ofFaction ] or 0) + amount
	end

	function jcms.statistics_AddMissionCount(misType, asClass, isCompleted, amount)
		misType = misType or "???"
		asClass = asClass or "infantry"
		amount = math.ceil(tonumber(amount) or 1)
		local tab = isCompleted and jcms.statistics.mymissions_completed or jcms.statistics.mymissions_started
		
		if not tab[ asClass ] then
			tab[ asClass ] = {}
		end

		local classMissionTab = tab[ asClass ]
		classMissionTab[ misType ] = (classMissionTab[ misType ] or 0) + amount
	end

	function jcms.statistics_AddOther(name, asClass, amount)
		asClass = asClass or "infantry"

		if not jcms.statistics.myother[ asClass ] then
			jcms.statistics.myother[ asClass ] = {}
		end

		jcms.statistics.myother[ asClass ][ name ] = (jcms.statistics.myother[ asClass ][ name ] or 0) + (tonumber(amount) or 1)
	end

	hook.Add("Think", "jcms_LevelUp", function()
		local mylevel = jcms.statistics_GetLevel()
		local toNext = jcms.statistics_GetEXPForNextLevel(mylevel + 1)

		if jcms.statistics_GetEXP() > toNext then
			jcms.statistics_AddEXP( -toNext )
			jcms.statistics_AddLevel(1)
		end
	end)
	
	timer.Create("jcms_PlaytimeTracker", 1, 0, function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end 

		-- TODO Track npc playtime?
		if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE then
			local myclass = jcms.cachedValues.playerClass
			local classData = jcms.classes[ myclass ]

			if classData and classData.jcorp then
				jcms.statistics_AddPlaytime(myclass, 1)
			end
		end
	end)

end

if SERVER then -- Server sending data to the players

	jcms.statistics_buffers = jcms.statistics_buffers or {}

	-- // Logic {{{

		function jcms.statistics_GetPlyBuffer(ply)
			if not jcms.statistics_buffers[ply] then
				jcms.statistics_buffers[ply] = { 
					class = ply:GetNWString("jcms_class", "infantry"),
					exp = 0, 
					factionKills = {}, 
					missionStatuses = {},
					other = {}
				}
			end

			return jcms.statistics_buffers[ply]
		end

		function jcms.statistics_AddKills(ply, faction, count)
			if not ( IsValid(ply) and ply:IsPlayer() ) then return end
			local buf = jcms.statistics_GetPlyBuffer(ply)
			buf.factionKills[ faction ] = (buf.factionKills[ faction ] or 0) + math.ceil( tonumber(count) or 1 )
		end

		function jcms.statistics_AddEXP(ply, amount)
			if not ( IsValid(ply) and ply:IsPlayer() ) then return end
			local buf = jcms.statistics_GetPlyBuffer(ply)
			buf.exp = buf.exp + math.ceil( tonumber(amount) or 1 )
		end

		function jcms.statistics_AddMissionStatus(ply, misType, factionType, isCompleted)
			if not ( IsValid(ply) and ply:IsPlayer() ) then return end
			local buf = jcms.statistics_GetPlyBuffer(ply)

			local misData = jcms.missions[ misType ]
			
			if not misData or misData.faction == "any" then
				misType = misType .. ":" .. assert(factionType, "invalid faction for generic/unknown mission type")
			end

			buf.missionStatuses[ misType ] = not not isCompleted
		end

		function jcms.statistics_AddOther(ply, name, amount)
			if not ( IsValid(ply) and ply:IsPlayer() ) then return end
			local buf = jcms.statistics_GetPlyBuffer(ply)
			local buf_other = buf.other
			local key =  tostring(name)
			buf_other[key] = (buf_other[key] or 0) + (tonumber(amount) or 1)
		end

		timer.Create("jcms_StatisticsUpdate", 10, 0, function()
			for ply, buf in pairs(jcms.statistics_buffers) do
				jcms.net_SendPlayStatistics(ply, buf)
				jcms.statistics_buffers[ ply ] = nil
			end
		end)

	-- // }}}

end