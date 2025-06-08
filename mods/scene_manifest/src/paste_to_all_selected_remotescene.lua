local functions = require("@interrobang/scene_manifest/mods/scene_manifest/src/info_functions.lua")
local func = functions[input.func_index]
local copy = func:get_value(input.current_copy)
for i = 1, #input.selected do
    local obj = input.selected[i]
    if obj and not obj:is_destroyed() then
        func:set_value(obj, copy)
    end
end
