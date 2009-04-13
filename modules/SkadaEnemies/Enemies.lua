local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local done = Skada:NewModule("EnemyDoneMode")
local taken = Skada:NewModule("EnemyTakenMode")

local doneplayers = Skada:NewModule("EnemyDonePlayers")
local takenplayers = Skada:NewModule("EnemyTakenPlayers")

done.name = L["Enemy damage done"]
taken.name = L["Enemy damage taken"]

local function find_player(mob, name)
	for i, p in ipairs(mob.players) do
		if p.name == name then
			return p
		end
	end
	
	local player = {name = name, done = 0, taken = 0, class = select(2, UnitClass(name))}
	table.insert(mob.players, player)
	return player
end

local function log_damage_taken(set, dmg)
	set.mobtaken = set.mobtaken + dmg.amount
	
	if not set.mobs[dmg.dstName] then
		set.mobs[dmg.dstName] = {taken = 0, done = 0, players = {}}
	end
	
	local mob = set.mobs[dmg.dstName]
	
	mob.taken = set.mobs[dmg.dstName].taken + dmg.amount
	
	local player = find_player(mob, dmg.srcName)
	player.taken = player.taken + dmg.amount
end

local function log_damage_done(set, dmg)
	set.mobdone = set.mobdone + dmg.amount

	if not set.mobs[dmg.srcName] then
		set.mobs[dmg.srcName] = {taken = 0, done = 0, players = {}}
	end
	
	local mob = set.mobs[dmg.srcName]
	
	mob.done = mob.done + dmg.amount
	
	local player = find_player(mob, dmg.dstName)
	player.done = player.done + dmg.amount
end

local dmg = {}

local function SpellDamageTaken(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcName and dstName and srcGUID ~= dstGUID then
		dmg.dstName = dstName
		dmg.srcName = srcName
		dmg.amount = select(4, ...)

		Skada:FixPets(dmg)
		log_damage_taken(Skada.current, dmg)
	end
end

local function SpellDamageDone(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcName and dstName and srcGUID ~= dstGUID then
		dmg.dstName = dstName
		dmg.srcName = srcName
		dmg.amount = select(4, ...)

		log_damage_done(Skada.current, dmg)
	end
end

local function SwingDamageTaken(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcName and dstName and srcGUID ~= dstGUID then
		dmg.dstName = dstName
		dmg.srcName = srcName
		dmg.amount = select(1,...)
		
		Skada:FixPets(dmg)
		log_damage_taken(Skada.current, dmg)
	end
end

local function SwingDamageDone(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcName and dstName and srcGUID ~= dstGUID then
		dmg.dstName = dstName
		dmg.srcName = srcName
		dmg.amount = select(1,...)
		
		log_damage_done(Skada.current, dmg)
	end
end

local function taken_click(win, data, button)
	if button == "LeftButton" then
		takenplayers.name = L["Damage on"].." "..data.label
		takenplayers.mob = data.label
		win:DisplayMode(takenplayers)
	elseif button == "RightButton" then
	 	win:RightClick()
	end
end

-- Enemy damage taken - list mobs.
function taken:Update(win, set)
	local nr = 1
	local max = 0
	
	for name, mob in pairs(set.mobs) do
		if mob.taken > 0 then
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			
			d.value = mob.taken
			d.id = name
			d.valuetext = Skada:FormatNumber(mob.taken)
			d.label = name
			
			if mob.taken > max then
				max = mob.taken
			end
			
			nr = nr + 1
		end
	end
	
	win.metadata.maxvalue = max
end

local function done_click(win, data, button)
	if button == "LeftButton" then
		doneplayers.name = L["Damage from"].." "..data.label
		doneplayers.mob = data.label
		win:DisplayMode(doneplayers)
	elseif button == "RightButton" then
	 	win:RightClick()
	end
end

function done:Update(win, set)
	local nr = 1
	local max = 0
	
	for name, mob in pairs(set.mobs) do
		if mob.done > 0 then
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			
			d.value = mob.done
			d.id = name
			d.valuetext = Skada:FormatNumber(mob.done)
			d.label = name
			
			if mob.done > max then
				max = mob.done
			end
			
			nr = nr + 1
		end
	end
	
	win.metadata.maxvalue = max
end

local function player_done_click(win, data, button)
	if button == "RightButton" then
	 	win:DisplayMode(done)
	end
end

function doneplayers:Update(win, set)
	if self.mob then
	
		for name, mob in pairs(set.mobs) do
	
			local nr = 1
			local max = 0
	
			if name == self.mob then
				for i, player in ipairs(mob.players) do
					if player.done > 0 then
					
						local d = win.dataset[nr] or {}
						win.dataset[nr] = d
						
						d.id = player.name
						d.label = player.name
						d.value = player.done
						d.valuetext = Skada:FormatNumber(player.done)..(" (%02.1f%%)"):format(player.done / mob.done * 100)
						d.class = player.class
						
						if player.done > max then
							max = player.done
						end
						
						nr = nr + 1
					end
				end
		
				win.metadata.maxvalue = max
		
			end
		end
	end
end

local function player_taken_click(win, data, button)
	if button == "RightButton" then
	 	win:DisplayMode(taken)
	end
end

function takenplayers:Update(win, set)
	if self.mob then
		
		-- Look for the chosen mob. We could store a reference here, but that would complicate garbage collecting the data later.
		for name, mob in pairs(set.mobs) do
		
			local nr = 1
			local max = 0
			
			-- Yay, we found it.
			if name == self.mob then
				
				-- Iterations 'R' Us.
				for i, player in ipairs(mob.players) do
					if player.taken > 0 then
					
						local d = win.dataset[nr] or {}
						win.dataset[nr] = d
						
						d.id = player.name
						d.label = player.name
						d.value = player.taken
						d.valuetext = Skada:FormatNumber(player.taken)..(" (%02.1f%%)"):format(player.taken / mob.taken * 100)
						d.class = player.class
						
						if player.taken > max then
							max = player.taken
						end
						
						nr = nr + 1
					end
				end
				
				win.metadata.maxvalue = max
				return
			end
			
		end
	end
end


function done:OnEnable()
	takenplayers.metadata 	= {click = player_taken_click, showspots = true}
	doneplayers.metadata 	= {click = player_done_click, showspots = true}
	done.metadata 			= {click = done_click}
	taken.metadata 			= {click = taken_click}

	Skada:RegisterForCL(SpellDamageTaken, 'SPELL_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamageTaken, 'SPELL_PERIODIC_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamageTaken, 'SPELL_BUILDING_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamageTaken, 'RANGE_DAMAGE', {src_is_interesting = true})

	Skada:RegisterForCL(SpellDamageDone, 'SPELL_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamageDone, 'SPELL_PERIODIC_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamageDone, 'SPELL_BUILDING_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamageDone, 'RANGE_DAMAGE', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(SwingDamageTaken, 'SWING_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SwingDamageDone, 'SWING_DAMAGE', {dst_is_interesting_nopets = true})
	
	Skada:AddMode(self)
end

function done:OnDisable()
	Skada:RemoveMode(self)
end

function taken:OnEnable()
	Skada:AddMode(self)
end

function taken:OnDisable()
	Skada:RemoveMode(self)
end

function done:GetSetSummary(set)
	return Skada:FormatNumber(set.mobdone)
end

function taken:GetSetSummary(set)
	return Skada:FormatNumber(set.mobtaken)
end

-- Called by Skada when a new set is created.
function done:AddSetAttributes(set)
	if not set.mobs then
		set.mobs = {}
		set.mobdone = 0
		set.mobtaken = 0
	end
end
