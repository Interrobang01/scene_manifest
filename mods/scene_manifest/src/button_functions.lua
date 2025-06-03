local current_copy = nil

local function button_go(ui, obj)
    if ui:button("Go"):clicked() then
        Scene:get_host():set_camera_position(obj:get_position())
    end
end

local function button_copy(ui, obj)
    if ui:button("Copy"):clicked() then
        current_copy = obj
    end
    -- local _, new_value = ui:radio_value(current_value, tostring(obj.id), "Copy")
    -- if new_value ~= current_copy then
    --     current_copy = new_value
    -- end
end

return {
    button_go,
    button_copy,
    current_copy = function()
        return current_copy
    end,
}
