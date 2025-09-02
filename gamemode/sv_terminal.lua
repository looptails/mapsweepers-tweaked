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

jcms.terminal_modeTypes = {
	pin = {
		command = function(ent, cmd, data, ply)
			if cmd == 0 then
				jcms.terminal_ToPurpose(ent)
				return true
			elseif cmd >= 1 and cmd <= 9 or cmd == 11 then
				if #data < 4 then
					local entering = cmd==11 and "0" or tostring(cmd)
					local newdata =  data .. entering
					return true, newdata
				end
			elseif cmd == 10 then
				if data == ent.jcms_pin then
					jcms.terminal_Unlock(ent, ply, false)
					return true, ""
				else
					jcms.terminal_Punish(ent, ply)
					ent:EmitSound("buttons/button8.wav", 75, 110, 1.0)
					return true, ""
				end
			elseif cmd == 12 then
				return true, ""
			end
		end
	},

	-- Normal terminals
	cash_cache = {
		command = function(ent, cmd, data, ply)
			if ent:GetNWBool("jcms_terminal_locked") then
				if cmd == 0 then
					jcms.terminal_ToUnlock(ent)
					return true
				end
			else
				local counts = { 10, 100, 1000, math.huge }
				local count = counts[ (cmd-1)%4 + 1 ]
				local depositing = cmd > 4

				if depositing then
					local plyCash = ply:GetNWInt("jcms_cash")
					count = math.min(count, plyCash)
					ply:SetNWInt("jcms_cash", plyCash - count)
					return count > 0, (tonumber(data) or 0) + count
				else
					local terminalCash = tonumber(data) or 0
					count = math.min(count, terminalCash)
					ply:SetNWInt("jcms_cash", ply:GetNWInt("jcms_cash") + count)
					ent:SetNWInt("cash", terminalCash - count)
					return count > 0, terminalCash - count
				end
			end
		end,
		
		generate = function(ent)
			local rn = ent:EntIndex()%6
			return (4+rn) * 500
		end
	},

	gambling = {
		command = function(ent, cmd, data, ply)
			local cash = ply:GetNWInt("jcms_cash", 0)

			if cash > 0 then
				local won = math.random() < 0.5
				ply:SetNWInt("jcms_cash", won and cash*2 or 0)

				ent:EmitSound(won and "garrysmod/content_downloaded.wav" or "buttons/button8.wav")

				if cash >= 10000 and not won then
					timer.Simple(0.8, function()
						if IsValid(ent) then
							
							util.BlastDamage(ent, ent, ent:WorldSpaceCenter(), 200, cash / 1000)
							local ed = EffectData()
							ed:SetMagnitude(1)
							ed:SetOrigin(ent:WorldSpaceCenter())
							ed:SetRadius(450)
							ed:SetNormal(jcms.vectorUp)
							ed:SetFlags(1)
							util.Effect("Explosion", ed)

							ply:ViewPunch( AngleRand(-30, 30) )

						end
					end)
				end

				if cash >= 150 and not won then
					jcms.announcer_SpeakChance(0.6, jcms.ANNOUNCER_HA)
					jcms.net_NotifyGeneric(ply, jcms.NOTIFY_LOST, jcms.util_CashFormat(cash) .. " J")
				end

				return true, won and 1 or 2
			else
				return false, 0
			end
		end,
		
		generate = function(ent)
			-- Announcer JonahSoldier warns us not to touch the gambling machine
			local timerId = "jcms_dontTouchGambling" .. ent:EntIndex()
			timer.Create(timerId, 0.5, 0, function()
				if not IsValid(ent) then
					timer.Remove(timerId)
				else
					ent.jcms_warnedAboutGambling = ent.jcms_warnedAboutGambling or {}
					for i, sweeper in ipairs(jcms.GetAliveSweepers()) do
						if not ent.jcms_warnedAboutGambling[sweeper] then
							local tr = sweeper:GetEyeTrace()
							if (tr.Entity == ent) and (tr.StartPos:DistToSqr(tr.HitPos) <= 230*230) then
								ent.jcms_warnedAboutGambling[sweeper] = true
								jcms.announcer_Speak(jcms.ANNOUNCER_DONTTOUCH, sweeper)
							end
						end
					end
				end
			end)
		end
	},

	upgrade_station = {
		command = function(ent, cmd, data, ply)
			local upgradeValues = string.Split(data, " ")

			local cost = 1000
			for i, value in ipairs(upgradeValues) do
				if value == "x" then
					cost = cost + 500
				end
			end

			if ply:GetNWInt("jcms_cash") < cost then
				return false
			end

			if tonumber(upgradeValues[ cmd ]) then
				local value = tonumber(upgradeValues[ cmd ])
				if cmd == 1 then
					ply.jcms_incendiaryUpgrade = (ply.jcms_incendiaryUpgrade and ply.jcms_incendiaryUpgrade + 1) or 1
					-- Incendiary Ammo upgrade
					ply.jcms_damageEffect = function(ply, target, dmgInfo)
						if not jcms.team_JCorp(target) and not(target:GetClass() == "jcms_fire" or target:GetClass() == "gmod_hands" or target:GetClass() == "predicted_viewmodel") and not target:IsWeapon() then 
							target:Ignite(ply.jcms_incendiaryUpgrade * 2)
						end
					end
				elseif cmd == 2 then
					-- Shield upgrade
					ply:SetMaxArmor( math.floor(ply:GetMaxArmor() * 1.25) )
				elseif cmd == 3 then
					-- Explosive Ammo upgrade
					ply.jcms_explosiveUpgrade = (ply.jcms_explosiveUpgrade and ply.jcms_explosiveUpgrade + 1) or 1
					local expl = ply.jcms_explosiveUpgrade --readability

					ply.jcms_EntityFireBullets = function(ent, bulletData)
						bulletData.TracerName = nil
						bulletData.Tracer = math.huge
				
						local ogCallback = bulletData.Callback
						bulletData.Callback = function(attacker, tr, dmgInfo)
							if type(ogCallback) == "function" then
								ogCallback(attacker, tr, dmgInfo)
							end

							local dmg = dmgInfo:GetDamage()
							local blastRadius, blastDmg = math.max(dmg^(2/3) * 5 * expl, 66), math.max(expl * dmg/4, 2)
							
							if SERVER then
								local effectdata = EffectData()
								local angles = attacker:EyeAngles()
								local origin = attacker:EyePos() + angles:Right() * 1 + angles:Up() * -2 + angles:Forward() * 16
								effectdata:SetStart(origin)
								effectdata:SetScale(math.random(6500, 9000))
								effectdata:SetMagnitude(blastRadius)
								effectdata:SetAngles(tr.Normal:Angle())
								effectdata:SetOrigin(tr.HitPos)
								effectdata:SetFlags(5)
								util.Effect("jcms_bolt", effectdata, true, true)
							end
				
							util.BlastDamage(ent, ent, tr.HitPos, blastRadius, blastDmg) --Roughly 50 rad, 5dmg for an smg | 100rad, 20dmg for a sniper
						end
					end
				end

				upgradeValues[cmd] = "x"
				ent:EmitSound("items/medshot4.wav", 100, 80, 1)
				ply:SetNWInt("jcms_cash", ply:GetNWInt("jcms_cash") - cost)
				return true, table.concat(upgradeValues, " ")
			else
				return false
			end
		end,

		generate = function(ent)
			local upgradeList = {
				health = { 5, 10, 15 },
				shield = { 25, 25, 25 },
				damage = { 0.05, 0.1, 0.2 }
			}

			local order = table.GetKeys(upgradeList)
			table.Shuffle(order)

			for i, category in ipairs(order) do
				local upgradeTiers = upgradeList[ category ]
				upgradeList[category] = upgradeTiers[i]
			end

			return string.format("%d %d %.2f", upgradeList.health, upgradeList.shield, upgradeList.damage)
		end
	},

	respawn_chamber = {
		command = function(ent, cmd, data, ply)
			if cmd == 0 and ent:GetNWBool("jcms_terminal_locked") then
				jcms.terminal_ToUnlock(ent)
				return true
			end
			return false
		end,

		generate = function(ent)
			local locked = ent:GetNWBool("jcms_terminal_locked") and not ent.respawnBeaconUsedUp

			if not locked then
				ent:SetColor( Color(255, 143, 143) )

				if not ent.initializedAsRespawnBeacon and jcms.director then
					table.insert(jcms.director.respawnBeacons, ent)
					ent.initializedAsRespawnBeacon = true
				end
			end

			return locked and "0" or "1"
		end
	},

	gunlocker = {
		command = function(ent, cmd, data, ply)
			local locked = ent:GetNWBool("jcms_terminal_locked")

			if cmd == 1 and not locked and data ~= "" then
				local oldValue = ply.jcms_canGetWeapons
				ply.jcms_canGetWeapons = true
				ply:Give(ent.jcms_weaponclass)
				ply.jcms_canGetWeapons = oldValue

				local gunstats = jcms.gunstats_GetExpensive(ent.jcms_weaponclass)
				if gunstats then
					jcms.net_NotifyGeneric(ply, jcms.NOTIFY_OBTAINED, gunstats.name or "#"..ent.jcms_weaponclass)
				end
				return true, ""
			elseif cmd == 2 and locked then
				jcms.terminal_ToUnlock(ent)
				return true
			end
		end,
		
		generate = function(ent)
			if not ent.jcms_weaponclass then
				local starterCash = jcms.cvar_cash_start:GetInt()
				local evacCash = jcms.cvar_cash_evac:GetInt()
				local winCash = jcms.cvar_cash_victory:GetInt()

				--not accounting for clerks because I couldn't be bothered.
				local totalCash = starterCash + (evacCash + winCash) * jcms.runprogress.winstreak

				local weights = {}
				for k,v in pairs(jcms.weapon_prices) do
					if v <= 0 then continue end
					--weights[k] = (v <= 3200 and (v/5) or (math.min(20000, v)^1.12 + 6000)) / 100
					local cost = v * jcms.util_GetLobbyWeaponCostMultiplier()

					if cost < totalCash * 0.5 then							--Not possible
						weights[k] = nil
					elseif cost < totalCash then							--Rapid fall off
						weights[k] = ((cost*2 / totalCash) - 1)^3 
					elseif cost >= totalCash and cost <= totalCash * 2 then	--Equally likely
						weights[k] = 1 
					else												--Fall-off but never reach 0
						weights[k] = 1 / (cost / totalCash - 1)
					end
				end

				local chosen = jcms.util_ChooseByWeight(weights)
				
				if not chosen then
					chosen = "weapon_crowbar"
				end

				ent.jcms_weaponclass = chosen
			end

			return ent.jcms_weaponclass
		end
	},
	
	shop = {
		command = function(ent, cmd, data, ply)
			local weapon = ply:GetActiveWeapon()
			local balance = ply:GetNWInt("jcms_cash")
			
			if IsValid(weapon) then
				local dist2 = ply:EyePos():DistToSqr(ent:WorldSpaceCenter())

				if dist2 > 256*256 then
					return false
				end

				if cmd == 1 then
					-- Selling current weapon
					local gunPriceMul = ent:GetGunPriceMul()
					local weaponPrice = jcms.weapon_prices[ weapon:GetClass() ]
					
					if not weaponPrice then
						return false
					else
						jcms.giveCash(ply, math.max(1, math.floor(weaponPrice*gunPriceMul*0.25)))
						ply:StripWeapon(weapon:GetClass())

						-- If the ammo type of the weapon is useless, we sell it.
						for i=1, 2 do
							local ammoType = i==1 and weapon:GetPrimaryAmmoType() or weapon:GetSecondaryAmmoType()

							if ammoType >= 0 then
								local useless = jcms.isAmmoTypeUseless(ply, ammoType)
								if useless then
									local count = ply:GetAmmoCount(ammoType)
									ply:SetAmmo(0, ammoType)
									jcms.giveCashForUselessAmmo(ply, ammoType, count)
								end
							end
						end

						return true
					end
					
				elseif cmd == 2 or cmd == 4 then
					-- Buying primary (cmd=2) or secondary (cmd=4) ammo
					local primary = cmd==2
					local ammoType = primary and weapon:GetPrimaryAmmoType() or weapon:GetSecondaryAmmoType()
					
					if ammoType and ammoType > 0 then
						local ammoTypeName = game.GetAmmoName(ammoType)
						local ammoPrice = jcms.weapon_ammoCosts[ ammoTypeName:lower() ] or jcms.weapon_ammoCosts._DEFAULT
						local ammoPriceMul = ent:GetAmmoPriceMul()
						
						local clipSize = primary and weapon:GetMaxClip1() or weapon:GetMaxClip2()
						local weaponModeTable = (primary and weapon.Primary) or (not primary and weapon.Secondary)

						if clipSize < 0 then
							clipSize = weaponModeTable and tonumber(weaponModeTable.DefaultClip) or 1
						end
						
						local totalPrice = math.ceil(math.ceil(ammoPrice * clipSize)*ammoPriceMul)
						if balance >= totalPrice then
							ply:GiveAmmo(clipSize, ammoType)
							ply:SetNWInt("jcms_cash", balance - totalPrice)
							return true
						else
							return false
						end
					end
				elseif cmd == 3 or cmd == 5 then
					-- Selling primary (cmd=3) or secondary (cmd=5) ammo
					local primary = cmd==3
					local ammoType = primary and weapon:GetPrimaryAmmoType() or weapon:GetSecondaryAmmoType()
					
					if ammoType and ammoType > 0 then
						local ammoTypeName = game.GetAmmoName(ammoType)
						local ammoPrice = jcms.weapon_ammoCosts[ ammoTypeName:lower() ] or jcms.weapon_ammoCosts._DEFAULT
						local ammoPriceMul = ent:GetAmmoPriceMul()
						local plyAmmo = ply:GetAmmoCount(ammoType)
						
						local clipSize = primary and weapon:GetMaxClip1() or weapon:GetMaxClip2()
						local weaponModeTable = (primary and weapon.Primary) or (not primary and weapon.Secondary)

						if clipSize < 0 then
							clipSize = weaponModeTable and tonumber(weaponModeTable.DefaultClip) or 1
						end
						
						local totalPrice = math.floor( math.max(1, ammoPrice*clipSize*0.5*ammoPriceMul) )
						if plyAmmo >= clipSize then
							ply:SetAmmo(plyAmmo-clipSize, ammoType)
							jcms.giveCash(ply, totalPrice)
							return true
						else
							return false
						end
					end
				end
			end
		end
	},

	thumper_controls = {
		command = function(ent, cmd, data, ply)
			if cmd == 0 then
				jcms.terminal_ToUnlock(ent)
				return true
			elseif cmd == 1 and not ent:GetNWBool("jcms_terminal_locked") then
				local worked, newdata = ent.jcms_terminal_Callback(ent, cmd, data, ply)
				return worked, newdata
			end
		end
	},
	
	jcorpnuke = {
		command = function(ent, cmd, data, ply)
			if cmd == 1 then
				local worked, newdata = ent.jcms_terminal_Callback(ent, cmd, data, ply)
				return worked, newdata
			end
		end
	},

	mainframe_terminal = {
		generate = function(ent)
			local isUnlocked = true
			for i, terminal in ipairs(ent.dependents) do 
				isUnlocked = isUnlocked and terminal.isComplete
			end

			if not isUnlocked then
				ent.jcms_hackTypeStored = ent.jcms_hackType
				ent.jcms_hackType = nil
			elseif ent.jcms_hackTypeStored then
				ent.jcms_hackType = ent.jcms_hackTypeStored
			end

			if not ent:GetNWBool("jcms_terminal_locked") then 
				local redVector = Vector(1, 0.25, 0.25)
				for i, nodeEnt in ipairs(ent.track) do 
					nodeEnt:SetEnergyColour(redVector)
				end
				ent.isComplete = true
				if IsValid(ent.prevTerminal) then --Re-generate our predecessor, so it updates/unlocks.
					jcms.terminal_ToPurpose(ent.prevTerminal)
				end
			end

			ent.isUnlocked = isUnlocked --So we can use this easily for object tagging in the mission file.
			isUnlocked = isUnlocked and "1" or "0"
			local trackId = tostring(ent.trackId)
			return trackId .. "_" .. isUnlocked
		end,

		command = function(ent, cmd, data, ply)
			local dataTbl = string.Explode( "_", data )
			local trackID = dataTbl[1]
			local unlocked = dataTbl[2]

			if cmd == 0 and unlocked and ent:GetNWBool("jcms_terminal_locked") then 
				jcms.terminal_ToUnlock(ent)
				return true
			end
		end
	},

	payload_controls = {
		command = function(ent, cmd, data, ply)
			if cmd == 0 then
				jcms.terminal_ToUnlock(ent)
				return true
			elseif cmd == 1 then

				if ent:GetNWBool("jcms_terminal_locked") then
					if data == "u" then
						jcms.terminal_ToUnlock(ent)
						return true
					else
						return true, "u"
					end
				else
					local worked, newdata = ent.jcms_terminal_Callback(ent, cmd, data, ply)
					return worked, newdata
				end
			end
		end,

		generate = function(ent)
			if ent.nodeWasCrossed then
				return "p"
			else
				return ""
			end
		end
	},

	-- Hacking
	spinners = {
		weight = 1,

		generate = function(ent)
			local size = math.random(8, 9)
			local startY = math.random(1, size)
			local goalY = math.random(1, size)

			local map = ""
			for i=1, size*size do
				map = map .. math.random(1, 6)
			end

			return size .. " " .. startY .. " " .. goalY .. " " .. map
		end,

		command = function(ent, cmd, data, ply)
			if not ent:GetNWBool("jcms_terminal_locked") then return end
			local size, startY, goalY, map = data:match("(%d+) (%d+) (%d+) (%w+)")
			size = tonumber(size)

			if size and #map == size^2 and cmd >= 1 and cmd <= size^2 then
				local t = {}
				for i=1, #map do
					t[i] = map:sub(i,i)
					if t[i]:match("%a") == t[i] then
						-- I know I could use string.byte and shit but nah.
						t[i] = ({a="1",b="2",c="3",d="4",e="5",f="6"})[ t[i] ]
					end
				end

				local piece = t[cmd]
				if piece == "1" then
					piece = "2"
				elseif piece == "2" then
					piece = "1"
				elseif piece == "6" then
					piece = "3"
				else
					piece = tostring(tonumber(piece) + 1)
				end
				t[cmd] = piece

				local flow = {
					{ ["10"]="10", ["-10"]="-10" },
					{ ["01"]="01", ["0-1"]="0-1" },
					{ ["-10"]="01", ["0-1"]="10" },
					{ ["10"]="01", ["0-1"]="-10" },
					{ ["10"]="0-1", ["01"]="-10" },
					{ ["-10"]="0-1", ["01"]="10" }
				}

				local x,y = 1, tonumber(startY)
				local dx, dy = 1, 0
				local unlocked = false
				while true do
					local piece = tonumber( t[ (y-1)*size + x ] )

					if piece then
						local nextflow = flow[ piece ][ dx..dy ]
						if nextflow then
							t[ (y-1)*size + x ] = ({"a","b","c","d","e","f"})[piece]

							if nextflow == "10" then
								dx, dy = 1, 0
							elseif nextflow == "-10" then
								dx, dy = -1, 0
							elseif nextflow == "0-1" then
								dx, dy = 0, -1
							elseif nextflow == "01" then
								dx, dy = 0, 1
							end
							x, y = x + dx, y + dy

							if x<1 or x>size or y<1 or y>size then
								if x > size and y==tonumber(goalY) then
									unlocked = true
								end
								break
							end
						else
							break
						end 
					else
						break
					end
				end

				if unlocked then
					jcms.terminal_Unlock(ent, ply, true)
				end

				map = table.concat(t)
				return true, ("%d %d %d %s"):format(size, startY, goalY, map)
			else
				return false                    
			end
		end
	},

	circuit = {
		weight = 1,

		generate = function(ent)
			local count = math.random(6, 7)
			local str = math.random(0,9) .. " "
			
			local pieces = {}
			for i = 1, count do
				table.insert(pieces, i)
				table.insert(pieces, i)
			end
			table.Shuffle(pieces)
			
			for i, piece in ipairs(pieces) do
				str = str .. piece
			end
			
			str = str .. " "
			for i = 1, count do
				str = str .. "0"
			end
			
			return str
		end,

		command = function(ent, cmd, data, ply)
			if not ent:GetNWBool("jcms_terminal_locked") then return end

			local split = string.Split(data, " ")
			
			if #split == 4 then
				local clickedId = tonumber(cmd)
				local clickedNumber = tonumber(split[2]:sub(clickedId, clickedId))
				local selectedId = tonumber(split[4])
				local selectedNumber = tonumber(split[2]:sub(selectedId, selectedId))
				
				if clickedNumber == selectedNumber and clickedId ~= selectedId then
					split[3] = split[3]:sub(1, clickedNumber-1) .. "1" .. split[3]:sub(clickedNumber+1, -1)
				elseif (clickedId ~= 0) and (clickedId ~= selectedId) then
					jcms.terminal_Punish(ent, ply)
				end
				
				if split[3]:match("1+") == split[3] then
					jcms.terminal_Unlock(ent, ply, true)
				end
				
				return true, table.concat(split, " ", 1, 3)
			else
				return true, data .. " " .. cmd
			end
			
			return false
		end
	},
	
	codematch = {
		weight = 1,

		generate = function(ent)
			local target = string.format("%x", math.random(16, 16*16-1))
			local str = math.random(5, 6) .. " " .. target
			
			local targetId = math.random(1, 20)
			for i=1, 20 do
				local piece = i == targetId and target or string.format("%x", math.random(16, 16*16-1))
				str = str .. " " .. piece
			end
			
			return str
		end,

		command = function(ent, cmd, data, ply)
			if not ent:GetNWBool("jcms_terminal_locked") then return end
			
			local split = string.Split(data, " ")
			if #split > 2 then
				local totalPieces = tonumber( split[1]:sub(1,1) ) or 0
				local wordSoFar = split[1]:sub(2, -1)
				
				local target = split[2]
				table.remove(split, 1)
				table.remove(split, 1)
				
				if (split[cmd] == target) then
					wordSoFar = wordSoFar .. target
					if #wordSoFar/2 >= totalPieces then
						jcms.terminal_Unlock(ent, ply, true)
					else
						target = string.format("%x", math.random(16, 16*16-1))
					end
				else
					jcms.terminal_Punish(ent, ply)
				end
				
				local str = totalPieces .. wordSoFar .. " " .. target
				
				local targetId = math.random(1, 20)
				for i=1, 20 do
					local piece = i == targetId and target or string.format("%x", math.random(16, 16*16-1))
					str = str .. " " .. piece
				end
				
				return true, str
			else
				return false
			end
			
			return false
		end
	},

	jeechblock = {
		weight = 1,

		generate = function(ent)
			local str = ""

			ent:StopSound("ambient/atmosphere/tone_alley.wav")

			if math.random() < 0.001 then
				str = "ILOVEJCORP"
				if math.random() < 0.1 then
					str = math.random() < 0.5 and "RUN" or "BEHINDYOU"
					ent:EmitSound("ambient/atmosphere/tone_alley.wav", 75, 90, 1, CHAN_STATIC)
				end
			else
				for i=1, 10 do
					str = str .. string.char(math.random() < 0.75 and math.random(0x41, 0x5a) or math.random(0x30, 0x39))
				end
			end
			
			return str .. " "
		end,

		command = function(ent, cmd, data, ply)
			local sample = "1234567890QWERTYUIOP-ASDFGHJKL+ZXCVBNM_"
			local char = sample:sub(cmd, cmd)

			local parts = data:Split(" ")

			if char then
				if char == "-" then
					local newWord = parts[2]:sub(1, -2)
					return #parts[2]>0, parts[1] .. " " .. newWord
				elseif char == "+" then
					if parts[1] == parts[2] then
						jcms.terminal_Unlock(ent, ply, true)
						ent:StopSound("ambient/atmosphere/tone_alley.wav")
						return true, data
					else
						jcms.terminal_Punish(ent, ply)
						ent:EmitSound("buttons/button8.wav", 75, 110, 1.0)
						return true, parts[1] .. " " .. parts[2]
					end
				elseif char == "_" then
					return (parts[2] and #parts[2]>0), parts[1] .. " "
				else
					if parts[2] and #parts[2] > #parts[1] + 5 then
						jcms.terminal_Punish(ent, ply)
						ent:EmitSound("buttons/button8.wav", 75, 110, 1.0)
						return true, parts[1] .. " "
					else
						return true, data .. char
					end
				end
			else
				return false
			end
		end
	}
}

for modeType, mode in pairs(jcms.terminal_modeTypes) do
	mode.generate = mode.generate or function(ent) return "" end
end

function jcms.terminal_Setup(ent, purposeType, theme)
	ent.jcms_pin = math.random(0,9) .. math.random(0,9) .. math.random(0,9) .. math.random(0,9)
	--print(ent.jcms_pin)
	
	-- Purpose & Hack type {{{
		local purpose = jcms.terminal_modeTypes[ purposeType ]
		if not purpose then 
			purposeType = "pin" 
			purpose = jcms.terminal_modeTypes.pin
		end

		local weighed = {}
		for modeType, mode in pairs(jcms.terminal_modeTypes) do
			if mode.weight then
				weighed[ modeType ] = mode.weight
			end
		end

		local hackType = jcms.util_ChooseByWeight(weighed)

		ent.jcms_purposeType = purposeType
		ent.jcms_hackType = hackType
	-- }}}

	-- NW {{{
		ent:SetNWBool("jcms_terminal_locked", true)
		ent:SetNWString("jcms_terminal_modeType", purposeType) -- Current mode, can be purpose or hack
		ent:SetNWString("jcms_terminal_modeData", purpose.generate(ent))
		ent:SetNWString("jcms_terminal_theme", theme)
	-- }}}
end

function jcms.terminal_Unlock(ent, hacker, intrusive)
	ent:SetNWBool("jcms_terminal_locked", false)
	ent:EmitSound("buttons/lever8.wav", 70, 106, 0.99)

	if intrusive then
		ent:SetNWString("jcms_terminal_theme", "jcorp")
	end
	
	if IsValid(hacker) and hacker:IsPlayer() then
		jcms.statistics_AddOther(hacker, "hacks", 1)
	end

	ent.jcms_hackType = nil
	timer.Simple(math.Rand(0.75, 1.25), function()
		if IsValid(ent) then
			jcms.terminal_ToPurpose(ent)
		end
	end)
end

function jcms.terminal_Punish(ent, ply)
	if IsValid(ent) and IsValid(ply) and ply:Alive() then
		local ed = EffectData()
		ed:SetEntity(ply)
		ed:SetMagnitude(4)
		ed:SetScale(1)
		util.Effect("TeslaHitBoxes", ed)
		
		ent:EmitSound("ambient/energy/zap"..math.random(2, 3)..".wav")
		ply:ScreenFade(SCREENFADE.IN, Color(230, 230, 255, math.random(50, 66)), math.Rand(0.1, 0.3), 0.05)
		
		local dmg = DamageInfo()
		dmg:SetAttacker(ent)
		dmg:SetInflictor(ent)
		dmg:SetDamageType(DMG_SHOCK)
		dmg:SetDamage(math.Rand(1, 7))
		ply:TakeDamageInfo(dmg)
		ply:ViewPunch(AngleRand(-4, 4))
	end
end

function jcms.terminal_ToUnlock(ent)
	-- Pins are obsolete now.
	jcms.terminal_ToHack(ent)

	--[[
	timer.Simple(math.Rand(0.05, 0.15), function()
		if not IsValid(ent) then return end
		ent:SetNWString("jcms_terminal_modeType", "pin")
		local hack = jcms.terminal_modeTypes.pin
		ent:SetNWString("jcms_terminal_modeData", hack.generate(ent))
	end)]]
end

function jcms.terminal_ToHack(ent)
	ent:EmitSound("weapons/stunstick/alyx_stunner" .. math.random(1,2) .. ".wav", 80, 104)
	timer.Simple(math.Rand(0.05, 0.15), function()
		if not IsValid(ent) then return end
		ent:SetNWString("jcms_terminal_modeType", ent.jcms_hackType)
		local hack = jcms.terminal_modeTypes[ ent.jcms_hackType ]
		ent:SetNWString("jcms_terminal_modeData", hack.generate(ent))
	end)
end

function jcms.terminal_ToPurpose(ent)
	ent:EmitSound("weapons/slam/mine_mode.wav", 80, 98)
	timer.Simple(math.Rand(0.05, 0.15), function()
		if not IsValid(ent) then return end
		ent:SetNWString("jcms_terminal_modeType", ent.jcms_purposeType)
		local purpose = jcms.terminal_modeTypes[ ent.jcms_purposeType ]
		ent:SetNWString("jcms_terminal_modeData", purpose.generate(ent))
	end)
end

hook.Add("EntityTakeDamage", "jcms_HackerStunstick", function(ent, dmg)
	if ent.jcms_hackType and dmg:GetInflictor():IsWeapon() and jcms.util_IsStunstick( dmg:GetInflictor() ) and jcms.team_JCorp(dmg:GetAttacker()) then
		local ed = EffectData()
		ed:SetEntity(ent)
		ed:SetMagnitude(4)
		ed:SetScale(1)
		util.Effect("TeslaHitBoxes", ed)

		if ent:GetNWString("jcms_terminal_modeType") == ent.jcms_hackType then
			jcms.terminal_ToPurpose(ent)
		else
			jcms.terminal_ToHack(ent)
		end
	end
end)
