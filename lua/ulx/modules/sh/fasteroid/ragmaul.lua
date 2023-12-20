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

local ragmaul = ulx.command( FasteroidSharedULX.category, "ulx ragmaul", ulx.ragmaul, "!ragmaul")
ragmaul:addParam{ type=ULib.cmds.PlayerArg, hint="target" }
ragmaul:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional, hint="attacker" }
ragmaul:defaultAccess( ULib.ACCESS_ADMIN )
ragmaul:help( "Mauls the target with the attacker's ragdoll." )