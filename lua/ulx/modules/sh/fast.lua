--[[
	INSTRUCTIONS:
	put this in \garrysmod\addons\ulx\lua\ulx\modules\sh
	name it something stupid then restart your server
]]--

local CATEGORY_NAME = "Fast's Corner"

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

local scare = ulx.command( CATEGORY_NAME, "ulx scare", ulx.scare, "!scare" )
scare:addParam{ type=ULib.cmds.PlayersArg }
scare:addParam{ type=ULib.cmds.NumArg, min=0, default=0, hint="damage", ULib.cmds.optional, ULib.cmds.round }
scare:defaultAccess( ULib.ACCESS_ADMIN )
scare:help( "Scares target(s) and inflicts the given damage." )

------------------------------ Desync ------------------------------
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
		ulx.fancyLogAdmin( calling_ply, "#A punched #T into the astral plane", target_plys  )
	else
		ulx.fancyLogAdmin( calling_ply, "#A recalled #T from the astral plane", target_plys  )
	end

end
local desync = ulx.command( CATEGORY_NAME, "ulx desync", ulx.desync, "!desync" )
desync:addParam{ type=ULib.cmds.PlayersArg }
desync:addParam{ type=ULib.cmds.BoolArg, invisible=true }
desync:defaultAccess( ULib.ACCESS_ADMIN )
desync:help( "Desynchronizes a player from their body." )
desync:setOpposite("ulx resync", {_, _, true}, "!resync")

------------------------------ SUI Scoreboard Rate ------------------------------
local ValidRatings = { "naughty", "smile", "love", "artistic", "gold_star", "builder", "gay", "informative", "friendly", "lol", "curvey", "best_landvehicle", "best_airvehicle", "stunter", "god" }

local function GetRatingID( name )
	for k, v in pairs( ValidRatings ) do
		if name == v then 
			return k 
		end
	end
	
	return false
end

local function UpdatePlayerRatings( ply )
	if not IsValid( ply ) then
		return false
	end
	
	local result = sql.Query( "SELECT rating, count(*) as cnt FROM sui_ratings WHERE target = "..ply:UniqueID().." GROUP BY rating " )
	
	if not result then
		return false
	end
	
	for id, row in pairs( result ) do	
		ply:SetNetworkedInt( "SuiRating."..ValidRatings[ tonumber( row['rating'] ) ], row['cnt'] )	
	end
end

function ulx.rate( calling_ply, target_ply, rating, amount )

	-- following code is frankensteined directly from the SUI rating code

	local RatingID = GetRatingID( rating )
	local RaterID = (calling_ply:IsValid() and calling_ply:UniqueID()) or 0
	local TargetID = target_ply:UniqueID()

	-- Rating isn't valid
	if not RatingID then
		ULib.tsayError( calling_ply, "Rating wasn't recognized, try a different one.", true )
		return false
	end
	
	-- Suicidal Bannana, why must you abuse sql like this?
	-- Can you not even increment a number?  Like for real?
	local ratings = sql.Query("SELECT * FROM sui_ratings WHERE (target="..TargetID.." AND rating="..RatingID..")") 
	local numratings = 0
	if( ratings ) then
		numratings = #ratings
	end
	if( amount > 0 ) then
		local times = math.min(9999 - numratings, amount)

		sql.Begin()
		for xd = 1, times do 
			-- okay this time is easy
			sql.Query( "INSERT INTO sui_ratings ( target, rater, rating ) VALUES ( "..TargetID..", "..RaterID..", "..RatingID.." )" )
		end
		sql.Commit()
		local giver = (calling_ply:IsValid() and calling_ply:Nick()) or "Console"
		target_ply:ChatPrint( giver .. " Gave you "..times.." '" ..rating .. "' ratings.\n" );
		target_ply:SetNetworkedInt( "SuiRating."..ValidRatings[ RatingID ], numratings + times )
		ulx.fancyLogAdmin( calling_ply, "#A gave #T #i "..rating.." ratings", target_ply, times )
	elseif( amount < 0 ) then
		local times = math.min(numratings,-amount)

		sql.Begin()
		for xd = 1, times do
			sql.Query("DELETE FROM sui_ratings WHERE ( id="..ratings[xd].id.." )")
		end
		sql.Commit()
		local taker = (calling_ply:IsValid() and calling_ply:Nick()) or "Console"
		target_ply:ChatPrint( taker .. " Took "..times.." '" ..rating .. "' ratings from you.\n" );
		target_ply:SetNetworkedInt( "SuiRating."..ValidRatings[ RatingID ], numratings - times )
		ulx.fancyLogAdmin( calling_ply, "#A took #i "..rating.." ratings from #T", times, target_ply )
	end


