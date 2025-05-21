local function iblib_split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Serializing pins is needed so the set of pins can't have duplicate elements
local function serialize_pin(obj, index)
    local type = obj:get_type()
    local id = obj.id
    return type..'-'..id..'-'..index
end
local function deserialize_pin(pin)
    return iblib_split(pin, "-")
end

---- Pagination ----
local pagination = {}
pagination.page = 1
pagination.page_size = 10
pagination.element_number = 0
pagination.refresh = function(self, element_number)
    self.element_number = element_number
    self.page = self:clamp_page(self.page)
end
pagination.get_index_range = function(self)
    local start_index = (self.page - 1) * self.page_size + 1
    local end_index = math.min(start_index + self.page_size - 1, self.element_number)
    
    return start_index, end_index
end
pagination.page_exists = function(self, page)
    return page > 0 and page <= math.ceil(self.element_number / self.page_size)
end
pagination.max_pages = function(self)
    return math.ceil(self.element_number / self.page_size)
end
pagination.change_page = function(self, amount)
    if self:page_exists(self.page + amount) then
        self.page = self.page + amount
    end
end
pagination.clamp_page = function(self, page)
    if (not page) or page < 1 then
        page = 1
    elseif page > self:max_pages() then
        page = self:max_pages()
    end
    return page
end

local show_objects = true
local show_attachments = false
local scene_objects = {}
local function refresh()
    local found_entities = {}

    if not Scene then
        print("Scene is not available.")
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
refresh()

-- Get the name of an object, or make up a name if it doesn't have one
-- Names must be unique because of dropdown rules
local function get_or_make_object_name(obj)
    local function get_size(number)
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

    local function get_color(color)
        local color_name = ""
        if not color then
            return ""
        end

        -- Check brightness
        local brightness = (color.r + color.g + color.b) / 3
        if brightness < 0.3 then
            color_name = "Dark "
        elseif brightness > 0.7 then
            color_name = "Light "
        end

        -- Find dominant color
        if color.r > color.g and color.r > color.b then
            color_name = color_name .. "Red "
        elseif color.g > color.r and color.g > color.b then
            color_name = color_name .. "Green "
        elseif color.b > color.r and color.b > color.g then
            color_name = color_name .. "Blue "
        elseif color.r > 0.5 and color.g > 0.5 then
            color_name = color_name .. "Yellow "
        elseif color.g > 0.5 and color.b > 0.5 then
            color_name = color_name .. "Cyan "
        elseif color.r > 0.5 and color.b > 0.5 then
            color_name = color_name .. "Purple "
        else
            color_name = color_name .. "Gray "
        end

        return color_name
    end

    local name = obj:get_name()
    if name == nil then
        if obj:get_type() == "object" then
            local shape = obj:get_shape()
            local shape_type = shape.shape_type
            
            -- Capitalize
            shape_type = shape_type:sub(1, 1):upper() .. shape_type:sub(2)

            -- Make a name based on the shape type
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
                shape_type = get_size(vec2(width, height)) .. #shape.points .. "-gon"
            end
            if shape_type == "Circle" or shape_type == "Capsule" then
                shape_type = get_size(shape.radius) .. shape_type
            end
            if shape_type == "Box" then
                shape_type = get_size(shape.size) .. shape_type
            end

            shape_type = get_color(obj:get_color()) .. shape_type

            name = shape_type
        else
            name = obj:get_type()
            name = name:sub(1, 1):upper() .. name:sub(2)
        end
    end
    name = name .. " (" .. obj.id .. ")"
    return name
end


---- Button Functions ----

local function button_go(ui, obj)
    if ui:button("Go"):clicked() then
        Scene:get_host():set_camera_position(obj:get_position())
    end
end

local current_copy = nil
local function button_copy(ui, obj)
    if ui:button("Copy"):clicked() then
        current_copy = obj
    end
    -- local _, new_value = ui:radio_value(current_value, tostring(obj.id), "Copy")
    -- if new_value ~= current_copy then
    --     current_copy = new_value
    -- end
end

local button_functions = {
    button_go,
    button_copy,
}
    
---- Info Functions ----
local show_all = false

