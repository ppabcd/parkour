local is_tribe = string.sub(room.name, 2, 2) == "\3"

no_powers = {}
local facing = {}
local cooldowns = {}
local max_leaderboard_rows
local leaderboard
local obj_whitelist = {_count = 0, _index = 1}

local function addShamanObject(id, x, y, ...)
	obj_whitelist._count = obj_whitelist._count + 1
	obj_whitelist[obj_whitelist._count] = {id, x, y}
	return tfm.exec.addShamanObject(id, x, y, ...)
end

local function checkCooldown(player, name, long, img, x, y, show)
	if cooldowns[player] then
		if cooldowns[player][name] and os.time() < cooldowns[player][name] then
			return false
		end
		cooldowns[player][name] = os.time() + long
	else
		cooldowns[player] = {
			[name] = os.time() + long
		}
	end

	if show then
		addNewTimer(
			long, tfm.exec.removeImage,
			tfm.exec.addImage(img, ":1", x, y, player)
		)
	end

	return true
end

local function despawnableObject(when, ...)
	local obj = addShamanObject(...)
	addNewTimer(when, tfm.exec.removeObject, obj)
end

local toilet
toilet = {
	water = function(img, id, x, y)
		tfm.exec.removeImage(img)

		local obj = addShamanObject(63, x, y)
		tfm.exec.addPhysicObject(id, x, y - 20, {
			type = 9,
			width = 30,
			height = 60,
			miceCollision = false,
			groundCollision = false,
			foreground = true
		})

		addNewTimer(5000, toilet.despawn, id, obj)
	end,
	despawn = function(id, obj)
		tfm.exec.removePhysicObject(id)
		tfm.exec.removeObject(obj)
	end
}

local powers = {
	{
		name = 'fly',
		maps = 5,
		cooldown = nil,
		image = {url = '16896d06614.png', x = 47, y = 33},

		qwerty = {key = "SPACE", keyCode = 32},

		fnc = function(player, key, down, x, y)
			tfm.exec.movePlayer(player, 0, 0, true, 0, -50, false)
		end
	},
	{
		name = 'speed',
		maps = 10,
		cooldown = 1000,
		cooldown_icon = {img = "17127e682ff.png", x = 30, y = 373},
		image = {url = '16896ed356d.png', x = 35, y = 25},

		qwerty = {key = "SHIFT", keyCode = 16},

		fnc = function(player, key, down, x, y)
			tfm.exec.movePlayer(player, 0, 0, true, facing[player] and 60 or -60, 0, true)
		end
	},
	{
		name = 'snowball',
		maps = 15,
		cooldown = 5000,
		cooldown_icon = {img = "17127e6674c.png", x = 8, y = 374},
		image = {url = '16896d045f9.png', x = 50, y = 40},

		qwerty = {key = "E", keyCode = 69},

		fnc = function(player, key, down, x, y)
			local right = facing[player]
			despawnableObject(5000, 34, x + (right and 20 or -20), y, 0, right and 10 or -10)
		end
	},
	{
		name = 'balloon',
		maps = 20,
		cooldown = 10000,
		cooldown_icon = {img = "17127e5b2d5.png", x = 52, y = 372},
		image = {url = '16896d0252b.png', x = 35, y = 20},

		qwerty = {key = "Q", keyCode = 81},
		azerty = {key = "A", keyCode = 65},

		fnc = function(player, key, down, x, y)
			if players_file[player].parkour.c < 200 then
				despawnableObject(2000, 28, x, y + 10)
			end
		end
	},
	{
		name = 'teleport',
		maps = 35,
		cooldown = 10000,
		cooldown_icon = {img = "17127e73965.png", x = 74, y = 373},
		image = {url = '16896d00614.png', x = 30, y = 20},

		click = true,

		fnc = tfm.exec.movePlayer
	},
	{
		name = 'smallbox',
		maps = 50,
		cooldown = 10000,
		cooldown_icon = {img ="17127e77dbe.jpg", x = 98, y = 373},
		image = {url = '1689fd4ffc4.jpg', x = 50, y = 40},

		qwerty = {key = "Z", keyCode = 90},
		azerty = {key = "W", keyCode = 87},

		fnc = function(player, key, down, x, y)
			despawnableObject(3000, 1, x, y + 10)
		end
	},
	{
		name = 'cloud',
		maps = 100,
		cooldown = 10000,
		cooldown_icon = {img= "17127e5f927.png", x = 121, y = 377},
		image = {url = '1689fe8325e.png', x = 15, y = 25},

		qwerty = {key = "X", keyCode = 88},

		fnc = function(player, key, down, x, y)
			despawnableObject(2000, 57, x, y + 10)
		end
	},
	{
		name = 'masterBalloon',
		maps = 200,
		cooldown = 10000,
		cooldown_icon = {img = "17127e62809.png", x = 142, y = 376},
		image = {url = '168ab7be931.png', x = 15, y = 20},

		qwerty = {key = "Q", keyCode = 81},
		azerty = {key = "A", keyCode = 65},

		fnc = function(player, key, down, x, y)
			if players_file[player].parkour.c < 400 then
				despawnableObject(3000, 2804, x, y + 10)
			end
		end
	},
	{
		name = 'bubble',
		maps = 400,
		cooldown = 10000,
		cooldown_icon = {img= "17127e5ca47.png", x = 161, y = 373},
		image = {url = '168ab822a4b.png', x = 30, y = 20},

		qwerty = {key = "Q", keyCode = 81},
		azerty = {key = "A", keyCode = 65},

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 59, x, y + 12)
		end
	},
	{
		name = 'rip',
		maps = 700,
		cooldown = 10000,
		cooldown_icon = { img = "17127e69ea4.png", x = 181, y = 373},
		image = {url = '169495313ad.png', x = 38, y = 23},

		qwerty = {key = "V", keyCode = 86},

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 90, x, y + 10)
		end
	},
	{
		name = 'choco',
		maps = 1500,
		cooldown = 25000,
		cooldown_icon = {img= "17127fc6b27.png", x = 201, y = 374},
		image = {url = '16d2ce46c57.png', x = 20, y = 56},

		qwerty = {key = "CTRL", keyCode = 17},

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 46, x + (facing[player] and 20 or -20), y - 30, 90)
		end
	},
	{
		name = 'bigBox',
		maps = 2500,
		cooldown = 25000,
		cooldown_icon = {img= "17127e77dbe.jpg", x = 221, y = 374},
		image = {url = '1689fd4ffc4.jpg', x = 50, y = 40},

		qwerty = {key = "B", keyCode = 66},

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 2, x, y + 10, 0)
		end
	},
	{
		name = 'trampoline',
		maps = 4000,
		cooldown = 25000,
		cooldown_icon = {img= "171cd9f5188.png", x = 241, y = 374},
		image = {url = '171cd98ed22.png', x = 20, y = 56},

		qwerty = {key = "N", keyCode = 78},

		fnc = function(player, key, down, x, y)
			despawnableObject(4000, 701, x, y + 10, 0)
		end
	},
	{
		name = 'toilet',
		ranking = 70,
		cooldown = 30000,
		cooldown_icon = {img= "171cd9e02d3.png", x = 261, y = 374},
		image = {url = "171cd3eddf1.png", x = 50, y = 40},

		qwerty = {key = "C", keyCode = 67},

		fnc = function(player, key, down, x, y)
			local id = room.playerList[player].id
			local img = tfm.exec.addImage("171cd3eddf1.png", "_51", x - 20, y - 20)
			tfm.exec.addPhysicObject(id, x, y + 13, {
				type = 14,
				friction = 0.3,
				width = 30
			})

			addNewTimer(5000, toilet.water, img, id, x, y)
		end
	},
}

