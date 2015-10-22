airshipdata = {data = {}}

local DIR_DELIM = DIR_DELIM or "/"
local data_path = minetest.get_worldpath()..DIR_DELIM.."airshipdata"..DIR_DELIM

function airshipdata.save(id)
	local data = airshipdata.data[id]
	print(data)
	local datastr = minetest.serialize(data)
	print(datastr)
	-- Check if the container is empty
	if not data or not next(data) then return end
	for _, sub_data in pairs(data) do
		if not next(sub_data) then return end
	end

	local file = io.open(data_path..id, "w")
	if not file then
		-- Most likely the data directory doesn't exist, create it
		-- and try again.
		if minetest.mkdir then
			minetest.mkdir(data_path)
		else
			-- Using os.execute like this is not very platform
			-- independent or safe, but most platforms name their
			-- directory creation utility mkdir, the data path is
			-- unlikely to contain special characters, and the
			-- data path is only mutable by the admin.
			os.execute('mkdir "'..data_path..'"')
		end
		file = io.open(data_path..id, "w")
		if not file then 
		print("data file can't create!!!")
		return end
	end

	local datastr = minetest.serialize(data)
	if not datastr then return end
	print(datastr)
	file:write(datastr)
	file:close()
	return true
end

function airshipdata.load(id)
	local file = io.open(data_path..id, "r")
	if not file then return end

	local data = minetest.deserialize(file:read("*all"))
	airshipdata.data[id] = data

	file:close()
	return data
end

-- Compatability
function airshipdata.get_container(player, id)
	return airshipdata.get(player:get_player_name(), id)
end

-- Retrieves a value from the data storage
function airshipdata.get(id, ...)
	local last = airshipdata.data[id]
	if last == nil then last = airshipdata.load(id) end
	if last == nil then
		last = {}
		airshipdata.data[id] = last
	end
	local cur = last
	for _, sub_id in ipairs({...}) do
		last = cur
		cur = cur[sub_id]
		if cur == nil then
			cur = {}
			last[sub_id] = cur
		end
	end
	return cur
end

-- Saves a container and reomves it from memory
function airshipdata.finish(id)
	airshipdata.save(id)
	airshipdata.data[id] = nil
end

-- Compatability
function airshipdata.save_container(player)
	return airshipdata.save(player:get_player_name())
end

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	airshipdata.save(player_name)
	airshipdata.data[player_name] = nil
end)

minetest.register_on_shutdown(function()
	for id in pairs(airshipdata.data) do
		airshipdata.save(id)
	end
end)

