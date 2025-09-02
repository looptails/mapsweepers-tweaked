--[[
	Map Sweepers - Co-op NPC Shooter Gamemode for Garry's Mod by "Octantis Addons" (consisting of MerekiDor & JonahSoldier)
    Copyright (C) 2025  MerekiDor

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

	See the full GNU GPL v3 in the LICENSE file.
	Contact E-Mail: merekidorian@gmail.com
--]]
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "J Corp Jump Pad"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/jcms/jcorp_jumppad.mdl")
		self:PhysicsInitStatic(SOLID_VPHYSICS)
	end
end

function ENT:JumpEffect()
    if SERVER then
        self:EmitSound("weapons/physcannon/superphys_launch"..math.random(1,4)..".wav")
    end

    local ed = EffectData()
    ed:SetOrigin(self:GetPos() + Vector(0, 0, 12))
    ed:SetNormal(Vector(0,0,1))
    ed:SetRadius(42)
    util.Effect("AR2Explosion", ed)
end

function ENT:LaunchPlayer(ply)
    if SERVER then
        ply.noFallDamage = true
    end

    self:JumpEffect()

    local vector = Vector(0, 0, ply:Crouching() and 260 or 580)

    local ev = ply:EyeAngles():Forward()
    ev:Mul(128)
    ev:Add(vector)

    ply:SetVelocity(ev)
end

hook.Add("OnPlayerJump", "jcms_BoostJump", function(ply)
    if SERVER or IsFirstTimePredicted() then
        local radius = 72
        local radius2 = radius*radius

        for i, pad in ipairs(ents.FindByClass "jcms_jumppad") do
            local dif = ply:GetPos()-pad:GetPos()
            if (dif.z > 0 and dif.z < 32) and (dif.x*dif.x + dif.y*dif.y) < radius2 then
                pad:LaunchPlayer(ply)
                break
            end
        end
    end
end)
