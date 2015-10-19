CONVERT_MOD_NAME=modname

CONVERT_INIT_DELAY = 1
CONVERT_INIT_TIMES = 1
CONVERT_BONES_DELAY = 1
CONVERT_UPDATE_TIME = 1
CONVERT_DROP = minetest.get_modpath("bones") ~= nil
CONVERT_DESTROY = false
CONVERT_LEVEL_MULTIPLIER = 1
CONVERT_HEAL_MULTIPLIER = 1
CONVERT_MATERIALS = {
	wood = "group:wood",
	cactus = "default:cactus",
	steel = "default:steel_ingot",
	bronze = "default:bronze_ingot",
	diamond = "default:diamond",
	gold = "default:gold_ingot",
	mithril = "moreores:mithril_ingot",
	crystal = "ethereal:crystal_ingot",
}
CONVERT_FIRE_PROTECT = minetest.get_modpath("ethereal") ~= nil
CONVERT_FIRE_NODES = {
	{"default:lava_source",     5, 4},
	{"default:lava_flowing",    5, 4},
	{"fire:basic_flame",        3, 4},
	{"ethereal:crystal_spike",  2, 1},
	{"bakedclay:safe_fire",     2, 1},
	{"default:torch",           1, 1},
}
--TODO:inventory_plus mod support is not completed.some commented code is reserved sample for expand,
--Don't delete.
local skin_mod = nil
local inv_mod = nil
local S = unified_inventory.gettext
local modpath = minetest.get_modpath(CONVERT_MOD_NAME)
local worldpath = minetest.get_worldpath()
local input = io.open(modpath.."/convertor.conf", "r")
if input then
	dofile(modpath.."/convertor.conf")
	input:close()
	input = nil
end
input = io.open(worldpath.."/convertor.conf", "r")
if input then
	dofile(worldpath.."/convertor.conf")
	input:close()
	input = nil
end
if not minetest.get_modpath("moreores") then
	CONVERT_MATERIALS.mithril = nil
end
if not minetest.get_modpath("ethereal") then
	CONVERT_MATERIALS.crystal = nil
end

-- override hot nodes so they do not hurt player anywhere but mod
if CONVERT_FIRE_PROTECT == true then
	for _, row in ipairs(CONVERT_FIRE_NODES) do
		if minetest.registered_nodes[row[1]] then
			minetest.override_item(row[1], {damage_per_second = 0})
		end
	end
end

local time = 0

convertor= {
	player_hp = {},
	attchedairship={pos={x=0,y=0,z=0}},   --To prevent the player from the off-line after the loss of the ship maneuvering state
	elements = {"head", "torso", "legs", "feet"},
	physics = {"jump","speed","gravity"},
	formspec = "size[8,8.5]list[detached:player_name_convertor;convertor;0,1;2,3;]"
		--.."image[2,0.75;2,4;convertor_preview]"  --reserved 
		.."list[current_player;main;0,4.5;8,4;]"
		.."list[current_player;craft;4,1;3,3;]"
		.."list[current_player;craftpreview;7,2;1,1;]"
		.."list[detached:player_name_convertor;charger;5,3;1,1;]"
		.."list[detached:player_name_convertor;fuel;6,3;1,1;]"
		.."button[7,3;1,1.5;Recharge;Recharge]"
		.."list[detached:player_name_convertor;ShipStage;5,2;1,1;]"
		.."tooltip[Recharge;Give the energy block charge]"
		--.."checkbox[3,3;ishighspeed;high speed mod;false;if selected the airship will fast lift and Consume ten times the energy.]"
		.."checkbox[3,3;ishighspeed;high speed;"..tostring(airship.highspeed).."]",
	textures = {},
	default_skin = "character",
	version = "0.4.4",
}

