
local CATEGORY_NAME = "Fast's Corner"

if SERVER then
	util.AddNetworkString( "FasteroidCSULX" )
end

FasteroidCSULX = nil
if CLIENT then
	WEBSOUNDS = { }
	FasteroidCSULX = { }
	net.Receive("FasteroidCSULX", function()
		FasteroidCSULX[ net.ReadString() ]()
	end)
end

FasteroidSharedULX = {}

FasteroidSharedULX.lookupULXCommand = function (command) -- used in swepify and serialize
	local base_command = ULib.splitArgs( command ) -- get args first

	-- first arg is the command; extract it for use
	local match = base_command[1] .. " " -- sayCmd keys all end with a space
	table.remove(base_command, 1)        -- don't need this anymore

	local cmd
	do
		local sayCmd = ULib.sayCmds[match]
		if not sayCmd then -- gorp
			ULib.tsayError( calling_ply, "Try a 'say' command, like !slap *", true )
			return
		end
		cmd = ULib.cmds.translatedCmds[sayCmd.access]
	end

	return base_command, match, cmd
end

FasteroidSharedULX.ulxSayEscape = function(text)
	text = string.Replace(text,"\\","\\\\")
	text = string.Replace(text,'"','\\"')
	return text
end

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
scare:help( "Slaps target(s) with the stalker scream sound and inflicts damage." )


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
		ulx.fancyLogAdmin( calling_ply, "#A punched #T into the astral plane", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A recalled #T from the astral plane", target_plys )
	end

end
local desync = ulx.command( CATEGORY_NAME, "ulx desync", ulx.desync, "!desync" )
desync:addParam{ type=ULib.cmds.PlayersArg }
desync:addParam{ type=ULib.cmds.BoolArg, invisible=true }
desync:defaultAccess( ULib.ACCESS_ADMIN )
desync:help( "Desynchronizes target(s) from their body, causing many strange effects." )
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
rate:help( "Modifies a player's SUI Scoreboard ratings.  Negative amounts take away ratings." )


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
local void = ulx.command( CATEGORY_NAME, "ulx void", ulx.void, "!void" )
void:addParam{ type=ULib.cmds.PlayersArg }
void:defaultAccess( ULib.ACCESS_ADMIN )
void:help( "Sends target(s) to the void.  Returning to the map from the void is very difficult, but technically possible." )


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
			end)
			timer.Simple( 3.1, function()
				net.Start("FasteroidCSULX")
					net.WriteString("lagdeath")
					net.WriteVector( v:GetPos() )
				net.Broadcast()
			end)

		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A did something to #T...", affected_plys )
	timer.Simple(3, function() ulx.fancyLogAdmin( nil, "#T lagged to death", affected_plys) end)

end
local laggyslay = ulx.command( CATEGORY_NAME, "ulx lag", ulx.laggyslay, "!lag" )
laggyslay:addParam{ type=ULib.cmds.PlayersArg }
laggyslay:defaultAccess( ULib.ACCESS_ADMIN )
laggyslay:help( "Causes target(s) to rubberband before dying spectacularly." )

if CLIENT then
	FasteroidCSULX.lagdeath = function()
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
	end
end


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

maxspeed = ulx.command( CATEGORY_NAME, "ulx maxphyspeed", ulx.maxspeed, "!maxphyspeed" )
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
maxangspeed = ulx.command( CATEGORY_NAME, "ulx maxangspeed", ulx.maxangspeed, "!maxangspeed" )
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
	ulx.fancyLogAdmin( calling_ply, "#A saved a spot on the map and named it #s", spot)
end

local setspot = ulx.command( CATEGORY_NAME, "ulx setspot", ulx.setspot, "!setspot" )
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

local removespot = ulx.command( CATEGORY_NAME, "ulx removespot", ulx.removespot, "!removespot" )
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

local spots = ulx.command( CATEGORY_NAME, "ulx spots", ulx.spots, "!spots" )
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

local spot = ulx.command( CATEGORY_NAME, "ulx spot", ulx.spot, "!spot" )
spot:addParam{ type=ULib.cmds.StringArg, ULib.cmds.optional, hint="name", default="random" }
spot:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional }
spot:defaultAccess( ULib.ACCESS_ALL )
spot:help( "Teleports the target to the previously set spot. Use the 'random' spot to choose randomly from all spots." )


------------------------------ Playsound Web ------------------------------
function ulx.playsoundweb( calling_ply, snd )
	net.Start( "FasteroidCSULX" )
		net.WriteString( "websound" )
		net.WriteString( snd )
	net.Broadcast()
	ulx.fancyLogAdmin( calling_ply, "#A played sound #s", snd )
end
local playsoundweb = ulx.command( CATEGORY_NAME, "ulx websound", ulx.playsoundweb, "!websound" )
playsoundweb:addParam{ type=ULib.cmds.StringArg, hint="url" }
playsoundweb:defaultAccess( ULib.ACCESS_ADMIN )
playsoundweb:help( "Plays the sound at the provided URL to all players." )

