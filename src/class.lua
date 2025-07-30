--- Constructor for new Class
---@param base? table: Class to inherit from
---@return table: New class
local function class(base)
    local classInst = {}
    local mt = {}
    classInst.__index = classInst
    if base then
        setmetatable(classInst, { __index = base })
    end
    mt.__call = function(self, ...)
        local instance = setmetatable({}, classInst)
        if instance.init then
            instance:init(...)
        end
        return instance
    end

    setmetatable(classInst, mt)

    return classInst
end

return class
