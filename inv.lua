CONVERT_MOD_NAME=modname

--TODO:inventory_plus mod support is not completed.some commented code is reserved sample for expand,
--Don't delete.  
local skin_mod = nil  
local inv_mod = nil
local S = unified_inventory.gettext
local modpath = minetest.get_modpath(CONVERT_MOD_NAME)
local worldpath = minetest.get_worldpath()
--if not minetest.get_modpath("moreores") then
	--CONVERT_MATERIALS.mithril = nil
--end
--if not minetest.get_modpath("ethereal") then
	--CONVERT_MATERIALS.crystal = nil
--end
--
--override hot nodes so they do not hurt player anywhere but mod
--if CONVERT_FIRE_PROTECT == true then
--	for _, row in ipairs(CONVERT_FIRE_NODES) do
--		if minetest.registered_nodes[row[1]] then
--			minetest.override_item(row[1], {damage_per_second = 0})
--		end
--	end
--end

local time = 0

convertor= {
	player_hp = {},
	attchedairship={pos={x=0,y=0,z=0}},   --To prevent the player from the off-line after the loss of the ship maneuvering state
	elements = {"WaterSpriteOrb", "FireSpriteOrb", "WoodSpriteOrb", "EarthSpriteOrb","MetalSpriteOrb"},  --reserved for expand
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
	local name = player:get_player_name()
	local airshipdata=airshipdata.get(player:get_player_name(), "airshipland")
	if airshipdata.attched then
		local airshippos=airshipdata.pos
		if not airshippos then
			airshippos=player:getpos()
		end
		--minetest.item_place(itemstack, player, {type="node", under=airshippos, above=airshippos})
		local airship 
		if airshipdata.removed then
			airship = minetest.add_entity(airshippos, "airshipland:airship")
			airshipdata.removed=false
		end
			if airship then
				local luaentity=airship:get_luaentity()
				luaentity.driver=player
				player:set_attach(luaentity.object, "",{x = 0, y = 11, z = -3}, {x = 0, y = 0, z = 0})
				default.player_attached[name] = true
				airshipdata.removed=false
				minetest.after(0.2, function()
					default.player_set_animation(player, "sit" , 30)
					luaentity.object:setyaw(player:get_look_yaw() - math.pi / 2)
				end)
			end
	end
	
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
	
end)
minetest.register_on_leaveplayer(function(player)  --is no effect,how to do?
	local name = player:get_player_name()
	--print("begin leaving!!!")
	if	default.player_attached[player:get_player_name()] then 
		print("player alse attached.")
		local pos=player:getpos()
		local parent=player:get_attach()  --  : returns parent, bone, position, rotation or nil if it isn't attached
		local luaentity
		if parent then
			luaentity=parent:get_luaentity()
			print("while player leaving ,also attached is "..luaentity.name)
			local airshipdata=airshipdata.get(player:get_player_name(), "airshipland")
			if luaentity.name=="airshipland:airship" then
				airshipdata.attched=true
				airshipdata.pos=pos
				parent:remove()
				airshipdata.removed=true
			end
		end	
	end
	
	--airshipdata.save(name)
end)

