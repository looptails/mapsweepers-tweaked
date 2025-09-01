AddCSLuaFile()

jcms = jcms or {}

local FCVAR_JCMS_NOTIFY_AND_SAVE = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
local FCVAR_JCMS_SHARED_SAVED = bit.bor(FCVAR_REPLICATED, FCVAR_JCMS_NOTIFY_AND_SAVE)

jcms.cvar_votekickThreshold = CreateConVar("jcms_votekick_threshold", "0.75", FCVAR_JCMS_SHARED_SAVED, "The ratio of players needed for a vote kick. 0.75 means 75% of the server (rounded up).", 0, 1)
jcms.cvar_voteEndRoundThreshold = CreateConVar("jcms_voteEvac_threshold", "0.5", FCVAR_JCMS_SHARED_SAVED, "The ratio of players needed for an end-round vote to be successful. 0.5 means 50% (rounded up).", 0, 1)

jcms.cvar_votekickTime = CreateConVar("jcms_votekick_duration", "30", FCVAR_JCMS_SHARED_SAVED, "The time to ban vote-kicked players for (0 is permanent!)")

jcms.cvar_votekick_enabled = CreateConVar("jcms_votekick_enabled", "1", FCVAR_JCMS_SHARED_SAVED, "Set to 0 to disable vote-kicking")
jcms.cvar_voteEvac_enabled = CreateConVar("jcms_voteEvac_enabled", "1", FCVAR_JCMS_SHARED_SAVED, "Set to 0 to disable evac voting")
