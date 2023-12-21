do -- initialize common functions

    if SERVER then
        util.AddNetworkString( "FasteroidClientULX" )
    end

    if CLIENT then
        FasteroidClientULX = FasteroidClientULX or {}
        net.Receive("FasteroidClientULX", function()
            FasteroidClientULX[ net.ReadString() ]()
        end)
    end

    FasteroidSharedULX = FasteroidSharedULX or {}
    FasteroidSharedULX.lookupULXCommand = function (command, calling_ply) -- used in swepify and serialize
        local base_command = ULib.splitArgs( command ) -- get args first

        -- first arg is the command; extract it for use
        local match = base_command[1] .. " " -- sayCmd keys all end with a space
        table.remove(base_command, 1)        -- don't need this anymore

        local cmd
        do
            local sayCmd = ULib.sayCmds[match]
            if not sayCmd then -- gorp
                ULib.tsayError( calling_ply, "Try a 'say' command, like !slap *", true )
                return
            end
            cmd = ULib.cmds.translatedCmds[sayCmd.access]
        end

        return base_command, match, cmd
    end

    FasteroidSharedULX.ulxSayEscape = function(text)
        text = string.Replace(text,"\\","\\\\")
        text = string.Replace(text,'"','\\"')
        return '"' .. text .. '"'
    end

    FasteroidSharedULX.category = "Fast's Corner"

end

do -- initialize commands

    local authors  = {"fasteroid", "styledstrike"}
    for _, author in ipairs(authors) do
        local commands = file.Find( "ulx/modules/sh/"..author.."/*.lua", "LUA" )

        local function catch( err )
            print( "ERROR: ", err )
        end

        for _, file in ipairs( commands ) do
            FasteroidSharedULX.currentFile = file
            local printFile = file
            if #file > 14 then
                printFile = file:sub(1, 7) .. "...lua "
            end
            Msg( "//  SUBMODULE: " .. printFile .. string.rep( " ", 14 - file:len() ) .. "//\n" )
            xpcall( include, catch, author.."/" .. file )
            AddCSLuaFile( "ulx/modules/sh/"..author.."/" .. file )
        end

    end

    FasteroidSharedULX.currentFile = nil
    
end