local scene_objects = {}

function refresh()
    local found_objects = {}

    if not Scene then
        print("Scene is not available.")
        return
    end

    found_objects = Scene:get_all_objects()

    -- Sort by x position
    table.sort(found_objects, function(a, b)
        return a:get_position().x < b:get_position().x
    end)

    -- Update the global list (overwriting previous)
    scene_objects = found_objects
    print("\nRefresh complete. Found " .. #scene_objects .. " objects.")
end
refresh()

local was_open = false
function on_update()
    -- Make the main bar item and see if it's open
    local open, anchor = Client:main_bar_item({})

    if not open then
        was_open = false
        return
    end

    if was_open == false then
        was_open = true
        refresh()
    end

    -- Make the window
    Client:window("Scene Manifest", {
        anchor = anchor,
        title_bar = false,
        resizable = false,
        collapsible = false,
    }, function(ui)
        ui:heading("Scene Manifest")
        ui:separator()

        -- Header row with refresh button
        ui:horizontal(function(ui)
            ui:label("Refreshes the list of objects")
            if ui:button("Refresh"):clicked() then
                refresh()
            end
        end)

        ui:add_space(10)

        -- Display the list of objects
        if not scene_objects or #scene_objects == 0 then
            ui:label("No objects found.")
            return
        end
        ui:label("Found " .. #scene_objects .. " objects:")
        ui:separator()
        for i, obj in ipairs(scene_objects) do
            ui:horizontal(function(ui)

                -- Get name
                name = obj:get_name()
                if name == nil then
                    local shape = obj:get_shape()
                    local shape_type = shape.shape_type
                    name = "Unnamed " .. shape_type
                end

                -- Display the name
                ui:label(name)

                -- Make Go button
                if ui:button("Go"):clicked() then
                    Scene:get_host():set_camera_position(obj:get_position())
                end
            end)
        end
    end)
end