if minetest.get_modpath("inventory_plus") then
	inv_mod = "inventory_plus"
	convertor.formspec = "size[8,8.5]button[0,0;2,0.5;main;Back]"
		.."list[detached:player_name_convertor;convertor;0,1;2,3;]"
		--.."image[2.5,0.75;2,4;convertor_preview]"   --reserved 
		--.."label[5,1;Level: convertor_level]"
		--.."label[5,1.5;Heal:  convertor_heal]"
		--.."label[5,2;Fire:  convertor_fire]"
		.."label[5,2.5;Energyblock & lamp ]"
		.."list[current_player;main;0,4.5;8,4;]"
		.."button[7,3;1,1.5;Recharge;Recharge]"
		.."list[detached:player_name_convertor;ShipStage;5,2;1,1;]"
		.."tooltip[Recharge;Give the energy block charge]"
		--.."checkbox[3,3;ishighspeed;high speed mod;false;if selected the airship will fast lift and Consume ten times the energy.]"
		.."checkbox[3,3;ishighspeed;high speed;"..tostring(airship.highspeed).."]"
	if minetest.get_modpath("crafting") then
		inventory_plus.get_formspec = function(player, page)
		end
	end
elseif minetest.get_modpath("unified_inventory") then
	inv_mod = "unified_inventory"
	unified_inventory.register_button("convertor", {
		type = "image",
		image = "inventory_plus_convertor.png",
		tooltip = S("airship")
	})
	unified_inventory.register_page("convertor", {
		get_formspec = function(player)
			local name = player:get_player_name()
			local formspec = "background[0.06,0.99;7.92,7.52;convertor_ui_form.png]"
				.."label[0,0;Place the energy block to provide power for the airship  ]"
				.."list[detached:"..name.."_convertor;convertor;0,1;2,3;]"
				--.."image[2.5,0.75;2,4;"..convertor.textures[name].preview.."]"  --reserved 
				--.."label[5,1;Level: "..convertor.def[name].level.."]"
				--.."label[5,1.5;Heal:  "..convertor.def[name].heal.."]"
				--.."label[5,2;Fire:  "..convertor.def[name].fire.."]"
				.."label[5,2.5;Energyblock & lamp ]"
				.."list[detached:"..name.."_convertor;charger;5,3;1,1;]"
				.."list[detached:"..name.."_convertor;fuel;6,3;1,1;]"
				.."button[7,3;1,1.5;Recharge;Recharge]"
				.."list[detached:"..name.."_convertor;ShipStage;5,2;1,1;]"
				.."tooltip[Recharge;Give the energy block charge]"
				--.."checkbox[3,3;ishighspeed;high speed mod;false;if selected the airship will fast lift and Consume ten times the energy.]"
				.."checkbox[3,3;ishighspeed;high speed;"..tostring(airship.highspeed).."]"
				
			if minetest.setting_getbool("unified_inventory_lite") then
				formspec = "background[0.06,0.49;7.92,7.52;convertor_ui_form.png]"
					.."label[0,0;Place the energy block to provide power for the airship  ]"
					.."list[detached:"..name.."_convertor;convertor;0,0.5;2,3;]"
					--.."image[2.5,0.25;2,4;"..convertor.textures[name].preview.."]"  --reserved 
					--.."label[5,0.5;Level: "..convertor.def[name].level.."]"
					--.."label[5,1;Heal:  "..convertor.def[name].heal.."]"
					--.."label[5,1.5;Fire:  "..convertor.def[name].fire.."]"
					.."label[5,2.5;Energyblock & lump ]"
					.."list[detached:"..name.."_convertor;charger;5,3;1,1;]"
					.."list[detached:"..name.."_convertor;fuel;6,3;1,1;]"
					.."button[7,3;1,1.5;Recharge;Recharge]"
					.."list[detached:"..name.."_convertor;ShipStage;5,2;1,1;]"
					.."tooltip[Recharge;Give the energy block charge]"
					--.."checkbox[3,3;ishighspeed;high speed mod;false;if selected the airship will fast lift and Consume ten times the energy.]"
					.."checkbox[3,3;ishighspeed;high speed;"..tostring(airship.highspeed).."]"
			end
			return {formspec=formspec}
		end,
	})
elseif minetest.get_modpath("inventory_enhanced") then
	inv_mod = "inventory_enhanced"
end


convertor.def = {
	state = 0,
	count = 0,
}
--[[
convertor.update_player_visuals = function(self, player)
	if not player then
		return
	end
	local name = player:get_player_name()
	if self.textures[name] then
		default.player_set_textures(player, {
			self.textures[name].skin,
			self.textures[name].convertor,
			self.textures[name].wielditem,
		})
	end
end --]]

