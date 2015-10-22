-- arishipland mod verison 1.3 by eye_mine,QQ:11758980  IRC:eye_mine  (usual offline)
-- modified from default:boats & 3d-armor mod.and the file savedata.lua is copy from datastorag mod.
-- License: LGPLv2+
--about bug and fix history ,see readme.txt


modname="airshipland"
local protect_mod=nil
local datastorage_mod=nil
if minetest.get_modpath("landrush") then 
	protect_mod="landrush"
end
--if minetest.get_modpath("datastorage") then 
	--datastorage_mod="datastorage"   
	--else datastorage_mod="mysavedata"
--end
	--test was errored for datastorage use with waypoint.lua in unified_inventory  mod together ,
	--so current is not use datastorage mod.perhaps I don't know how to use datastorage mod.
datastorage_mod="mysavedata"  
if not protect_mod then 
minetest.log("error", "airshipLand: Did not find protect mod :landrush, airship can not go into effect .")
else 
	dofile(minetest.get_modpath(modname).."/airship.lua")
	dofile(minetest.get_modpath(modname).."/inv.lua")
	--if datastorage_mod=="datastorage" then
	
	--elseif datastorage_mod=="mysavedata" then
	dofile(minetest.get_modpath(modname).."/savedata.lua")
	--end
end
