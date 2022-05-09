
local CATEGORY_NAME = "Fast's Corner"

if SERVER then
	util.AddNetworkString( "FasteroidCSULX" )
end

local FasteroidCSULX
if CLIENT then
	WEBSOUNDS = { }
	FasteroidCSULX = { }
	net.Receive("FasteroidCSULX", function()
		FasteroidCSULX[ net.ReadString() ]()
	end)
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

------------------------------ Max Physics Speed ------------------------------
local maxspeed
function ulx.maxspeed( calling_ply, speed )
	local haha = physenv.GetPerformanceSettings()
	if( not maxspeed.args[2].default ) then // update default first time we run this
		maxspeed.args[2].default = haha.MaxVelocity
	end
	haha.MaxVelocity = speed
	physenv.SetPerformanceSettings(haha)
	ulx.fancyLogAdmin( calling_ply, "#A redefined lightspeed as #i source units per second", speed )
end

maxspeed = ulx.command( CATEGORY_NAME, "ulx maxphyspeed", ulx.maxspeed, "!maxphyspeed" )
maxspeed:addParam{ type=ULib.cmds.NumArg, min = 0, max = 2147483647, hint="speed" }
maxspeed:defaultAccess( ULib.ACCESS_SUPERADMIN )
maxspeed:help( "Sets the engine's max speed for physics objects." )

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

local function infloop(ent, bullet)
	if( IsValid(ent) and ent:IsPlayer() and ent:getShitAim() ) then

		local theta = CurTime() * 4200
		local spread = bullet.Dir:Angle() + Angle(15,0,0)
		spread:RotateAroundAxis( bullet.Dir, util.SharedRandom( "shitaim", 0, 360 ) )
		bullet.Dir = spread:Forward()
		bullet.Spread = Vector(1,1,0)*0.1
		return true 

	end
end

hook.Add( "EntityFireBullets", "ulx_shitaim", infloop )

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

------------------------------ Return ------------------------------
-- make ulx return work when you die
hook.Add("DoPlayerDeath", "ulx_return_death", function(ply) 
	ply.ulx_prevpos = ply:GetPos()
	ply.ulx_prevang = ply:EyeAngles()
end )

------------------------------ Bot Bomb ------------------------------
local botNames = {
	"death",
	"bomb",
	"slave"
}
local botFailMessages = {
	"FUCK",
	"aGH",
	"NO",
	"rip",
}
local botSuccessMessages = {
	"HA",
	"GOTCHA",
	"YEET",
	"FUCKED",
	"GONE"
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
	bot:Say(botFailMessages[math.random(#botFailMessages)])
	botbombExplode(bot,bot)
	bot:Kick()
	hook.Remove("Think",hookName)
end

function ulx.botbomb( calling_ply, target_ply, dmg )
	
	if( player.GetCount() == game.MaxPlayers() ) then 
		ULib.tsayError( calling_ply, "Can't spawn a bot, the server is full!", true )
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
		ULib.tsayError( calling_ply, "Ceiling is too low, can't airstrike the target!", true )		
		return
	end

	local bot = player.CreateNextBot( botNames[math.random(#botNames)] )
	bot:GodEnable()
	bot:SetPos(trace.HitPos)

	local hookName = "botbomb_"..target_ply:Nick()

	timer.Create(hookName,10,1,function() -- remove after 10 seconds if it doesn't find them
		if( bot == NULL ) then return end
		failBotbomb(bot,hookName)
	end)

	hook.Add("Think",hookName,function()
		
		if( target_ply == NULL ) then
			if bot ~= NULL then
				failBotbomb(bot,hookName)
			end
		elseif( bot == NULL ) then
			hook.Remove("Think",hookName)
		end

		local aimVec = (target_ply:GetShootPos() - bot:GetShootPos())
		bot:SetEyeAngles( aimVec:Angle() )
		aimVec[3] = 0
		local damping = bot:GetVelocity()
		damping[3] = 0
		bot:SetVelocity( aimVec:GetNormalized()*20 - damping * 0.1  )

		local collisionCheck = util.TraceHull( {
			start = bot:GetPos(),
			endpos = bot:GetPos(),
			filter = function(e) if e == target_ply or e == target_ply:GetVehicle() then return true else return false end end,
			mins = Vector(-17,-17,-1),
			maxs = Vector(17,17,73),
			ignoreworld = true,
		} )

		if( collisionCheck.Hit ) then
			bot:SetPos(target_ply:GetPos() + Vector(0,0,100))
			bot:Say(botSuccessMessages[math.random(#botSuccessMessages)])
			botbombExplode(target_ply,bot)
			bot:Kill()
			timer.Simple(0.5, function() if bot~=NULL then bot:Kick() end end)
			hook.Remove("Think",hookName)
		elseif bot:OnGround() then
			failBotbomb(bot,hookName)
		end
		
	end)

end

local botbomb = ulx.command( CATEGORY_NAME, "ulx botbomb", ulx.botbomb, "!botbomb" )
botbomb:addParam{ type=ULib.cmds.PlayerArg }
botbomb:defaultAccess( ULib.ACCESS_SUPERADMIN )
botbomb:help( "Airstrikes the target with a bot." )