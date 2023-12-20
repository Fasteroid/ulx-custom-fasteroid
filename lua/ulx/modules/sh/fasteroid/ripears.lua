------------------------------ Rip Ears ------------------------------
function ulx.ripears( calling_ply, target_plys, should_asmr )
	for i=1, #target_plys do
			local v = target_plys[ i ]
			if not should_asmr then
				net.Start("FasteroidClientULX")
					net.WriteString("ripears")
				net.Send(v)
			else
				net.Start("FasteroidClientULX")
					net.WriteString("asmr")
				net.Send(v)
			end
	end
	if should_asmr then
		ulx.fancyLogAdmin( calling_ply, false, "#A played pleasant silence to #T", target_plys)
	else
		ulx.fancyLogAdmin( calling_ply, false, "#A destroyed the ears of #T", target_plys)
	end
end
local ear = ulx.command( FasteroidSharedULX.category, "ulx ripears", ulx.ripears, "!ripears" )
ear:addParam{ type=ULib.cmds.PlayersArg }
ear:addParam{ type=ULib.cmds.BoolArg, invisible=true }
ear:defaultAccess( ULib.ACCESS_SUPERADMIN )
ear:help( "Exposes target(s) to very loud sound until stopped with !asmr.  Prolonged exposure should be avoided." )
ear:setOpposite("ulx asmr", {_, _, true}, "!asmr")

if CLIENT then
	local function loud( soundname, numberofsounds, pitch )
		for i = 0, numberofsounds do
			LocalPlayer():EmitSound( soundname, 2000, pitch or 100, 1 )
			LocalPlayer():GetActiveWeapon():EmitSound( soundname, 2000, pitch or 100, 1 )
			surface.PlaySound(soundname)
		end
	end
	FasteroidClientULX.ripears = function()
		hook.Add("HUDPaint" , "ULX.Fasteroid.RipEars" , function()
			loud( "vehicles/v8/vehicle_impact_heavy"..math.random(1,4)..".wav", 32, 100 )
			util.ScreenShake(LocalPlayer():GetPos(),24,5,0.04,60000)
			DrawMotionBlur(0.1, 0.8, 0.01)
		end)
	end
	FasteroidClientULX.asmr = function()
		RunConsoleCommand("stopsound","")
		hook.Remove("HUDPaint" , "ULX.Fasteroid.RipEars" )
	end
end