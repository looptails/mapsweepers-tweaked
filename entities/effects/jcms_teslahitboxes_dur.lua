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

--[[
	The teslahitboxes effect, but applied constantly. 

	Allows consistent tesla effects to be set up without as much net strain.
--]]

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	local ent = data:GetEntity() 
	self.ent = ent

	if not IsValid(self.ent) then return end 

	local applyEffect = self
	if ent.jcms_eff_teslahitboxes then --Update existing if applied to an ent that already has one.
		applyEffect = ent.jcms_eff_teslahitboxes
	else
		ent.jcms_eff_teslahitboxes = self
	end

	local dur = data:GetScale()-- scale used for duration
	
	if dur == 0 then 
		applyEffect.infinite = true
		applyEffect.endTime = 0
	else --Negative numbers for instant destroy
		applyEffect.endTime = CurTime() + dur
		applyEffect.infinite = false
	end

	local interval = data:GetMagnitude() --Magnitude for interval.
	interval = interval / 512 -- We want better accuracy rather than better range (this maxes it out at 2s.)
	
	applyEffect.interval = interval
	
	self:SetPos(self.ent:WorldSpaceCenter())
	self:SetParent(self.ent)
end

function EFFECT:Think()
	local ed = EffectData()
	ed:SetEntity(self.ent)
	ed:SetMagnitude(4)
	ed:SetScale(1)
	util.Effect("TeslaHitBoxes", ed)

	self:SetNextClientThink(CurTime() + (self.interval or 0))
	return IsValid(self.ent) and (self.infinite or (self.endTime or 0) > CurTime()) and (self.ent.Health and self.ent:Health() >= 0) --We'll always play our tesla effect at least once.
end

function EFFECT:Render()

end
