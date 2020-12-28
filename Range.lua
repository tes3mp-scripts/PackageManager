return function (Version)
    local Range = class("Range")

    local SEPARATOR = " "

    Range.NOTHING = -1
    Range.ANY = 0
    Range.EQUALS = 1
    Range.UNDER = 2
    Range.ABOVE = 3
    Range.BETWEEN = 4

    local operatorMap = {
        ["*"] = Range.ANY,
        ["#"] = Range.NOTHING,
        ["="] = Range.EQUALS,
        ["<"] = Range.UNDER,
        [">"] = Range.ABOVE,
        ["~"] = Range.BETWEEN
    }

    function Range:_init(type, a, b)
        self.type = type
        self.a = a
        self.b = b
    end

    function Range.Parse(source)
        local operator = string.sub(source, 1, 1)
        local type = operatorMap[operator]
        if not type then
            error ("Unknown range operator!")
        end
        local a
        local b
        if type == Range.BETWEEN then
            local pos = string.find(source, SEPARATOR)
            a = Version(string.sub(source, 2, pos - 1))
            b = Version(string.sub(source, pos + 1))
        elseif type ~= Range.NOTHING then
            a = Version(string.sub(source, 2))
        end
        return Range(type, a, b)
    end

    function Range:ToString()
        local operator
        for ch, v in pairs(operatorMap) do
            if v == self.type then
                operator = ch
                break
            end
        end
        if self.type == Range.NOTHING or self.type == Range.ANY then
            return operator
        elseif self.type == Range.BETWEEN then
            return table.concat{operator, self.a.ToString(), " ", self.b.ToString()}
        else
            return operator .. self.a.ToString()
        end
    end

    local testMap = {
        [Range.ANY] = function(r, v) return true end,
        [Range.NOTHING] = function(r, v) return false end,
        [Range.EQUALS] = function(r, v) return r.a == v end,
        [Range.UNDER] = function(r, v) return v < r.a end,
        [Range.ABOVE] = function(r, v) return v > r.a end,
        [Range.BETWEEN] = function(r, v) return r.a < v and v < r.b end
    }
    function Range:Test(version)
        return testMap[self.type](self, version)
    end

    local intersectMap = {
        [Range.EQUALS] = {
            [Range.EQUALS] = function(r1, r2)
                if r1.a == r2.a then
                    return Range(Range.EQUALS, r1.a)
                else
                    return Range(Range.NOTHING)
                end
            end,
            [Range.UNDER] = function(r1, r2)
                if r1.a < r2.a then
                    return Range(Range.EQUALS, r1.a)
                else
                    return Range(Range.NOTHING)
                end
            end,
            [Range.ABOVE] = function(r1, r2)
                if r1.a > r2.a then
                    return Range(Range.EQUALS, r1.a)
                else
                    return Range(Range.NOTHING)
                end
            end,
            [Range.BETWEEN] = function(r1, r2)
                if r2.a < r1.a and r1.a < r2.b then
                    return Range(Range.EQUALS, r1.a)
                else
                    return Range(Range.NOTHING)
                end
            end
        },
        [Range.UNDER] = {
            [Range.UNDER] = function(r1, r2)
                return Range(Range.EQUALS, r1.a * r2.a)
            end,
            [Range.ABOVE] = function(r1, r2)
                if r2.a == r1.a then
                    return Range(Range.EQUALS, r1.a)
                elseif r2.a < r1.a then
                    return Range(Range.BETWEEN, r2.a, r1.a)
                else
                    return Range(Range.NOTHING)
                end
            end,
            [Range.BETWEEN] = function(r1, r2)
                if r1.a == r2.a then
                    return Range(Range.EQUALS, r1.a)
                elseif r1.a > r2.a then
                    return Range(Range.BETWEEN, r2.a, r1.a * r2.b)
                else
                    return Range(Range.NOTHING)
                end
            end
        },
        [Range.ABOVE] = {
            [Range.ABOVE] = function(r1, r2)
                return Range(Range.EQUALS, r1.a + r2.a)
            end,
            [Range.BETWEEN] = function(r1, r2)
                if r1.a == r2.b then
                    return Range(Range.EQUALS, r1.a)
                elseif r1.a < r2.b then
                    return Range(Range.BETWEEN, r1.a + r2.a, r2.b)
                else
                    return Range(Range.NOTHING)
                end
            end
        },
        [Range.BETWEEN] = {
            [Range.BETWEEN] = function(r1, r2)
                if r1.b == r2.a then
                    return Range(Range.EQUALS, r1.b)
                elseif r1.a == r2.b then
                    return Range(Range.EQUALS, r1.a)
                elseif r2.a < r1.b and r2.b > r1.a then
                    return Range(Range.BETWEEN, r1.a + r2.a, r1.b * r2.b)
                else
                    return Range(Range.NOTHING)
                end
            end
        }
    }

    function Range:__mult(other)
        local r1 = self
        local r2 = other
        if r1.type > r2.type then
            r1, r2 = r2, r1
        end
        if r1.type == Range.NOTHING then
            return Range(Range.NOTHING)
        elseif r1.type == Range.ANY then
                return Range(Range.ANY)
        else
            return intersectMap[r1.type][r2.type](r1, r2)
        end
    end

    return Range
end