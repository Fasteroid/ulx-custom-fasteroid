------------------------------ Fake Disconnect ------------------------------
function ulx.fakedc(calling_ply, target_ply)
	local ulib_sorted_hooks = hook.GetULibTable()["PlayerDisconnected"]
	for i=-1, 2 do -- skip -2 since that will de-auth the target_ply
		local hooks = ulib_sorted_hooks[i]
		for _, f in pairs(hooks) do
			f.fn(target_ply)
		end
	end
	ulx.fancyLogAdmin( calling_ply, true, "#A made #T pretend to disconnect", target_ply )
end
local discon = ulx.command( FasteroidSharedULX.category, "ulx fakedc", ulx.fakedc, "!fakedc", true, false, true )
discon:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional, hint="target" }
discon:defaultAccess( ULib.ACCESS_ADMIN )
discon:help( "Calls disconnect hook logic for the target to fake them leaving the server." )

------------------------------ Fake Ban  ------------------------------
function ulx.fakeban(calling_ply, target_ply, minutes, reason)
	local time = "for #s"
	if minutes == 0 then time = "permanently" end
	local str = "#A banned #T " .. time
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
    ulx.fakedc(calling_ply, target_ply) -- also pretend we disconnected them for added funzies
end

local fakeban = ulx.command( FasteroidSharedULX.category, "ulx fakeban", ulx.fakeban, "!fakeban")
fakeban:addParam{ type=ULib.cmds.PlayerArg }
fakeban:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
fakeban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
fakeban:defaultAccess( ULib.ACCESS_ADMIN )
fakeban:help( "Fake ban, now with fake disconnect built-in." )
