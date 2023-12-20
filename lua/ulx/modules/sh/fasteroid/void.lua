------------------------------ Void ------------------------------
function ulx.void( calling_ply, target_plys )
	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		else
			v.ulx_prevpos = v:GetPos()
			v.ulx_prevang = v:EyeAngles()
			v:SetVelocity(-v:GetVelocity())
			v:SetPos(Vector(-131071,-131071,-131071))
			timer.Create("void_"..v:Nick(),0.1,0,function()
				if( v:GetPos():IsEqualTol(Vector(-131071,-131071,-131071),32) ) then
					timer.Remove("void_"..v:Nick())
				end
				v:SetVelocity(-v:GetVelocity())
				v:SetPos(Vector(-131071,-131071,-131071))
			end)

			table.insert( affected_plys, v )
		end
	end
	ulx.fancyLogAdmin( calling_ply, "#A voided #T", affected_plys )
end
local void = ulx.command( FasteroidSharedULX.category, "ulx void", ulx.void, "!void" )
void:addParam{ type=ULib.cmds.PlayersArg }
void:defaultAccess( ULib.ACCESS_ADMIN )
void:help( "Sends target(s) to the void.  Returning to the map from the void is very difficult, but technically possible." )