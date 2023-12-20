------------------------------ Spots ------------------------------
local spots = {}
local spots_currentmap = {}
local filein = file.Read("ulx_spots.txt") // sql is cool, but I don't like it

if( filein ) then
	spots = util.JSONToTable(filein)
else
	spots = {}
end

if( not spots[game.GetMap()] ) then
	spots[game.GetMap()] = {}
end

local spots_currentmap = spots[game.GetMap()]

function ulx.setspot( calling_ply, spot )
	spot = spot:lower()
	if( spot == "random" ) then ULib.tsayError( calling_ply, "Pick something else please, random is reserved!", true ) end
	local funny = {}
	funny.pos = calling_ply:GetPos()
	funny.ang = calling_ply:EyeAngles()
	funny.movetype = calling_ply:GetMoveType()
	spots_currentmap[spot] = funny
	file.Write("ulx_spots.txt", util.TableToJSON(spots))
	ulx.fancyLogAdmin( calling_ply, "#A saved a spot on the map and named it #s", spot)
end

local setspot = ulx.command( FasteroidSharedULX.category, "ulx setspot", ulx.setspot, "!setspot" )
setspot:addParam{ type=ULib.cmds.StringArg, hint="name" }
setspot:defaultAccess( ULib.ACCESS_ADMIN )
setspot:help( "Sets a restart-persistent, map-specific spot players can teleport to." )

function ulx.removespot( calling_ply, spot )
	spot = spot:lower()
	if( spot == "random" ) then ULib.tsayError( calling_ply, "Pick something else please, random is reserved!", true ) end
	spots_currentmap[spot] = nil
	file.Write("ulx_spots.txt", util.TableToJSON(spots))
	ulx.fancyLogAdmin( calling_ply, "#A removed the spot #s if it existed", spot)
end

local removespot = ulx.command( FasteroidSharedULX.category, "ulx removespot", ulx.removespot, "!removespot" )
removespot:addParam{ type=ULib.cmds.StringArg, hint="name" }
removespot:defaultAccess( ULib.ACCESS_ADMIN )
removespot:help( "Removes a previously set spot." )

function ulx.spots( calling_ply, search )
	local n = 0
	ULib.tsayColor(calling_ply, true,Color(255,255,255),"-------- ULX Spots --------")
	for k, v in SortedPairs(spots_currentmap) do
		if( string.find( k, search ) ) then
			n = n + 1
			ULib.tsayColor( calling_ply, true, Color(180,255,255), n.."", Color(255,255,255), "\t|\t" , Color(255,180,255), k )
		end
	end
end

local spots = ulx.command( FasteroidSharedULX.category, "ulx spots", ulx.spots, "!spots" )
spots:addParam{ type=ULib.cmds.StringArg, hint="search term", default="", ULib.cmds.optional }
spots:defaultAccess( ULib.ACCESS_ADMIN )
spots:help( "Lists the names of all spots that include the give search term.  Provide nothing to list them all." )

function ulx.spot( calling_ply, spot, target_ply )
	spot = spot:lower()

	if ulx.getExclusive( target_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( target_ply, calling_ply ), true )
	else
		local funnyspot = nil

		if( spot ~= "random" ) then
			funnyspot = spots_currentmap[spot]
		else
			funnyspot = table.Random(spots_currentmap)
		end

		if( funnyspot ) then
			target_ply.ulx_prevpos = target_ply:GetPos()
			target_ply.ulx_prevang = target_ply:EyeAngles()
			target_ply:SetPos( funnyspot.pos )
			target_ply:SetEyeAngles( funnyspot.ang )
			target_ply:SetMoveType( funnyspot.movetype )
		else
			ULib.tsayError( calling_ply, "Location \""..spot.."\" not set yet; say \"!setspot "..spot.."\" to set it", true )
			return
		end

		if( spot ~= "random" ) then
			ulx.fancyLogAdmin( calling_ply, "#A teleported #T to #s", target_ply, spot )
		else
			ulx.fancyLogAdmin( calling_ply, "#A teleported #T to a random noteworthy location", target_ply )
		end

	end

end

local spot = ulx.command( FasteroidSharedULX.category, "ulx spot", ulx.spot, "!spot" )
spot:addParam{ type=ULib.cmds.StringArg, ULib.cmds.optional, hint="name", default="random" }
spot:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional }
spot:defaultAccess( ULib.ACCESS_ALL )
spot:help( "Teleports the target to the previously set spot. Use the 'random' spot to choose randomly from all spots." )