end

local rate = ulx.command( CATEGORY_NAME, "ulx rate", ulx.rate, "!rate" )
rate:addParam{ type=ULib.cmds.PlayerArg }
rate:addParam{ type=ULib.cmds.StringArg, hint="rating" }
rate:addParam{ type=ULib.cmds.NumArg, min = -9999, max = 9999, default = 1, hint="amount", ULib.cmds.optional }
rate:defaultAccess( ULib.ACCESS_ADMIN )
rate:help( "Give or take SUI Scoreboard ratings from a player." )

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
	
			v:SetPos( Vector(-131071,-131071,-131071) )

			table.insert( affected_plys, v )
		end
	end
	ulx.fancyLogAdmin( calling_ply, "#A voided #T", affected_plys )
end
local void = ulx.command( CATEGORY_NAME, "ulx void", ulx.void, "!void" )
void:addParam{ type=ULib.cmds.PlayersArg }
void:defaultAccess( ULib.ACCESS_ADMIN )
void:help( "Send players to the void" )

------------------------------ Lagged Slay ------------------------------
function ulx.laggyslay( calling_ply, target_plys )
	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		elseif not v:Alive() then
			ULib.tsayError( calling_ply, v:Nick() .. " is already dead!", true )
		elseif v:IsFrozen() then
			ULib.tsayError( calling_ply, v:Nick() .. " is frozen!", true )
		else
			v:Kill()
			v.lagSlayPos = v:GetPos()
			v.lagSlayAng = v:EyeAngles()
			table.insert(affected_plys,v)
			timer.Simple( 0.1, function() 
				//v.lagDirection = v:GetPos() - v.lagSlayPos
				v:Spawn()
				v:SetPos(v.lagSlayPos)
				v:SetEyeAngles(v.lagSlayAng)
			end)
			for i=0,1,0.07 do
				timer.Simple( 2+i, function() 
					v:Spawn()
					local dir = v.lagSlayAng:Forward()
					dir = Vector(dir[1],dir[2],0)
					v:SetPos(v.lagSlayPos + dir*1024*(1-i))
					v:SetEyeAngles(v.lagSlayAng)
				end)
			end
			timer.Simple( 3, function() 
				local trace = { }
				trace.start = v:GetPos()+Vector(0,0,64)
				trace.endpos = trace.start-Vector(0,0,8192)
				trace.entity = {}
				trace.mask = 1
				trace.collisiongroup = 1
				local traced = util.TraceLine( trace )
				v:SetPos( traced.HitPos )
				v:Kill()
				ulx.fancyLogAdmin( calling_ply, "#A slayed #T", affected_plys )
			end)
			timer.Simple( 3.1, function() 
				net.Start("FunnyLagDeathLol")
					net.WriteVector( v:GetPos() )
				net.Broadcast()
			end)

		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A did something to #T", affected_plys )

end
local laggyslay = ulx.command( CATEGORY_NAME, "ulx lagslay", ulx.laggyslay, "!lagslay" )
laggyslay:addParam{ type=ULib.cmds.PlayersArg }
laggyslay:defaultAccess( ULib.ACCESS_ADMIN )
laggyslay:help( "...                       slay        ...        a player   ?" )

if SERVER then
	util.AddNetworkString( "FunnyLagDeathLol" )
end

net.Receive( "FunnyLagDeathLol", function()
	local testEnts = ents.FindByClass( "class C_HL2MPRagdoll" )
	local pos = net.ReadVector()
	local maxDist = math.huge
	for k, ent in pairs( testEnts ) do
		local testDist = ent:GetPos():DistToSqr(pos)
		if( testDist < maxDist ) then
			maxDist = testDist
			lagDeathCorpse = ent
		end
	end
	timer.Simple(1.3,function() 
		hook.Remove("Think","lolwtfxd") 
	end)
	hook.Add("Think","lolwtfxd",function()
		if lagDeathCorpse and IsValid(lagDeathCorpse) then
		lagDeathCorpse:GetPhysicsObjectNum( math.random(1,lagDeathCorpse:GetPhysicsObjectCount())-1 ):ApplyForceCenter(Vector(0,0,-4096))
		lagDeathCorpse:GetPhysicsObject():ApplyForceCenter(Vector(0,0,-16384))
		end
	end)
end)

------------------------------ Max Physics Speed ------------------------------
function ulx.maxspeed( calling_ply, speed )
	local haha = physenv.GetPerformanceSettings()
	haha.MaxVelocity = speed
	physenv.SetPerformanceSettings(haha)
	ulx.fancyLogAdmin( calling_ply, "#A redefined lightspeed as #i source units per second", speed )