convertor.set_player_convertor= function(self, player)
	local name, player_inv = convertor:get_valid_player(player, "[set_player_convertor]")
	if not name then
		return
	end
	local convertor_texture = "3d_convertor_trans.png"
	local convertor_level = 0
	local convertor_heal = 0
	local convertor_fire = 0
	local state = 0
	local items = 0
	local elements = {}
	local textures = {}
	local physics_o = {speed=1,gravity=1,jump=1}
	local material = {type=nil, count=1}
	local preview = convertor:get_preview(name) or "character_preview.png"
	for _,v in ipairs(self.elements) do
		elements[v] = false
	end
--[[for i=1, 6 do
		local stack = player_inv:get_stack("convertor", i)
		local item = stack:get_name()
		if stack:get_count() == 1 then
			local def = stack:get_definition()
			for k, v in pairs(elements) do
				if v == false then
					local level = def.groups["convertor_"..k]
					if level then
						local texture = item:gsub("%:", "_")
						table.insert(textures, texture..".png")
						preview = preview.."^"..texture.."_preview.png"
						convertor_level = convertor_level + level
						state = state + stack:get_wear()
						items = items + 1
						local heal = def.groups["convertor_heal"] or 0
						convertor_heal = convertor_heal + heal
						local fire = def.groups["convertor_fire"] or 0
						convertor_fire = convertor_fire + fire
						for kk,vv in ipairs(self.physics) do
							local o_value = def.groups["physics_"..vv]
							if o_value then
								physics_o[vv] = physics_o[vv] + o_value
							end
						end
						local mat = string.match(item, "%:.+_(.+)$")
						if material.type then
							if material.type == mat then
								material.count = material.count + 1
							end
						else
							material.type = mat
						end
						elements[k] = true
					end
				end
			end
		end   
	end   --]]
--	local ChargerStack = player_inv:get_stack("charger", i)
--		local item = stack:get_name()
		--if stack:get_count() == 1 then
		
		
	if minetest.get_modpath("shields") then
		convertor_level = convertor_level * 0.9
	end
	if material.type and material.count == #self.elements then
		convertor_level = convertor_level * 1.1
	end
	convertor_level = convertor_level * CONVERT_LEVEL_MULTIPLIER
	convertor_heal = convertor_heal * CONVERT_HEAL_MULTIPLIER
	if #textures > 0 then
		convertor_texture = table.concat(textures, "^")
	end
	local convertor_groups = {fleshy=100}
	if convertor_level > 0 then
		convertor_groups.level = math.floor(convertor_level / 20)
		convertor_groups.fleshy = 100 - convertor_level
	end
--	player:set_convertor_groups(convertor_groups)
--	player:set_physics_override(physics_o)
	self.textures[name].convertor= convertor_texture
	self.textures[name].preview = preview
	self.def[name].state = state
	self.def[name].count = items
	self.def[name].level = convertor_level
	self.def[name].heal = convertor_heal
	self.def[name].jump = physics_o.jump
	self.def[name].speed = physics_o.speed
	self.def[name].gravity = physics_o.gravity
	self.def[name].fire = convertor_fire
	self:update_player_visuals(player)   
end   

