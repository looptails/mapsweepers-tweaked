if not(engine.ActiveGamemode() == "mapsweepers") then return end
include("jcms_serverext/shared.lua")

jcms.serverExtension_voteKickIndex = 1

hook.Add("OnChatTab", "jcms_serverExtension_chatTab_votekick", function(text)
	if not string.StartsWith(string.lower(text), "!votekick") then 
		return text 
	end

	local allPlys = player.GetAll()

	--not very readable. This increments and wraps around
	jcms.serverExtension_voteKickIndex = ((jcms.serverExtension_voteKickIndex) % #allPlys) + 1
	local ind = jcms.serverExtension_voteKickIndex

	local nick = allPlys[ind]:Nick()

	return "!votekick " .. nick
end)

hook.Add("MapSweepersScoreboardPlayerMenu", "jcms_serverExtension_scoreboard", function(m, elem, ply, i)
	if not jcms.cvar_votekick_enabled:GetBool() then return end
	m:AddSpacer()
	m:AddOption("Votekick", function()
		RunConsoleCommand("say", "!votekick " .. ply:Nick())
	end)
end)


hook.Add("MapSweepersScoreboardControls", "jcms_serverExtension_scoreboard", function(pnl)
	if not jcms.cvar_voteEvac_enabled:GetBool() then return end 

	local btn = pnl:Add("DButton")
	btn:SetText("Vote to evacuate early")
	btn:Dock(TOP)
	btn.DoClick = function()
		RunConsoleCommand( "say", "!evac" )
	end
	btn.Paint = jcms.paint_ButtonFilled
end)