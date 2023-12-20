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
local badaim = ulx.command( FasteroidSharedULX.category, "ulx shitaim", ulx.badaim, "!shitaim" )
badaim:addParam{ type=ULib.cmds.PlayersArg }
badaim:addParam{ type=ULib.cmds.BoolArg, invisible=true }
badaim:defaultAccess( ULib.ACCESS_ADMIN )
badaim:help( "Causes all bullets fired by target(s) to stray about 15 degrees away from their crosshair in random directions." )
badaim:setOpposite("ulx unshitaim", {_, _, true}, "!unshitaim")