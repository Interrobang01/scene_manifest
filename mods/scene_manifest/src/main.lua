--[[
Adds a UI to manage the contents of the scene.
--]]

---- Requires ----
local pagination = require("@interrobang/scene_manifest/mods/scene_manifest/src/pagination.lua")
local button_functions = require("@interrobang/scene_manifest/mods/scene_manifest/src/button_functions.lua")
local info_functions = require("@interrobang/scene_manifest/mods/scene_manifest/src/info_functions.lua")
local serialization = require("@interrobang/scene_manifest/mods/scene_manifest/src/serialization.lua")
local serialize_pin = serialization.serialize_pin
local deserialize_pin = serialization.deserialize_pin
local get_unique_id = serialization.get_unique_id






local show_objects = true
local show_attachments = false
local scene_objects = {}
local function hard_refresh()
    local found_entities = {}

    if not Scene then
        print("Can't refresh: Scene is not available.")
        return
    end

    if show_objects then
        local found_objects = Scene:get_all_objects()
        -- Sort by x position
        table.sort(found_objects, function(a, b)
            return a:get_position().x < b:get_position().x
        end)
        for _, obj in ipairs(found_objects) do
            table.insert(found_entities, obj)
        end
    end
    if show_attachments then
        local found_attachments = Scene:get_all_attachments()
        -- Sort by x position
        table.sort(found_attachments, function(a, b)
            return a:get_local_position().x < b:get_local_position().x
        end)
        for _, att in ipairs(found_attachments) do
            table.insert(found_entities, att)
        end
    end

    -- Update the global list (overwriting previous)
    scene_objects = found_entities

    -- Refresh pagination
    pagination:refresh(#scene_objects)
end
hard_refresh()

local function soft_refresh()
    -- This is a soft refresh, which just updates the pagination

    -- Clear destroyed objects
    local changed = false
    for i = #scene_objects, 1, -1 do
        local obj = scene_objects[i]
        if obj:is_destroyed() then
            table.remove(scene_objects, i)
            changed = true
        end
    end

    if changed then
        pagination:refresh(#scene_objects)
    end
end

-- Get the size description for a number or vector
local function get_name_size(number)
    if true then
        return "" -- No size description for now
    end
    local aspect_ratio_description = ""
    local aspect_ratio
    local size = ""
    if type(number) ~= "number" then -- if it's a vector
        aspect_ratio = math.max(number.x / number.y, number.y / number.x)
        number = number:magnitude()
    end

    if number < 0.01 then
        size = "Tiny "
    elseif number < 0.1 then
        size = "Small "
    elseif number < 5 then
        size = ""
    elseif number < 10 then
        size = "Big "
    elseif number < 15 then
        size = "Large "
    elseif number < 30 then
        size = "Huge "
    else
        size = "Massive "
    end

    if aspect_ratio then
        if aspect_ratio > 3 then
            aspect_ratio_description = "Thin "
        elseif aspect_ratio > 1.5 then
            aspect_ratio_description = "Narrow "
        end
    end

    return size..aspect_ratio_description
end

-- Get the color description for a color table
local function get_name_color(color)
    if not color then
        return ""
    end
    local h, s, v = color:get_hsv()
    local name = ""
    -- Grayscale check
    if s < 0.15 or v < 0.08 then
        if v < 0.08 then
            name = "Black "
        elseif v > 0.92 then
            name = "White "
        else
            name = "Gray "
        end
        return name
    end
    -- Light/Dark modifiers
    if v > 0.85 then
        name = "Light "
    elseif v < 0.25 then
        name = "Dark "
    end
    -- Color name by hue
    local hue = h
    if hue < 15 or hue >= 345 then
        name = name .. "Red "
    elseif hue < 40 then
        if v < 0.7 then
            name = name .. "Brown "
        else
            name = name .. "Orange "
        end
    elseif hue < 65 then
        name = name .. "Yellow "
    elseif hue < 170 then
        name = name .. "Green "
    elseif hue < 200 then
        name = name .. "Teal "
    elseif hue < 260 then
        name = name .. "Blue "
    elseif hue < 290 then
        name = name .. "Purple "
    elseif hue < 320 then
        name = name .. "Magenta "
    else
        name = name .. "Pink "
    end
    return name
end

-- Get the shape type name for an object shape
local function get_name_shape_type(shape, obj)
    local shape_type = shape.shape_type
    -- Capitalize
    shape_type = shape_type:sub(1, 1):upper() .. shape_type:sub(2)

    if shape_type == "Polygon" then
        -- Get bounding box
        local min_x, min_y, max_x, max_y = shape.points[1].x, shape.points[1].y, shape.points[1].x, shape.points[1].y
        for i = 2, #shape.points do
            local point = shape.points[i]
            min_x = math.min(min_x, point.x)
            min_y = math.min(min_y, point.y)
            max_x = math.max(max_x, point.x)
            max_y = math.max(max_y, point.y)
        end
        local width = max_x - min_x
        local height = max_y - min_y
        shape_type = get_name_size(vec2(width, height)) .. shape_type--#shape.points .. "-gon"
    elseif shape_type == "Circle" or shape_type == "Capsule" then
        shape_type = get_name_size(shape.radius) .. shape_type
    elseif shape_type == "Box" then
        shape_type = get_name_size(shape.size) .. shape_type
    end

    shape_type = get_name_color(obj:get_color()) .. shape_type
    return shape_type
end

-- Get the name of an object, or make up a name if it doesn't have one
-- Names must be unique because of dropdown rules
local function get_or_make_object_name(obj)
    local name = obj:get_name()
    if name == nil then
        if obj:get_type() == "object" then
            local shape = obj:get_shape()
            name = get_name_shape_type(shape, obj)
        else
            name = obj:get_type()
            name = name:sub(1, 1):upper() .. name:sub(2)
        end
    end
    name = name
    local id = "(" .. get_unique_id(obj) .. ")"-- .. string.rep("-", 20) -- For making it easier to click
    return name, id
end


---- Button Functions ----


    
local show_all = false

local info_functions_shown = {}
for i = 1, #info_functions do
    info_functions_shown[i] = true
end

-- Does the static UI at the top
local function add_window_header(ui)
    ui:heading("Scene Manifest")
    ui:separator()

    -- Header row with refresh button
    ui:horizontal(function(ui)
        if ui:button("Refresh"):clicked() then
            hard_refresh()
        end
    end)

    ui:add_space(10)
end

local pins = {}
local function add_pin_button(ui, obj, index)
    local serialized_pin = serialize_pin(obj, index)
    local response, new_checked = ui:toggle(pins[serialized_pin], "Pin")
    if response:clicked() then
        if new_checked then
            pins[serialized_pin] = true
        else
            pins[serialized_pin] = nil
        end
    end
end

local function paste_to_object(obj, func)
    if button_functions.current_copy() then
        if not button_functions.current_copy():is_destroyed() then
            local copy = func:get_value(button_functions.current_copy())
            func:set_value(obj, copy) -- paste
        end
    end
end

local function paste_to_all_selected(obj, func)
    if button_functions.current_copy() then
        if not button_functions.current_copy():is_destroyed() then
            
            local selected_objects = self:get_selected_objects()
            local selected_attachments = self:get_selected_attachments()
            local selected = selected_attachments
            for i = 1, #selected_objects do
                selected[#selected+1] = selected_objects[i]
            end

            RemoteScene:run{
                input = {
                    selected = selected,
                    func = func,
                },
                code = [[
                    local copy = input.func:get_value(button_functions.current_copy())
                    for i = 1, #input.selected do
                        local obj = input.selected[i]
                        if obj and not obj:is_destroyed() then
                            input.func:set_value(obj, copy)
                        end
                    end
                ]],
            }
        end
    end
end
local function paste_to_all_visible(obj, func)
    if button_functions.current_copy() then
        if not button_functions.current_copy():is_destroyed() then
            local copy = func:get_value(button_functions.current_copy())
            if show_objects then
                for _, selected in ipairs(Scene:get_all_objects()) do
                    func:set_value(selected, copy) -- paste
                end
            end
            if show_attachments then
                for _, selected in ipairs(Scene:get_all_attachments()) do
                    func:set_value(selected, copy) -- paste
                end
            end
        end
    end
end

local pasting_to_all_selected = false
local function add_paste_button(ui, obj, func)
    if ui:button("Paste"):clicked() then
        if pasting_to_all_selected then
            paste_to_all_visible(obj, func)--paste_to_all_selected(obj, func)
        else
            paste_to_object(obj, func)
        end
    end
end

local function add_info_function(ui, obj, func_index, func)
    ui:horizontal(function(ui)
        add_pin_button(ui, obj, func_index)
        add_paste_button(ui, obj, func)
        
        func:display(ui, obj)
    end)
end

local function add_info_functions(ui, obj)
    for index, func in ipairs(info_functions) do
        if pins[serialize_pin(obj, index)] or (info_functions_shown[index] and func:get_visible(obj)) then
            add_info_function(ui, obj, index, func)
        end
    end
end

local expand_all = false
local function add_window_object(ui, obj)
    if obj:is_destroyed() then
        return
    end
    ui:horizontal(function(ui)
        -- Get name
        local name, id = get_or_make_object_name(obj)
        
        -- Make info dropdown as name
        -- Or don't if expand_all is true
        if not expand_all then
            ui:collapsing_header(name .. " " .. id, function(ui)
                add_info_functions(ui, obj)
            end)
        else
            ui:label(name)
            ui:vertical(function(ui)
                add_info_functions(ui, obj)
            end)
        end

        -- Make buttons
        for _, func in ipairs(button_functions) do
            func(ui, obj)
        end
    end)
end

local function add_window_objects(ui, objs)
    local start_index, end_index = pagination:get_index_range()
    for i = start_index, end_index do
        local obj = objs[i]
        if obj and not obj:is_destroyed() then
            add_window_object(ui, obj) -- Call the function to add the object
        end
    end
end

local function add_window_decrement_page_button(ui)
    if ui:button("-"):clicked() then
        pagination:change_page(-1)
    end
end

local function add_window_increment_page_button(ui)
    if ui:button("+"):clicked() then
        pagination:change_page(1)
    end
end

local last_text = ""
local function add_window_page_text_input(ui)
    local _, new_text = ui:text_edit_singleline(last_text)
    local new_page = tonumber(new_text)
    new_page = pagination:clamp_page(new_page)
    if new_text ~= last_text and new_page and pagination:page_exists(new_page) then
        pagination.page = new_page
    end
    last_text = tostring(pagination.page)
end

local function add_first_options_horizontal(ui)
    ui:horizontal(function(ui)
        local response, new_expand_all = ui:toggle(expand_all, "Expand All")
        expand_all = new_expand_all

        local response, new_show_all = ui:toggle(show_all, "Always Show Properties")
        show_all = new_show_all
    end)
end

local function add_second_options_horizontal(ui)
    ui:horizontal(function(ui)
        local obj_response, new_show_objects = ui:toggle(show_objects, "Show Objects")
        show_objects = new_show_objects

        local att_response, new_show_attachments = ui:toggle(show_attachments, "Show Attachments")
        show_attachments = new_show_attachments

        if obj_response:clicked() or att_response:clicked() then
            hard_refresh()
        end
    end)
end

local function add_buttons_horizontal(ui)
    ui:horizontal(function(ui)
        if ui:button(pasting_to_all_selected and "Click Property to Paste" or "Paste to All Selected"):clicked() then
            pasting_to_all_selected = not pasting_to_all_selected
        end
    end)
end

local function add_info_function_toggle_collapsing_header(ui)
    ui:collapsing_header("Toggle Info", function(ui)
        for i = 1, #info_functions do
            local is_shown = info_functions_shown[i]
            local name = info_functions[i].name
            local response, new_is_shown = ui:toggle(is_shown, name)
            if response:clicked() then
                info_functions_shown[i] = new_is_shown
            end
        end
    end)
end

local function add_window_objects_header(ui, objs_length)
    -- Pagination horizontal
    ui:horizontal(function(ui)
        if pagination:max_pages() > 1 then
            add_window_decrement_page_button(ui)
            ui:label("Page ")
            add_window_page_text_input(ui)
            ui:label(" of " .. pagination:max_pages())
            add_window_increment_page_button(ui)
        end

        ui:label("Found " .. #scene_objects .. " object" .. (#scene_objects == 1 and "" or "s"))

    end)

    -- Options horizontal
    add_first_options_horizontal(ui)
    -- Second options horizontal
    add_second_options_horizontal(ui)
    -- Paste To Selected horizontal
    add_buttons_horizontal(ui)
    -- Info function toggle dropdown
    add_info_function_toggle_collapsing_header(ui)

    ui:separator()
end

local function add_window_objects_empty_header(ui)
    ui:label("No objects found.")
    ui:separator()
end

local function add_window_objects_pins(ui)
    local pinned_something = false
    for pin, pinned in pairs(pins) do
        if pinned then
            local type, id, index = table.unpack(deserialize_pin(pin))
            local obj
            if type == "object" then
                obj = Scene:get_object(tonumber(id))
            elseif type == "attachment" then
                obj = Scene:get_attachment(tonumber(id))
            end
            if obj then
                pinned_something = true
                add_info_function(ui, obj, index, info_functions[tonumber(index)]) -- Call the function to add the object property
            else
                --pins[pin] = nil -- Unpin if the object is destroyed
            end
        else
            pins[pin] = nil -- Clear this pin if it's not pinned
        end
    end

    if pinned_something then
        ui:separator()
    end
end

local function add_window(ui)
    if not Scene then
        ui:label("Scene Manifest is only available to the host.")
        return
    end

    add_window_header(ui)

    -- Display the list of objects
    add_window_objects_header(ui, #scene_objects)
    if scene_objects and #scene_objects > 0 then
        add_window_objects_pins(ui)
        ui:scroll_area({}, function(ui)
            add_window_objects(ui, scene_objects)
        end)
    end
end

local was_open = false
function on_update()
    -- Make the main bar item and see if it's open
    local open, anchor = Client:main_bar_item({
        name = "Scene Manifest",
        icon = "@interrobang/scene_manifest/mods/scene_manifest/assets/clipboard.png"
    })

    -- Don't draw if not open
    if not open then
        was_open = false
        return
    end

    -- Refresh on open
    if was_open == false then
        was_open = true
        hard_refresh()
    else
        soft_refresh()
    end

    -- Make the window
    Client:window("Scene Manifest", {
        anchor = anchor,
        title_bar = false,
        resizable = true,
        collapsible = false,
    }, add_window) -- add_window is the function that draws the UI
end
