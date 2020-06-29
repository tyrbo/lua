local HeaderData = require('opcodes.opcodes')
local ParseOptions = require('opcodes.utils')
local options = ParseOptions(arg, "")

function PrintUsage()
    print("sort [--output] [--seed] [--iters] [--help | h]")
    print("\n[INPUT]")
    print("--output: header files output location (optional, default '.')")
    print("\n[OPTIONS]")
    print("--seed: seed to initialize the pseudo-random number generator")
    print("--iters: maximum number of invalid-shuffles before throwing an error")
end

local output = "."
local shuffleIters = 25
if options:Bool("help", "h", false) then
    PrintUsage()
    return
end

output = options:String("output", "", output)
shuffleIters = math.abs(options:Int("iters", "", shuffleIters))
if options:Int("seed", "", nil) then
    math.randomseed(options:Int("seed", "", nil))
end

--[[
    Util Functions
--]]

--[[ OpCode is wrapped in a preprocessor directive --]]
local function IsPreprocessorDirective(s)
    return string.startswith(s, "#if")
end

--[[ Ensure all arrays are of the same size (or is empty) --]]
local function SanitizeLength(arrays, errLabel)
    local len = 0
    for _,t in ipairs(arrays) do
        if len == 0 then
            len = #t
        elseif #t ~= 0 and #t ~= len then
            error(("Invalid CodeBlock '%s' %d %d"):format(errLabel, len, #t));
        end
        len = #t
    end
    return len
end

--[[
    Return each codetype array for a given group, e.g., (Groupings.Instructions,
    "Instructions") should return its arrays for "Codes" and "Names".
--]]
local function EachCodeTypeArray(groupenum, codetype)
    local keys = nil
    local arrays = { }
    if HeaderData.Structure[codetype].Substructs then -- Has substructures
        keys = table.orderedIndex(groupenum) -- deterministic order
        for i=1,#keys do
            arrays[#arrays + 1] = groupenum[keys[i]]
        end
    else -- Is a string array
        arrays[#arrays + 1] = groupenum
    end
    return arrays,keys
end

--[[ Return each codetype array for a given category: "Unshared", "Shared" --]]
local function EachStringArray(data, category)
    local arrays = { }
    for _,s in pairs(data[category]) do
        for _,v in ipairs(EachCodeTypeArray(data.Enums[s], s)) do
            arrays[#arrays + 1] = v
        end
    end
    return arrays
end

--[[
    Insert a function into an integer sequence that when called, expands its
    Group sub-shuffling into a sink array.
--]]
local function GroupInsert(shuffle, data, codetype, index)
    table.insert(shuffle, index, function(sink, substruct)
        local enum = data.Enums[codetype]
        local eshuff = data.unsharedSequences[codetype] or data.sharedSequence
        if not eshuff or not enum then
            return sink -- Grouping doesn't have sorting of his codetype
        elseif HeaderData.Structure[codetype].Substructs then -- Has substructures
            table.ordered_append(sink, enum[substruct], eshuff)
        else -- Simple array
            table.ordered_append(sink, enum, eshuff)
        end

        --[[
            Handle KInstructions/KModes edge-cases: the general rule is that
            KInstructions always proceed their counter-part. However, that
            condition (prepend/append) can be randomized if need be. However,
            beware of OneToOne codetypes (e.g., make prepend/append global).
        --]]
        local hasKMode = (data.sharedLookup.KModes or data.unsharedLookup.KModes)
        local hasKInst = (data.sharedLookup.KInstructions or data.unsharedLookup.KInstructions)
        if (codetype == "Instructions" and hasKInst) or (codetype == "Modes" and hasKMode) then
            local kstruct = "K" .. codetype
            local kenum = data.Enums[kstruct]

            if HeaderData.Structure[kstruct].Substructs then -- Has substructures
                table.ordered_append(sink, kenum[substruct], eshuff)
            else -- Simple array
                table.ordered_append(sink, kenum, eshuff)
            end
        end
    end)
end

--[[
    Append the contents of one group to the *END* of another group. This
    function is an over-generalized append unary-to-binary function.
--]]
local function GroupAppend(sink, source)
    local sourceSequence = source.sharedSequence
    local sinkSequence = sink.sharedSequence
    local sinkLength = #sinkSequence
    for i=1,#sourceSequence do -- Append shared sequence
        sinkSequence[#sinkSequence + 1] = sourceSequence[i] + sinkLength
    end

    for _,codetype in pairs(HeaderData.Enums) do
        local sinkEnum = sink.Enums[codetype]
        local sourceEnum = source.Enums[codetype]

        local bs = (sink.unsharedSequences[codetype] or sink.sharedSequence)
        local us = (source.unsharedSequences[codetype] or source.sharedSequence)

        if sourceEnum and not sinkEnum then -- doesn't exist in sink, copy ref.
            sink.Enums[codetype] = sourceEnum
            sink.Unshared[#sink.Unshared + 1] = codetype

            -- Caching structures
            sink.unsharedLookup[codetype] = sink.Unshared[#sink.Unshared]
            sink.unsharedSequences[codetype] = us
        --[[
            Doesn't exist in source, ensure shared-sequence length is still
            satisfied
        --]]
        elseif sinkEnum and not sourceEnum then
            if sink.sharedLookup[codetype] then
                for _,v in pairs(EachCodeTypeArray(sinkEnum, codetype)) do
                    for i=1,#us do
                        v[#v + 1] = ""
                    end
                end
            end
        elseif sinkEnum and sourceEnum then
            if sink.unsharedSequences[codetype] then  -- Unshared append
                local sinkUSequence = sink.unsharedSequences[codetype]
                local sinkULength = #sinkUSequence
                for i=1,#us do
                    sinkUSequence[#sinkUSequence + 1] = us[i] + sinkULength
                end
            end

            local sinkArr = EachCodeTypeArray(sinkEnum, codetype)
            local sourceArr = EachCodeTypeArray(sourceEnum, codetype)
            for i=1,#sinkArr do
                for j=1,#sourceArr[i] do
                    sinkArr[i][#(sinkArr[i]) + 1] = sourceArr[i][j]
                end
            end
        else
            error(("Invalid Structure: %s"):format(codetype))
        end
    end
end

-------------------------------------------------------------------------------
---------------------------------- Groupings ----------------------------------
-------------------------------------------------------------------------------
local Unsorted = HeaderData.Groupings.Unsorted

--[[ Operate on groupings by sorted key-list for deterministic reasons --]]
local sorted = { }
for k,data in pairs(HeaderData.Groupings) do
    sorted[#sorted + 1] = k

    -- Create some cached fields for each grouping
    data.sharedLookup = table.invert(data.Shared)
    data.unsharedLookup = table.invert(data.Unshared)
    data.sharedSequence = nil
    data.unsharedSequences = { }

    -- Sanitize: (1) Ensure subtables are of the same size; (2) Ensure all
    -- shared enums have their tables/subtables of the same size. Using an empty
    -- string to denote empty space (trimmed on output)
    local len = SanitizeLength(EachStringArray(data, "Shared"), k)
    data.sharedSequence = table.sequence(len) -- Cache the shuffle size

    -- Sanitize: (2) Structures that must remain one-to-one, ensure groupings
    -- handle both cases & have the same number of elements.
    for _,codetype in pairs(data.Shared) do
        if HeaderData.Structure.OneToOne[codetype] then
            for oneone,_ in pairs(HeaderData.Structure.OneToOne[codetype]) do
                if not data.sharedLookup[oneone] then
                    error(("%s missing shared one-to-one: %s"):format(k, oneone))
                end
            end
        end
    end

    -- Compute the lengths of the each unshared enumerated type
    for _,codetype in pairs(data.Unshared) do
        if HeaderData.Structure.OneToOne[codetype] and k ~= "Unsorted" then
            error(("[%s] Cannot have unshared one-to-one structure: %s"):format(k, codetype or ""))
        end

        local enum = data.Enums[codetype]
        local len = SanitizeLength(EachCodeTypeArray(enum, codetype), k)
        data.unsharedSequences[codetype] = table.sequence(len) -- Cache the shuffle size
    end
end
table.sort(sorted)

--[[ Locally sort each grouping --]]
for i=1,#sorted do
    local data = HeaderData.Groupings[sorted[i]]
    if data.Local then
        -- Shuffle shared enumerations
        local shuffle = table.iterative_shuffle(data.sharedSequence, shuffleIters, function(s)
            local valid = true
            for _,t in ipairs(EachStringArray(data, "Shared")) do
                valid = valid
                    and string.trim(t[s[1]]) ~= "" -- Empty strings cannot lead
                    and not IsPreprocessorDirective(t[s[1]])
                    and not IsPreprocessorDirective(t[s[#s]])
                    and data.Validate(data, s)
            end
            return valid
        end)

        if shuffle then
            data.sharedSequence = shuffle
        else
            error(("Could not find valid shuffling: %s"):format(sorted[i]))
        end

        -- Shuffle unshared enumerations
        for _,codetype in pairs(data.Unshared) do
            local shuffle = table.iterative_shuffle(data.unsharedSequences[codetype], shuffleIters, function(s)
                local valid = true
                for _,t in pairs(EachCodeTypeArray(data.Enums[codetype], codetype)) do
                    valid = valid
                        and string.trim(t[s[1]]) ~= ""
                        and not IsPreprocessorDirective(t[s[1]])
                        and not IsPreprocessorDirective(t[s[#s]])
                end
                return valid
            end)

            if shuffle then
                data.unsharedSequences[codetype] = shuffle
            else
                error(("Could not find valid shuffling: %s"):format(sorted[i]))
            end
        end
    end
end

--[[ Append Unary to Binary --]]
GroupAppend(HeaderData.Groupings.Binary, HeaderData.Groupings.Unary)

--[[ For each enumerated types select insertion points --]]
sorted = table.shuffle(sorted) -- Shuffle names for ordering

local processed = { }
for _,codetype in pairs(HeaderData.Enums) do
    if processed[codetype] or codetype == "KInstructions" or codetype == "KModes" then
        -- Continue

    --[[
        Structures that must remain one-to-one for the duration of the
        shuffling. The shared sequence is duplicated and given the same
        insertion point therefore expansion should be the same.
    --]]
    elseif HeaderData.Structure.OneToOne[codetype] then
        for otherType,_ in pairs(HeaderData.Structure.OneToOne[codetype]) do
            local shuffle = Unsorted.unsharedSequences[otherType]
            for i=1,#sorted do
                -- Insertion point for each group
                if sorted[i] ~= "Unsorted" and sorted[i] ~= "Unary" then
                    GroupInsert(shuffle, HeaderData.Groupings[sorted[i]], otherType, #shuffle + 1)
                end
            end
            processed[otherType] = true
        end
    else
        local shuffle = Unsorted.unsharedSequences[codetype]
        for i=1,#sorted do -- Insertion point for each group
            if sorted[i] ~= "Unsorted" and sorted[i] ~= "Unary" then
                local index = 1 + math.random(0, #shuffle)
                GroupInsert(shuffle, HeaderData.Groupings[sorted[i]], codetype, index)
            end
        end
    end
    processed[codetype] = true
end

--[[ Build results table --]]
HeaderData.Rules = { }
for _,codetype in pairs(HeaderData.Enums) do
    HeaderData.Rules[codetype] = { }
end

for _,codetype in pairs(HeaderData.Enums) do
    local sequence,keys = EachCodeTypeArray(Unsorted.Enums[codetype], codetype)
    local shuffle = Unsorted.unsharedSequences[codetype]

    local result = { } -- Remap to key/value
    for i=1,#sequence do
        local expansion = { }
        for j=1,#shuffle do
            if type(shuffle[j]) == "function" then
                shuffle[j](expansion, (keys and keys[i]) or nil)
            else
                expansion[#expansion + 1] = sequence[i][shuffle[j]]
            end
        end

        if keys then
            result[keys[i]] = expansion
        else
            assert(#sequence == 1, "Key Length")
            result = expansion
        end
    end

    HeaderData.Structure[codetype].Output(result, output)
    Unsorted.Enums[codetype] = result -- New enum is expanded enum
end

for i=1,#sorted do -- Insertion point for each group
    local grouping = HeaderData.Groupings[sorted[i]]
    if grouping.Post then
        grouping.Post(HeaderData.Rules, grouping, grouping.sharedSequence, output)
    end
end

for _,codetype in pairs(HeaderData.Enums) do
    local f_output = HeaderData.Structure[codetype].Rules
    local rules = HeaderData.Rules[codetype]

    if f_output and #rules > 0 then
        f_output(rules, output)
    elseif f_output or #rules > 0 then
        error("Missing Rules function")
    end
end