local keyPowers, clickPowers = {
	qwerty = {},
	azerty = {}
}, {}
local player_keys = {}

function bindNecessary(player)
	local player_pos = leaderboard[player] or max_leaderboard_rows + 1
	local maps = players_file[player].parkour.c
	local power, cond
	for key, powers in next, player_keys[player] do
		if powers._count then
			for index = 1, powers._count do
				power = powers[index]
				if power.ranking then
					cond = player_pos <= power.ranking
				else
					cond = maps >= power.maps
				end
				if cond then
					system.bindKeyboard(player, key, true, true)
				end
			end
		end
	end

	for index = 1, #clickPowers do
		power = clickPowers[index]
		if power.ranking then
			cond = player_pos <= power.ranking
		else
			cond = maps >= power.maps
		end
		if cond then
			system.bindMouse(player, true)
			break
		end
	end
end

function unbind(player)
	local keys = player_keys[player]
	if not keys then return end

	for key, power in next, keys do
		if type(key) == "number" then
			system.bindKeyboard(player, key, true, false)
		end
	end

	system.bindMouse(player, false)
end

onEvent("Keyboard", function(player, key, down, x, y)
	if not room.playerList[player] or bans[ room.playerList[player].id ] then return end

	if key == 0 then
		facing[player] = false
		return
	elseif key == 2 then
		facing[player] = true
		return
	end

	if not players_file[player] or not player_keys[player] or not victory[player] then return end
	local powers = player_keys[player][key]
	if not powers then return end

	local player_pos = leaderboard[player] or max_leaderboard_rows + 1
	local file = players_file[player].parkour
	local maps, show_cooldowns = file.c, file.pcool == 1
	local power, cond
	for index = powers._count, 1, -1 do
		power = powers[index]
		if power.ranking then
			cond = player_pos <= power.ranking
		else
			cond = maps >= power.maps
		end
		if cond then
			if (not power.cooldown) or checkCooldown(player, power.name, power.cooldown, power.cooldown_icon.img, power.cooldown_icon.x, power.cooldown_icon.y, show_cooldowns) then
				power.fnc(player, key, down, x, y)
			end
			break
		end
	end
end)

