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
	Consistent purple electricity effects on the target.
	Same draw func as used for hacked buildings.

	Can be applied indefinitely or for a duration to reduce networking.
--]]

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init( data )
	self.ent = data:GetEntity()
	local dur = data:GetScale()-- scale used for duration
	if not IsValid(self.ent) then return end 

	if dur == 0 then 
		self.infinite = true
		self.endTime = 0
	else
		self.endTime = CurTime() + dur
		self.infinite = false
	end

	self:SetPos(self.ent:WorldSpaceCenter())
	self:SetParent(self.ent)
end

function EFFECT:Think()
	return IsValid(self.ent) and (self.infinite or self.endTime > CurTime())
end

function EFFECT:Render()
	if not IsValid(self.ent) then return end 

	jcms.render_HackedByRebels(self.ent)
end