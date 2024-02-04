------------------------------ Prop (based on !ragdoll) ------------------------------

local function unpropPlayer( ply, death )

    ply:DisallowSpawning( false )
    ply:SetParent()
	ply:UnSpectate() -- Need this for DarkRP for some reason, works fine without it in sbox

	local prop = ply.ulx_prop
	ply.ulx_prop = nil -- Gotta do this before spawn or our hook catches it
	ulx.clearExclusive( ply )

    if not death then
        ULib.spawn( ply, true )
    end

	if IsValid(prop) then
        prop:RemoveCallOnRemove("ULX.Fasteroid.PlayerProp")
        prop:DisallowDeleting( false )
		prop:Remove()
        ply:SetPos( prop:GetPos() )
        ply:SetVelocity( prop:GetVelocity() )
        ply:SetAngles( Angle( 0, prop:GetAngles().y, 0 ))
    end

end

local function propPlayer( ply, model )
	local prop = ents.Create( "prop_physics" )
    prop.ragdolledPly = ply
	local velocity = ply:GetVelocity()

	prop:SetPos( ply:WorldSpaceCenter() )
	prop:SetAngles( ply:GetAngles() )
	prop:SetModel( model )
	prop:Spawn()
	prop:Activate()

    local phys = prop:GetPhysicsObject()
    if not phys:IsValid() then
        prop:Remove()
        return false
    end

    phys:SetVelocity(velocity)

	if ply:InVehicle() then
		ply:ExitVehicle()
	end

	ULib.getSpawnInfo( ply ) -- Collect information so we can respawn them in the same state.

	ply:SetParent( prop ) -- So their player ent will match up (position-wise) with where their ragdoll is.

	ply:Spectate( OBS_MODE_CHASE ) -- make it super disorienting (lol)
	ply:SpectateEntity( prop )
	ply:StripWeapons() -- Otherwise they can still use the weapons.
	ply:DisallowSpawning( true )

	ply.ulx_prop = prop
	ulx.setExclusive( ply, "a prop" )

    prop:CallOnRemove("ULX.Fasteroid.PlayerProp", function()
        unpropPlayer(ply, true)
    end)

    return true
end

function ulx.prop( calling_ply, target_plys, model, opposite )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]
		if not opposite then
			if ulx.getExclusive( v, calling_ply ) then
				ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
			elseif not v:Alive() then
				ULib.tsayError( calling_ply, v:Nick() .. " is dead!", true )
			else
				local success = propPlayer( v, model )
                if not success then
                    ULib.tsayError( calling_ply, model .. " didn't have valid physics; aborting.", true )
                    return
                end
				table.insert( affected_plys, v )
			end
		elseif v.ulx_prop then
			unpropPlayer( v )
			table.insert( affected_plys, v )
		end
	end

	if not opposite then
		ulx.fancyLogAdmin( calling_ply, "#A turned #T into a #s", affected_plys, model )
	else
		ulx.fancyLogAdmin( calling_ply, "#A turned #T back into a player", affected_plys )
	end
end

local prop = ulx.command( FasteroidSharedULX.category, "ulx prop", ulx.prop, "!prop" )
prop:addParam{ type=ULib.cmds.PlayersArg }
prop:addParam{ type=ULib.cmds.StringArg }
prop:addParam{ type=ULib.cmds.BoolArg, invisible=true }
prop:defaultAccess( ULib.ACCESS_ADMIN )
prop:help( "Turns target(s) into inanimate objects" )
prop:setOpposite( "ulx unprop", {_, _, "", true}, "!unprop" )

local function propDisconnectedCheck( ply )
	if ply.ulx_prop then
		ply.ulx_prop:DisallowDeleting( false )
		ply.ulx_prop:Remove()
	end
end
hook.Add( "PlayerDisconnected", "ULX.Fasteroid.PropPlayerDisconnect", propDisconnectedCheck, HOOK_MONITOR_HIGH )

local function killPropOnCleanup()
	local players = player.GetAll()
	for i=1, #players do
		local ply = players[i]
		if ply.ulx_prop then
			unpropPlayer( ply )
            ply:Kill()
		end
	end
end
hook.Add("PreCleanupMap","ULX.Fasteroid.PropPlayerCleanup", killPropOnCleanup )



-- note: this will also override death messages for ragdolled players!
local function overrideDeathByPlayerProp(victim, dmg)

    -- overrides death message when someone is killed by a player prop_physics
    local attacker  = dmg:GetAttacker()
    local inflictor = dmg:GetInflictor()
    if attacker and attacker.ragdolledPly then
        dmg:SetAttacker(attacker.ragdolledPly)
    end
    if inflictor and inflictor.ragdolledPly then
        dmg:SetInflictor(inflictor.ragdolledPly)
    end

    -- do damage to the prop_physics's soul if they get attacked
    local soul = victim.ragdolledPly
    if soul then
        timer.Simple(0, function()
            if not victim:IsValid() then
                if not IsValid(attacker) then attacker = soul end
                if not IsValid(inflictor) then inflictor = soul end
                hook.Run("PlayerDeath", soul, inflictor, attacker) -- show killfeed
                soul:KillSilent()
            end
        end)    
    end

end
hook.Add("EntityTakeDamage","ULX.Fasteroid.PropPlayerKill",overrideDeathByPlayerProp)

local function overrideDeathByPlayerProp(ply, _)
    if ply.ulx_prop then return false end
end
hook.Add("AllowPlayerPickup","ULX.Fasteroid.PreventPlayerPropPickup",overrideDeathByPlayerProp)