onEvent("Mouse", function(player, x, y)
	if not room.playerList[player] or bans[ room.playerList[player].id ] then return end

	if not players_file[player] or not victory[player] then return end

	local player_pos = leaderboard[player] or max_leaderboard_rows + 1
	local file = players_file[player].parkour
	local maps, show_cooldowns = file.c, file.pcool == 1
	local power, cond
	for index = 1, #clickPowers do
		power = clickPowers[index]
		if power.ranking then
			cond = player_pos <= power.ranking
		else
			cond = maps >= power.maps
		end
		if cond then
			if (not power.cooldown) or checkCooldown(player, power.name, power.cooldown, power.cooldown_icon.img, power.cooldown_icon.x, power.cooldown_icon.y, show_cooldowns) then
				power.fnc(player, x, y)
			end
		end
	end
end)

onEvent("NewPlayer", function(player)
	system.bindKeyboard(player, 0, true, true)
	system.bindKeyboard(player, 2, true, true)
end)

onEvent("PlayerDataParsed", function(player, data)
	local keyboard = data.parkour.keyboard == 1 and "qwerty" or "azerty"
	player_keys[player] = keyPowers[keyboard]

	if data.parkour.killed > os.time() then
		no_powers[player] = true
		translatedChatMessage("kill_minutes", player, math.ceil((data.parkour.killed - os.time()) / 1000 / 60))
	else
		no_powers[player] = nil
	end

	if victory[player] then
		if not no_powers[player] then
			bindNecessary(player)
		end
	else
		unbind(player)
	end
end)

onEvent("PlayerWon", function(player)
	if bans[ room.playerList[player].id ] then return end
	if not players_file[player] then return end

	if count_stats and room.uniquePlayers >= min_save and player_count >= min_save and not is_tribe and not review_mode then
		local file = players_file[player].parkour
		file.c = file.c + 1
		file.hour_c = file.hour_c + 1
		file.week_c = file.week_c + 1

		if file.hour_c >= 35 and file.hour_c % 5 == 0 then
			sendPacket(3, room.name .. "\000" .. room.playerList[player].id .. "\000" .. player .. "\000" .. file.hour_c)
		end

		savePlayerData(player)
	end

	if not no_powers[player] then
		bindNecessary(player)
	end
end)

onEvent("NewGame", function()
	local now = os.time()

	local to_remove, count = {}, 0
	for player in next, no_powers do
		if not players_file[player] or players_file[player].parkour.killed <= now then
			count = count + 1
			to_remove[count] = player
		end
	end

	for index = 1, count do
		no_powers[to_remove[index]] = nil
	end

	facing = {}
	cooldowns = {}
	obj_whitelist = {_count = 0, _index = 1}

	setmetatable(room.objectList, {
		__newindex = function(self, key, value)
			if self[key] == value then return end

			rawset(self, key, value)

			local obj
			for index = obj_whitelist._index, obj_whitelist._count do
				obj = obj_whitelist[index]
				if obj[1] ~= value.type or obj[2] ~= value.x or obj[3] ~= value.y then
					tfm.exec.removeObject(key)
				else
					obj_whitelist._index = index + 1
				end
				break
			end
		end
	})

	local file
	for player in next, in_room do
		file = players_file[player]
		if file and file.parkour.hour_r <= now then
			file.parkour.hour_c = 0
			file.parkour.hour_r = now + 60 * 60 * 1000
			savePlayerData(player)
		end

		unbind(player)
	end
end)

onEvent("GameStart", function()
	local clickPointer = 0
	local qwerty_keys = keyPowers.qwerty
	local azerty_keys = keyPowers.azerty
	local qwerty_keyCode, azerty_keyCode

	local power
	for index = 1, #powers do
		power = powers[index]
		power.index = index
		if power.click then
			clickPointer = clickPointer + 1
			clickPowers[clickPointer] = power
		else
			if not power.azerty then
				power.azerty = power.qwerty
			end

			qwerty_keyCode = power.qwerty.keyCode
			azerty_keyCode = power.azerty.keyCode

			if qwerty_keys[qwerty_keyCode] then
				qwerty_keys[qwerty_keyCode]._count = qwerty_keys[qwerty_keyCode]._count + 1
				qwerty_keys[qwerty_keyCode][qwerty_keys[qwerty_keyCode]._count] = power
			else
				qwerty_keys[qwerty_keyCode] = {_count = 1, [1] = power}
			end

			if azerty_keys[azerty_keyCode] then
				azerty_keys[azerty_keyCode]._count = azerty_keys[azerty_keyCode]._count + 1
				azerty_keys[azerty_keyCode][azerty_keys[azerty_keyCode]._count] = power
			else
				azerty_keys[azerty_keyCode] = {_count = 1, [1] = power}
			end

			qwerty_keys[power] = power.qwerty.key
			azerty_keys[power] = power.azerty.key
		end
	end
end)
