------------------------------ Playsound Web ------------------------------
function ulx.playsoundweb( calling_ply, snd )
	net.Start( "FasteroidClientULX" )
		net.WriteString( "websound" )
		net.WriteString( snd )
	net.Broadcast()
	ulx.fancyLogAdmin( calling_ply, "#A played sound #s", snd )
end
local playsoundweb = ulx.command( FasteroidSharedULX.category, "ulx websound", ulx.playsoundweb, "!websound" )
playsoundweb:addParam{ type=ULib.cmds.StringArg, hint="url" }
playsoundweb:defaultAccess( ULib.ACCESS_ADMIN )
playsoundweb:help( "Plays the sound at the provided URL to all players." )

if CLIENT then
    local websound_instances = {}

	FasteroidClientULX.websound = function()
		local url = net.ReadString()
		sound.PlayURL( url, "", function( station )
			if ( IsValid( station ) ) then
				time = time or math.huge
				time = time + CurTime()
				station:Play()
				websound_instances[ station ] = time
			end
		end )
	end
	hook.Add( "Think", "WebSoundProc", function()
		for k, v in pairs( websound_instances ) do
			if( not IsValid(k) or k:GetState()==GMOD_CHANNEL_STOPPED ) then
				websound_instances[k] = nil // remove sound if it finishes
				continue
			end
			if( CurTime() > v ) then
				k:Stop()
				websound_instances[k] = nil
				k = nil
			end
		end
	end )
	net.Receive( "PlaySoundWeb", function( station )
		playWebSound( net.ReadString() )	// no garbage collection for you
	end)
end