convertor.update_convertor= function(self, player)
	local name, player_inv, convertor_inv, pos = convertor:get_valid_player(player, "[update_convertor]")
	if not name then
		return
	end
	local hp = player:get_hp() or 0
	if CONVERT_FIRE_PROTECT == true then
		pos.y = pos.y + 1.4 -- head level
		local node_head = minetest.get_node(pos).name
		pos.y = pos.y - 1.2 -- feet level
		local node_feet = minetest.get_node(pos).name
		-- is player inside a hot node?
		for _, row in ipairs(CONVERT_FIRE_NODES) do
			-- check for fire protection, if not enough then get hurt
			if row[1] == node_head or row[1] == node_feet then
				if hp > 0 and convertor.def[name].fire < row[2] then
					hp = hp - row[3] * CONVERT_UPDATE_TIME
					player:set_hp(hp)
					break
				end
			end
		end
	end	
	if hp <= 0 or hp == self.player_hp[name] then
		return
	end
	if self.player_hp[name] > hp then
		local heal_max = 0
		local state = 0
		local items = 0
		for i=1, 6 do
			local stack = player_inv:get_stack("convertor", i)
			if stack:get_count() > 0 then
				local use = stack:get_definition().groups["convertor_use"] or 0
				local heal = stack:get_definition().groups["convertor_heal"] or 0
				local item = stack:get_name()
				stack:add_wear(use)
				convertor_inv:set_stack("convertor", i, stack)
				player_inv:set_stack("convertor", i, stack)
				state = state + stack:get_wear()
				items = items + 1
				if stack:get_count() == 0 then
					local desc = minetest.registered_items[item].description
					if desc then
						minetest.chat_send_player(name, "Your "..desc.." got destroyed!")
					end
					--self:set_player_convertor(player)
					convertor:update_inventory(player)
				end
				heal_max = heal_max + heal
			end
		end
		self.def[name].state = state
		self.def[name].count = items
		heal_max = heal_max * CONVERT_HEAL_MULTIPLIER
		if heal_max > math.random(100) then
			player:set_hp(self.player_hp[name])
			return
		end
	end
	self.player_hp[name] = hp
end
--reserved sample code for expand airship function 
convertor.get_player_skin = function(self, name)
	local skin = nil
	if skin_mod == "skins" or skin_mod == "simple_skins" then
		skin = skins.skins[name]
	elseif skin_mod == "u_skins" then
		skin = u_skins.u_skins[name]
	elseif skin_mod == "wardrobe" then
		skin = string.gsub(wardrobe.playerSkins[name], "%.png$","")
	end
	return skin or convertor.default_skin
end

convertor.get_preview = function(self, name)
	if skin_mod == "skins" then
		return convertor:get_player_skin(name).."_preview.png"
	end
end
--]]
convertor.get_convertor_formspec = function(self, name)
	if not convertor.textures[name] then
		minetest.log("error", "3d_convertor: Player texture["..name.."] is nil [get_convertor_formspec]")
		return ""
	end
	if not convertor.def[name] then
		minetest.log("error", "3d_convertor: Convertor  def["..name.."] is nil [get_convertor_formspec]")
		return ""
	end
	local formspec = convertor.formspec:gsub("player_name", name)
	formspec = formspec:gsub("convertor_preview", convertor.textures[name].preview)
	--formspec = formspec:gsub("convertor_charger", convertor.def[name].charger)

	return formspec
end

convertor.update_inventory = function(self, player)
	local name = convertor:get_valid_player(player, "[set_player_convertor]")
	if not name or inv_mod == "inventory_enhanced" then
		return
	end
	if inv_mod == "unified_inventory" then
		if unified_inventory.current_page[name] == "convertor" then
			unified_inventory.set_inventory_formspec(player, "convertor")
		end
	else
		local formspec = convertor:get_convertor_formspec(name)
		if inv_mod == "inventory_plus" then
			local page = player:get_inventory_formspec()
			if page:find("detached:"..name.."_convertor") then
				inventory_plus.set_inventory_formspec(player, formspec)
			end
		else
			player:set_inventory_formspec(formspec)
		end
	end
end

convertor.get_valid_player = function(self, player, msg)
	msg = msg or ""
	if not player then
		minetest.log("error", "3d_convertor: Player reference is nil "..msg)
		return
	end
	local name = player:get_player_name()
	if not name then
		minetest.log("error", "3d_convertor: Player name is nil "..msg)
		return
	end
	local pos = player:getpos()
	local player_inv = player:get_inventory()
	local convertor_inv = minetest.get_inventory({type="detached", name=name.."_convertor"})
	if not pos then
		minetest.log("error", "3d_convertor: Player position is nil "..msg)
		return
	elseif not player_inv then
		minetest.log("error", "3d_convertor: Player inventory is nil "..msg)
		return
	elseif not convertor_inv then
		minetest.log("error", "3d_convertor: Detached convertorinventory is nil "..msg)
		return
	end
	return name, player_inv, convertor_inv, pos
