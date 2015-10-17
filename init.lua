-- arishipland mod by eye_mine,QQ:11758980  IRC:eye_mine  (usual offline)
-- modified from default:boats & 3d-armor mod.
-- License: LGPLv2+
-- knowed question: 1.player offline then online,player will fall from airship. 2. fast lift showed stat perhaps error.
modname="airshipland"
local protect_mod=nil
if minetest.get_modpath("landrush") then 
	protect_mod="landrush"
end
if not protect_mod then 
minetest.log("error", "airshipLand: Did not find protect mod :landrush, airship can not go into effect .")
else 
	dofile(minetest.get_modpath(modname).."/airship.lua")
	dofile(minetest.get_modpath(modname).."/inv.lua")
end
