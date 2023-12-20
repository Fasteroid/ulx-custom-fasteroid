------------------------------ Max Physics Speed & Angular Speed ------------------------------
local maxspeed, maxangspeed

function ulx.maxspeed( calling_ply, speed )
	local phys = physenv.GetPerformanceSettings()
	local semantics = {"redefined","as"}
	if phys.MaxVelocity == speed then -- assume they want help
		ULib.tsayError( calling_ply, maxspeed:getUsage(calling_ply), true )
		return
	end
	if maxspeed.args[2].default == speed then
		semantics = {"reset","to"}
	end
	phys.MaxVelocity = speed
	physenv.OldSetPerformanceSettings(phys)
	ulx.fancyLogAdmin( calling_ply, "#A "..semantics[1].." lightspeed "..semantics[2].." #i source units per second", speed )
end

maxspeed = ulx.command( FasteroidSharedULX.category, "ulx maxphyspeed", ulx.maxspeed, "!maxphyspeed" )
maxspeed:addParam{ type=ULib.cmds.NumArg, min = 0, max = 2147483647, hint="speed", ULib.cmds.optional }
maxspeed:defaultAccess( ULib.ACCESS_SUPERADMIN )
maxspeed:help( "Sets the engine's max speed for physics objects." )


function ulx.maxangspeed( calling_ply, speed )
	local phys = physenv.GetPerformanceSettings()
	local semantics = {"redefined","as"}
	if phys.MaxAngularVelocity == speed then -- assume they want help
		ULib.tsayError( calling_ply, maxangspeed:getUsage(calling_ply), true )
		return
	end
	if maxangspeed.args[2].default == speed then
		semantics = {"reset","to"}
	end
	phys.MaxAngularVelocity = speed
	physenv.OldSetPerformanceSettings(phys)
	ulx.fancyLogAdmin( calling_ply, "#A "..semantics[1].." angular lightspeed "..semantics[2].." #i rotations per second", speed )
end
maxangspeed = ulx.command( FasteroidSharedULX.category, "ulx maxangspeed", ulx.maxangspeed, "!maxangspeed" )
maxangspeed:addParam{ type=ULib.cmds.NumArg, min=0, max = 2147483647, hint="speed", ULib.cmds.optional }
maxangspeed:defaultAccess( ULib.ACCESS_SUPERADMIN )
maxangspeed:help( "Sets the engine's max rotational speed for physics objects." )

local function setPhysFuncDefaults(settings)
	if not settings then return end -- wtf?
	maxspeed.args[2].default    = settings.MaxVelocity
	maxangspeed.args[2].default = settings.MaxAngularVelocity
end

physenv.OldSetPerformanceSettings = physenv.OldSetPerformanceSettings or physenv.SetPerformanceSettings
physenv.SetPerformanceSettings = function(phys)
	setPhysFuncDefaults( phys )
	physenv.OldSetPerformanceSettings(phys)
end

setPhysFuncDefaults( physenv.GetPerformanceSettings() )