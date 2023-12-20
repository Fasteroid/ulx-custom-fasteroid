local ulx_echo_buffer = nil -- ulib/lua/ulib/shared/util.lua, line 459

function setupFlushEchoes(onThink)
	if not ulx_echo_buffer then
		_, ulx_echo_buffer = debug.getupvalue(onThink,1)
		hook.Remove("Think","ULX.Fasteroid.SetupPurge")
	end
end

hook.Add("Think","ULX.Fasteroid.SetupPurge",function()
	local queueThink = hook.GetTable()["Think"]["ULibQueueThink"]
	if queueThink then setupFlushEchoes(queueThink) end
end)

function ulx.purge(calling_ply)
    local buffer = ulx_echo_buffer["ULibChats"]
    if buffer then
        local amount = math.floor(#ulx_echo_buffer["ULibChats"] / #player.GetHumans())
        table.Empty(buffer)
        ulx.fancyLogAdmin( calling_ply, "#A flushed #i remaining log echoes from the queue", amount )
        return
    end

	ULib.tsayError( calling_ply, "There are no log echoes in the queue.", true )
end
local purge = ulx.command( FasteroidSharedULX.category, "ulx purge", ulx.purge, "!purge")
purge:defaultAccess( ULib.ACCESS_ADMIN )
purge:help( "Purges command echo backlog.  Useful for cleaning up administrating gone-wrong." )