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
				net.Start("FasteroidClientULX")
					net.WriteString("lagdeath")
					net.WriteVector( v:GetPos() )
				net.Broadcast()
			end)

		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A did something to #T...", affected_plys )
	timer.Simple(3, function() ulx.fancyLogAdmin( nil, "#T lagged to death", affected_plys) end)

end
local laggyslay = ulx.command( FasteroidSharedULX.category, "ulx lag", ulx.laggyslay, "!lag" )
laggyslay:addParam{ type=ULib.cmds.PlayersArg }
laggyslay:defaultAccess( ULib.ACCESS_ADMIN )
laggyslay:help( "Causes target(s) to rubberband before dying spectacularly." )

if CLIENT then
	FasteroidClientULX.lagdeath = function()
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
			hook.Remove("Think","ULX.Fasteroid.LagDeathCorpse")
		end)
		hook.Add("Think","ULX.Fasteroid.LagDeathCorpse",function()
			if lagDeathCorpse and IsValid(lagDeathCorpse) then
			lagDeathCorpse:GetPhysicsObjectNum( math.random(1,lagDeathCorpse:GetPhysicsObjectCount())-1 ):ApplyForceCenter(Vector(0,0,-4096))
			lagDeathCorpse:GetPhysicsObject():ApplyForceCenter(Vector(0,0,-16384))
			end
		end)
	end
end
