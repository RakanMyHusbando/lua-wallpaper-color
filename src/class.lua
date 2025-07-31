--- Constructor for new Class
---@param base? table: Class to inherit from
---@return table: New class
local function class(base)
    local classInst = {}
    local mt = {}
    classInst.__index = classInst

    if base then
        setmetatable(classInst, { __index = base })
        classInst.__parent = function(instance, ...)
            if base.init then
                base.init(instance, ...)
            end
        end
    end

    mt.__call = function(_, ...)
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