end
--[[  --sample code reserved for expand to airship Model
-- Register Player Model
default.player_register_model("3d_convertor_character.b3d", {
	animation_speed = 30,
	textures = {
		convertor.default_skin..".png",
		"3d_convertor_trans.png",
		"3d_convertor_trans.png",
	},
	animations = {
		stand = {x=0, y=79},
		lay = {x=162, y=166},
		walk = {x=168, y=187},
		mine = {x=189, y=198},
		walk_mine = {x=200, y=219},
		sit = {x=81, y=160},
	},
})  --]]
--Fuel recharge energy values define:
RechargeDef={{name="default:coal_lump",Charge=500},{name="default:copper_lump",Charge=2000},
{name="default:iron_lump",Charge=5000},{name="default:gold_lump",Charge=50000},
{name="default:mese_crystal",Charge=65535}}
-- Register Callbacks
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = convertor:get_valid_player(player, "[on_player_receive_fields]")
	if not name or inv_mod == "inventory_enhanced" then
		return
	end
	if inv_mod == "inventory_plus" and fields.convertor then
		local formspec = convertor:get_convertor_formspec(name)
		inventory_plus.set_inventory_formspec(player, formspec)
		return
	end
	if fields["Recharge"] then
		local playerinv=player:get_inventory()
		local convertor_inv = minetest.get_inventory({type="detached", name=name.."_convertor"})
		local ChargerStack=playerinv:get_stack("charger", 1)
		local FuelStack=playerinv:get_stack("fuel", 1)
		local FuelCOunt=FuelStack:get_count()
		if not FuelStack:is_empty() and not ChargerStack:is_empty() then 
			local wear=ChargerStack:get_wear()
			if wear==0 then return end
			local ItemName=FuelStack:get_name()
			local reChargeVale=0
			for k,v in pairs(RechargeDef) do
				if ItemName==v.name then
					reChargeVale=v.Charge
					break
				end
			end
			local meta=ChargerStack:get_metadata()
			local energyV=tonumber(meta)
			local newV= energyV+reChargeVale
			if newV>65535 then newV=65535 end
			meta=tostring(newV)
			ChargerStack:set_metadata(meta)
			ChargerStack:add_wear(-reChargeVale)
			convertor_inv:set_stack("charger", 1, ChargerStack)
			playerinv:set_stack("charger", 1, ChargerStack)
			FuelStack:set_count(FuelCOunt-1)
			convertor_inv:set_stack("fuel", 1, FuelStack)  --must reset convertor_inv and playerinv together.
			playerinv:set_stack("fuel", 1, FuelStack)
			else 
				return
		end
	
	end
	if fields["ishighspeed"] then 
		if airship.highspeed==false then
			airship.highspeed=true
		else airship.highspeed=false
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	default.player_set_model(player, "3d_convertor_character.b3d")--TODO:add airship 3d model
	local name = player:get_player_name()
	local player_inv = player:get_inventory()
	local convertor_inv = minetest.create_detached_inventory(name.."_convertor", {
		on_put = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, stack)
			--convertor:set_player_convertor(player)
			convertor:update_inventory(player)
			if listname=="convertor" or listname=="charger" and stack:get_name()=="airshipland:Energyblock" then
				local meta=stack:get_metadata()
				if string.len(meta)>0  then
					stack:set_wear(65535-tonumber(meta))  --reset wear to show amounts of energy  
				else 
					meta=tostring(65535-tonumber(stack:get_wear()))
					stack:set_metadata(meta)
				end	
				inv:set_stack(listname, index, stack)  --must reset convertor_inv and playerinv together.
				player_inv:set_stack(listname, index, stack)
			end
		end,
		on_take = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, nil)
			--convertor:set_player_convertor(player)
			convertor:update_inventory(player)
		end,
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			local stack = inv:get_stack(to_list, to_index)
			player_inv:set_stack(to_list, to_index, stack)
			player_inv:set_stack(from_list, from_index, nil)
			--convertor:set_player_convertor(player)
			convertor:update_inventory(player)
		end,
		allow_put = function(inv, listname, index, stack, player)
		local count=stack:get_count()
		local StackName=stack:get_name()
			if listname=="convertor" then
			return 1
			elseif listname=="charger" then 
				if stack:get_name()=="airshipland:Energyblock" and stack:get_wear()~=0 then
				return 1
				else return 0
				end
			elseif listname=="fuel" then 
				for k,v in pairs(RechargeDef) do
					if StackName==v.name then
					return count 
					end
					
				end
				return 0
			end	
		end,
		allow_take = function(inv, listname, index, stack, player)
			return stack:get_count()
		end,
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			local name=player:get_player_name()
			local inv=minetest.get_inventory({type="detached", name=name.."_convertor"}) 
			local stack = inv:get_stack(from_list, from_index)
			local count=stack:get_count()
		local StackName=stack:get_name()
			if to_list=="convertor" then
			return 1
			elseif to_list=="charger" then 
				if stack:get_name()=="airshipland:Energyblock" and stack:get_wear()~=0 then
				return 1
				else return 0
				end
			elseif to_list=="fuel" then 
				for k,v in pairs(RechargeDef) do
					if StackName==v.name then
						return count
					end
				end
				return 0	
			end	
		end,
	})
	
	if inv_mod == "inventory_plus" then
		inventory_plus.register_button(player,"convertor", "Convertor")
	end
	convertor_inv:set_size("convertor", 6)
	player_inv:set_size("convertor", 6)
	
	convertor_inv:set_size("charger", 1)
	player_inv:set_size("charger", 1)
	convertor_inv:set_size("fuel", 1)
	player_inv:set_size("fuel", 1)
	for i=1, 6 do
		local stack = player_inv:get_stack("convertor", i)
		convertor_inv:set_stack("convertor", i, stack)
	end	
	
	local stack = player_inv:get_stack("charger", 1)
	convertor_inv:set_stack("charger", 1, stack)
	local stack = player_inv:get_stack("fuel", 1)
	convertor_inv:set_stack("fuel", 1, stack)

	-- Legacy support, import player's convertor from old inventory format
	for _,v in pairs(convertor.elements) do
		local list = "convertor_"..v
		convertor_inv:add_item("convertor", player_inv:get_stack(list, 1))
		player_inv:set_stack(list, 1, nil)
	end
	-- TODO Remove this on the next version upate

	convertor.player_hp[name] = 0
	convertor.def[name] = {
		state = 0,
		count = 0,
		level = 0,
		heal = 0,
		jump = 1,
		speed = 1,
		gravity = 1,
		fire = 0,
	}
	convertor.textures[name] = {
		skin = convertor.default_skin..".png",
		convertor= "3d_convertor_trans.png",
		wielditem = "3d_convertor_trans.png",
		preview = convertor.default_skin.."_preview.png",
	}
	if skin_mod == "skins" then
		local skin = skins.skins[name]
		if skin and skins.get_type(skin) == skins.type.MODEL then
			convertor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "simple_skins" then
		local skin = skins.skins[name]
		if skin then
		    convertor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "u_skins" then
		local skin = u_skins.u_skins[name]
		if skin and u_skins.get_type(skin) == u_skins.type.MODEL then
			convertor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "wardrobe" then
		local skin = wardrobe.playerSkins[name]
		if skin then
			convertor.textures[name].skin = skin
		end
	end
	if minetest.get_modpath("player_textures") then
		local filename = minetest.get_modpath("player_textures").."/textures/player_"..name
		local f = io.open(filename..".png")
		if f then
			f:close()
			convertor.textures[name].skin = "player_"..name..".png"
		end
	end
	for i=1, CONVERT_INIT_TIMES do
		minetest.after(CONVERT_INIT_DELAY * i, function(player)
			--convertor:set_player_convertor(player)
			if not inv_mod then
				convertor:update_inventory(player)
			end
		end, player)
	end
	
	--     [get airship storge status]
	local pos=player:getpos()
	local Item=convertor_inv:get_stack("ShipStage", 1)
	if not Item:is_empty() then
		local meta=Item:get_metadata() 
		local driver=meta:get_string("driver")
		if not dirver then
			local restorepos=meta:get_string("pos")
			local nod=minetest.add_node(restorepos)
			--convertor_inv:set_stack("ShipStage", 1, nil)
			--player_inv:set_stack("ShipStage", 1, nil)
			print("airship restored")
		player:set_attach(nod, "", {x=0,y=0.2,z=0}, {x=0,y=0,z=0})
		end
	end
