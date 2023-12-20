------------------------------ Improvements ------------------------------

-- make ulx return work when you die
do
    hook.Add("DoPlayerDeath", "ulx_return_death", function(ply)
        ply.ulx_prevpos = ply:GetPos()
        ply.ulx_prevang = ply:EyeAngles()
    end )
end

-- apply player colors to ulx ragdoll
do
    local newRagdoll = function(calling_ply, target_plys, should_unragdoll) 
        FasteroidSharedULX.OldRagdoll(calling_ply, target_plys, should_unragdoll) -- call original
        local affected_plys = {}

        for _, ply in pairs(target_plys) do
            if IsValid(ply.ragdoll) then
                ply:SetNW2Entity( "ulxragdoll", ply.ragdoll )
                table.insert(affected_plys, ply)
            end
        end

        if #affected_plys < 1 then return end -- nothing to do

        net.Start("FasteroidClientULX")
            net.WriteString("requestRagdoll")
            net.WriteUInt(#affected_plys,8)
            for _, ply in ipairs(affected_plys) do
                net.WriteEntity(ply)
            end
        net.Broadcast()

    end

    if SERVER then
        hook.Add("Think","ULX.Fasteroid.WaitForULXRagdoll", function()
            for _, cmd in ipairs(ulx.cmdsByCategory["Fun"]) do 
                if cmd.cmd ~= "ulx ragdoll" then continue end

                FasteroidSharedULX.OldRagdoll = FasteroidSharedULX.OldRagdoll or ulx.ragdoll

                cmd.fn      = newRagdoll
                ulx.ragdoll = newRagdoll

                hook.Remove("Think","ULX.Fasteroid.WaitForULXRagdoll")
                return
            end
        end)
    end

    if CLIENT then
        FasteroidClientULX.requestRagdoll = function()
            local amt = net.ReadUInt(8)
            for i=1, amt do
                local ent = net.ReadEntity()
                -- stupid client is slow and we need to wait for it to learn about the ragdoll ent
                local hookname = "ulxRagdollColor" .. ent:Nick()
                hook.Add("Tick", hookname, function()
                    local rag = ent:GetNW2Entity("ulxragdoll")
                    if rag then
                        rag.GetPlayerColor = function() return ent:GetPlayerColor() end
                        hook.Remove("Tick",hookname)
                    end
                end)
            end
        end
    end
end