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

local botbomb = ulx.command( FasteroidSharedULX.category, "ulx botbomb", ulx.botbomb, "!botbomb" )
botbomb:addParam{ type=ULib.cmds.PlayerArg }
botbomb:defaultAccess( ULib.ACCESS_SUPERADMIN )
botbomb:help( "Airstrikes the target with a bot." )