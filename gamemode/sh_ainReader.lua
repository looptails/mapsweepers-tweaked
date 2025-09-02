-- AinReader Module by JonahSoldier.
AddCSLuaFile()

ainReader = ainReader or {} --Likely to use this in other addons, don't want to store redundant data.

--i lov the ai node .s..


-- // Data Read-Ins {{{
	function ainReader.readNodeData()
		if ainReader.nodeDataRead then return end 

		local fileName = "maps/graphs/" .. game.GetMap() .. ".ain"
		local path = "GAME"
		if not file.Exists(fileName, path) then path = "BSP" end
		if not file.Exists(fileName, path) then 
			jcms_debug_fileLog("Failed to read map .ain: " .. game.GetMap())
			return 
		end --not gonna be good if this happens.

		local ainFile = file.Open(fileName, "rb", path)
		ainFile:Seek(8)
		local numNodes = ainFile:ReadLong()

		ainReader.nodePositions = {}
		for i=1, numNodes, 1 do 
			ainFile:Seek(12 + (16 + (4*10) + 1 + 4)  * (i-1)) --Assumes ""NumHulls"" of 10, I'm not sure where this number comes from so I'm concerned about it.
			table.insert( ainReader.nodePositions, Vector(ainFile:ReadFloat(), ainFile:ReadFloat(), ainFile:ReadFloat()) )
			--we actually don't care about any of the other data atm.
		end

		ainReader.nodeDataRead = true 
	end

	--A complete version would read the links too but we don't need that right now.
-- // }}}