local info_shape = {}
info_shape.set_value = function(self, obj, value)
    obj:set_shape(value)
end
info_shape.get_visible = function(self, obj)
    return obj:get_type() == "object"
end
info_shape.get_value = function(self, obj)
    return obj:get_shape()
end
info_shape.display = function(self, ui, obj)
    ui:label("Shape Type: " .. obj:get_shape().shape_type)
end

local info_position = {}
info_position.set_value = function(self, obj, value)
    local is_object = obj:get_type() == "object"
    if is_object then
        obj:set_position(value)
    else
        obj:set_local_position(value)
    end
end
info_position.get_visible = function(self, obj)
    return true
end
info_position.get_value = function(self, obj)
    local is_object = obj:get_type() == "object"
    if is_object then
        return obj:get_position()
    else
        return obj:get_local_position()
    end
end
info_position.display = function(self, ui, obj)
    local position = self:get_value(obj)
    -- Format position
    local x = string.format("%.1f", position.x)
    local y = string.format("%.1f", position.y)

    -- Set label
    ui:label("Position: (" .. x .. ", " .. y .. ")")

    -- Set position field
    local _, new_x = ui:text_edit_singleline(x)
    local _, new_y = ui:text_edit_singleline(y)
    if new_x ~= x or new_y ~= y then
        -- Set new position
        local new_position = vec2(tonumber(new_x), tonumber(new_y))
        self:set_value(obj, new_position)
    end
end

local info_orientation = {}
info_orientation.set_value = function(self, obj, value)
    local is_object = obj:get_type() == "object"
    if is_object then
        obj:set_angle(value)
    else
        obj:set_local_angle(value)
    end
end
info_orientation.get_visible = function(self, obj)
    return true
end
info_orientation.get_value = function(self, obj)
    local is_object = obj:get_type() == "object"
    if is_object then
        return obj:get_angle()
    else
        return obj:get_local_angle()
    end
end
info_orientation.display = function(self, ui, obj)
    local angle = self:get_value(obj)

    -- Choose word based on angle
    local orientation = ""
    if angle < math.pi/4 and angle > -math.pi/4 then
        orientation = "Up"
    elseif angle < 3*math.pi/4 and angle > math.pi/4 then
        orientation = "Left"
    elseif angle < -3*math.pi/4 or angle > 3*math.pi/4 then
        orientation = "Down"
    else
        orientation = "Right"
    end

    -- Set label
    ui:label("Facing: " .. orientation .. " (" .. string.format("%.1f", angle) .. ")")

    -- Make rotation buttons
    if ui:button("Rotate CCW"):clicked() then
        self:set_value(obj, self:get_value(obj) - math.pi/2)
    end
    if ui:button("Rotate CW"):clicked() then
        self:set_value(obj, self:get_value(obj) + math.pi/2)
    end
end

local info_velocity = {}
info_velocity.set_value = function(self, obj, value)
    obj:set_linear_velocity(value)
end
info_velocity.get_visible = function(self, obj)
    local is_object = obj:get_type() == "object"
    if not is_object then
        return is_object
    end
    return show_all or (obj:get_linear_velocity():magnitude() > 0.01 or math.abs(obj:get_angular_velocity()) > 0.01)
end
info_velocity.get_value = function(self, obj)
    return obj:get_linear_velocity()
end
info_velocity.display = function(self, ui, obj)
    local velocity = obj:get_linear_velocity()
    local x = string.format("%.1f", velocity.x)
    local y = string.format("%.1f", velocity.y)
    ui:label("Linear Velocity: (" .. x .. ", " .. y .. ")")
    
    local angular_velocity = obj:get_angular_velocity()
    local a = string.format("%.1f", angular_velocity)
    ui:label("Angular Velocity: " .. a)
end

local info_material = {}
info_material.set_value = function(self, obj, value)
    obj:set_friction(value[1])
    obj:set_restitution(value[2])
    obj:set_density(value[3])
end
info_material.get_visible = function(self, obj)
    local is_object = obj:get_type() == "object"
    if not is_object then
        return is_object
    end
    local friction = obj:get_friction()
    local restitution = obj:get_restitution()
    local density = obj:get_density()
    local epsilon = 0.0001
    return show_all or (math.abs(friction - 0.3) > epsilon or math.abs(restitution - 0.3) > epsilon or math.abs(density - 1.0) > epsilon)
