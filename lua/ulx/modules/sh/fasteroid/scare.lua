------------------------------ Scare ------------------------------
function ulx.scare( calling_ply, target_plys, dmg )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]
		ULib.slap( v, dmg )
		for i=1, 20 do // louder sound
			v:EmitSound("npc/stalker/go_alert2a.wav")
		end
		table.insert( affected_plys, v )
	end

	ulx.fancyLogAdmin( calling_ply, "#A scared #T and did #i damage", affected_plys, dmg )
end

local scare = ulx.command( FasteroidSharedULX.category, "ulx scare", ulx.scare, "!scare" )
scare:addParam{ type=ULib.cmds.PlayersArg }
scare:addParam{ type=ULib.cmds.NumArg, min=0, default=0, hint="damage", ULib.cmds.optional, ULib.cmds.round }
scare:defaultAccess( ULib.ACCESS_ADMIN )
scare:help( "Slaps target(s) with the stalker scream sound and inflicts damage." )