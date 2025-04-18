--[[ Forward declare functions if needed by environment, otherwise definitions are below ]]
-- function refresh() end
-- function on_update() end

local scene_objects = {}

-- Function to refresh the objects
function refresh()
    print("Refreshing object list...")

    local found_objects = {}
    found_objects = Scene:get_all_objects()

    -- Update the global list (overwriting previous)
    scene_objects = found_objects

    print("\nRefresh complete. Found " .. #all_scripts .. " scripts.")

end -- end of refresh() function

