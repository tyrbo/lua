--[[
    General utility functions.

    This script greedily pollutes standard libraries and ideally functions 
    should follow the form:
        X.function(...) = X.function or function(...)

        end
--]]

function string.concat_dir(directory, file)
    directory = (directory and (directory .. "/")) or ""
    return directory .. file
end

--[[ Return true if the string starts with the specified prefix --]]
function string.startswith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

--[[
    Remove leading and trailing characters from a string according to some
    specified pattern "r" (defaulting to: %s+)
--]]
function string.trim(str, r)
   r = r or '%s+'
   return (string.gsub(string.gsub(str, '^' .. r, ''), r .. '$', ''))
end

--[[ Remove trailing characters from a string according to some specified pattern "r". --]]
function string.rtrim(str, r) return string.gsub(str, (r or '%s+') .. '$', '') end

--[[ Append a source array to a sink --]]
function table.append(sink, source)
    if sink ~= nil and source ~= nil then
        for i=1,#source do
            sink[#sink + 1] = source[i]
        end
    end
end

--[[ @SOURCE: http://lua-users.org/wiki/SortedIteration --]]
function table.orderedIndex(t)
    local orderedIndex = {}
    for key,_ in pairs(t) do table.insert(orderedIndex, key) end
    table.sort(orderedIndex)
    return orderedIndex
end

--[[ Invert the key & values within a table. --]]
function table.invert(t)
    local map = { }
    for key,val in pairs(t) do map[val] = key end
    return map
end

--[[ Generate a sequence of integers, corresponding to the shuffle index. --]]
function table.sequence(n)
    local t = { }
    for i=1,n do t[i] = i end
    return t
end

--[[ Clone & shuffle an array --]]
function table.shuffle(base)
    local t = { }
    for i=1,#base do
        t[#t + 1] = base[i]
    end

    local j
    local iterations = #t
    for i = iterations, 2, -1 do
        j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

--[[ Append a source array to a sink according to some order --]]
function table.ordered_append(sink, source, order)
    for i=1,#order do
        local value = source[order[i]]
        if string.trim(value) ~= "" then
            sink[#sink + 1] = value
        end
    end
end

--[[
    Shuffle an array until either a condition (possibly on that array) is true
    or a maximum number of iterations has occurred.
--]]
function table.iterative_shuffle(sequence, maxIterations, condition)
    maxIterations = maxIterations or 1000
    if sequence == nil or #sequence == 0 then
        return { }  -- Throw an error, technically invalid
    end

    local iterations = 0
    while not valid and iterations < maxIterations do
        iterations = iterations + 1
        local shuffle_next = table.shuffle(sequence)
        if condition(shuffle_next) then
            return shuffle_next
        end
    end

    return nil
end

--[[ Modified: http://lua-users.org/wiki/AlternativeGetOpt --]]
return function(arg, options)
    local tab = setmetatable({ }, { __index = {
        String = function(self, long, short, default)
            local o = self[long] or self[short] or default
            return (type(o) == "string" and o) or nil
        end,

        Int = function(self, long, short, default)
            local o = self[long] or self[short] or default
            return (type(o) == "number" and o) or tonumber(o)
        end,

        Bool = function(self, long, short, default)
            local o = self[long] or self[short] or default
            if type(o) == "boolean" then
                return o
            end
            return (tonumber(o) == 1) or (tonumber(o) == nil and default)
        end,
    }})

    for k, v in ipairs(arg) do
        if string.sub( v, 1, 2) == "--" then
            local x = string.find(v, "=", 1, true)
            if x then
                tab[string.sub(v, 3, x - 1)] = string.sub(v, x + 1)
            else
                tab[string.sub(v, 3)] = true
            end
        elseif string.sub(v, 1, 1) == "-" then
            local y = 2
            local l = string.len(v)
            while (y <= l) do
                local jopt = string.sub(v, y, y)
                if string.find(options, jopt, 1, true) then
                    if y < l then
                        tab[jopt] = string.sub(v, y + 1)
                        y = l
                    else
                        tab[jopt] = arg[k + 1]
                    end
                else
                    tab[jopt] = true
                end
                y = y + 1
            end
        end
    end
    return tab
end