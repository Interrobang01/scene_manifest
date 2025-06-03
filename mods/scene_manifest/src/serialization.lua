---- Requires----
local iblib_split = require("@interrobang/scene_manifest/mods/scene_manifest/src/iblib.lua")


-- Serializing pins is needed so the set of pins can't have duplicate elements
local function serialize_pin(obj, index)
    local type = obj:get_type()
    local id = obj.id
    return type..'-'..id..'-'..index
end
local function deserialize_pin(pin)
    return iblib_split(pin, "-")
end

-- Gets a string ID unique for both objects and attachments
-- Used for dropdowns and stuff that need unique IDs
local function get_unique_id(obj)
    local type = obj:get_type()
    local id = obj.id
    return type:sub(1, 1)..id
end

return {
    serialize_pin = serialize_pin,
    deserialize_pin = deserialize_pin,
    get_unique_id = get_unique_id,
}
