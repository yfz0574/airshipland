local function is_water(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "water") ~= 0
end
local function can_reach(pos,name)
	if is_inlandowner(pos,name) then
		return true
	else 
		return false
	end
end
 function is_inlandowner(pos,name)
	if name==landrush.get_owner(pos) then

		return true
	else 
		return false
	end
end

local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i / math.abs(i)
	end
end


local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end


local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

--
-- airship entity
--

airship = {
	physical = true,
	collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
	visual = "mesh",
	mesh = "airship.obj",
	textures = {"default_mese_block.png"},

	driver = nil,
	highspeed=false,
	v = 0,
	last_v = 0,
	removed = false
}


function airship.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	local name = clicker:get_player_name()
	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
		default.player_attached[name] = false
		default.player_set_animation(clicker, "stand" , 30)
		local pos = clicker:getpos()
		pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
		minetest.after(0.1, function()
			clicker:setpos(pos)
		end)
	elseif not self.driver then
		self.driver = clicker
		clicker:set_attach(self.object, "",
			{x = 0, y = 11, z = -3}, {x = 0, y = 0, z = 0})
		default.player_attached[name] = true
		minetest.after(0.2, function()
			default.player_set_animation(clicker, "sit" , 30)
		end)
		self.object:setyaw(clicker:get_look_yaw() - math.pi / 2)
	end
end


function airship.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal = 1})
	if staticdata then
		self.v = tonumber(staticdata)
	end
	self.last_v = self.v
end


function airship.get_staticdata(self)
	return tostring(self.v)
end


function airship.on_punch(self, puncher, time_from_last_punch,
		tool_capabilities, direction)
	if not puncher or not puncher:is_player() or self.removed then
		return
	end
	if self.driver and puncher == self.driver then
		self.driver = nil
		puncher:set_detach()
		default.player_attached[puncher:get_player_name()] = false
	end
	if not self.driver then
		self.removed = true
		-- delay remove to ensure player is detached
		minetest.after(0.1, function()
			self.object:remove()
		end)
		if not minetest.setting_getbool("creative_mode") then
			puncher:get_inventory():add_item("main", "airshipland:airship")
		end
	end
end
--constant
Normal=1      --Normal status
LessEmergy=2  --power is less,will auto crash land
OutofLand=3   --there is not in owner land