end)

if CONVERT_DROP == true or CONVERT_DESTROY == true then
	convertor.drop_convertor= function(pos, stack)
		local obj = minetest.add_item(pos, stack)
		if obj then
			obj:setvelocity({x=math.random(-1, 1), y=5, z=math.random(-1, 1)})
		end
	end
	minetest.register_on_dieplayer(function(player)
		local name, player_inv, convertor_inv, pos = convertor:get_valid_player(player, "[on_dieplayer]")
		if not name then
			return
		end
		local drop = {}
		for i=1, player_inv:get_size("convertor") do
			local stack = convertor_inv:get_stack("convertor", i)
			if stack:get_count() > 0 then
				table.insert(drop, stack)
				convertor_inv:set_stack("convertor", i, nil)
				player_inv:set_stack("convertor", i, nil)
			end
		end
		--convertor:set_player_convertor(player)
		if inv_mod == "unified_inventory" then
			unified_inventory.set_inventory_formspec(player, "craft")
		elseif inv_mod == "inventory_plus" then
			local formspec = inventory_plus.get_formspec(player,"main")
			inventory_plus.set_inventory_formspec(player, formspec)
		else
			convertor:update_inventory(player)
		end
		if CONVERT_DESTROY == false then
			minetest.after(CONVERT_BONES_DELAY, function()
				local node = minetest.get_node(vector.round(pos))
				if node then
					if node.name == "bones:bones" then
						local meta = minetest.get_meta(vector.round(pos))
						local owner = meta:get_string("owner")
						local inv = meta:get_inventory()
						for _,stack in ipairs(drop) do
							if name == owner and inv:room_for_item("main", stack) then
								inv:add_item("main", stack)
							else
								convertor.drop_convertor(pos, stack)
							end
						end
					end
				else
					for _,stack in ipairs(drop) do
						convertor.drop_convertor(pos, stack)
					end
				end
			end)
		end
	end)
