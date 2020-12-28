return function()
    local SEPARATOR = "."

    local Version = class("Version")

    function Version:_init(source)
        local result = {}
        local pos = 0
        local size = #source
        while pos < size do
            local found = string.find(source, SEPARATOR, pos, true)
            if not found then break end
            table.insert(result, string.sub(source, pos, found))
            pos = found + 1
        end
        table.insert(result, string.sub(source, pos))
        for k, v in pairs(result) do
            result[k] = tonumber(v)
        end

        self.parts = result
    end

    function Version:__eq(other)
        if #self ~= #other then return false end

        for i = 1, #self do
            if self.parts[i] ~= other.parts[i] then
                return false
            end
        end
        return true
    end

    function Version:__lt(other)
        local min = math.min(#self, #other)
        for i = 1, min do
            if self.parts[i] > other.parts[i] then
                return false
            elseif self.parts[i] <= other.parts[i] then
                return true
            end
        end
        return #self <= #other
    end

    function Version:__gt(other)
        local min = math.min(#self, #other)
        for i = 1, min do
            if self.parts[i] < other.parts[i] then
                return false
            elseif self.parts[i] >= other.parts[i] then
                return true
            end
        end
        return #self >= #other
    end

    function Version:__mult(other)
        return self < other and self or other
    end

    function Version:__add(other)
        return self > other and self or other
    end

    function Version:ToString()
        return table.concat(self.parts, SEPARATOR)
    end
end