if CLIENT then
	FasteroidCSULX.websound = function()
		local url = net.ReadString()
		sound.PlayURL( url, "", function( station )
			if ( IsValid( station ) ) then
				time = time or math.huge
				time = time + CurTime()
				station:Play()
				WEBSOUNDS[ station ] = time
			end
		end )
	end
	hook.Add( "Think", "WebSoundProc", function()
		for k, v in pairs( WEBSOUNDS ) do
			if( not IsValid(k) or k:GetState()==GMOD_CHANNEL_STOPPED ) then
				WEBSOUNDS[k] = nil // remove sound if it finishes
				continue
			end
			if( CurTime() > v ) then
				k:Stop()
				WEBSOUNDS[k] = nil
				k = nil
			end
		end
	end )
	net.Receive( "PlaySoundWeb", function( station )
		playWebSound( net.ReadString() )	// no garbage collection for you
	end)
end


------------------------------ "Bad Aim" ------------------------------
local PlayerMeta = FindMetaTable("Player")
function PlayerMeta:getShitAim( )
	return self:GetNW2Bool( "shitaim", false )
end

if SERVER then
	function PlayerMeta:setShitAim( enabled )
		self:SetNW2Bool( "shitaim", enabled )
	end
end

local function aimModifier(ent, bullet)
	if( IsValid(ent) and ent:IsPlayer() and ent:getShitAim() ) then
		local theta = CurTime() * 4200
		local spread = bullet.Dir:Angle() + Angle(15,0,0)
		spread:RotateAroundAxis( bullet.Dir, util.SharedRandom( "shitaim", 0, 360 ) )
		bullet.Dir = spread:Forward()
		bullet.Spread = Vector(1,1,0)*0.1
		return true
	end
end
hook.Add( "EntityFireBullets", "ulx_shitaim", aimModifier )

function ulx.badaim( calling_ply, target_plys, mode )

	for i = 1, #target_plys do
		v = target_plys[i]
		v:setShitAim( not mode )
	end


	if( not mode ) then
		ulx.fancyLogAdmin( calling_ply, "#A disabled #T's aiming skills", target_plys  )
	else
		ulx.fancyLogAdmin( calling_ply, "#A re-enabled #T's aiming skills", target_plys  )
	end

end
local badaim = ulx.command( CATEGORY_NAME, "ulx shitaim", ulx.badaim, "!shitaim" )
badaim:addParam{ type=ULib.cmds.PlayersArg }
badaim:addParam{ type=ULib.cmds.BoolArg, invisible=true }
badaim:defaultAccess( ULib.ACCESS_ADMIN )
badaim:help( "Causes all bullets fired by target(s) to stray about 15 degrees away from their crosshair in random directions." )
badaim:setOpposite("ulx unshitaim", {_, _, true}, "!unshitaim")


------------------------------ Rip Ears ------------------------------
function ulx.ripears( calling_ply, target_plys, should_asmr )
	for i=1, #target_plys do
			local v = target_plys[ i ]
			if not should_asmr then
				net.Start("FasteroidCSULX")
					net.WriteString("ripears")
				net.Send(v)
			else
				net.Start("FasteroidCSULX")
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
local ear = ulx.command( "Lua Scripts", "ulx ripears", ulx.ripears, "!ripears" )
ear:addParam{ type=ULib.cmds.PlayersArg }
ear:addParam{ type=ULib.cmds.BoolArg, invisible=true }
ear:defaultAccess( ULib.ACCESS_SUPERADMIN )
ear:help( "Exposes target(s) to very loud sound until stopped with !asmr.  Prolonged exposure should be avoided." )
ear:setOpposite("ulx asmr", {_, _, true}, "!asmr")

if CLIENT then
	local function earrape( soundname, numberofsounds, pitch )
		for i = 0, numberofsounds do
			LocalPlayer():EmitSound( soundname, 2000, pitch or 100, 1 )
			LocalPlayer():GetActiveWeapon():EmitSound( soundname, 2000, pitch or 100, 1 )
			surface.PlaySound(soundname)
		end
	end
	FasteroidCSULX.ripears = function()
		local Player = LocalPlayer()
		if not Player.ripearsHook then
			local hooh = "" -- randomize the hook so it's just a bit harder for skids to block
			for i=1, 64 do
				hooh = hooh .. string.char( math.random(33, 126) )
			end
			hook.Add("HUDPaint" , hooh , function()
				earrape( "vehicles/v8/vehicle_impact_heavy"..math.random(1,4)..".wav", 32, 100 )
				util.ScreenShake(Player:GetPos(),24,5,0.04,60000)
				DrawMotionBlur(0.1, 0.8, 0.01)
			end)
			Player.ripearsHook = hooh
		end
	end
	FasteroidCSULX.asmr = function()
		local Player = LocalPlayer()
		RunConsoleCommand("stopsound","")
		if( Player.ripearsHook ) then
			hook.Remove("HUDPaint" , Player.ripearsHook )
			Player.ripearsHook = nil
		end
	end