end
info_material.get_value = function(self, obj)
    return {obj:get_friction(), obj:get_restitution(), obj:get_density()}
end
info_material.display = function(self, ui, obj)
    local friction = obj:get_friction()
    local restitution = obj:get_restitution()
    local density = obj:get_density()
    ui:vertical(function(ui)
        ui:label("Friction: " .. string.format("%.2f", friction))
        ui:label("Restitution: " .. string.format("%.2f", restitution))
        ui:label("Density: " .. string.format("%.2f", density))
    end)
end

local info_awake = {}
info_awake.set_value = function(self, obj, value)
    obj:set_is_awake(value)
end
info_awake.get_visible = function(self, obj)
    return obj:get_type() == "object"
end
info_awake.get_value = function(self, obj)
    return obj:get_is_awake()
end
info_awake.display = function(self, ui, obj)
    local response, new_awake = ui:toggle(self:get_value(obj), "Awake")
    if response:clicked() then
        self:set_value(obj, new_awake)
    end
end

local info_destroy = {}
info_destroy.set_value = function(self, obj, value)
    if value then
        obj:destroy()
    end
end
info_destroy.get_visible = function(self, obj)
    return true
end
info_destroy.get_value = function(self, obj)
    return obj:is_destroyed()
end
info_destroy.display = function(self, ui, obj)
    if ui:button("Destroy"):clicked() then
        self:set_value(obj, true)
    end
end

local info_functions = {
    info_position,
    info_orientation,
    info_velocity,
    info_shape,
    info_material,
    info_awake,
    info_destroy,
}

-- Does the static UI at the top
local function add_window_header(ui)
    ui:heading("Scene Manifest")
    ui:separator()

    -- Header row with refresh button
    ui:horizontal(function(ui)
        if ui:button("Refresh"):clicked() then
            refresh()
        end
    end)

    ui:add_space(10)
end

local pins = {}
local function add_pin_button(ui, obj, index)
    local serialized_pin = serialize_pin(obj, index)
    local _, new_checked = ui:toggle(pins[serialized_pin], "Pin")
    if new_checked == false then
        pins[serialized_pin] = nil
    else
        pins[serialized_pin] = true
    end
end

local function add_paste_button(ui, obj, func)
    if ui:button("Paste"):clicked() and current_copy then
        if not current_copy:is_destroyed() then
            local copy = func:get_value(current_copy)
            func:set_value(obj, copy) -- paste
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
    for index, func in pairs(info_functions) do
        if pins[serialize_pin(obj, index)] or func:get_visible(obj) then
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
        -- Make buttons
        for _, func in ipairs(button_functions) do
            func(ui, obj)
        end

        -- Get name
        local name = get_or_make_object_name(obj)
        
        -- Make info dropdown as name
        -- Or don't if expand_all is true
        if not expand_all then
            ui:collapsing_header(name, function(ui)
                add_info_functions(ui, obj)
            end)
        else
            ui:label(name)
            ui:vertical(function(ui)
                add_info_functions(ui, obj)
            end)
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
    ui:horizontal(function(ui)
        local response, new_expand_all = ui:toggle(expand_all, "Expand All");
        expand_all = new_expand_all

        local response, new_show_all = ui:toggle(show_all, "Always Show Properties");
        show_all = new_show_all
    end)
    -- Second options horizontal
    ui:horizontal(function(ui)
        local obj_response, new_show_objects = ui:toggle(show_objects, "Show Objects");
        show_objects = new_show_objects

        local att_response, new_show_attachments = ui:toggle(show_attachments, "Show Attachments");
        show_attachments = new_show_attachments

        if obj_response:clicked() or att_response:clicked() then
            refresh()
        end
    end)
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
            local type, id, index = deserialize_pin(pin)
            local obj = Scene:get_object(tonumber(id))
            if obj then
                pinned_something = true
                add_info_function(ui, obj, index, info_functions[tonumber(index)]) -- Call the function to add the object property
            else
                pins[pin] = nil -- Unpin if the object is destroyed
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