local status=nil
local WARNINGTIME=0  --warnning for crash land time count
function airship.on_step(self, dtime)
	local name
	
	if self.driver then
		name=self.driver:get_player_name()
		local player_inv = self.driver:get_inventory()
		local inv=minetest.get_inventory({type="detached", name=name.."_convertor"}) 
		local pos=self.object:getpos()
		local uppos,downpos={x=pos.x,y=pos.y+1,z=pos.z},{x=pos.x,y=pos.y-1,z=pos.z}
		local newpos

			if inv:contains_item("convertor", "airshipland:Energyblock") then
				local size=inv:get_size("convertor")
				local haveEmergy=false
				local usenumber=nil
				for i=1, 6 do
					local stack=inv:get_stack("convertor", i)
					local 	wear=stack:get_wear()	
					local StackName=stack:get_name()
					if StackName=="airshipland:Energyblock" and wear<65500 then --wear max is 65535
						haveEmergy=true 
						local itemdef=minetest.registered_items[StackName]
						local uses=itemdef.groups.uses
						local downnode=minetest.get_node(downpos)
						if downnode.name=="air" then
							--if not minetest.setting_getbool("creative_mode") then  --creative mode is not need this airship ??
							local energyV=tonumber(stack:get_metadata())
							if self.highspeed==true then 
								energyV=energyV-(65535 /uses *1*10)
								stack:add_wear(65535 /uses *1*10)   --can use at about 3.5 minutes.
							else 
								energyV=energyV-(65535 /uses *1)
								stack:add_wear(65535 /uses *1) --can use at about 35 minutes.
							end
							stack:set_metadata(tostring(energyV))
							inv:set_stack("convertor", i, stack)
							player_inv:set_stack("convertor", i, stack)
							usenumber=i
							break
						end
					end
				
				end
				if  haveEmergy== false then
					status=LessEmergy
					local downnode=minetest.get_node(downpos)
					if downnode.name=="air" then
						WARNINGTIME=WARNINGTIME+1
						if WARNINGTIME==1 or WARNINGTIME==330 then  --Tip at first and after 10 second.
							minetest.chat_send_player(name,"WARNING!The airship emergy is less,if very less,It will auto crash landed.")
						end
					else WARNINGTIME=0
					end
					
				return 
				else status=Normal
				end
				
			else 
				status=LessEmergy
				local node=minetest.get_node(downpos)
				if node.name=="air" then
					WARNINGTIME=WARNINGTIME+1
					if WARNINGTIME==1 or WARNINGTIME==330 then 
						minetest.chat_send_player(name,"WARNING!The airship emergy is less,if very less,It will auto crash landed.")
					end
				else WARNINGTIME=0
				end   
			end 
		
		self.v = get_v(self.object:getvelocity()) * get_sign(self.v)
		
		--if status==LessEmergy or status==OutofLand then --excute crash land
		if status==LessEmergy then --excute crash land
		local node=minetest.get_node(downpos)
			if node.name=="air" then
			newpos={x=pos.x,y=pos.y-0.1,z=pos.z}
			self.object:setpos(newpos)
			else WARNINGTIME=0
			end   
		return end 
		
		local ctrl = self.driver:get_player_control()
		local yaw = self.object:getyaw()
		local frontpos,backpos
		if yaw <=45  or yaw >315 then           --facedir is north
		frontpos={x=pos.x,y=pos.y,z=pos.z+1}
		backpos={x=pos.x,y=pos.y,z=pos.z-1}
		elseif yaw <=135 then 					--facedir is west
		frontpos={x=pos.x-1,y=pos.y,z=pos.z}
		backpos={x=pos.x+1,y=pos.y,z=pos.z}
		elseif yaw <=225 then 					--facedir is south
		frontpos={x=pos.x,y=pos.y,z=pos.z-1}
		backpos={x=pos.x,y=pos.y,z=pos.z+1}
		elseif yaw <=315 then  					--facedir is east
		frontpos={x=pos.x+1,y=pos.y,z=pos.z}
		backpos={x=pos.x-1,y=pos.y,z=pos.z}	
		end
		
		if ctrl.up and can_reach(frontpos,name) then
			if self.highspeed==true then 
				self.v = self.v + 1 
			else
				self.v = self.v + 0.1
			end
		elseif ctrl.down and can_reach(backpos,name) then
			if self.highspeed==true then 
				self.v = self.v - 1   
			else
				self.v = self.v - 0.1
			end
		elseif not can_reach(frontpos,name) then
			minetest.chat_send_player(name,"Go to area is not your land, the airship can down only")
		end
		
		if ctrl.jump and can_reach(uppos,name) then
			local node=minetest.get_node(uppos)
			if node.name=="air" then
				if self.highspeed==true then 
					newpos={x=pos.x,y=pos.y+1,z=pos.z}
				else newpos={x=pos.x,y=pos.y+0.2,z=pos.z}
				end
				self.object:setpos(newpos)
			end
		elseif ctrl.sneak then
			local node=minetest.get_node(downpos)
			if node.name=="air" then
				if self.highspeed==true then 
					newpos={x=pos.x,y=pos.y-1,z=pos.z}
				else newpos={x=pos.x,y=pos.y-0.2,z=pos.z}
				end
			self.object:setpos(newpos)
			end
			elseif not can_reach(frontpos,name) then
			minetest.chat_send_player(name,"Go to area is not your land, the airship can down only")
		end
		
		
		if ctrl.left then
			if self.v < 0 then
				self.object:setyaw(yaw - (1 + dtime) * 0.03)
			else
				self.object:setyaw(yaw + (1 + dtime) * 0.03)
			end
		elseif ctrl.right then
			if self.v < 0 then
				self.object:setyaw(yaw + (1 + dtime) * 0.03)
			else 
				self.object:setyaw(yaw - (1 + dtime) * 0.03)
			end
		elseif not can_reach(frontpos,name) then
			minetest.chat_send_player(name,"Go to area is not your land, the airship can down only")
		end
	--end
		local velo = self.object:getvelocity()
		if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
			self.object:setpos(self.object:getpos())
			return
		end
		local s = get_sign(self.v)
		self.v = self.v - 0.02 * s
		if s ~= get_sign(self.v) then
			self.object:setvelocity({x = 0, y = 0, z = 0})
			self.v = 0
			return
		end
		if self.highspeed==true then 
			if math.abs(self.v) > 25 then
				self.v = 25 * get_sign(self.v)
			end
		else
			if math.abs(self.v) > 4.5 then
				self.v = 4.5 * get_sign(self.v)
			end
		end

		local p = self.object:getpos()
		p.y = p.y - 0.5
		local new_velo = {x = 0, y = 0, z = 0}
		local new_acce = {x = 0, y = 0, z = 0}
		if is_inlandowner(self.object:getpos(),name) then
					new_acce = {x = 0, y = 0, z = 0}
				if math.abs(self.object:getvelocity().y) < 1 then
					local pos = self.object:getpos()
					pos.y = math.floor(pos.y) + 0.5
					self.object:setpos(pos)
					new_velo = get_velocity(self.v, self.object:getyaw(), 0)
				else
					new_velo = get_velocity(self.v, self.object:getyaw(),
					self.object:getvelocity().y)
					self.object:setpos(self.object:getpos())
				end
	
		elseif not is_water(p) then
		local nodedef = minetest.registered_nodes[minetest.get_node(p).name]
		if (not nodedef) or nodedef.walkable then
			self.v = 0
			new_acce = {x = 0, y = 1, z = 0}
		else
			new_acce = {x = 0, y = -9.8, z = 0}
		end
		new_velo = get_velocity(self.v, self.object:getyaw(),
			self.object:getvelocity().y)
		self.object:setpos(self.object:getpos())
		p.y = p.y + 1
		if is_water(p) then
			local y = self.object:getvelocity().y
			if y >= 4.5 then
				y = 4.5
			elseif y < 0 then
				new_acce = {x = 0, y = 20, z = 0}
			else
				new_acce = {x = 0, y = 5, z = 0}
			end
			new_velo = get_velocity(self.v, self.object:getyaw(), y)
			self.object:setpos(self.object:getpos())
		else
			new_acce = {x = 0, y = 0, z = 0}
			if math.abs(self.object:getvelocity().y) < 1 then
				local pos = self.object:getpos()
				pos.y = math.floor(pos.y) + 0.5
				self.object:setpos(pos)
				new_velo = get_velocity(self.v, self.object:getyaw(), 0)
			else
				new_velo = get_velocity(self.v, self.object:getyaw(),
					self.object:getvelocity().y)
				self.object:setpos(self.object:getpos())
			end
		end
	end
	self.object:setvelocity(new_velo)
	self.object:setacceleration(new_acce)
	end
