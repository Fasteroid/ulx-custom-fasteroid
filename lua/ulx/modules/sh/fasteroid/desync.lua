function ulx.desync( calling_ply, target_plys, sync )

	for i = 1, #target_plys do
		v = target_plys[i]
		for j, k in pairs( ents.GetAll() ) do
			if( true ) then -- TODO: further research must be done to know what actually causes the out-of-body effect so we don't have to do this for every entity
				k:SetPreventTransmit(v, not sync)
			end
		end
	end

	if( not sync ) then
		ulx.fancyLogAdmin( calling_ply, "#A punched #T into the astral plane", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A recalled #T from the astral plane", target_plys )
	end

end
local desync = ulx.command( FasteroidSharedULX.category, "ulx desync", ulx.desync, "!desync" )
desync:addParam{ type=ULib.cmds.PlayersArg }
desync:addParam{ type=ULib.cmds.BoolArg, invisible=true }
desync:defaultAccess( ULib.ACCESS_ADMIN )
desync:help( "Desynchronizes target(s) from their body, causing many strange effects." )
desync:setOpposite("ulx resync", {_, _, true}, "!resync")