end


------------------------------ Fake Ban ------------------------------
function ulx.fakeban(calling_ply, target_ply, minutes, reason)
	local time = "for #s"
	if minutes == 0 then time = "permanently" end
	local str = "#A banned #T " .. time
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
end
local fakeban = ulx.command( CATEGORY_NAME, "ulx fakeban", ulx.fakeban, "!fakeban")
fakeban:addParam{ type=ULib.cmds.PlayerArg }
fakeban:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
fakeban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
fakeban:defaultAccess( ULib.ACCESS_ADMIN )
fakeban:help( "Doesn't actually ban them." )


------------------------------ Bot Bomb ------------------------------

local BOTBOMB_CONSTS = {
	botNames = {
		"death",
		"bomb",
		"exploder",
		"doomfist",
		"nuker"
	},
	botFailMessages = {
		"FUCK",
		"aGH",
		"NO",
		"rip",
		"bruh",
		"h"
	},
	botSuccessMessages = {
		"HA",
		"GOTCHA",
		"YEET",
		"FUCKED",
		"GONE",
		"BOOM",
	}
}

-- stolen from ulx custom, forgive me
-- I was lazy today
local function botbombExplode(ply, bot)
	local playerpos = ply:GetPos()
	local waterlevel = ply:WaterLevel()

	timer.Simple( 0.1, function()
		local traceworld = {}
			traceworld.start = playerpos
			traceworld.endpos = traceworld.start + ( Vector( 0,0,-1 ) * 250 )
			local trw = util.TraceLine( traceworld )
			local worldpos1 = trw.HitPos + trw.HitNormal
			local worldpos2 = trw.HitPos - trw.HitNormal
		util.Decal( "Scorch",worldpos1,worldpos2 )
	end )

	bot:GodDisable()
	ply:GodDisable()
	ply:TakeDamage( 2147483647, bot, ply ) -- I know kill exists but this makes it show up in the killfeed, which is funnier

	util.ScreenShake( playerpos, 100, 15, 1.5, 800 )

	if ( waterlevel > 1 ) then
		local vPoint = playerpos + Vector(0,0,10)
			local effectdata = EffectData()
			effectdata:SetStart( vPoint )
			effectdata:SetOrigin( vPoint )
			effectdata:SetScale( 3 )
		util.Effect( "WaterSurfaceExplosion", effectdata )
		local vPoint = playerpos + Vector(0,0,10)
			local effectdata = EffectData()
			effectdata:SetStart( vPoint )
			effectdata:SetOrigin( vPoint )
			effectdata:SetScale( 3 )
		util.Effect( "HelicopterMegaBomb", effectdata )
	else
		local vPoint = playerpos + Vector( 0,0,10 )
			local effectdata = EffectData()
			effectdata:SetStart( vPoint )
			effectdata:SetOrigin( vPoint )
			effectdata:SetScale( 3 )
		util.Effect( "HelicopterMegaBomb", effectdata )
		ply:EmitSound( Sound ("ambient/explosions/explode_4.wav") )
	end
end

