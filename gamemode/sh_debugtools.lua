AddCSLuaFile()

jcms_debugValues = {} --I'm going to have to leave stuff in some other parts of the code, I'd like that to be easy to clean-up afterwards.

file.CreateDir("mapsweepers")
file.CreateDir("mapsweepers/server")
file.CreateDir("mapsweepers/client")

local sessionStart = os.date("%Y").."_"..os.date("%m").."_"..os.date("%d").."-"..os.date("%H").."_"..os.date("%M")

function jcms_debug_fileLog(str)
	local realm = CLIENT and "client" or "server"
	local filePath = "mapsweepers/"..realm.."/".."debuglog_"..sessionStart..".txt"

	if not file.Exists(filePath, "DATA") then
		file.Write(filePath, "")
	end

	file.Append(filePath, str.."\n")
end