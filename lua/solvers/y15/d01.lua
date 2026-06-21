local function solve(input)
    local floor = 0
    local first_neg = nil
    for i = 1, #input, 1 do
        local char = input:sub(i, i)
        if char == "(" then
            floor = floor + 1
        elseif char == ")" then
            floor = floor - 1
        end
        if floor < 0 and first_neg == nil then first_neg = i end
    end
    return floor, first_neg
end

local function test()
    return true
end

return { solve_fn = solve, test_fn = test, input_mode = INPUT_MODE.FIRST_LINE }