end

minetest.register_entity("airshipland:airship", airship)


minetest.register_craftitem("airshipland:airship", {
	description = "airship",
	inventory_image = "airship_inventory.png",--"^default_meselamp.png",
	wield_image = "airship_wield.png",
	wield_scale = {x = 2, y = 2, z = 1},
	liquids_pointable = true,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node"  then
			return
		end
		pointed_thing.under.y = pointed_thing.under.y + 0.5
		minetest.add_entity(pointed_thing.under, "airshipland:airship")
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})


minetest.register_craft({
	output = "airshipland:airship",
	recipe = {
		{"",           "",           ""          },
		{"default:mese_crystal", "landrush:landclaim", "default:mese_crystal"},
		{"default:mese_crystal", "default:mese_crystal", "default:mese_crystal"},
	},
})

minetest.register_tool("airshipland:Energyblock", {
	description = "Energyblock",
	inventory_image = "Energyblock.png",
	wield_image = "Energyblock.png",
	groups = {uses=65535},
	on_use = function(...) do return end end
})

minetest.register_craft({
	output = "airshipland:Energyblock",
	recipe = {
		{"default:mese_crystal","default:mese_crystal","default:mese_crystal"},
		{"default:mese_crystal",  "",                   "default:mese_crystal"},
		{"default:mese_crystal", "default:mese_crystal", "default:mese_crystal"},
	},
})

