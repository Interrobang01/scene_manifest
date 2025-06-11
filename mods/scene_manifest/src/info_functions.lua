---- Requires----
local get_unique_id = require("@interrobang/scene_manifest/mods/scene_manifest/src/serialization.lua").get_unique_id

local info_shape = {}
info_shape.name = "Shape"
info_shape.set_value = function(self, obj, value)
    if obj:get_type() ~= "object" then
        return
    end
    obj:set_shape(value)
end
info_shape.get_visible = function(self, obj)
    return obj:get_type() == "object"
end
info_shape.get_value = function(self, obj)
    return obj:get_shape()
end
info_shape.display = function(self, ui, obj)
    local shape = self:get_value(obj)
    local shape_changed = false
    
    ui:vertical(function(ui)
        ui:label("Shape Type: " .. shape.shape_type)
        if shape.shape_type == "box" then
            local x = shape.size.x
            local y = shape.size.y

            ui:horizontal(function(ui)
                ui:label("Width:")
                local _, new_x = ui:text_edit_singleline(x)
                if tostring(new_x) ~= tostring(x) then
                    shape_changed = true
                    -- Set new position
                    shape.size.x = tonumber(new_x)
                end
            end)
            ui:horizontal(function(ui)
                ui:label("Height:")
                local _, new_y = ui:text_edit_singleline(y)
                if tostring(new_y) ~= tostring(y) then
                    shape_changed = true
                    -- Set new position
                    shape.size.y = tonumber(new_y)
                end
            end)
        elseif shape.shape_type == "circle" or shape.shape_type == "capsule" then
            local radius = shape.radius
            ui:horizontal(function(ui)
                ui:label("Radius:")
                local _, new_radius = ui:text_edit_singleline(radius)
                if tostring(new_radius) ~= tostring(radius) then
                    shape_changed = true
                    -- Set new position
                    shape.radius = tonumber(new_radius)
                end
            end)
            if shape.shape_type == "capsule" then
                local local_point_a = shape.local_point_a
                local local_point_b = shape.local_point_b
                ui:horizontal(function(ui)
                    ui:label("Point A:")
                    local _, new_x = ui:text_edit_singleline(local_point_a.x)
                    local _, new_y = ui:text_edit_singleline(local_point_a.y)
                    if tostring(new_x) ~= tostring(local_point_a.x) or tostring(new_y) ~= tostring(local_point_a.y) then
                        shape_changed = true
                        -- Set new position
                        shape.local_point_a = vec2(tonumber(new_x), tonumber(new_y))
                    end
                end)
                ui:horizontal(function(ui)
                    ui:label("Point B:")
                    local _, new_x = ui:text_edit_singleline(local_point_b.x)
                    local _, new_y = ui:text_edit_singleline(local_point_b.y)
                    if tostring(new_x) ~= tostring(local_point_b.x) or tostring(new_y) ~= tostring(local_point_b.y) then
                        shape_changed = true
                        -- Set new position
                        shape.local_point_b = vec2(tonumber(new_x), tonumber(new_y))
                    end
                end)
            end
        elseif shape.shape_type == "polygon" then
            ui:label("Polygon Points:")
            local to_remove = {}
            for i, point in ipairs(shape.points) do
                local x = point.x
                local y = point.y
                
                ui:horizontal(function(ui)
                    ui:label("Point " .. i .. ":")
                    local _, new_x = ui:text_edit_singleline(x)
                    local _, new_y = ui:text_edit_singleline(y)
                    if tostring(new_x) ~= tostring(x) or tostring(new_y) ~= tostring(y) then
                        shape_changed = true
                        -- Set new position
                        local new_position = vec2(tonumber(new_x), tonumber(new_y))
                        shape.points[i] = new_position
                    end
                    if ui:button("Delete"):clicked() then
                        shape_changed = true
                        to_remove[#to_remove+1] = i
                    end
                end)
            end
            -- Remove points
            for i = #to_remove, 1, -1 do
                table.remove(shape.points, to_remove[i])
            end
            -- Add point button
            if ui:button("Add Point"):clicked() then
                shape_changed = true
                table.insert(shape.points, vec2(0, 0))
            end
        end
    end)
    if shape_changed then
        -- Set new shape
        self:set_value(obj, shape)
    end
end

local info_position = {}
info_position.name = "Position"
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

    ui:vertical(function(ui)
        -- Set label
        ui:label("Position:")
    
        -- Set position field
        ui:horizontal(function(ui)
            ui:label("X:")
            local _, new_x = ui:text_edit_singleline(x)
            if tostring(new_x) ~= tostring(x) then
                -- Set new position
                position.x = tonumber(new_x)
                self:set_value(obj, position)
            end
        end)
        ui:horizontal(function(ui)
            ui:label("Y:")
            local _, new_y = ui:text_edit_singleline(y)
            if tostring(new_y) ~= tostring(y) then
                -- Set new position
                position.y = tonumber(new_y)
                self:set_value(obj, position)
            end
        end)
    end)
end

local info_orientation = {}
info_orientation.name = "Orientation"
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
info_velocity.name = "Velocity"
info_velocity.set_value = function(self, obj, value)
    if obj:get_type() ~= "object" then
        return
    end
    obj:set_linear_velocity(value)
end
info_velocity.get_visible = function(self, obj)
    local is_object = obj:get_type() == "object"
    if not is_object then
        return is_object
    end
    return (obj:get_linear_velocity():magnitude() > 0.01 or math.abs(obj:get_angular_velocity()) > 0.01)
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
info_material.name = "Material"
info_material.set_value = function(self, obj, value)
    if obj:get_type() ~= "object" then
        return
    end
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
    return (math.abs(friction - 0.3) > epsilon or math.abs(restitution - 0.3) > epsilon or math.abs(density - 1.0) > epsilon)
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
info_awake.name = "Awake"
info_awake.set_value = function(self, obj, value)
    if obj:get_type() ~= "object" then
        return
    end
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

local info_name = {}
info_name.name = "Name"
info_name.set_value = function(self, obj, value)
    obj:set_name(value)
end
info_name.get_visible = function(self, obj)
    return true
end
info_name.get_value = function(self, obj)
    return obj:get_name() or ""
end
info_name.display = function(self, ui, obj)
    local name = self:get_value(obj)
    ui:label("Name: ")
    local _, new_name = ui:text_edit_singleline(name)
    if tostring(new_name) ~= tostring(name) then
        self:set_value(obj, new_name)
    end
end

local info_color = {}
info_color.name = "Color"
info_color.set_value = function(self, obj, value)
    if obj:get_type() ~= "object" then
        return
    end
    obj:set_color(value)
end
info_color.get_visible = function(self, obj)
    return obj:get_type() == "object"
end
info_color.get_value = function(self, obj)
    return obj:get_color()
end
info_color.display = function(self, ui, obj)
    local color = self:get_value(obj)
    local r = string.format("%.2f", color.r)
    local g = string.format("%.2f", color.g)
    local b = string.format("%.2f", color.b)
    local a = string.format("%.2f", color.a)

    ui:vertical(function(ui)
        ui:label("Color: (" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")")
        ui:horizontal(function(ui)
            ui:label("R:")
            local _, new_r = ui:text_edit_singleline(r)
            if tostring(new_r) ~= tostring(r) then
                -- Set new position
                color.r = tonumber(new_r)
            end
        end)
        ui:horizontal(function(ui)
            ui:label("G:")
            local _, new_g = ui:text_edit_singleline(g)
            if tostring(new_g) ~= tostring(g) then
                -- Set new position
                color.g = tonumber(new_g)
            end
        end)
        ui:horizontal(function(ui)
            ui:label("B:")
            local _, new_b = ui:text_edit_singleline(b)
            if tostring(new_b) ~= tostring(b) then
                -- Set new position
                color.b = tonumber(new_b)
            end
        end)
        ui:horizontal(function(ui)
            ui:label("A:")
            local _, new_a = ui:text_edit_singleline(a)
            if tostring(new_a) ~= tostring(a) then
                -- Set new position
                color.a = tonumber(new_a)
            end
        end)
    end)

    self:set_value(obj, color) -- set the value to the object
end

local info_z_index = {}
info_z_index.name = "Z Index"
info_z_index.set_value = function(self, obj, value)
    if obj:get_type() ~= "object" then
        return
    end
    obj:set_z_index(value)
end
info_z_index.get_visible = function(self, obj)
    return obj:get_type() == "object"
end
info_z_index.get_value = function(self, obj)
    return obj:get_z_index()
end
info_z_index.display = function(self, ui, obj)
    local z_index = self:get_value(obj)
    ui:label("Z Index: ")
    local _, new_z_index = ui:text_edit_singleline(z_index)
    if tostring(new_z_index) ~= tostring(z_index) then
        self:set_value(obj, tonumber(new_z_index))
    end
end

local info_body_type = {}
info_body_type.name = "Body Type"
info_body_type.set_value = function(self, obj, value)
    if obj:get_type() ~= "object" then
        return
    end
    obj:set_body_type(value)
end
info_body_type.get_visible = function(self, obj)
    return obj:get_type() == "object"
end
info_body_type.get_value = function(self, obj)
    return obj:get_body_type()
end
info_body_type.display = function(self, ui, obj)
    local body_type = self:get_value(obj)
    local body_types = {BodyType.Dynamic, BodyType.Static, BodyType.Kinematic}

    -- Set label
    ui:label("Body Type: ")

    -- Make dropdown
    local _, new_body_type = ui:dropdown(get_unique_id(obj), body_type, body_types)
    if new_body_type ~= body_type then
        self:set_value(obj, new_body_type)
    end
end

local info_destroy = {}
info_destroy.destroy_confirmations = {}
info_destroy.name = "Destroy"
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
    local obj_id = obj.id
    -- If confirmation is pending for this object
    if self.destroy_confirmations[obj_id] then
        if ui:button("Confirm"):clicked() then
            self:set_value(obj, true)
            self.destroy_confirmations[obj_id] = nil
        end
        if ui:button("Cancel"):clicked() then
            self.destroy_confirmations[obj_id] = nil
        end
    else
        if ui:button("Destroy"):clicked() then
            self.destroy_confirmations[obj_id] = true
        end
    end
    -- Clean up if object is destroyed
    if obj:is_destroyed() then
        self.destroy_confirmations[obj_id] = nil
    end
end

return {
    info_position,
    info_orientation,
    info_velocity,
    info_shape,
    info_material,
    info_awake,
    --info_name, -- Changes the header name every time so it works badly
    info_body_type,
    info_z_index,
    info_color, -- we have a color editor for that
    info_destroy,
}