end
minetest.register_on_leaveplayer(function(player)  --is no effect,how to do?
local name = player:get_player_name()
local convertor_inv = minetest.get_inventory({type="detached", name=name.."_convertor"})
local player_inv = player:get_inventory()
minetest.log("action","player on leaving.")
			convertor_inv:set_stack("convertor", 1, ItemStack("default:stone"))
			player_inv:set_stack("convertor", 1, ItemStack("default:stone"))
	if	default.player_attached[player:get_player_name()] then 
		local pos=player:getpos()
		local nod=minetest.get_node(pos)
		minetest.log("action","--prepare to store airship")
		if nod:get_name()=="airshipland:airship" then
			local meta=minetest.get_metadata(pos)
			--meta:set_string("owner",name)
			--meta:set_string("pos",tostring(pos))
			--meta:from_table( { driver=name,pos=tostring(pos) } )
			local def=nod:get_definition()
			local Item=ItemStack(def)
			--meta:set_string("doors_owner", pn)
			--local data
			--local data_str = minetest.serialize(data)
			--local data_str =""      --meta:set_string("infotext", "Chest");
			Item:set_metadata(meta)
			--stack:get_metadata()   new_stack:set_metadata(data_str)   local inv = meta:get_inventory()
			--meta:set_string("infotext", "Furnace is empty")
			--minetest.add_item(pos, "airshipland:airship")
			--minetest.item_place(itemstack, placer, pointed_thing, param2)
			convertor_inv:set_stack("convertor", 1, ItemStack("default:dirt"))
			player_inv:set_stack("convertor", 1, ItemStack("default:dirt"))
			convertor_inv:set_stack("ShipStage", 1, Item)
			player_inv:set_stack("ShipStage", 1, Item)
			minetest.remove_node(pos)
			minetest.log("action","---------------------------------airship was stored")
		end
	end
end)
--[[
minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time > CONVERT_UPDATE_TIME then
		for _,player in ipairs(minetest.get_connected_players()) do
			convertor:update_convertor(player)
		end
		time = 0
	end
end)   --]]