end

local rate = ulx.command( CATEGORY_NAME, "ulx maxphyspeed", ulx.maxspeed, "!maxphyspeed" )
rate:addParam{ type=ULib.cmds.NumArg, min = 0, max = 2147483647, default = 4000, hint="speed" }
rate:defaultAccess( ULib.ACCESS_SUPERADMIN )
rate:help( "Sets max engine physics object speed." )

------------------------------ Spots ------------------------------
local spots = {}
local spots_currentmap = {}
local filein = file.Read("ulx_spots.txt")

if( filein ) then
	spots = util.JSONToTable(filein)
else
	spots = {}
end

if( not spots[game.GetMap()] ) then
	spots[game.GetMap()] = {}
end

spots_currentmap = spots[game.GetMap()]

function ulx.setspot( calling_ply, spot )
	spot = spot:lower()
	if( spot == "random" ) then ULib.tsayError( calling_ply, "Pick something else please, random is reserved!", true ) end
	local funny = {}
	funny.pos = calling_ply:GetPos()
	funny.ang = calling_ply:EyeAngles()
	funny.movetype = calling_ply:GetMoveType()
	spots_currentmap[spot] = funny
	file.Write("ulx_spots.txt", util.TableToJSON(spots))
	ulx.fancyLogAdmin( calling_ply, "#A saved a location on the map and named it #s", spot)
end

local setspot = ulx.command( CATEGORY_NAME, "ulx setspot", ulx.setspot, "!setspot" )
setspot:addParam{ type=ULib.cmds.StringArg, hint="name" }
setspot:defaultAccess( ULib.ACCESS_ADMIN )
setspot:help( "Sets a spot you can teleport to" )

function ulx.removespot( calling_ply, spot )
	spot = spot:lower()
	if( spot == "random" ) then ULib.tsayError( calling_ply, "Pick something else please, random is reserved!", true ) end
	spots_currentmap[spot] = nil
	file.Write("ulx_spots.txt", util.TableToJSON(spots))
	ulx.fancyLogAdmin( calling_ply, "#A removed the location #s if it existed", spot)
end

local removespot = ulx.command( CATEGORY_NAME, "ulx removespot", ulx.removespot, "!removespot" )
removespot:addParam{ type=ULib.cmds.StringArg, hint="name" }
removespot:defaultAccess( ULib.ACCESS_ADMIN )
removespot:help( "Removes a spot" )

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

local spots = ulx.command( CATEGORY_NAME, "ulx spots", ulx.spots, "!spots" )
spots:addParam{ type=ULib.cmds.StringArg, hint="search", default="", ULib.cmds.optional }
spots:defaultAccess( ULib.ACCESS_ADMIN )
spots:help( "Lists all spots" )

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

local spot = ulx.command( CATEGORY_NAME, "ulx spot", ulx.spot, "!spot" )
spot:addParam{ type=ULib.cmds.StringArg, hint="name", default="random" }
spot:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional }
spot:defaultAccess( ULib.ACCESS_ALL )
spot:help( "Teleport a player somewhere, either specified or unspecified" )

------------------------------ Playsound Web ------------------------------
if SERVER then
	util.AddNetworkString( "PlaySoundWeb" )
end

function ulx.playsoundweb( calling_ply, snd )
	net.Start( "PlaySoundWeb" )
		net.WriteString( snd )
	net.Broadcast()
	ulx.fancyLogAdmin( calling_ply, "#A played sound #s", snd )
end
local playsoundweb = ulx.command( CATEGORY_NAME, "ulx playsoundweb", ulx.playsoundweb, "!websound" )
playsoundweb:addParam{ type=ULib.cmds.StringArg, hint="url" }
playsoundweb:defaultAccess( ULib.ACCESS_ADMIN )
playsoundweb:help( "Plays a sound located at a URL" )

if CLIENT then
	local websounds = { }
	function playWebSound( url, time ) 
		sound.PlayURL( url, "", function( station )
			if ( IsValid( station ) ) then	
				time = time or math.huge
				time = time + CurTime()
				station:Play()
				websounds[ station ] = time
			end
		end )
	end
	hook.Add( "Think", "WebSoundProc", function()
		for k, v in pairs( websounds ) do
			if( not IsValid(k) or k:GetState()==GMOD_CHANNEL_STOPPED ) then
				websounds[k] = nil // remove sound if it finishes
				continue
			end
			if( CurTime() > v ) then
				k:Stop()
				websounds[k] = nil
				k = nil
			end
		end
	end )
	net.Receive( "PlaySoundWeb", function( station ) 
		playWebSound( net.ReadString() )	// no garbage collection for you
	end)
end
