------------------------------ Serialize (PROBABLY DANGEROUS) ------------------------------
local playerParseAndValidate
local playersParseAndValidate
local sayCmdCheck
local lookupULXCommand = FasteroidSharedULX.lookupULXCommand
local escape           = FasteroidSharedULX.ulxSayEscape

hook.Add("Think","ULX.Fasteroid.SetupSerialize", function()
    
	sayCmdCheck = hook.GetTable()["PlayerSay"]["ULib_saycmd"]

    if not sayCmdCheck or not ULib then return end

    playerParseAndValidate  = ULib.cmds.PlayerArg.parseAndValidate
    playersParseAndValidate = ULib.cmds.PlayersArg.parseAndValidate

    hook.Remove("Think", "ULX.Fasteroid.SetupSerialize")

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
					new_command[arg_index] = escape( v:Nick() )
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

local serialize = ulx.command( FasteroidSharedULX.category, "ulx serialize", ulx.serialize, "!serialize" )
serialize:addParam{ type=ULib.cmds.StringArg, ULib.cmds.takeRestOfLine, hint="any ulx command" }
serialize:defaultAccess( ULib.ACCESS_SUPERADMIN )
serialize:help( "Split one command into many.  Read command usage on Github for more." )