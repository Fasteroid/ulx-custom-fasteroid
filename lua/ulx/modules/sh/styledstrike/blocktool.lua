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

local blocktool = ulx.command( FasteroidSharedULX.category, "ulx blocktool", ulx.blocktool, "!blocktool" )
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
