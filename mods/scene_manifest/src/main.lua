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

-- Get the name of an object, or make up a name if it doesn't have one
local function get_or_make_object_name(obj)
    local name = obj:get_name()
    if name == nil then
        local shape = obj:get_shape()
        local shape_type = shape.shape_type
        name = "Unnamed " .. shape_type
    end
    return name
end

---- Button Functions ----

local function button_go(ui, obj)
    Scene:get_host():set_camera_position(obj:get_position())
end

local button_functions = {
    ["Go"] = button_go,
}
    

-- Does the static UI at the top
local function add_window_header(ui)
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
end

local function add_window_objects_header(ui, objs_length)
    ui:label("Found " .. #scene_objects .. " objects:")
    ui:separator()
end

local function add_window_object(ui, obj)
    ui:horizontal(function(ui)
        -- Get name
        name = get_or_make_object_name(obj)
    
        -- Display the name
        ui:label(name)
    
        -- Make buttons
        for name, func in pairs(button_functions) do
            if ui:button(name):clicked() then
                func(ui, obj)
            end
        end
    end)
end

local function add_window_objects(ui, objs)
    for i, obj in ipairs(objs) do
        add_window_object(ui, obj) -- Call the function to add the object
    end
end

local function add_window_objects_empty_header(ui)
    ui:label("No objects found.")
    ui:separator()
end

local function add_window(ui)
    add_window_header(ui)

    -- Display the list of objects
    if scene_objects and #scene_objects > 0 then
        add_window_objects_header(ui, #scene_objects)
        add_window_objects(ui, scene_objects)
    else
        add_window_objects_empty_header(ui) -- Say that there are no objects
    end
end

local was_open = false
function on_update()
    -- Make the main bar item and see if it's open
    local open, anchor = Client:main_bar_item({})

    -- Don't draw if not open
    if not open then
        was_open = false
        return
    end

    -- Refresh on open
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
    }, add_window) -- add_window is the function that draws the UI
end
