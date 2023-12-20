------------------------------ Swepify ------------------------------

local sayCmdCheck
local playerParseAndValidate
local playersParseAndValidate
local lookupULXCommand = FasteroidSharedULX.lookupULXCommand
local escape           = FasteroidSharedULX.ulxSayEscape

hook.Add("Think","ULX.Fasteroid.SetupSwepify", function()
	sayCmdCheck = hook.GetTable()["PlayerSay"]["ULib_saycmd"]

    if not sayCmdCheck or not ULib then return end

    playerParseAndValidate = ULib.cmds.PlayerArg.parseAndValidate
    playersParseAndValidate = ULib.cmds.PlayersArg.parseAndValidate

    hook.Remove("Think", "ULX.Fasteroid.SetupSwepify")
end)

-- we need to detour several functions at the moment of execution to modify ulx's usual behavior.
-- this is the part that does the privilege escalation, delete this if you don't want that.
local function setSwepifyDetours(calling_ply, command, cmd, swep)

	ulx.oldFancyLogAdmin  = ulx.oldFancyLogAdmin or ulx.fancyLogAdmin
	ULib.oldUclQuery      = ULib.oldUclQuery or ULib.ucl.query
	ULib.oldGetUsers      = ULib.oldGetUsers or ULib.getUsers

    -- various monkey-patches for obscure bugs
	local playerParseAndValidate_detour = function(...)
		local args = {...}
		if not args[3] then args[3] = "^" end
		if args[3] == "!" then args[3] = "!^" end
		args[2] = calling_ply
		return playerParseAndValidate(unpack(args))
	end
	local playersParseAndValidate_detour = function(...)
		local args = {...}
		if not args[3] then args[3] = "^" end
		if args[3] == "!" then args[3] = "!^" end
		args[2] = calling_ply
		return playersParseAndValidate(unpack(args))
	end

	for _, arg in ipairs( cmd.args ) do 
		local argtype = arg.type
		if argtype.parseAndValidate == playerParseAndValidate then
			argtype.parseAndValidate = playerParseAndValidate_detour
			argtype.oldParse         = playerParseAndValidate
		end
		if argtype.parseAndValidate == playersParseAndValidate then
			argtype.parseAndValidate = playersParseAndValidate_detour
			argtype.oldParse         = playersParseAndValidate
		end
	end

	ulx.fancyLogAdmin = function(...) -- verbose logs are funny
		local args = {...}
		args[#args+1] = calling_ply
		args[#args+1] = command
		if type(args[2]) == "string" then
			args[2] = args[2] .. " using a gun spawned by #T that executes #s"
		end
		ulx.oldFancyLogAdmin(unpack(args))
	end
	ULib.ucl.query = function(...) -- this controls permissions
		local args = {...}
		args[1] = calling_ply
		return ULib.oldUclQuery(unpack(args))
	end
	ULib.getUsers = function(...) -- this controls behavior of selectors
		local args = {...}
		args[3] = swep.Owner
		return ULib.oldGetUsers(unpack(args))
	end

end

local function clearSwepifyDetours(cmd)
	ulx.fancyLogAdmin = ulx.oldFancyLogAdmin 
	ULib.ucl.query    = ULib.oldUclQuery 
	ULib.getUsers     = ULib.oldGetUsers 

	for _, arg in ipairs( cmd.args ) do 
		local argtype = arg.type
		if argtype.oldParse then argtype.parseAndValidate = argtype.oldParse end
	end
end

function ulx.swepify( calling_ply, command )

	if not IsValid( calling_ply ) then ULib.tsayError( calling_ply, "This can't be used from console, sorry...", true ) return end

	local base_command, match, cmd = lookupULXCommand(command)
	if not base_command then return end

	local SWEP = SWEPIFY.generate()

		function SWEP:PrimaryAttack()
			self.Weapon:GetTable().BaseClass.PrimaryAttack(self)

			local arg_index = 1 -- since some args are invisible, we can't just use the index ipairs gives us below
			local command_copy = table.Copy(base_command)
			local args_copy    = table.Copy(cmd.args)
			table.remove(args_copy,1) -- no caller

			for _, argInfo in ipairs(args_copy) do -- check each arg to see if it needs to be converted

				if argInfo.invisible then continue end

				if command_copy[arg_index] == "@" then -- time to replace
					self.Owner:LagCompensation(true)
					local tr = self.Owner:GetEyeTraceNoCursor()
					self.Owner:LagCompensation(false)

					local victim = tr.Entity

					if victim:IsVehicle() then victim = victim:GetDriver() end

					if IsValid(victim) and victim:IsPlayer() then
						command_copy[arg_index] = escape(victim:Nick())
					else
						command_copy[arg_index] = string.char(34,1,34)
					end
				end
				arg_index = arg_index + 1
			end

			setSwepifyDetours(calling_ply, command, cmd, self)
				pcall( sayCmdCheck, self.Owner, match .. table.concat(command_copy," ") )
			clearSwepifyDetours(cmd)

		end
	
	weapons.Register(SWEP, SWEP.ClassName)

	local gun = ents.Create(SWEP.ClassName)
	local eyetrace = calling_ply:GetEyeTrace()
	gun:SetPos( eyetrace.HitPos + eyetrace.HitNormal * 15 )
	gun:SetSwepID( SWEP.SwepID )
	gun:SetSwepAuthor( calling_ply:Nick() )
	gun:SetSwepName( command )
	gun:Spawn()

	weapons.Register({Base = "swepify_gun"}, SWEP.ClassName)

	ulx.fancyLogAdmin( calling_ply, "#A summoned a gun that executes #s", command )

end

local swepify = ulx.command( FasteroidSharedULX.category, "ulx swepify", ulx.swepify, "!swepify" )
swepify:addParam{ type=ULib.cmds.StringArg,  hint="any ulx command", ULib.cmds.takeRestOfLine }
swepify:defaultAccess( ULib.ACCESS_SUPERADMIN )
swepify:help( "Package a command into a SWEP.  Best used with the @ selector!" )