local function failBotbomb(bot, hookName)
	hook.Remove("Think",hookName)
	if not IsValid(bot) then return end
	local botFailMessages = BOTBOMB_CONSTS.botFailMessages
	bot:Say(botFailMessages[math.random(#botFailMessages)])
	botbombExplode(bot,bot)
	timer.Simple(0.5, function() if IsValid(bot) then bot:Kick() end end)
end

local function succBotbomb(bot, target_ply, hookName)
	bot:SetPos(target_ply:GetPos() + Vector(0,0,100))
	local botSuccessMessages = BOTBOMB_CONSTS.botSuccessMessages
	bot:Say(botSuccessMessages[math.random(#botSuccessMessages)])
	botbombExplode(target_ply,bot)
	bot:Kill()
	timer.Simple(0.5, function() if bot~=NULL then bot:Kick() end end)
	hook.Remove("Think",hookName)
end

function ulx.botbomb( calling_ply, target_ply, dmg )

	if( player.GetCount() == game.MaxPlayers() ) then
		ULib.tsayError( calling_ply, "Can't spawn the bot, the server is full!", true )
		return
	end

	if( target_ply:InVehicle() ) then
		ULib.tsayError( calling_ply, "Target is in a vehicle.", true )
		return
	end

	local trace = util.TraceHull( {
		start = target_ply:WorldSpaceCenter(),
		endpos = target_ply:WorldSpaceCenter() + Vector(0,0,8192),
		filter = target_ply,
		mins = Vector(-16,-16,0), -- size of the bot
		maxs = Vector(16,16,72)
	} )

	if trace.Fraction < 0.2 then
		ULib.tsayError( calling_ply, "Target is under something.", true )
		return
	end

	ulx.fancyLogAdmin( calling_ply, "#A called in an airstrike on #T", target_ply )

	local botNames = BOTBOMB_CONSTS.botNames
	local bot = player.CreateNextBot( botNames[math.random(#botNames)] )
	bot:GodEnable()
	bot:SetPos(trace.HitPos)

	local hookName = "botbomb_"..math.random()

	timer.Create(hookName, 10, 1, function() -- remove after 10 seconds if it doesn't find them
		failBotbomb(bot,hookName)
	end)

	hook.Add("Think",hookName,function()

		-- make absolutely sure both of these are valid
		if not IsValid(target_ply) then
			failBotbomb(bot,hookName)
		end
		if not IsValid(bot) then
			failBotbomb(bot,hookName)
		end

		local aimVec = (target_ply:GetShootPos() - bot:GetShootPos())
		bot:SetEyeAngles( aimVec:Angle() )
		aimVec[3] = 0
		local damping = bot:GetVelocity()
		damping[3] = 0
		bot:SetVelocity( aimVec:GetNormalized()*50 - damping * 0.05  )

		local collisionCheck = util.TraceHull( {
			start = bot:GetPos(),
			endpos = bot:GetPos(),
			filter = function(e) if e == target_ply then return true else return false end end,
			mins = Vector(-17,-17,-1),
			maxs = Vector(17,17,73),
			ignoreworld = true,
		} )

		if( collisionCheck.Hit ) then
			succBotbomb(bot,target_ply,hookName)
		elseif bot:OnGround() then
			failBotbomb(bot,hookName)
		end

	end)

end


local botbomb = ulx.command( CATEGORY_NAME, "ulx botbomb", ulx.botbomb, "!botbomb" )
botbomb:addParam{ type=ULib.cmds.PlayerArg }
botbomb:defaultAccess( ULib.ACCESS_SUPERADMIN )
botbomb:help( "Airstrikes the target with a bot." )


------------------------------ Serialize (PROBABLY DANGEROUS) ------------------------------
local playerParseAndValidate
local playersParseAndValidate
local sayCmdCheck
local lookupULXCommand = FasteroidSharedULX.lookupULXCommand
local escape           = FasteroidSharedULX.ulxSayEscape

hook.Add("Think","ULX_Fasteroid_SetupSerialize", function()
	local temp = hook.GetTable()["PlayerSay"]
	if (ULib and temp["ULib_saycmd"]) then
		hook.Remove("Think", "ULX_Fasteroid_SetupSerialize")
		playerParseAndValidate = ULib.cmds.PlayerArg.parseAndValidate
		playersParseAndValidate = ULib.cmds.PlayersArg.parseAndValidate
		sayCmdCheck = temp["ULib_saycmd"]
	end
end)

function ulx.serialize( calling_ply, command )

	local base_command, match, cmd = lookupULXCommand(command)
	if not base_command then return end

	local commands = { base_command } -- start with base command to serialize

	local arg_index = 1 -- since some args are invisible, we can't just use the index ipairs gives us below

	for _, argInfo in ipairs( cmd.args ) do -- check each arg to see if it needs to be serialized

		if( argInfo.type.invisible ) then
			continue
		end

		if( (argInfo.type.parseAndValidate == playerParseAndValidate or argInfo.type.parseAndValidate == playersParseAndValidate) and base_command[arg_index] ) then -- time to serialize

			local commands_copy = table.Copy(commands) -- copy and purge
			commands = { }
			
			for _, command_copy in pairs(commands_copy) do -- process commands (base command or output from previous loop iter)

				local suspect_arg = command_copy[arg_index]
				local targets     = ULib.getUsers(suspect_arg, true, calling_ply)

				if not targets then continue end

				for k, v in pairs( targets ) do -- generate serialized commands
					local new_command = table.Copy(command_copy)
					new_command[arg_index] = '"' .. escape( v:Nick() ) .. '"'
					table.insert(commands, new_command)
				end

			end
		end

		arg_index = arg_index + 1

	end

	ulx.fancyLogAdmin( calling_ply, "#A serialized #s", command )

	for k, args in pairs(commands) do
		pcall( sayCmdCheck, calling_ply, match .. table.concat(args," ") )
	end

end

local serialize = ulx.command( CATEGORY_NAME, "ulx serialize", ulx.serialize, "!serialize" )
serialize:addParam{ type=ULib.cmds.StringArg, ULib.cmds.takeRestOfLine, hint="any ulx command" }
serialize:defaultAccess( ULib.ACCESS_SUPERADMIN )
serialize:help( "Split one command into many.  Read command usage on Github for more." )


------------------------------ Flush Echos ------------------------------
local ulx_echo_buffer = nil -- ulib/lua/ulib/shared/util.lua, line 459
function setupFlushEchoes(onThink)
	if not ulx_echo_buffer then
		_, ulx_echo_buffer = debug.getupvalue(onThink,1)
		hook.Remove("Think","ULX_Fasteroid_SetupPurge")
	end
end

hook.Add("Think","ULX_Fasteroid_SetupPurge",function()
	local onThink = hook.GetTable()["Think"]["ULibQueueThink"]
	if onThink then
		setupFlushEchoes(onThink)
	end
end)

function ulx.purge(calling_ply)
	local f = hook.GetTable()["Think"]["ULibQueueThink"]
	if f then
		setupFlushEchoes(f) -- just in case someone runs this stupidly early
		local buffer = ulx_echo_buffer["ULibChats"]
		if buffer then
			local amount = math.floor(#ulx_echo_buffer["ULibChats"] / #player.GetHumans())
			table.Empty(buffer)
			ulx.fancyLogAdmin( calling_ply, "#A flushed #i remaining log echoes from the queue", amount )
			return
		end
	end
	ULib.tsayError( calling_ply, "There are no log echoes in the queue.", true )
end
local purge = ulx.command( CATEGORY_NAME, "ulx purge", ulx.purge, "!purge")
purge:defaultAccess( ULib.ACCESS_ADMIN )
purge:help( "Purges command echo backlog.  Useful for cleaning up administrating gone-wrong." )


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
local discon = ulx.command( CATEGORY_NAME, "ulx fakedc", ulx.fakedc, "!fakedc", true, false, true )
discon:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional, hint="target" }
discon:defaultAccess( ULib.ACCESS_SUPERADMIN )
discon:help( "Calls disconnect hook logic for the target to fake them leaving the server." )


------------------------------ Ragmaul ------------------------------
local logecho = GetConVar("ulx_logecho")
local logfile = GetConVar("ulx_logfile")
local logoldv = {}

local function setCanLog(can)
	if can then
		logecho:SetInt(logoldv.echo or logecho:GetInt())
		logfile:SetInt(logoldv.file or logfile:GetInt())
	else
		logoldv.echo = logecho:GetInt()
		logoldv.file = logfile:GetInt()
		logecho:SetInt(0)
		logfile:SetInt(0)
	end
end

local function lookupPhysobj(ent, keyword)
	local physobjs = {}
	for n=0, ent:GetPhysicsObjectCount()-1 do
		local name = ent:GetBoneName( ent:TranslatePhysBoneToBone(n) ):lower()
		if name:find( keyword, 1, true ) then return ent:GetPhysicsObjectNum(n) end
	end
end

local function propelBoneTowards(physobj, dir, speed, violence, mode)
	if not IsValid( physobj ) then return end
	if mode then 
		dir = (dir - physobj:GetPos()):GetNormalized()
	end
	physobj:ApplyForceCenter( (dir * speed - physobj:GetVelocity() * violence) * physobj:GetMass() )
end

local RAGMAUL_CONSTS = {
	SPEED = 1500,
	HULLMAX = Vector(8,8,8),
	HULLMIN = Vector(-8,-8,-8),
	WALLAVOID = 32
}

function ragmaulThink(target, attacker, bones, rag)

	local SPEED = RAGMAUL_CONSTS.SPEED
	local HULLMAX = RAGMAUL_CONSTS.HULLMAX
	local HULLMIN = RAGMAUL_CONSTS.HULLMIN
	local WALLAVOID = RAGMAUL_CONSTS.WALLAVOID

	local pelvispos = bones.pelvis:GetPos()
	local targetpos = (target:GetShootPos())
	local forward = targetpos - pelvispos
	forward:Normalize()

	local tr = util.TraceHull({
		maxs = HULLMAX,
		mins = HULLMIN,
		start = pelvispos,
		endpos = targetpos,
		filter = {target, rag}
	})

	if tr.StartSolid then -- oh god we're inside the world
		bones.pelvis:SetPos( pelvispos * (1-tr.FractionLeftSolid) + targetpos * (tr.FractionLeftSolid) )
	end

	if tr.HitPos:DistToSqr(pelvispos) < WALLAVOID*WALLAVOID then 
		local slideDir = ( tr.HitNormal:Cross( forward ):GetNormalized() )
		slideDir[3] = math.sin(CurTime() * 2)
		slideDir:Normalize()
		forward = (tr.HitPos - slideDir * WALLAVOID) - pelvispos
	end

	forward:Normalize()
	local right = forward:Cross(Vector(0,0,1))
	right:Normalize()
	local up = right:Cross(forward)

	local sinvec = up * math.sin(CurTime()*20) * 50

	propelBoneTowards(bones.pelvis , forward, SPEED, 0.2)
	propelBoneTowards(bones.rhand  , pelvispos + forward * 150 + right * 20 + sinvec, SPEED, 0.5, true )
	propelBoneTowards(bones.lhand  , pelvispos + forward * 150 - right * 20 - sinvec, SPEED, 0.5, true )
	propelBoneTowards(bones.rfoot  , pelvispos - forward * 150 + right * 20 - sinvec * 0.25, SPEED, 0.5, true )
	propelBoneTowards(bones.lfoot  , pelvispos - forward * 150 - right * 20 + sinvec * 0.25, SPEED, 0.5, true )
	propelBoneTowards(bones.head   , pelvispos + forward * 150 + VectorRand()*40, SPEED, 0.5, true )	

end

function ulx.ragmaul(calling_ply, target, attacker)

	if attacker == target then
		ULib.tsayError( calling_ply, "Attacker and target cannot be the same player!", true ) return
	end

	if not target:Alive() then
		ULib.tsayError( calling_ply, target:Nick() .. " is dead!", true ) return
	end

	if target.ULXExclusive and target.ULXExclusive ~= "ragdolled" then
		ULib.tsayError( calling_ply, target:Nick() .. " is " .. target.ULXExclusive .. "!", true ) return
	end

	if attacker.ULXExclusive and attacker.ULXExclusive ~= "ragdolled" then
		ULib.tsayError( calling_ply, ulx.getExclusive(attacker, calling_ply), true ) return
	end

	local appliedRagdoll = false
	if not IsValid(attacker.ragdoll) then -- make sure they're ragdolled
		appliedRagdoll = true
		attacker.ulx_prevpos = attacker:GetPos() -- make sure this works with return since they'll move
		attacker.ulx_prevang = attacker:EyeAngles()
		setCanLog(false)
			pcall( ulx.ragdoll, attacker, {attacker}, false ) -- do it silently though
		setCanLog(true)
	end

	local rag = attacker.ragdoll
	if not IsValid(rag) then return end
	
	rag.bones = {
		head   = lookupPhysobj(rag,"head")   or lookupPhysobj(rag,"spine2"),
		rhand  = lookupPhysobj(rag,"r_hand") or lookupPhysobj(rag,"r_forearm"),
		lhand  = lookupPhysobj(rag,"l_hand") or lookupPhysobj(rag,"l_forearm"),
		rfoot  = lookupPhysobj(rag,"r_foot") or lookupPhysobj(rag,"r_calf"),
		lfoot  = lookupPhysobj(rag,"l_foot") or lookupPhysobj(rag,"l_calf"),
		pelvis = rag:GetPhysicsObjectNum(0)
	}
	local bones = rag.bones

	local function resetAttacker()
		if( appliedRagdoll ) then
			ulx.ragdoll(attacker, {attacker}, true)
			attacker:SetVelocity( attacker:GetVelocity() * -0.9 ) -- prevent them from flying off somewhere
		else
			ulx.fancyLogAdmin( attacker, "#A finished attacking #T", target )
		end
	end

	if not IsValid(bones.pelvis) then
		if( appliedRagdoll ) then -- undo it
			setCanLog(false)
				pcall( ulx.ragdoll, attacker, {attacker}, true )
			setCanLog(true)			
		end
		ULib.tsayError( calling_ply, "Something went horribly wrong with the attacker's ragdoll!", true ) return
	end

	hook.Add("Think", rag, function()

		if not IsValid(rag) then hook.Remove("Think", rag) end
		if not target:Alive() then hook.Remove("Think", rag) resetAttacker() end

		ragmaulThink(target, attacker, bones, rag)

	end)

	ulx.fancyLogAdmin( calling_ply, "#A ragmaulled #T with #T", target, attacker )

end

local ragmaul = ulx.command( CATEGORY_NAME, "ulx ragmaul", ulx.ragmaul, "!ragmaul")
ragmaul:addParam{ type=ULib.cmds.PlayerArg, hint="target" }
ragmaul:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional, hint="attacker" }
ragmaul:defaultAccess( ULib.ACCESS_ADMIN )
ragmaul:help( "Mauls the target with the attacker's ragdoll." )


------------------------------ Swepify ------------------------------

local sayCmdCheck
local lookupULXCommand = FasteroidSharedULX.lookupULXCommand
local escape           = FasteroidSharedULX.ulxSayEscape

hook.Add("Think","ULX_Fasteroid_SetupSwepify", function()
	local temp = hook.GetTable()["PlayerSay"]
	if (temp["ULib_saycmd"]) then
		hook.Remove("Think", "ULX_Fasteroid_SetupSwepify")
		sayCmdCheck = temp["ULib_saycmd"]
	end
end)

local swepify_dormant = util.Stack()
local swepify_total   = 0

local function swepifyAlloc()
	if #swepify_dormant > 0 then 
		return swepify_dormant:Pop() 
	else
		swepify_total = swepify_total + 1
		return swepify_total
	end
end

local function new_SwepifyClass(id)

	local SWEP = {}
	SWEP.Base = "swepify_gun"
	SWEP.SwepifyID = id
	SWEP.ClassName = "swepify_gun_" .. id

	function SWEP:OnRemove()
		swepify_dormant:Push(self.SwepifyID)
		weapons.Register({Base = "swepify_gun"}, self.ClassName)
	end

	return SWEP

end

-- we need to detour several functions at the moment of execution to modify ulx's usual behavior.
-- this is the part that does the privilege escalation, delete this if you don't want that.
local function setSwepifyDetours(calling_ply, command)
	ulx.oldFancyLogAdmin       = ulx.oldFancyLogAdmin or ulx.fancyLogAdmin
	ULib.oldUclQuery           = ULib.oldUclQuery or ULib.ucl.query
	ulx.fancyLogAdmin = function(...)
		local args = {...}
		args[#args+1] = calling_ply
		args[#args+1] = command
		args[2] = args[2] .. " using a gun spawned by #T that executes #s"
		ulx.oldFancyLogAdmin(unpack(args))
	end
	ULib.ucl.query = function(...)
		local args = {...}
		args[1] = calling_ply
		return ULib.oldUclQuery(unpack(args))
	end
end
local function clearSwepifyDetours()
	ulx.fancyLogAdmin = ulx.oldFancyLogAdmin 
	ULib.ucl.query    = ULib.oldUclQuery 
end

function ulx.swepify( calling_ply, command )

	if not IsValid( calling_ply ) then ULib.tsayError( calling_ply, "This can't be used from console, sorry...", true ) return end

	local base_command, match, cmd = lookupULXCommand(command)
	if not base_command then return end

	local SWEP = new_SwepifyClass( swepifyAlloc() )

		function SWEP:SetupDataTables()
			self.Weapon:GetTable().BaseClass.SetupDataTables(self)
			timer.Simple(0.1,function()
				self:SetSwepAuthor(calling_ply:Nick())
				self:SetSwepName(command)
			end)
		end

		function SWEP:PrimaryAttack()
			self.Weapon:GetTable().BaseClass.PrimaryAttack(self)

			local arg_index = 1 -- since some args are invisible, we can't just use the index ipairs gives us below
			local command_copy = table.Copy(base_command)

			for _, argInfo in ipairs( cmd.args ) do -- check each arg to see if it needs to be serialized
				if( argInfo.type.invisible ) then
					continue
				end
				if( command_copy[arg_index] == "@" ) then -- time to replace
					local tr = util.TraceHull({
						start = self.Owner:GetShootPos(),
						endpos = self.Owner:GetShootPos() + ( self.Owner:GetAimVector() * 8192 ),
						filter = self.Owner,
						mins = Vector( -8, -8, -8 ),
						maxs = Vector( 8, 8, 8 ),
						mask = MASK_SHOT_HULL
					})
					local victim = tr.Entity
					if( victim:IsPlayer() ) then
						command_copy[arg_index] = escape(victim:Nick())
					else
						command_copy[arg_index] = string.char(34,1,34)
					end
				end
				arg_index = arg_index + 1
			end
			setSwepifyDetours(calling_ply, command)
				pcall( sayCmdCheck, self.Owner, match .. table.concat(command_copy," ") )
			clearSwepifyDetours()
		end

    weapons.Register(SWEP, SWEP.ClassName)
	
	local gun = ents.Create(SWEP.ClassName)
	local eyetrace = calling_ply:GetEyeTrace()
	gun:SetPos( eyetrace.HitPos + eyetrace.HitNormal * 15 )
	gun:Spawn()

	net.Start("FasteroidCSULX")
		net.WriteString("registerSwepify")
		net.WriteUInt(SWEP.SwepifyID,16)
	net.Broadcast()

	ulx.fancyLogAdmin( calling_ply, "#A summoned a gun that executes #s", command )

end

local swepify = ulx.command( CATEGORY_NAME, "ulx swepify", ulx.swepify, "!swepify" )
swepify:addParam{ type=ULib.cmds.StringArg, ULib.cmds.takeRestOfLine, hint="any ulx command" }
swepify:defaultAccess( ULib.ACCESS_SUPERADMIN )
swepify:help( "Package a command into a SWEP.  Best used with the @ selector!" )

if CLIENT then
	FasteroidCSULX.registerSwepify = function()
		local id = net.ReadUInt(16)
		local SWEP = new_SwepifyClass(id)
		weapons.Register(SWEP, SWEP.ClassName)
	end
end


------------------------------ StyledStrike: Block Tools ------------------------------
local BTools = {
	blocked = {},
	all_tools = {}
}

if SERVER then
	-- load the blacklist stored on disk
	local raw_data = file.Read( "ulx/blocked_tools.txt", "DATA" )
	if raw_data then
		BTools.blocked = util.JSONToTable( raw_data ) or {}
	end

	function BTools:Save()
		file.Write( "ulx/blocked_tools.txt", util.TableToJSON( self.blocked, true ) )
	end

	function BTools:Block( steam_id, tool_class )
		self.blocked[steam_id] = self.blocked[steam_id] or {}
		self.blocked[steam_id][tool_class] = true

		self:Save()
	end

	function BTools:Unblock( steam_id, tool_class )
		local ply_blocked = self.blocked[steam_id]
		if not ply_blocked then return end

		ply_blocked[tool_class] = nil

		if table.Count( ply_blocked ) == 0 then
			self.blocked[steam_id] = nil
		end

		self:Save()
	end

	function BTools:IsBlocked( ply, tool_class )
		local ply_blocked = self.blocked[ply:SteamID()]

		if ply_blocked and ply_blocked[tool_class] then
			ply:ChatPrint( "This tool is blocked." )
			ulx.logSpawn( string.format( "%s <%s> tried to use the tool %s -=BLOCKED", ply:Nick(), ply:SteamID(), tool_class ) )

			return true
		end
	end

	hook.Add("CanTool", "ulxcustom_check_tool_block", function( ply, _, tool )
		if BTools:IsBlocked( ply, tool ) then return false end
	end, HOOK_HIGH)
end

function ulx.blocktool( calling_ply, target_plys, tool_class, b_unblock )
	for _, ply in ipairs( target_plys ) do
		if b_unblock then
			BTools:Unblock( ply:SteamID(), tool_class )
		else
			BTools:Block( ply:SteamID(), tool_class )
		end
	end

	if b_unblock then
		ulx.fancyLogAdmin( calling_ply, true, "#A unblocked the tool #s for #T", tool_class, target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, true, "#A blocked the tool #s for #T", tool_class, target_plys )
	end
end

local blocktool = ulx.command( CATEGORY_NAME, "ulx blocktool", ulx.blocktool, "!blocktool" )
blocktool:addParam{ type = ULib.cmds.PlayersArg }
blocktool:addParam{ type = ULib.cmds.StringArg, completes = BTools.all_tools, hint = "tool class" }
blocktool:addParam{ type = ULib.cmds.BoolArg, invisible = true }
blocktool:defaultAccess( ULib.ACCESS_ADMIN )
blocktool:help( "Blocks a tool for the target(s)" )
blocktool:setOpposite( "ulx unblocktool", {_, _, _, true}, "!unblocktool" )

hook.Add("InitPostEntity", "blocktool_populate_autocomplete", function()
	-- populate the tools list (for autocomplete)

	for k, _ in pairs( weapons.GetStored( "gmod_tool" ).Tool ) do
		BTools.all_tools[#BTools.all_tools + 1] = k
	end

	table.sort(BTools.all_tools)
end)


------------------------------ Improvements: Return ------------------------------
-- make ulx return work when you die
hook.Add("DoPlayerDeath", "ulx_return_death", function(ply)
	ply.ulx_prevpos = ply:GetPos()
	ply.ulx_prevang = ply:EyeAngles()
end )


------------------------------ Improvements: Ragdoll ------------------------------
-- apply player colors

local newRagdoll = function(calling_ply, target_plys, should_unragdoll) 
	OldUlxRagdoll(calling_ply, target_plys, should_unragdoll) -- call original
	local affected_plys = {}

	for _, ply in pairs(target_plys) do
		if IsValid(ply.ragdoll) then
			ply:SetNW2Entity( "ulxragdoll", ply.ragdoll )
			table.insert(affected_plys, ply)
		end
	end

	if #affected_plys < 1 then return end -- nothing to do

	net.Start("FasteroidCSULX")
		net.WriteString("requestRagdoll")
		net.WriteUInt(#affected_plys,8)
		for _, ply in ipairs(affected_plys) do
			net.WriteEntity(ply)
		end
	net.Broadcast()

end


hook.Add("Think","ULX_Fasteroid_WaitForULXRagdoll", function()
	for _, cmd in ipairs(ulx.cmdsByCategory["Fun"]) do 
		if cmd.cmd ~= "ulx ragdoll" then continue end

		OldUlxRagdoll = OldUlxRagdoll or ulx.ragdoll

		cmd.fn = newRagdoll
		ulx.ragdoll = newRagdoll

		hook.Remove("Think","ULX_Fasteroid_WaitForULXRagdoll")
		return
	end
end)


if CLIENT then
	FasteroidCSULX.requestRagdoll = function()
		local amt = net.ReadUInt(8)
		for i=1, amt do
			local ent = net.ReadEntity()
			-- stupid client is slow and we need to wait for it to learn about the ragdoll ent
			local hookname = "ulxRagdollColor" .. ent:Nick()
			hook.Add("Tick", hookname, function()
				local rag = ent:GetNW2Entity("ulxragdoll")
				if rag then
					rag.GetPlayerColor = function() return ent:GetPlayerColor() end
					hook.Remove("Tick",hookname)
				end
			end)
		end
	end
end