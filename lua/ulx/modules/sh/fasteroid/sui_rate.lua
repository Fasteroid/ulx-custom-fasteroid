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

local rate = ulx.command( FasteroidSharedULX.category, "ulx rate", ulx.rate, "!rate" )
rate:addParam{ type=ULib.cmds.PlayerArg }
rate:addParam{ type=ULib.cmds.StringArg, hint="rating" }
rate:addParam{ type=ULib.cmds.NumArg, min = -9999, max = 9999, default = 1, hint="amount", ULib.cmds.optional }
rate:defaultAccess( ULib.ACCESS_ADMIN )
rate:help( "Modifies a player's SUI Scoreboard ratings.  Negative amounts take away ratings." )